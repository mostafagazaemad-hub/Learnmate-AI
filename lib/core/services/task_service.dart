import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/study_task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _userTasksCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to access tasks');
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  /// Saves ALL generated tools as a SINGLE session document in Firestore.
  /// Each tool type (Plan, Summary, Quiz, Flashcards, MindMap) is a field.
  Future<void> saveSession({
    required String topic,
    required String subject,
    required Map<String, dynamic> tools, // e.g. {'Plan': '...', 'Flashcards': '...'}
  }) async {
    try {
      // Check if a session for this topic already exists (update it) or create new
      final query = await _userTasksCollection
          .where('topic', isEqualTo: topic)
          .limit(1)
          .get();

      final sessionData = {
        'topic': topic,
        'subject': subject,
        'tools': tools,
        'toolTypes': tools.keys.toList(),
        'date': DateTime.now().toIso8601String(),
        'status': 'Completed',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (query.docs.isNotEmpty) {
        // Update existing session - merge tools
        final existingData = query.docs.first.data() as Map<String, dynamic>;
        final existingTools = Map<String, dynamic>.from(existingData['tools'] ?? {});
        existingTools.addAll(tools);
        sessionData['tools'] = existingTools;
        sessionData['toolTypes'] = existingTools.keys.toList();
        await query.docs.first.reference.update(sessionData);
      } else {
        // Create new session
        sessionData['createdAt'] = FieldValue.serverTimestamp();
        await _userTasksCollection.add(sessionData);
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      rethrow;
    }
  }

  Stream<List<StudyTask>> getTasks() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final toolTypes = List<String>.from(data['toolTypes'] ?? []);
          final tools = data['tools'] as Map<String, dynamic>?;
          return StudyTask(
            id: doc.id,
            topic: data['topic'] ?? 'Untitled',
            subject: data['subject'] ?? 'General',
            date: _formatDate(data['date']),
            status: data['status'] ?? 'Completed',
            statusColor: _getStatusColor(data['status']),
            icon: _getIconForTypes(toolTypes),
            tools: tools,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting tasks stream: $e');
      return Stream.value([]);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF4CAF50);
      case 'In Progress':
        return const Color(0xFF8E80FF);
      case 'Paused':
        return const Color(0xFFFF9F69);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  /// Returns an icon based on what tool types are available in the session
  IconData _getIconForTypes(List<String> types) {
    if (types.contains('Flashcards')) return Icons.style_outlined;
    if (types.contains('Quiz')) return Icons.quiz_outlined;
    if (types.contains('Plan')) return Icons.event_note_outlined;
    if (types.contains('Summary')) return Icons.description_outlined;
    if (types.contains('MindMap')) return Icons.account_tree_outlined;
    return Icons.science_outlined;
  }

  Future<void> deleteTask(String id) async {
    try {
      await _userTasksCollection.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }
}
