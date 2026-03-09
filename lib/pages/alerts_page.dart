import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/alert_card.dart';
import '../widgets/alerts_filter_tabs.dart';
import '../mainpage/home_page.dart';
import '../mainpage/profile_page.dart';
import '../mainpage/sanitrax_live_route_map.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F2),
      body: Stack(
        children: [
          // Main Content Layout
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      _buildAlertList(),
                      const SizedBox(height: 100), // Bottom padding for Nav
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Bottom Navigation
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF5E6F52),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 44),
              const Text(
                'MARK ALL READ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Alerts',
            style: GoogleFonts.playfairDisplay(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifications and neighborhood updates',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          AlertsFilterTabs(
            activeTab: selectedFilter,
            onTabChanged: (tab) {
              setState(() {
                selectedFilter = tab;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlert(
            type: 'REMINDER',
            time: '2M AGO',
            title: 'Truck is 1 hour away',
            description:
                'The collection truck for your sector is approaching. Please ensure bins are on the curb.',
            icon: Icons.local_shipping,
            iconBgColor: const Color(0xFFF1F8F1),
            iconColor: const Color(0xFF5E6F52),
            hasIndicator: true,
            indicatorColor: const Color(0xFF5E6F52),
            delay: const Duration(milliseconds: 100),
          ),
          _buildAlert(
            type: 'DELAY',
            time: '45M AGO',
            title: 'Delay Update',
            description:
                'Recycling pickup is delayed by approx. 2 hours due to heavy traffic in the North Sector.',
            icon: Icons.warning_amber,
            iconBgColor: const Color(0xFFFFF8F0),
            iconColor: const Color(0xFFF2994A),
            hasIndicator: true,
            indicatorColor: const Color(0xFFF2994A),
            delay: const Duration(milliseconds: 200),
          ),
          _buildAlert(
            type: 'SCHEDULE',
            time: '3H AGO',
            title: 'Holiday Schedule Change',
            description:
                'Reminder: No pickup this Monday due to the public holiday. Tuesday routes will shift to Wednesday.',
            icon: Icons.calendar_today,
            iconBgColor: const Color(0xFFF0F7FF),
            iconColor: const Color(0xFF3498DB),
            delay: const Duration(milliseconds: 300),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'YESTERDAY',
              style: TextStyle(
                color: Color(0xFF8C968A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ),
          _buildAlert(
            type: 'COMPLETED',
            time: '1D AGO',
            title: 'Collection Completed',
            description: 'Your waste was successfully collected at 9:45 AM.',
            icon: Icons.check_circle,
            iconBgColor: const Color(0xFFF2F2F2),
            iconColor: const Color(0xFF999999),
            opacity: 0.7,
            delay: const Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert({
    required String type,
    required String time,
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    bool hasIndicator = false,
    Color? indicatorColor,
    double opacity = 1.0,
    Duration delay = Duration.zero,
  }) {
    // Basic filter logic
    if (selectedFilter == 'Reminders' && type != 'REMINDER')
      return const SizedBox.shrink();
    if (selectedFilter == 'Delays' && type != 'DELAY')
      return const SizedBox.shrink();

    return AlertCard(
      type: type,
      time: time,
      title: title,
      description: description,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      hasIndicator: hasIndicator,
      indicatorColor: indicatorColor,
      opacity: opacity,
      delay: delay,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_outlined, 'HOME', false),
            _buildNavItem(Icons.calendar_today_outlined, 'SCHEDULE', false),
            _buildNavItem(Icons.notifications, 'ALERTS', true),
            _buildNavItem(Icons.person_outline, 'PROFILE', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'HOME') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else if (label == 'SCHEDULE') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SanitraxLiveRouteMap()),
          );
        } else if (label == 'ALERTS') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AlertsPage()),
          );
        } else if (label == 'PROFILE') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF5E6F52) : const Color(0xFFC0C0C0),
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF5E6F52)
                  : const Color(0xFFC0C0C0),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
