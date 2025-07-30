import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/user_plant.dart';
import '../ui/plant_diary/plant_diary.dart';

class PlantDiaryWidget extends StatefulWidget {
  final UserPlant userPlant;
  final List<Map<String, dynamic>> diaryEntries;
  final bool isLoading;
  final VoidCallback onRefresh;

  const PlantDiaryWidget({
    super.key,
    required this.userPlant,
    required this.diaryEntries,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<PlantDiaryWidget> createState() => _PlantDiaryWidgetState();
}

class _PlantDiaryWidgetState extends State<PlantDiaryWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredEntries = [];
  DateTime? _selectedDate;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _filteredEntries = widget.diaryEntries;
  }

  @override
  void didUpdateWidget(PlantDiaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diaryEntries != widget.diaryEntries) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredEntries = widget.diaryEntries.where((entry) {
        // Search filter
        bool matchesSearch = true;
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          final note = entry['note']?.toString().toLowerCase() ?? '';
          matchesSearch = note.contains(searchTerm);
        }

        // Date filter (single date - check if entry is on the same day)
        bool matchesDate = true;
        if (_selectedDate != null) {
          final entryDate = DateTime.parse(entry['entry_date']);
          final selectedDateOnly = DateTime(
              _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
          final entryDateOnly =
              DateTime(entryDate.year, entryDate.month, entryDate.day);
          matchesDate = selectedDateOnly.isAtSameMomentAs(entryDateOnly);
        }

        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF399942),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _applyFilters();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _applyFilters();
      }
    });
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search and filter buttons row
          Row(
            children: [
              Expanded(
                child: _showSearchBar
                    ? TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search notes...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF399942)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide:
                                const BorderSide(color: Color(0xFF399942)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => _applyFilters(),
                      )
                    : Text(
                        'Diary Entries (${_filteredEntries.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _toggleSearch,
                icon: Icon(
                  _showSearchBar ? Icons.close : Icons.search,
                  color: const Color(0xFF399942),
                ),
              ),
              IconButton(
                onPressed: _showDatePicker,
                icon: Icon(
                  Icons.calendar_today,
                  color: _selectedDate != null
                      ? const Color(0xFF399942)
                      : Colors.grey,
                ),
              ),
            ],
          ),

          // Active filters display
          if (_selectedDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF399942).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF399942).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFF399942)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF399942),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: const Icon(Icons.close,
                        size: 14, color: Color(0xFF399942)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<Map<String, dynamic>> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 120,
      height: 90,
      child: _buildMultiImageGrid(images),
    );
  }

  Widget _buildMultiImageGrid(List<Map<String, dynamic>> images) {
    // Always show as 2x2 grid like in the example
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Top row
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridImage(
                    images.isNotEmpty ? images[0] : null,
                    isTopLeft: true,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: _buildGridImage(
                    images.length > 1 ? images[1] : null,
                    isTopRight: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Bottom row
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGridImage(
                    images.length > 2 ? images[2] : null,
                    isBottomLeft: true,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    children: [
                      _buildGridImage(
                        images.length > 3 ? images[3] : null,
                        isBottomRight: true,
                      ),
                      // Show count overlay if more than 4 images
                      if (images.length > 4)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImage(
    Map<String, dynamic>? image, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    BorderRadius borderRadius = BorderRadius.zero;

    if (isTopLeft) {
      borderRadius = const BorderRadius.only(topLeft: Radius.circular(8));
    } else if (isTopRight) {
      borderRadius = const BorderRadius.only(topRight: Radius.circular(8));
    } else if (isBottomLeft) {
      borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(8));
    } else if (isBottomRight) {
      borderRadius = const BorderRadius.only(bottomRight: Radius.circular(8));
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Colors.grey[200],
      ),
      child: image != null
          ? ClipRRect(
              borderRadius: borderRadius,
              child: Image.network(
                image['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 16,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Colors.grey[100],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF399942),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchAndFilterBar(),

          // Diary entries list
          Expanded(
            child: _filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isNotEmpty ||
                                  _selectedDate != null
                              ? Icons.search_off
                              : Icons.book_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty ||
                                  _selectedDate != null
                              ? 'No entries found'
                              : 'No diary entries yet',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        if (_searchController.text.isNotEmpty ||
                            _selectedDate != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _clearDateFilter();
                            },
                            child: const Text(
                              'Clear filters',
                              style: TextStyle(color: Color(0xFF399942)),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: widget.onRefresh,
                            child: const Text(
                              'Refresh',
                              style: TextStyle(color: Color(0xFF399942)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      widget.onRefresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        final entryDate = DateTime.parse(entry['entry_date']);
                        final formattedDate =
                            DateFormat('EEEE, MMM d, yyyy').format(entryDate);
                        final images =
                            entry['images'] as List<Map<String, dynamic>>? ??
                                [];

                        return GestureDetector(
                          onTap: () => _showEntryDetail(context, entry, images),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFF2F8F2), // Very light green
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF399942).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main content row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left side - Note text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (entry['note'] != null &&
                                              entry['note']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text(
                                              entry['note'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            Text(
                                              images.length == 1
                                                  ? 'Photo entry'
                                                  : images.length > 1
                                                      ? '${images.length} photos'
                                                      : 'Diary entry',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Right side - Image grid (always show grid area)
                                    _buildImageGrid(images),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Bottom row - Date and menu
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _showEntryOptions(context, entry),
                                      child: const Icon(
                                        Icons.more_horiz,
                                        color: Colors.black54,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      // Floating Action Button to add new entry
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PlantDiaryPage(),
            ),
          ).then((_) {
            widget.onRefresh();
          });
        },
        backgroundColor: const Color(0xFF399942),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEntryDetail(BuildContext context, Map<String, dynamic> entry,
      List<Map<String, dynamic>> images) {
    final entryDate = DateTime.parse(entry['entry_date']);
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(entryDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images section
                      if (images.isNotEmpty) ...[
                        SizedBox(
                          height: MediaQuery.of(context).size.width * 0.75,
                          child: PageView.builder(
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    images[index]['image_url'],
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image indicators
                        if (images.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // Note section
                      if (entry['note'] != null &&
                          entry['note'].toString().isNotEmpty) ...[
                        const Text(
                          'Note',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry['note'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryOptions(BuildContext context, Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF399942)),
              title: const Text('Edit Entry'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit entry page
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Entry'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, entry);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content:
            const Text('Are you sure you want to delete this diary entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(context, entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(BuildContext context, Map<String, dynamic> entry) {
    // TODO: Implement actual delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete functionality not implemented yet'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
