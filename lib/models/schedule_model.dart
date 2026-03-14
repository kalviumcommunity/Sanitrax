import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String? id;
  final String area;
  final String collectionDay;
  final String wasteType;
  final Timestamp nextCollectionDate;

  ScheduleModel({
    this.id,
    required this.area,
    required this.collectionDay,
    required this.wasteType,
    required this.nextCollectionDate,
  });

  // Factory constructor to create a ScheduleModel from a Map
  factory ScheduleModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ScheduleModel(
      id: documentId,
      area: data['area'] ?? '',
      collectionDay: data['collectionDay'] ?? '',
      wasteType: data['wasteType'] ?? '',
      nextCollectionDate: data['nextCollectionDate'] ?? Timestamp.now(),
    );
  }

  // Method to convert a ScheduleModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'collectionDay': collectionDay,
      'wasteType': wasteType,
      'nextCollectionDate': nextCollectionDate,
    };
  }
}
