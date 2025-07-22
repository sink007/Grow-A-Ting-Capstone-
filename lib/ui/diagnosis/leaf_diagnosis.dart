import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

class LeafDiagnosisPage extends StatefulWidget {
  const LeafDiagnosisPage({super.key});

  @override
  State<LeafDiagnosisPage> createState() => _LeafDiagnosisPageState();
}

class _LeafDiagnosisPageState extends State<LeafDiagnosisPage> {
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
      "Cherry_(including_sour)___Powdery_mildew",
      "Cherry_(including_sour)___healthy"
    ],
    "Orange": [
      "orange_Black_spot",
      "orange_canker",
      "orange_greening",
      "orange_healthy"
    ],
    "Corn": [
      "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
      "Corn_(maize)___Common_rust_",
      "Corn_(maize)___Northern_Leaf_Blight",
      "Corn_(maize)___healthy"
    ],
    "Pepper": ["Pepper,_bell___Bacterial_spot", "Pepper,_bell___healthy"],
    "Potato": [
      "Potato___Early_blight",
      "Potato___Late_blight",
      "Potato___healthy"
    ],
    "Tomato": [
      "Tomato___Bacterial_spot",
      "Tomato___Early_blight",
      "Tomato___Late_blight",
      "Tomato___Leaf_Mold",
      "Tomato___Septoria_leaf_spot",
      "Tomato___Spider_mites Two-spotted_spider_mite",
      "Tomato___Target_Spot",
      "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
      "Tomato___Tomato_mosaic_virus",
      "Tomato___healthy"
    ],
    "Cassava": [
      "cassava- bacterial blight",
      "cassava- brown spot",
      "cassava- green mite",
      "cassava- healthy",
      "cassava- mosaic"
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadClassNames();
    _loadDiagnosisHistory();
  }

  Future<void> _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/diagnosis/plant_modelV2.tflite');
  }

  Future<void> _loadClassNames() async {
    final jsonString =
        await rootBundle.loadString('assets/diagnosis/classV2_names.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _classNames = jsonList.cast<String>();
  }

  Future<void> _loadDiagnosisHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final res = await _supabase
          .from('response')
          .select('*, diagnosis (plant_type, timestamp, user_id)')
          .order('diagnosis_date', ascending: false);

      final filtered =
          res.where((r) => r['diagnosis']['user_id'] == userId).toList();

      setState(() {
        _diagnosisHistory = List<Map<String, dynamic>>.from(filtered);
      });

      print("✅ Loaded ${filtered.length} diagnosis results");
    } catch (e) {
      print("❌ Failed to load history: $e");
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      final file = File(picked.path);
      setState(() {
        _image = file;
        _result = null;
      });
      await _runDiagnosis(file);
    }
  }

  Future<void> _runDiagnosis(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print("❌ No user logged in");
      return;
    }

    if (_selectedCrop == null || !plantDiseaseMap.containsKey(_selectedCrop)) {
      setState(() => _result = 'Please select a valid crop first.');
      return;
    }

    final oriImage = img.decodeImage(await imageFile.readAsBytes());
    if (oriImage == null) return;

    final resized = img.copyResize(oriImage, width: 256, height: 256);
    final input = List.generate(
        1,
        (_) => List.generate(
            256,
            (y) => List.generate(256, (x) {
                  final pixel = resized.getPixel(x, y);
                  return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
                })));

    var output =
        List.filled(_classNames.length, 0.0).reshape([1, _classNames.length]);
    _interpreter.run(input, output);

    final rawOutput = output[0] as List<double>;
    final allowedLabels = plantDiseaseMap[_selectedCrop]!;
    final allowedIndices = [
      for (int i = 0; i < _classNames.length; i++)
        if (allowedLabels.contains(_classNames[i])) i
    ];

    final filtered = List<double>.filled(_classNames.length, 0);
    double total = 0;
    for (final i in allowedIndices) {
      filtered[i] = rawOutput[i];
      total += rawOutput[i];
    }
    for (final i in allowedIndices) {
      filtered[i] = total > 0 ? filtered[i] / total : 0.0;
    }

    final maxIndex = filtered
        .indexWhere((v) => v == filtered.reduce((a, b) => a > b ? a : b));
    final prediction = _classNames[maxIndex];
    final confidence = filtered[maxIndex];

    String description = '';
    String solution = '';
    if (prediction.toLowerCase().contains('early_blight')) {
      description =
          'Early blight is a common disease in potato caused by a fungus.';
      solution =
          'Remove infected leaves. Apply a fungicide if necessary. Practice crop rotation.';
    } else if (prediction.toLowerCase().contains('gray_leaf') ||
        prediction.toLowerCase().contains('cercospora')) {
      description =
          'Gray leaf spot is a fungal disease affecting corn, causing rectangular lesions.';
      solution =
          'Avoid overhead watering. Use resistant varieties. Apply fungicides early if needed.';
    } else if (prediction.toLowerCase().contains('healthy')) {
      description = 'The plant appears healthy.';
      solution = 'Continue proper care and regular monitoring.';
    } else {
      description = 'No detailed info available.';
      solution = 'Consider consulting an expert or extension officer.';
    }

    setState(() {
      _result =
          "$prediction\nConfidence: ${(confidence * 100).toStringAsFixed(2)}%";
    });

    try {
      final now = DateTime.now();
      final fileName = "${now.millisecondsSinceEpoch}.jpg";
      final path = '$userId/$fileName';
      final imageBytes = await imageFile.readAsBytes();

      final uploadRes = await _supabase.storage
          .from('private-uploads')
          .uploadBinary(path, imageBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'));

      print('✅ Upload key: $uploadRes');

      String signedUrl = '';
      try {
        signedUrl = await _supabase.storage
            .from('private-uploads')
            .createSignedUrl(path, 3600);
        print("✅ Signed URL created: $signedUrl");
      } catch (e) {
        print("⚠️ Failed to create signed URL: $e");
      }

      final imageInsert = await _supabase
          .from('image')
          .insert({
            'img_name': fileName,
            'file_path': path,
            'signed_key': signedUrl,
            'date_info': now.toIso8601String(),
          })
          .select()
          .single();
      final imageId = imageInsert['image_id'];
      print("✅ Image DB row inserted: $imageId");

      final diagnosisInsert = await _supabase
          .from('diagnosis')
          .insert({
            'user_id': userId,
            'image_id': imageId,
            'result': [prediction],
            'timestamp': now.toIso8601String(),
            'plant_type': [_selectedCrop],
          })
          .select()
          .single();
      final diagnosisId = diagnosisInsert['diagnosis_id'];
      print("✅ Diagnosis DB row inserted: $diagnosisId");

      await _supabase.from('response').insert({
        'diagnosis_id': diagnosisId,
        'result': prediction,
        'description': description,
        'solution': solution,
        'diagnosis_confidence': confidence,
        'diagnosis_date': now.toIso8601String(),
      });
      print("✅ Response saved");

      await _loadDiagnosisHistory();
    } catch (e) {
      print("❌ Something went wrong: $e");
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
              'Leaf Diagnosis',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          // Modern Dropdown with white background menu
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
            decoration: InputDecoration(
              labelText: 'Crop Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            dropdownColor: Colors.white, // White background for dropdown menu
            menuMaxHeight: 300, // Prevent menu from being too tall
            isExpanded: true, // Ensure menu aligns properly below field
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              
              ElevatedButton.icon(
                onPressed: () => _pickImageFromSource(ImageSource.gallery),
                icon: const Icon(Icons.image, size: 20),
                label: const Text('Gallery', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () => _pickImageFromSource(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text('Camera', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
         
          const SizedBox(height: 16),
          if (_result != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          if (_diagnosisHistory.isEmpty)
              Column(
                children: [
                  Image.asset('assets/images/potted-plants.png', height: 150),
                  const SizedBox(height: 16),
                  const Text(
                    "No previous diagnoses found",
                    style: TextStyle(color:Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    "Start diagnosing to dig deeper into plant health!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
          ..._diagnosisHistory.map((entry) =>
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry['result'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 8),
                      Text("Crop: ${entry['diagnosis']['plant_type']}",
                        style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Text("Confidence: ${(entry['diagnosis_confidence'] * 100).toStringAsFixed(2)}%",
                        style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Text("Description: ${entry['description']}",
                        style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Text("Solution: ${entry['solution']}",
                        style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          entry['diagnosis']['timestamp']
                              .toString()
                              .split('T')
                              .first,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    ),
  );
}









}
