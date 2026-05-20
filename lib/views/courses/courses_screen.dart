import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/course_model.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_course_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final FirestoreService _firestore = FirestoreService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All Topics';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final settings = SettingsService();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = settings.isDarkMode;
        final isArabic = settings.locale.languageCode == 'ar';
        final allTopicsLabel = isArabic ? 'جميع المواضيع' : 'All Topics';
        
        // Ensure _selectedCategory is updated if language changes
        String displayCategory = _selectedCategory;
        if (displayCategory == 'All Topics' && isArabic) displayCategory = allTopicsLabel;
        if (displayCategory == 'جميع المواضيع' && !isArabic) displayCategory = 'All Topics';

        return StreamBuilder<DocumentSnapshot>(
          stream: user != null 
              ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final bool isInstructor = userData?['role'] == 'instructor';

            return Scaffold(
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              floatingActionButton: isInstructor ? FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddCourseScreen()),
                ),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(isArabic ? 'إضافة دورة' : 'Add Course', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ) : null,
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
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
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
                          hintText: isArabic ? 'ابحث عن دورات تعليمية' : 'Search courses',
                          hintStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),

                  // Categories
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildCategoryChip(allTopicsLabel, displayCategory == allTopicsLabel, isDark),
                        const SizedBox(width: 12),
                        _buildCategoryChip(isArabic ? 'الرياضيات' : 'Mathematics', displayCategory == (isArabic ? 'الرياضيات' : 'Mathematics'), isDark),
                        const SizedBox(width: 12),
                        _buildCategoryChip(isArabic ? 'علم البيانات' : 'Data Science', displayCategory == (isArabic ? 'علم البيانات' : 'Data Science'), isDark),
                        const SizedBox(width: 12),
                        _buildCategoryChip(isArabic ? 'التكنولوجيا' : 'Technology', displayCategory == (isArabic ? 'التكنولوجيا' : 'Technology'), isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Course List
                  Expanded(
                    child: _buildCourseListStream(isDark, isArabic, displayCategory),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildCourseListStream(bool isDark, bool isArabic, String displayCategory) {
    return StreamBuilder<List<Course>>(
      stream: _firestore.getCoursesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        var courses = snapshot.data ?? [];
        
        // Filter by category
        if (displayCategory != 'All Topics' && displayCategory != (isArabic ? 'جميع المواضيع' : 'All Topics')) {
          courses = courses.where((c) => c.category == displayCategory).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          courses = courses.where((c) => 
            c.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
            c.instructorName.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }

        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  isArabic ? 'لا توجد دورات بعد' : 'No courses found',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildCourseCard(course, isDark, isArabic),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCard : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, bool isDark, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: AppColors.darkDivider) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  course.imageUrl.isNotEmpty ? course.imageUrl : 'https://picsum.photos/seed/${course.id}/800/600',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180, color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.video_library, color: AppColors.primary, size: 48),
                  ),
                ),
              ),
              if (course.videoUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.primary, size: 32),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${course.price}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? 'بواسطة ${course.instructorName}' : 'By ${course.instructorName}',
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      course.rating.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    Text(
                      ' (${course.reviewsCount})',
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people_outline, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      isArabic ? '${(course.studentsCount / 1000).toStringAsFixed(1)} ألف طالب' : '${(course.studentsCount / 1000).toStringAsFixed(1)}k students',
                      style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                if (course.courseWebsite != null && course.courseWebsite!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.link, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.courseWebsite!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(isArabic ? 'تصفح الدورة' : 'Browse Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.background,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                      child: Icon(Icons.favorite_border, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
