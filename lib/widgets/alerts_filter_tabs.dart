import 'package:flutter/material.dart';

class AlertsFilterTabs extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChanged;

  const AlertsFilterTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          _buildTab('All'),
          const SizedBox(width: 12),
          _buildTab('Reminders'),
          const SizedBox(width: 12),
          _buildTab('Delays'),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = activeTab == label;
    return GestureDetector(
      onTap: () => onTabChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF5E6F52) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
