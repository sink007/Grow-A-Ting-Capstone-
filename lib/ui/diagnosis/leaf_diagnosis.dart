import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'scan_camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:grow_a_ting/widgets/diagnosis_popup.dart';
import 'dart:ui' as ui;
import 'package:grow_a_ting/services/plant_identify_api.dart';

class LeafDiagnosisPage extends StatefulWidget {
  const LeafDiagnosisPage({super.key});

  @override
  State<LeafDiagnosisPage> createState() => _LeafDiagnosisPageState();
}

class _LeafDiagnosisPageState extends State<LeafDiagnosisPage> {
  bool _uiReady = false;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  File? _image;
  String? _result;
  late Interpreter _interpreter;
  late List<String> _classNames;
  List<Map<String, dynamic>> _diagnosisHistory = [];

  String? _selectedCrop;

  final Map<String, List<String>> plantDiseaseMap = {
    "Cherry": [
      "Cherry - Powdery Mildew",
      "Cherry - Healthy"
    ],
    "Corn": [
      "Corn - Cercospora/Gray Leaf Spot",
      "Corn - Common Rust",
      "Corn - Northern Leaf Blight",
      "Corn - Healthy"
    ],
    "Sweet Pepper": [
      "Pepper - Bacterial Spot",
      "Pepper - Healthy"
    ],
    "Potato": [
      "Potato - Early Blight",
      "Potato - Late Blight",
      "Potato - Healthy"
    ],
    "Cassava": [
      "Cassava - Bacterial Blight",
      "Cassava - Brown Spot",
      "Cassava - Green Mite",
      "Cassava - Healthy",
      "Cassava - Mosaic Virus"
    ],
    "Orange": [
      "Orange - Black Spot",
      "Orange - Canker",
      "Orange - Greening",
      "Orange - Healthy"
    ],
    "Tomato": [
      "Tomato - Early Blight",
      "Tomato - Healthy",
      "Tomato - Late Blight",
      "Tomato - Magnesium Deficiency",
      "Tomato - Nitrogen Deficiency"
    ]
  };


  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadModel();
    await _loadClassNames();
    await _loadDiagnosisHistory();

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _uiReady = true;
    });
  }

  void _showDiagnosisPopup({
    required String title,
    required String description,
    required String solution,
    required File image,
    double? confidence, // ✅ Make this optional
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DiagnosisPopup(
        title: title,
        description: description,
        solution: solution,
        image: image,
        confidence: confidence, // ✅ Pass as nullable
        onClose: () {
          setState(() {
            _image = null;
            _result = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _loadModel() async {
    _interpreter =
    await Interpreter.fromAsset('assets/diagnosis/plant_modelV2_transfer.tflite');
  }

  Future<void> _loadClassNames() async {
    final jsonString = await rootBundle.loadString(
        'assets/diagnosis/classV2_names.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _classNames = jsonList.cast<String>();
    print("🔍 Loaded ${_classNames.length} class labels.");
  }

  Future<void> _loadDiagnosisHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('response')
          .select('*, diagnosis (plant_type, timestamp, user_id, image:image_id (signed_key))')
          .order('diagnosis_date', ascending: false);

      final filtered = res
          .where((r) => r['diagnosis']['user_id'] == userId)
          .toList();

      setState(() {
        _diagnosisHistory = List<Map<String, dynamic>>.from(filtered);
      });

      print("✅ Loaded ${filtered.length} diagnosis results");
    } catch (e) {
      print("❌ Failed to load history: $e");
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a crop type first.")),
      );
      return;
    }

    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final file = File(picked.path);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Preview"),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, height: 200),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context); // close preview
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Dialog(
                    backgroundColor: Colors.transparent,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );

                await Future.delayed(const Duration(seconds: 1));
                Navigator.of(context, rootNavigator: true).pop(); // close loader

                _runDiagnosis(file);
              },
              icon: const Icon(Icons.search),
              label: const Text("Run Diagnosis"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade300,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _runDiagnosis(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print("No user logged in");
      return;
    }

    final isLeaf = await PlantIdApi.isLeaf(imageFile);

    if (!isLeaf) {
      _showDiagnosisPopup(
        title: "Unrecognized Image",
        description: "This doesn't appear to be a valid leaf.",
        solution: "Please retake the photo with better lighting and angle.",
        image: imageFile,
      );
      return;
    }
    if (_selectedCrop == null || !plantDiseaseMap.containsKey(_selectedCrop)) {
      setState(() => _result = 'Please select a valid crop first.');
      return;
    }

    final oriImage = img.decodeImage(await imageFile.readAsBytes());
    if (oriImage == null) return;

    final resized = img.copyResize(oriImage, width: 224, height: 224);
    final input = List.generate(1, (_) =>
        List.generate(224, (y) =>
            List.generate(224, (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            })));

    var output = List.filled(_classNames.length, 0.0).reshape([1, _classNames.length]);
    _interpreter.run(input, output);

    final rawOutput = output[0] as List<double>;
    final allowedLabels = plantDiseaseMap[_selectedCrop]!;
    final allowedSet = allowedLabels.map((e) => e.trim()).toSet();

    print(' Checking matches for $_selectedCrop...');
    print('Allowed: $allowedSet');

    final allowedIndices = <int>[];
    for (int i = 0; i < _classNames.length; i++) {
      final modelLabel = _classNames[i].trim();
      if (allowedSet.contains(modelLabel)) {
        allowedIndices.add(i);
      }
    }

    if (allowedIndices.isEmpty) {
      print("No matching labels found for $_selectedCrop");
      setState(() => _result = ' No matching disease labels for $_selectedCrop');
      return;
    }

    final filtered = List<double>.filled(_classNames.length, 0);
    double total = 0;
    for (final i in allowedIndices) {
      filtered[i] = rawOutput[i];
      total += rawOutput[i];
    }
    for (final i in allowedIndices) {
      filtered[i] = total > 0 ? filtered[i] / total : 0.0;
    }

    final maxIndex = allowedIndices.reduce((a, b) =>
    filtered[a] > filtered[b] ? a : b);

    final prediction = _classNames[maxIndex];
    final confidence = filtered[maxIndex];

    // Optional description/solution logic
    String description = '';
    String solution = '';
    if (prediction.contains('Early Blight')) {
      description = 'Early blight is a fungal disease common in tomatoes and potatoes. It starts as dark, concentric spots on older leaves and can spread rapidly if not treated.';
      solution = 'Carefully prune off affected leaves and dispose of them away from your garden. Apply a garden-safe fungicide weekly. Space plants well and avoid watering the leaves to reduce humidity.';
    } else if (prediction.contains('Late Blight')) {
      description = 'Late blight is a fast-spreading disease that affects leaves, stems, and fruit, especially in cool, wet conditions. It causes dark, mushy patches that quickly rot.';
      solution = 'Immediately remove and bag infected plants—don’t compost them. Use a copper-based fungicide if detected early. Try to water at the soil level to keep leaves dry.';
    } else if (prediction.contains('Common Rust')) {
      description = 'Common rust appears as reddish-brown pustules on corn leaves, slowing plant growth and reducing yield.';
      solution = 'Plant rust-resistant corn varieties at home. Remove infected leaves and keep garden tools clean. A fungicide spray may help if used early.';
    } else if (prediction.contains('Northern Leaf Blight')) {
      description = 'This fungal disease causes long, gray-green or tan streaks on corn leaves, often forming in humid, rainy conditions.';
      solution = 'Use resistant corn seeds when planting. Rotate your crops each season. If needed, apply a home-garden-approved fungicide.';
    } else if (prediction.contains('Gray Leaf Spot') || prediction.contains('Cercospora')) {
      description = 'Gray leaf spot causes narrow, rectangular lesions on corn leaves. It thrives in warm, humid environments and spreads via spores.';
      solution = 'Space corn plants to allow air flow. Avoid watering from above. Use a preventive fungicide early in the season if this has been an issue in your area.';
    } else if (prediction.contains('Powdery Mildew')) {
      description = 'Powdery mildew is a fungal infection that looks like white powder on leaf surfaces. It weakens the plant by reducing photosynthesis.';
      solution = 'Cut off infected leaves and avoid watering the leaves directly. Spray homemade remedies like diluted baking soda or use sulfur-based fungicides.';
    } else if (prediction == 'Pepper - Bacterial Spot') {
      description = 'This disease causes dark, greasy-looking spots on pepper leaves and fruit, especially during hot and wet periods.';
      solution = 'Use copper-based sprays. Water plants early in the day at the base, not on the leaves. Avoid planting peppers in the same spot next season.';
    } else if (prediction == 'Cassava - Bacterial Blight') {
      description = 'Cassava bacterial blight leads to wilting, water-soaked leaf spots, and plant death in severe cases.';
      solution = 'Only plant healthy cuttings. Remove and destroy affected plants. Sterilize tools and avoid working with wet plants.';
    } else if (prediction.contains('Magnesium Deficiency')) {
      description = 'Older leaves turn yellow between the veins while the veins stay green. This can affect fruit development in tomatoes.';
      solution = 'Mix Epsom salt (magnesium sulfate) in water (1 tablespoon per gallon) and spray on leaves or water the soil once every two weeks.';
    } else if (prediction.contains('Nitrogen Deficiency')) {
      description = 'Plants look pale and weak, with older leaves turning yellow first. Growth is usually stunted.';
      solution = 'Apply organic compost, well-rotted manure, or a balanced fertilizer. Mulch well to retain nutrients.';
    } else if (prediction.contains('Canker')) {
      description = 'Canker causes dark, sunken lesions on stems and branches, leading to dieback or fruit drop in citrus trees.';
      solution = 'Cut off and burn infected areas. Disinfect pruning tools between cuts. Apply copper sprays as prevention.';
    } else if (prediction.contains('Black Spot')) {
      description = 'Black spot leads to small, dark lesions on leaves, often followed by yellowing and leaf drop. Common in oranges.';
      solution = 'Remove fallen and infected leaves. Use neem oil or a fungicide spray. Avoid watering from above.';
    } else if (prediction.contains('Greening')) {
      description = 'Citrus greening (HLB) is a deadly disease spread by tiny insects called psyllids. It causes yellow shoots, misshapen fruit, and leaf drop.';
      solution = 'Remove infected trees immediately. Control psyllids using horticultural oils or insecticidal soap. Plant certified disease-free trees.';
    } else if (prediction.contains('Brown Spot')) {
      description = 'Brown spot creates round to irregular brown lesions on cassava leaves. It can weaken the plant and lower yields.';
      solution = 'Use clean planting material. Remove damaged leaves. Keep the area weed-free and apply fungicide if needed.';
    } else if (prediction.contains('Green Mite')) {
      description = 'Green mites suck sap from cassava leaves, causing curling, yellowing, and stunted growth.';
      solution = 'Encourage natural predators like ladybugs or use neem oil. Resistant cassava varieties help reduce risk.';
    } else if (prediction.contains('Mosaic')) {
      description = 'Mosaic virus causes patchy green/yellow leaves and twisted stems. It spreads through infected cuttings or whiteflies.';
      solution = 'Plant only certified virus-free cuttings. Uproot infected plants immediately. Control whiteflies with insecticidal soap.';
    } else if (prediction.contains('Healthy')) {
      description = 'The leaf shows no signs of disease or deficiency at this time.';
      solution = 'Maintain regular watering, fertilizing, and pest checks. Keep leaves dry and remove any debris around the plant.';
    }

    _showDiagnosisPopup(
        title: prediction,
        description: description,
        solution: solution.contains('\n') ? solution : solution.replaceAll('. ', '.\n'),
        image: imageFile,
        confidence: confidence
    );



    try {
      final now = DateTime.now();
      final fileName = "${now.millisecondsSinceEpoch}.jpg";
      final folder = 'diagnosis-images/$userId';
      final fullPath = '$folder/$fileName';
      final imageBytes = await imageFile.readAsBytes();

      // Upload image
      try {
        await _supabase.storage
            .from('private-uploads')
            .uploadBinary(
          fullPath,
          imageBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

        print('Upload successful: $fullPath');
      } catch (e) {
        print('Upload failed: $e');
        return;
      }

      // Optional: confirm file appears in folder list
      final files = await _supabase.storage
          .from('private-uploads')
          .list(path: folder);

      // Create signed URL with retry
      String signedUrl = '';
      try {
        signedUrl = await _supabase.storage
            .from('private-uploads')
            .createSignedUrl(fullPath, 60 * 60 * 24 * 30);
        print("Signed URL created: $signedUrl");
      } catch (e) {
        print("Signed URL failed first try: $e");
      }

      // Insert image record
      int imageId;
      try {
        final imageInsert = await _supabase.from('image').insert({
          'img_name': fileName,
          'file_path': fullPath,
          'signed_key': signedUrl,
          'date_info': now.toIso8601String(),
        }).select().single();

        imageId = imageInsert['image_id'];
        print("Image DB row inserted: $imageId");
      } catch (e) {
        print("Image insert failed: $e");
        return;
      }

      // Insert diagnosis and response
      try {
        final diagnosisInsert = await _supabase.from('diagnosis').insert({
          'user_id': userId,
          'image_id': imageId,
          'result': [prediction],
          'timestamp': now.toIso8601String(),
          'plant_type': [_selectedCrop],
        }).select().single();

        final diagnosisId = diagnosisInsert['diagnosis_id'];
        print("Diagnosis DB row inserted: $diagnosisId");

        await _supabase.from('response').insert({
          'diagnosis_id': diagnosisId,
          'result': prediction,
          'description': description,
          'solution': solution,
          'diagnosis_confidence': confidence,
          'diagnosis_date': now.toIso8601String(),
        });
        print("Response saved");
      } catch (e) {
        print("Diagnosis or response insert failed: $e");
        return;
      }

      await _loadDiagnosisHistory();

    } catch (e) {
      print("Top-level error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!_uiReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaf Diagnosis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("How to Use & Info"),
                  content: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "1. Select your crop type.\n"
                                "2. Upload or take a picture of the leaf.\n"
                                "3. Wait for the system to analyze the image and show results.",
                          ),
                          SizedBox(height: 12),
                          Text(
                            "About This System:\n"
                                "This system uses AI to detect plant diseases. While trained for accuracy, AI can still make mistakes. "
                                " Each crop currently supports a limited set of diseases — more crops and their respective diseases will be added in the future.",
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Supported Diseases:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          Text("• Cherry"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text("• Powdery Mildew"),
                          ),

                          SizedBox(height: 8),
                          Text("• Corn"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Cercospora / Gray Leaf Spot"),
                                Text("• Common Rust"),
                                Text("• Northern Leaf Blight"),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),
                          Text("• Pepper"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text("• Bacterial Spot"),
                          ),

                          SizedBox(height: 8),
                          Text("• Potato"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Early Blight"),
                                Text("• Late Blight"),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),
                          Text("• Cassava"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Bacterial Blight"),
                                Text("• Brown Spot"),
                                Text("• Green Mite"),
                                Text("• Mosaic Virus"),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),
                          Text("• Orange"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Black Spot"),
                                Text("• Canker"),
                                Text("• Greening"),
                              ],
                            ),
                          ),

                          SizedBox(height: 8),
                          Text("• Tomato"),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• Early Blight"),
                                Text("• Late Blight"),
                                Text("• Magnesium Deficiency"),
                                Text("• Nitrogen Deficiency"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16), // Shift dropdown down
            DropdownButtonFormField<String>(
              value: _selectedCrop,
              hint: const Text('Select Crop Type'), 
              onChanged: (value) {
                setState(() {
                  _selectedCrop = value!;
                  _result = null;
                  _image = null;
                });
              },
              items: plantDiseaseMap.keys.map((crop) {
                return DropdownMenuItem<String>(
                  value: crop,
                  child: Text(crop),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Crop Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImageFromSource(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedCrop == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a crop type first.")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanCameraPage(
                          onImageCaptured: _runDiagnosis, // auto-run your model
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _result!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 30),
            const Text(
              'Previous Diagnoses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 80),
            if (_diagnosisHistory.isEmpty)
              Image.asset(
                'assets/images/potted-plants.png',
                height: 150,
              ),
              const Center(child: Text("No previous diagnoses found.")),
            ..._diagnosisHistory.map((entry) {
              final rawName = (entry['result'] ?? '') as String;
              final crop = (entry['diagnosis']['plant_type'] as List?)?.join(', ') ?? 'Unknown';

              // Remove crop name from result
              String removeCropPrefix(String diseaseName, String cropName) {
                final parts = diseaseName.split(' - ');
                if (parts.length != 2) return diseaseName.trim();
                final crop = parts[0].trim().toLowerCase();
                final name = parts[1].trim();
                if (cropName.toLowerCase() == crop) return name;
                return diseaseName.trim();
              }

              final cleanedName = removeCropPrefix(rawName, crop);
              final description = entry['description'] ?? '';
              final solution = entry['solution'] ?? '';
              final signedUrl = entry['diagnosis']['image']?['signed_key'] ?? '';
              final date = entry['diagnosis']['timestamp']?.toString().split('T').first ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(cleanedName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Crop: $crop\nDate: $date"),
                  trailing: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => DiagnosisPopup(
                          title: rawName,
                          description: description,
                          solution: solution.contains('\n') ? solution : solution.replaceAll('. ', '.\n'),
                          image: null,
                          imageUrl: signedUrl,
                          onClose: () => Navigator.pop(context),
                        ),
                      );
                    },
                    child: const Text("Show Details"),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}