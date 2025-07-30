import 'package:flutter/material.dart';

enum AlertType {
  tooHot,
  tooCold,
}

class TemperatureAlert {
  final String plantName;
  final String message;
  final AlertType type;

  TemperatureAlert({
    required this.plantName,
    required this.message,
    required this.type,
  });
}

class WeatherAlertCard extends StatefulWidget {
  final List<TemperatureAlert> alerts;
  final double currentTemperature;
  final VoidCallback? onSeeAllPressed;

  const WeatherAlertCard({
    super.key,
    required this.alerts,
    required this.currentTemperature,
    this.onSeeAllPressed,
  });

  @override
  State<WeatherAlertCard> createState() => _WeatherAlertCardState();
}

class _WeatherAlertCardState extends State<WeatherAlertCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.tooHot:
        return Colors.orange;
      case AlertType.tooCold:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.tooHot:
        return Icons.wb_sunny;
      case AlertType.tooCold:
        return Icons.ac_unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Shows only the first 2 alerts as a preview
    // and a "See All" button if there are more than 2 alerts
    final displayedAlerts = widget.alerts.take(2).toList();
    final hasMoreAlerts = widget.alerts.length > 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Header with title and expand/collapse button
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Timely Cares',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        '${widget.alerts.length} alert${widget.alerts.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current temperature info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.thermostat,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Temperature: ${widget.currentTemperature.round()}°C',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alert list (showing only first 2)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedAlerts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final alert = displayedAlerts[index];
                        final alertColor = _getAlertColor(alert.type);
                        final alertIcon = _getAlertIcon(alert.type);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: alertColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: alertColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                alertIcon,
                                color: alertColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  alert.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // See All button (if there are more than 2 alerts)
                    if (hasMoreAlerts) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: widget.onSeeAllPressed,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.grey[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'See All ${widget.alerts.length} Alerts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[700],
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Helpful tip
                    if (widget.alerts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.green[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: Monitor temperature regularly and adjust plant locations as needed.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}