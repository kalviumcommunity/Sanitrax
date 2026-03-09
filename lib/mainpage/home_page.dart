import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/mainpage/schedule_page.dart';
import 'package:flutter_application_1/mainpage/sanitrax_live_route_map.dart';
import 'package:flutter_application_1/mainpage/report_issue_page.dart';
import 'package:flutter_application_1/mainpage/profile_page.dart';

// TODO: Replace this placeholder with your actual Mapbox access token.
const String kMapboxAccessToken = 'pk.placeholder';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      title: 'Sanitrax',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // track current bottom nav selection so the icon can appear active
  int _selectedIndex = 0;

  // UPDATED: Navigation logic to include the Schedule Page
  void _navigateTo(String title, {int? navIndex}) {
    if (navIndex != null) {
      setState(() => _selectedIndex = navIndex);
    }
    final lower = title.toLowerCase();
    if (lower.contains('home')) {
      // return to home route
      Navigator.popUntil(context, (route) => route.isFirst);
      setState(() => _selectedIndex = 0);
    } else if (lower.contains('schedule')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SchedulePage()),
      );
    } else if (lower.contains('report') || lower.contains('issue')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReportIssuePage()),
      );
    } else if (lower.contains('track') ||
        lower.contains('live') ||
        lower.contains('map')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SanitraxLiveRouteMap()),
      );
    } else if (lower.contains('profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else if (lower.contains('alert')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlertsPage()),
      );
    }
    // additional tabs can be handled here as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [_buildHeader(), _buildMainContent()]),
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
      color: const Color(0xFF4A5D4A),
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SANITRAX\nPREMIUM SERVICE',
                  style: GoogleFonts.inter(color: Colors.white70, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
                },
                child: const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE6CCB2), child: Icon(Icons.person, color: Colors.brown)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Sanitrax',
            style: GoogleFonts.playfairDisplay(
              fontSize: 52,
              height: 0.85,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 35),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Household Waste',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Standard Sanitrax Pickup',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '10:15 AM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
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
            _buildSectionHeader('Sanitrax Actions'),
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
                    title: 'Report\nIssue',
                    bgColor: const Color(0xFFFFEBEB),
                    iconColor: Colors.red,
                    onTap: () => _navigateTo("Report Issue"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FeatureButton(
                    icon: Icons.calendar_today_outlined,
                    title: 'Pickup\nSchedule',
                    bgColor: Colors.white,
                    iconColor: const Color(0xFF4A5D4A),
                    onTap: () => _navigateTo("Schedule"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            _buildSectionHeader('Upcoming Bins'),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A5D4A),
          ),
        ),
        TextButton(
          onPressed: () => _navigateTo(title),
          child: const Text(
            'See All',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard() {
    final bool hasToken =
        kMapboxAccessToken.isNotEmpty && kMapboxAccessToken != 'pk.placeholder';

    return _PressableScale(
      onTap: () => _navigateTo("Map"),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: hasToken ? null : Colors.grey[300],
          image: hasToken
              ? DecorationImage(
                  image: NetworkImage(
                    'https://api.mapbox.com/styles/v1/mapbox/light-v10/static/-74.006,40.7128,12/600x400?access_token=$kMapboxAccessToken',
                  ),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFF4A5D4A),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackButton() {
    return _PressableScale(
      onTap: () => _navigateTo("Live Tracking"),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF4A5D4A),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Track Sanitrax Truck',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '24\nWED',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paper & Cardboard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Sanitrax Recycling',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
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
          _navItem(
            Icons.notifications_outlined,
            'ALERTS',
            _selectedIndex == 3,
            3,
          ),
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
}

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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: bgColor == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5D4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});
  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
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
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
