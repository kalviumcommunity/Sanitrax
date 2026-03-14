import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String? id;
  final String reportedBy;
  final String issueType;
  final String description;
  final String status;
  final Timestamp submittedAt;
  final String? imageUrl;

  IssueModel({
    this.id,
    required this.reportedBy,
    required this.issueType,
    required this.description,
    this.status = 'Submitted',
    required this.submittedAt,
    this.imageUrl,
  });

  // Factory constructor to create an IssueModel from a Map
  factory IssueModel.fromMap(Map<String, dynamic> data, String documentId) {
    return IssueModel(
      id: documentId,
      reportedBy: data['reportedBy'] ?? '',
      issueType: data['issueType'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Submitted',
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'],
    );
  }

  // Method to convert an IssueModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'reportedBy': reportedBy,
      'issueType': issueType,
      'description': description,
      'status': status,
      'submittedAt': submittedAt,
      'imageUrl': imageUrl,
    };
  }
}
