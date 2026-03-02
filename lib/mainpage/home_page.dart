import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sanitrax_live_route_map.dart';

void main() => runApp(const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false));

/// --- Dummy Destination Page ---
class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF4A5D4A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A5D4A)),
      ),
      body: Center(
        child: Text(
          'Welcome to the $title Page',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 
  void _navigateTo(String title) {
    Widget page;
    if (title.toLowerCase().contains('track') ||
        title.toLowerCase().contains('live map') ||
        title.toLowerCase() == 'map') {
      page = const SanitraxLiveRouteMap();
    } else {
      page = DummyPage(title: title);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildMainContent(),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF4A5D4A), // Matches the dark olive in image
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TUESDAY\n15 NOVEMBER 22',
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE6CCB2),
                child: Icon(Icons.person, color: Colors.brown),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'My\nCollections',
            style: GoogleFonts.playfairDisplay( // High-contrast serif
              fontSize: 52,
              height: 0.85,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Household Waste',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Standard Curbside Pickup',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('ON TIME',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '10:15 AM',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBFBFB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 15),
            _buildMapCard(),
            const SizedBox(height: 20),
            _buildTrackButton(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FeatureButton(
                    icon: Icons.report_gmailerrorred_rounded,
                    title: 'Report\nMissed Pickup',
                    bgColor: const Color(0xFFFFEBEB), // Pale red background
                    iconColor: Colors.red,
                    onTap: () => _navigateTo("Report Missed Pickup"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FeatureButton(
                    icon: Icons.calendar_today_outlined,
                    title: 'Full\nSchedule',
                    bgColor: Colors.white,
                    iconColor: const Color(0xFF4A5D4A),
                    onTap: () => _navigateTo("Full Schedule"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            _buildSectionHeader('Upcoming'),
            const SizedBox(height: 15),
            _buildUpcomingCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4A5D4A))),
        SizedBox(
          height: 30,
          child: TextButton(
            onPressed: () => _navigateTo("All $title"),
            style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEFEFEF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: const Text('See All',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildMapCard() {
    return _PressableScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SanitraxLiveRouteMap())),
      child: Container(
        height: 190,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFFE8EDE7), Color(0xFFD9E1D4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, color: Color(0xFF4A5D4A), size: 28),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration:
                        BoxDecoration(color: const Color(0xFF4A5D4A), borderRadius: BorderRadius.circular(6)),
                    child: const Text('TRUCK 04',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT LOCATION',
                        style: GoogleFonts.inter(
                            fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    const Text('New York District 4',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4A5D4A))),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrackButton() {
    return _PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SanitraxLiveRouteMap(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: const Color(0xFF4A5D4A).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
            ]),
        child: ElevatedButton.icon(
          onPressed: null, // Tap handled by _PressableScale
          icon: const Icon(Icons.explore_outlined, size: 22, color: Colors.white),
          label: const Text('Track Live Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A5D4A),
            disabledBackgroundColor: const Color(0xFF4A5D4A),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard() {
    return _PressableScale(
      onTap: () => _navigateTo("Upcoming Details"),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text('WED', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
                  const Text('24',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4A5D4A))),
                ],
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paper & Cardboard',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF4A5D4A))),
                  Text('Standard Curbside',
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0), size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'HOME', true),
          _navItem(Icons.calendar_month, 'SCHEDULE', false),
          _navItem(Icons.map_outlined, 'MAP', false),
          _navItem(Icons.settings_outlined, 'SETTINGS', false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    Color color = isActive ? const Color(0xFF4A5D4A) : const Color(0xFFB0BEC5);
    return _PressableScale(
      onTap: () => _navigateTo(label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

/// --- Custom Feature Button with Scale Animation ---
class FeatureButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const FeatureButton({
    super.key,
    required this.icon,
    required this.title,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: bgColor == Colors.white
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]
              : [],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5D4A))),
          ],
        ),
      ),
    );
  }
}

/// --- Pressable Scale Widget with Animation ---
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}