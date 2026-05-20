import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../models/course_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // ─── Classroom Methods ─────────────────────────────────────────────────────
  
  Future<void> addClassroom(Classroom classroom) async {
    await _firestore.collection('classrooms').add(classroom.toMap());
  }

  Stream<List<Classroom>> getClassroomsStream() {
    return _firestore.collection('classrooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Classroom.fromDoc(doc)).toList());
  }

  Stream<List<Classroom>> getUserClassroomsStream(String uid) {
    return _firestore.collection('classrooms')
        .where('instructorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => Classroom.fromDoc(doc)).toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  Future<List<Classroom>> searchClassrooms(String query) async {
    final snapshot = await _firestore.collection('classrooms')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs.map((doc) => Classroom.fromDoc(doc)).toList();
  }

  // ─── Course Methods ─────────────────────────────────────────────────────────

  Future<void> addCourse(Course course) async {
    await _firestore.collection('courses').add(course.toMap());
  }

  Stream<List<Course>> getCoursesStream() {
    return _firestore.collection('courses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Course.fromDoc(doc)).toList());
  }

  Future<List<Course>> searchCourses(String query) async {
    final snapshot = await _firestore.collection('courses')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs.map((doc) => Course.fromDoc(doc)).toList();
  }
}
