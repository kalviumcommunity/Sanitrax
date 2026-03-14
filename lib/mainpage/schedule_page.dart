import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/models/schedule_model.dart';
import 'package:flutter_application_1/services/firestore_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _selectedIndex = 1;
  Timer? _timer;
  DateTime _now = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<ScheduleModel>> _schedulesStream;

  @override
  void initState() {
    super.initState();
    _schedulesStream = _firestoreService.getSchedules();
    _prepareSchedules();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _prepareSchedules() async {
    try {
      await _firestoreService.seedSchedulesIfEmpty();
      await _firestoreService.rollSchedulesForwardIfNeeded();
    } catch (_) {
      // Keep page usable even if writes fail due to rules or offline mode.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateTo(String title, {int? navIndex}) {
    if (navIndex != null) {
      setState(() => _selectedIndex = navIndex);
    }
    if (title.toLowerCase().contains('home')) {
      Navigator.popUntil(context, (route) => route.isFirst);
      setState(() => _selectedIndex = 0);
    }
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
        title: Text(
          'Sanitrax',
          style: GoogleFonts.playfairDisplay(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ScheduleModel>>(
        stream: _schedulesStream,
        builder: (context, snapshot) {
          final schedules = snapshot.data ?? <ScheduleModel>[];

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load schedules from Firestore.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (schedules.isEmpty) {
            return const Center(
              child: Text('No schedules found in Firestore yet.'),
            );
          }

          final next = _nextSchedule(schedules);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNextPickupHero(next),
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Text(
                    'Weekly Schedule',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4A5D4A),
                    ),
                  ),
                ),
                _buildScheduleList(schedules),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildNextPickupHero(ScheduleModel? next) {
    final nextTime = next?.nextCollectionDate.toDate();
    final remaining = nextTime == null
        ? Duration.zero
        : nextTime.difference(_now);
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    final hours = safeRemaining.inHours.toString().padLeft(2, '0');
    final minutes = (safeRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safeRemaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
      decoration: const BoxDecoration(
        color: Color(0xFF4A5D4A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Next Pickup',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            nextTime == null
                ? 'No schedule available'
                : '${next!.collectionDay} • ${_formatDate(nextTime)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          if (next != null)
            Text(
              next.wasteType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timerUnit(hours, 'HRS'),
              _timerUnit(minutes, 'MIN'),
              _timerUnit(seconds, 'SEC'),
            ],
          ),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleModel> schedules) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: schedules.map((schedule) {
          final date = schedule.nextCollectionDate.toDate();
          final isToday =
              date.year == _now.year &&
              date.month == _now.month &&
              date.day == _now.day;
          final isPast = date.isBefore(_now);

          return _scheduleCard(
            schedule.collectionDay,
            _formatDateTime(date),
            schedule.wasteType,
            isToday,
            isPast ? 'COLLECTED' : (isToday ? 'TODAY' : 'UPCOMING'),
          );
        }).toList(),
      ),
    );
  }

  Widget _scheduleCard(
    String day,
    String time,
    String type,
    bool isToday,
    String? status,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFF5B6B5B) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
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
                    Text(
                      day,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : const Color(0xFF4A5D4A),
                      ),
                    ),
                    if (status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.white24
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: isToday ? Colors.white70 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: isToday ? Colors.white : const Color(0xFF4A5D4A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : const Color(0xFF4A5D4A),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isToday)
            const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      color: Colors.white,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF4A5D4A) : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFF4A5D4A) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  ScheduleModel? _nextSchedule(List<ScheduleModel> schedules) {
    final upcoming =
        schedules
            .where((s) => !s.nextCollectionDate.toDate().isBefore(_now))
            .toList()
          ..sort(
            (a, b) => a.nextCollectionDate.toDate().compareTo(
              b.nextCollectionDate.toDate(),
            ),
          );

    if (upcoming.isNotEmpty) {
      return upcoming.first;
    }

    return schedules.isEmpty ? null : schedules.first;
  }

  String _formatDate(DateTime dt) {
    final m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(dt)} • $hour:$min $ampm';
  }
}
