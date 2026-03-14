class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  // Factory constructor to create a UserModel from a Map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'Resident',
    );
  }

  // Method to convert a UserModel to a Map (e.g., for writing to Firestore)
  Map<String, dynamic> toMap() {
    return {'email': email, 'name': name, 'role': role};
  }
}
