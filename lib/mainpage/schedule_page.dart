import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Separate file for the schedule page that was previously defined in
/// `home_page.dart`.  All helper widgets are kept private to the class
/// since they are not needed elsewhere.

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _selectedIndex = 1; // schedule tab active

  void _navigateTo(String title, {int? navIndex}) {
    if (navIndex != null) {
      setState(() => _selectedIndex = navIndex);
    }
    final lower = title.toLowerCase();
    if (lower.contains('home')) {
      // return to home route
      Navigator.popUntil(context, (route) => route.isFirst);
      setState(() => _selectedIndex = 0);
    }
    // additional tabs can be handled here as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A5D4A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sanitrax',
            style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNextPickupHero(),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Text('Weekly Schedule',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4A5D4A))),
            ),
            _buildScheduleList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildNextPickupHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
      decoration: const BoxDecoration(
        color: Color(0xFF4A5D4A),
        borderRadius:
            BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Text('Next Pickup',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          const Text('Tuesday, Oct 24',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timerUnit('14', 'HRS'),
              _timerUnit('22', 'MIN'),
              _timerUnit('05', 'SEC'),
            ],
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4A5D4A),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Pickup Details',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _timerUnit(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _scheduleCard('Monday', '07:00 AM - 09:00 AM', 'LANDFILL', false, 'COLLECTED'),
          _scheduleCard('Tuesday', '08:00 AM - 10:00 AM', 'ORGANIC WASTE', true, 'PENDING'),
          _scheduleCard('Wednesday', '08:00 AM - 11:00 AM', 'RECYCLING', false, null),
          _scheduleCard('Thursday', 'No Collection Scheduled', '', false, null),
          _scheduleCard('Friday', '07:00 AM - 09:00 AM', 'LANDFILL', false, null),
        ],
      ),
    );
  }

  Widget _scheduleCard(String day, String time, String type, bool isToday, String? status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF5B6B5B) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : const Color(0xFF4A5D4A))),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white24 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isToday ? Colors.white : Colors.grey)),
                      ),
                  ],
                ),
                Text(time,
                    style: TextStyle(
                        color: isToday ? Colors.white70 : Colors.grey, fontSize: 14)),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 16,
                          color: isToday ? Colors.white : const Color(0xFF4A5D4A)),
                      const SizedBox(width: 5),
                      Text(type,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : const Color(0xFF4A5D4A),
                              letterSpacing: 1)),
                    ],
                  ),
                ]
              ],
            ),
          ),
          if (isToday)
            const Icon(Icons.notifications_active, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 10), color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'HOME', _selectedIndex == 0, 0),
          _navItem(Icons.calendar_month, 'Schedule', _selectedIndex == 1, 1),
          _navItem(Icons.map, 'MAP', _selectedIndex == 2, 2),
          _navItem(Icons.settings, 'SETTINGS', _selectedIndex == 3, 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () => _navigateTo(label, navIndex: index),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: isActive ? const Color(0xFF4A5D4A) : Colors.grey),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? const Color(0xFF4A5D4A) : Colors.grey))
      ]),
    );
  }
}
