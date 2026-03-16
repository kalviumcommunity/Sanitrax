import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/issue_model.dart';
import 'package:flutter_application_1/models/schedule_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  //------------- User Methods -------------//

  /// Add a new user to the `users` collection in Firestore.
  /// The document ID will be the user's UID from Firebase Authentication.
  Future<void> addUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error adding user to Firestore: $e');
      rethrow;
    }
  }

  /// Get a user's profile data from Firestore.
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      rethrow;
    }
  }

  /// Update a user's profile data in Firestore.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user in Firestore: $e');
      rethrow;
    }
  }

  //------------- Issue Methods -------------//

  /// Add a new issue to the `issues` collection.
  Future<void> addIssue(IssueModel issue) async {
    try {
      await _db.collection('issues').add(issue.toMap());
    } catch (e) {
      print('Error adding issue to Firestore: $e');
      rethrow;
    }
  }

  /// Get a stream of all issues.
  Stream<List<IssueModel>> getIssues() {
    return _db
        .collection('issues')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  //------------- Schedule Methods -------------//

  /// Get a stream of all schedules.
  Stream<List<ScheduleModel>> getSchedules() {
    return _db
        .collection('schedules')
        .orderBy('nextCollectionDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Add a new schedule entry to the `schedules` collection.
  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      await _db.collection('schedules').add(schedule.toMap());
    } catch (e) {
      print('Error adding schedule to Firestore: $e');
      rethrow;
    }
  }

  /// Seed a few schedules when the collection is empty.
  Future<void> seedSchedulesIfEmpty() async {
    try {
      final snapshot = await _db.collection('schedules').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return;
      }

      final now = DateTime.now();
      final demo = <ScheduleModel>[
        ScheduleModel(
          area: 'Urban Heights',
          collectionDay: 'Monday',
          wasteType: 'LANDFILL',
          nextCollectionDate: Timestamp.fromDate(
            now.add(const Duration(days: 1)),
          ),
        ),
        ScheduleModel(
          area: 'Urban Heights',
          collectionDay: 'Tuesday',
          wasteType: 'ORGANIC WASTE',
          nextCollectionDate: Timestamp.fromDate(
            now.add(const Duration(days: 2)),
          ),
        ),
        ScheduleModel(
          area: 'Urban Heights',
          collectionDay: 'Wednesday',
          wasteType: 'RECYCLING',
          nextCollectionDate: Timestamp.fromDate(
            now.add(const Duration(days: 3)),
          ),
        ),
      ];

      final batch = _db.batch();
      for (final schedule in demo) {
        final ref = _db.collection('schedules').doc();
        batch.set(ref, schedule.toMap());
      }
      await batch.commit();
    } catch (e) {
      print('Error seeding schedules: $e');
      rethrow;
    }
  }

  /// Moves past schedule dates forward by 7-day cycles so next pickups stay upcoming.
  Future<void> rollSchedulesForwardIfNeeded() async {
    try {
      final now = DateTime.now();
      final snapshot = await _db.collection('schedules').get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _db.batch();
      var hasChanges = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['nextCollectionDate'];
        if (ts is! Timestamp) {
          continue;
        }

        var next = ts.toDate();
        while (next.isBefore(now)) {
          next = next.add(const Duration(days: 7));
        }

        final original = ts.toDate();
        if (!next.isAtSameMomentAs(original)) {
          final weekday = _weekdayNames[next.weekday - 1];
          batch.update(doc.reference, {
            'nextCollectionDate': Timestamp.fromDate(next),
            'collectionDay': weekday,
          });
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await batch.commit();
      }
    } catch (e) {
      print('Error rolling schedules forward: $e');
      rethrow;
    }
  }

  /// Saves active route points so they are visible in Firestore.
  Future<void> saveLiveRoute({
    required List<Map<String, double>> stops,
    required List<Map<String, double>> path,
  }) async {
    try {
      final payload = {
        'stops': stops,
        'path': path,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Keep latest route in a stable doc for consumers.
      await _db
          .collection('live_routes')
          .doc('active')
          .set(payload, SetOptions(merge: true));

      // Also write a history record so each map open creates a visible DB entry.
      await _db.collection('map_routes').add(payload);
    } catch (e) {
      print('Error saving live route: $e');
      rethrow;
    }
  }

  //------------- Driver Workflow Methods -------------//

  Stream<Map<String, dynamic>?> watchTodayDriverAssignment(String driverUid) {
    final dayKey = todayKey();
    final docId = '${dayKey}_$driverUid';
    return _db.collection('driver_assignments').doc(docId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return null;
      }
      final data = doc.data() ?? <String, dynamic>{};
      return <String, dynamic>{'id': doc.id, ...data};
    });
  }

  Future<void> createOrUpdateDriverAssignment({
    required String driverUid,
    required String driverName,
    required String areaName,
    required String assignedByUid,
    double? targetLat,
    double? targetLng,
  }) async {
    final dayKey = todayKey();
    final docId = '${dayKey}_$driverUid';
    await _db.collection('driver_assignments').doc(docId).set({
      'dayKey': dayKey,
      'driverUid': driverUid,
      'driverName': driverName,
      'areaName': areaName,
      'assignedByUid': assignedByUid,
      'status': 'assigned',
      if (targetLat != null) 'targetLat': targetLat,
      if (targetLng != null) 'targetLng': targetLng,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> submitDriverCheckIn({
    required String driverUid,
    required String driverName,
    required String areaName,
    required String selfieUrl,
    required double latitude,
    required double longitude,
  }) async {
    final dayKey = todayKey();
    final checkinId = '${dayKey}_$driverUid';

    await _db.collection('driver_checkins').doc(checkinId).set({
      'dayKey': dayKey,
      'driverUid': driverUid,
      'driverName': driverName,
      'areaName': areaName,
      'selfieUrl': selfieUrl,
      'latitude': latitude,
      'longitude': longitude,
      'checkinAt': FieldValue.serverTimestamp(),
      'status': 'checked_in',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final assignmentId = '${dayKey}_$driverUid';
    await _db.collection('driver_assignments').doc(assignmentId).set({
      'status': 'checked_in',
      'lastCheckinAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setDriverTripStatus({
    required String driverUid,
    required String status,
  }) async {
    final dayKey = todayKey();
    final assignmentId = '${dayKey}_$driverUid';
    await _db.collection('driver_assignments').doc(assignmentId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'active_trip') 'startedAt': FieldValue.serverTimestamp(),
      if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateDriverLiveLocation({
    required String driverUid,
    required String driverName,
    required String areaName,
    required double latitude,
    required double longitude,
    required bool onDuty,
    double? targetLat,
    double? targetLng,
  }) async {
    final dayKey = todayKey();
    await _db.collection('driver_live_locations').doc(driverUid).set({
      'dayKey': dayKey,
      'driverUid': driverUid,
      'driverName': driverName,
      'areaName': areaName,
      'latitude': latitude,
      'longitude': longitude,
      if (targetLat != null) 'targetLat': targetLat,
      if (targetLng != null) 'targetLng': targetLng,
      'onDuty': onDuty,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchDriverLiveLocation(String driverUid) {
    return _db
        .collection('driver_live_locations')
        .doc(driverUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          final data = doc.data() ?? <String, dynamic>{};
          return <String, dynamic>{'id': doc.id, ...data};
        });
  }

  Stream<List<Map<String, dynamic>>> streamActiveDriversToday({
    String? areaName,
  }) {
    final dayKey = todayKey();
    return _db.collection('driver_live_locations').snapshots().map((snapshot) {
      var drivers = snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .where((item) {
            final onDuty = item['onDuty'] == true;
            final isToday = item['dayKey'] == dayKey;
            return onDuty && isToday;
          })
          .toList();

      if (areaName != null && areaName.trim().isNotEmpty) {
        drivers = drivers
            .where(
              (item) =>
                  (item['areaName']?.toString().toLowerCase() ?? '') ==
                  areaName.toLowerCase(),
            )
            .toList();
      }

      return drivers;
    });
  }

  Stream<List<Map<String, dynamic>>> streamTodayDriverCheckins() {
    final dayKey = todayKey();
    return _db
        .collection('driver_checkins')
        .where('dayKey', isEqualTo: dayKey)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList();
          items.sort((a, b) {
            final at = a['checkinAt'];
            final bt = b['checkinAt'];
            final ad = at is Timestamp
                ? at.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            final bd = bt is Timestamp
                ? bt.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          return items;
        });
  }
}
