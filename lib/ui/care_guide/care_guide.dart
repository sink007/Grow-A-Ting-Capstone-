     
import 'package:flutter/material.dart';
import '../../model/plant.dart';

class CareGuidePage extends StatefulWidget {
  final Plant plant;

  const CareGuidePage({super.key, required this.plant});

  @override
  State<CareGuidePage> createState() => _CareGuidePageState();
}

class _CareGuidePageState extends State<CareGuidePage> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isExpanded = false;
  
  // Track which sections are expanded
  final Map<String, bool> _sectionStates = {
    'description': true,
    'tools': false,
    'growth': false,
    'water': false,
    'pruning': false,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Auto-expand when scrolled down significantly
    if (_scrollController.offset > 100 && !_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName.toLowerCase()) {
      case 'watering can':
      case 'watering':
        return Icons.water_drop;
      case 'pruning shears':
      case 'pruning':
      case 'shears':
        return Icons.content_cut;
      case 'fertilizer':
      case 'plant food':
        return Icons.compost;
      case 'pot':
      case 'planter':
      case 'container':
        return Icons.inbox_rounded;
      case 'soil':
      case 'compost':
        return Icons.terrain_rounded;
      case 'spray bottle':
      case 'mister':
        return Icons.spa;
      case 'thermometer':
        return Icons.thermostat;
      case 'light':
      case 'grow light':
      case 'sunlight':
        return Icons.wb_sunny;
      default:
        return Icons.build;
    }
  }

  Color get _primaryGreen => const Color(0xFF025A1E);
  Color get _lightGreen => const Color(0xFFEEF8EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Image header
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      // Plant image
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: widget.plant.imageUrl != null
                            ? Image.network(
                                widget.plant.imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: _lightGreen,
                                child: Icon(
                                  Icons.local_florist,
                                  size: 80,
                                  color: _primaryGreen,
                                ),
                              ),
                      ),
                      
                      // Back button
                      Positioned(
                        top: 40,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content container that overlaps image
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 270,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plant name and info
                          _buildPlantHeader(),
                          
                          const SizedBox(height: 24),
                          
                          // Care requirements (always visible)
                          _buildCareRequirements(),
                          
                          const SizedBox(height: 16),
                          
                          // Expandable sections
                          if (widget.plant.description != null)
                            _buildExpandableSection(
                              'description',
                              'Description',
                              Icons.info_outline_rounded,
                              _buildDescriptionContent(),
                            ),
                          
                          if (widget.plant.toolsNeeded.isNotEmpty)
                            _buildExpandableSection(
                              'tools',
                              'Tools Needed',
                              Icons.grass_sharp,
                              _buildToolsContent(),
                            ),
                          
                          if (widget.plant.growthStages.isNotEmpty)
                            _buildExpandableSection(
                              'growth',
                              'Growth Stages',
                              Icons.spa,
                              _buildGrowthStagesContent(),
                            ),
                          
                          if (widget.plant.wateringCondition != null)
                            _buildExpandableSection(
                              'water',
                              'Water',
                              Icons.water_drop_outlined,
                              _buildWaterContent(),
                            ),
                          
                          if (widget.plant.pruning != null)
                            _buildExpandableSection(
                              'pruning',
                              'Pruning',
                              Icons.content_cut_outlined,
                              _buildPruningContent(),
                            ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlantHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Drag indicator
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        Text(
          widget.plant.commonName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _primaryGreen,
          ),
        ),
        
        if (widget.plant.scientificName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.plant.scientificName!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF399942),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCareRequirements() {
    return Row(
      children: [
        Expanded(
          child: _buildCareItem(
            Icons.wb_sunny,
            'Sunlight',
            widget.plant.sunlight ?? 'Full sun',
            Color(0xFFF7F169),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCareItem(
            Icons.water_drop,
            'Water',
            widget.plant.water ?? 'Every 3-4 days',
            Colors.blue.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildCareItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
        
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(String key, String title, IconData icon, Widget content) {
    bool isExpanded = _sectionStates[key] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF399942), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sectionStates[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: _primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: content,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent() {
    return Text(
      widget.plant.description!,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
        height: 1.5,
      ),
    );
  }

  Widget _buildToolsContent() {
    return Column(
      children: widget.plant.toolsNeeded.map((tool) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getToolIcon(tool.name),
                  color: _primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:_primaryGreen,
                      ),
                    ),
                    if (tool.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tool.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrowthStagesContent() {
    return Row(
      children: widget.plant.growthStages.map((stage) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.week,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stage.description,
                  style: TextStyle(
                    fontSize: 11,
                    color:_primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.plant.wateringCondition!.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPruningContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPruningItem('Condition', widget.plant.pruning!.condition),
        const SizedBox(height: 16),
        _buildPruningItem('Frequency', widget.plant.pruning!.frequency),
      ],
    );
  }

  Widget _buildPruningItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
