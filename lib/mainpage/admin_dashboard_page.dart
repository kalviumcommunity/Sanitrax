import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/auth/login_page.dart';
import 'package:flutter_application_1/mainpage/admin_live_tracking_map_page.dart';
import 'package:flutter_application_1/mainpage/schedule_page.dart';
import 'package:flutter_application_1/services/firestore_service.dart';
import 'package:flutter_application_1/services/geocoding_service.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/user_model.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _showAssignDriverDialog(BuildContext context) async {
    final firestore = FirestoreService();
    final areaController = TextEditingController();
    final cityController = TextEditingController();
    String? selectedDriverId;
    List<UserModel> drivers = <UserModel>[];
    bool geocoding = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Driver For Today'),
              content: FutureBuilder<List<UserModel>>(
                future: firestore.getUsersByRole('Driver'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  drivers = snapshot.data ?? <UserModel>[];
                  if (drivers.isEmpty) {
                    return const Text(
                      'No users with role Driver found. Create a driver account first.',
                    );
                  }

                  selectedDriverId ??= drivers.first.uid;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedDriverId,
                        decoration: const InputDecoration(labelText: 'Driver'),
                        items: drivers
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d.uid,
                                child: Text(
                                  '${d.name} (${d.email})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          selectedDriverId = value;
                        }),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: cityController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'City Name',
                          hintText: 'e.g. Coimbatore',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: areaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Area Name',
                          hintText: 'e.g. Saravanampatti',
                        ),
                      ),
                      if (geocoding) ...[
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Locating on map…'),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: geocoding
                      ? null
                      : () async {
                          if (drivers.isEmpty || selectedDriverId == null) {
                            return;
                          }
                          final area = areaController.text.trim();
                          final city = cityController.text.trim();
                          if (area.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter area name')),
                            );
                            return;
                          }

                          double? targetLat;
                          double? targetLng;

                          if (city.isNotEmpty) {
                            setState(() => geocoding = true);
                            final query = '$area, $city';
                            final point = await GeocodingService().geocode(
                              query,
                            );
                            setState(() => geocoding = false);
                            if (point != null) {
                              targetLat = point.latitude;
                              targetLng = point.longitude;
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not locate "$query" on map. '
                                    'Assignment saved without destination.',
                                  ),
                                ),
                              );
                            }
                          }

                          final driver = drivers.firstWhere(
                            (d) => d.uid == selectedDriverId,
                          );
                          await firestore.createOrUpdateDriverAssignment(
                            driverUid: driver.uid,
                            driverName: driver.name,
                            areaName: area,
                            assignedByUid:
                                FirebaseAuth.instance.currentUser?.uid ??
                                'admin',
                            targetLat: targetLat,
                            targetLng: targetLng,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  targetLat != null
                                      ? 'Assigned ${driver.name} to $area, $city — destination located on map.'
                                      : 'Assigned ${driver.name} to $area for today.',
                                ),
                              ),
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A5D4A),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.calendar_month,
                    label: 'Schedules',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SchedulePage()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.assignment_ind,
                    label: 'Assign Driver',
                    onTap: () => _showAssignDriverDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.map,
                    label: 'Live Route',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLiveTrackingMapPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Today Driver Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().streamTodayDriverCheckins(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Failed to load attendance: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final checkins = snapshot.data ?? <Map<String, dynamic>>[];
                  if (checkins.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('No drivers checked in today yet.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: checkins.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = checkins[index];
                      final ts = item['checkinAt'];
                      final when = ts is Timestamp
                          ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
                          : '--:--';
                      final driverName =
                          (item['driverName'] as String?) ?? 'Driver';
                      final areaName =
                          (item['areaName'] as String?) ?? 'Unknown area';
                      final selfieUrl = (item['selfieUrl'] as String?) ?? '';

                      return Container(
                        width: 230,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9F3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2EADF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFDFE8D8),
                                  backgroundImage: selfieUrl.isNotEmpty
                                      ? NetworkImage(selfieUrl)
                                      : null,
                                  child: selfieUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Color(0xFF4A5D4A),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driverName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        areaName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A7C59),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Checked in at $when',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<IssueModel>>(
                stream: FirestoreService().getIssues(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final issues = snapshot.data ?? <IssueModel>[];
                  if (issues.isEmpty) {
                    return const Center(child: Text('No issues reported yet.'));
                  }
                  return ListView.separated(
                    itemCount: issues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final issue = issues[index];
                      return ListTile(
                        tileColor: const Color(0xFFF5F5F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(issue.issueType),
                        subtitle: Text(issue.description),
                        trailing: Text(issue.status),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF3EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4A5D4A), size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
