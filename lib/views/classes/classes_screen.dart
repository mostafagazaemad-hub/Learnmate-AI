import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/classroom_model.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import 'add_class_screen.dart';
import 'classroom_details_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final FirestoreService _firestore = FirestoreService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = settings.isDarkMode;
        final isArabic = settings.locale.languageCode == 'ar';

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            appBar: AppBar(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'LearnMate AI', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                ),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.textPrimary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // Search and New Class Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: isArabic ? 'ابحث في فصولك' : 'Search your classes',
                              hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              border: InputBorder.none,
                              icon: const Icon(Icons.search, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddClassScreen()),
                        ),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(isArabic ? 'فصل جديد' : 'New Class', style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: [
                    Tab(text: isArabic ? 'فصولي' : 'My Classes'),
                    Tab(text: isArabic ? 'المنضم إليها' : 'Joined'),
                    Tab(text: isArabic ? 'المؤرشفة' : 'Archived'),
                  ],
                ),
                Divider(height: 1, color: isDark ? AppColors.darkDivider : AppColors.divider),

                // Tab Bar View
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildClassListStream(isDark, isArabic),
                      Center(child: Text(isArabic ? 'الفصول المنضم إليها' : 'Joined Classes', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))),
                      Center(child: Text(isArabic ? 'الفصول المؤرشفة' : 'Archived Classes', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildClassListStream(bool isDark, bool isArabic) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<Classroom>>(
      stream: _firestore.getUserClassroomsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        var classrooms = snapshot.data ?? [];
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          classrooms = classrooms.where((c) => 
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            c.subject.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (classrooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'لا توجد فصول دراسية بعد' : 'No classrooms yet',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: classrooms.length,
          itemBuilder: (context, index) {
            final classroom = classrooms[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildClassItem(classroom, isDark, isArabic),
            );
          },
        );
      },
    );
  }

  Widget _buildClassItem(Classroom classroom, bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: classroom.isPublic ? AppColors.primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        classroom.isPublic ? (isArabic ? 'عام' : 'PUBLIC') : (isArabic ? 'خاص' : 'PRIVATE'),
                        style: TextStyle(
                          color: classroom.isPublic ? AppColors.primary : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      classroom.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic ? 'بواسطة ${classroom.instructorName}' : 'by ${classroom.instructorName}',
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  classroom.imageUrl.isNotEmpty ? classroom.imageUrl : 'https://picsum.photos/seed/${classroom.id}/500/300',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80, height: 80, color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.image_not_supported, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkDivider : AppColors.divider),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people_outline, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? '${classroom.membersCount} عضو' : '${classroom.membersCount} Members',
                    style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassroomDetailsScreen(classroom: classroom),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isArabic ? 'إدارة' : 'Manage', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
