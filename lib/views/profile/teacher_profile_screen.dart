import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dashboard/teacher_dashboard.dart';
import '../classes/classes_screen.dart';
import '../courses/my_courses_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Teacher Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          if (userData == null) return const Center(child: Text('User data not found'));

          final String name = userData['name'] ?? user?.displayName ?? 'Teacher';
          final String specialization = userData['specialization'] ?? 'Educator';
          final String degrees = userData['degrees'] ?? 'Certified Professional';
          final String experience = "${userData['yearsOfExperience'] ?? 0} years experience";
          final String photoUrl = userData['photoUrl'] ?? user?.photoURL ?? 'https://img.freepik.com/free-photo/portrait-expressive-young-woman_1258-48167.jpg';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Header
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          image: DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(specialization, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 32),

                // Professional Info
                _buildSectionTitle('PROFESSIONAL INFO'),
                _buildInfoTile(Icons.school, 'Primary Specialization', specialization),
                _buildInfoTile(Icons.workspace_premium, 'Degrees & Certifications', degrees),
                _buildInfoTile(Icons.history, 'Years of Experience', experience),

                const SizedBox(height: 24),
                // My Teaching
                _buildSectionTitle('MY TEACHING'),
                _buildTeachingActionTile(Icons.dashboard_outlined, 'My Dashboard', true, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
                }),
                _buildTeachingActionTile(Icons.book_outlined, 'My Courses', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyCoursesScreen()));
                }),
                _buildTeachingActionTile(Icons.people_outline, 'My Classes', false, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ClassesScreen()));
                }),

                const SizedBox(height: 24),
                // Account
                _buildSectionTitle('ACCOUNT'),
                _buildInfoTile(Icons.person_outline, 'Personal Information', user?.email ?? ''),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (value.isNotEmpty)
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildTeachingActionTile(IconData icon, String title, bool hasBadge, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBadge)
              const Icon(Icons.grid_view, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
