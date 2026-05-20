import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String instructorName;
  final String instructorId;
  final double rating;
  final int reviewsCount;
  final int studentsCount;
  final double price;
  final String imageUrl;
  final String? videoUrl;
  final String description;
  final String category;
  final String? courseWebsite;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.title,
    required this.instructorName,
    required this.instructorId,
    required this.rating,
    required this.reviewsCount,
    required this.studentsCount,
    required this.price,
    required this.imageUrl,
    this.videoUrl,
    required this.description,
    required this.category,
    this.courseWebsite,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'instructorName': instructorName,
      'instructorId': instructorId,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'studentsCount': studentsCount,
      'price': price,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'description': description,
      'category': category,
      'courseWebsite': courseWebsite,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Course.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      instructorName: data['instructorName'] ?? '',
      instructorId: data['instructorId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      studentsCount: data['studentsCount'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'],
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      courseWebsite: data['courseWebsite'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
