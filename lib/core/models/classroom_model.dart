import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String instructorId;
  final String instructorName;
  final bool isPublic;
  final int membersCount;
  final String imageUrl;
  final DateTime createdAt;

  Classroom({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    required this.isPublic,
    required this.membersCount,
    required this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'isPublic': isPublic,
      'membersCount': membersCount,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Classroom.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Classroom(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      instructorId: data['instructorId'] ?? '',
      instructorName: data['instructorName'] ?? '',
      isPublic: data['isPublic'] ?? true,
      membersCount: data['membersCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
