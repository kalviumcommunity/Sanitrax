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
}
