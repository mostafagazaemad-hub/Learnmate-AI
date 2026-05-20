import 'package:flutter/material.dart';

class StudyTask {
  final String id;
  final String topic;
  final String subject;
  final String date;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Map<String, dynamic>? tools;

  const StudyTask({
    required this.id,
    required this.topic,
    required this.subject,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.icon,
    this.tools,
  });
}
