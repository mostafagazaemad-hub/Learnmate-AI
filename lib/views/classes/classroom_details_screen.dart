import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/settings_service.dart';
import '../../core/models/classroom_model.dart';
import 'classroom_settings_screen.dart';

class ClassroomDetailsScreen extends StatefulWidget {
  final Classroom classroom;
  const ClassroomDetailsScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailsScreen> createState() => _ClassroomDetailsScreenState();
}

class _ClassroomDetailsScreenState extends State<ClassroomDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => ClassroomSettingsScreen(classroom: widget.classroom))
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.classroom.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.classroom.imageUrl.isNotEmpty ? widget.classroom.imageUrl : 'https://picsum.photos/seed/${widget.classroom.id}/800/400',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 60,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.classroom.subject,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: [
                        Tab(text: isArabic ? 'الساحة' : 'Stream'),
                        Tab(text: isArabic ? 'الواجبات' : 'Classwork'),
                        Tab(text: isArabic ? 'الأشخاص' : 'People'),
                      ],
                    ),
                    isDark,
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildStreamTab(isDark, isArabic),
                _buildClassworkTab(isDark, isArabic),
                _buildPeopleTab(isDark, isArabic),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic ? 'سيتم تفعيل هذه الميزة قريباً' : 'Feature coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      }
    );
  }

  Widget _buildStreamTab(bool isDark, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnnouncementBox(isDark, isArabic),
      ],
    );
  }

  Widget _buildAnnouncementBox(bool isDark, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), child: const Icon(Icons.person, color: AppColors.primary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isArabic ? 'أعلن عن شيء لفصلك...' : 'Announce something to your class...',
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(String author, String content, String time, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Text(author[0])),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildClassworkTab(bool isDark, bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'لا توجد واجبات بعد' : 'No assignments yet',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab(bool isDark, bool isArabic) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(isArabic ? 'المعلمون' : 'Teachers', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        ListTile(
          leading: CircleAvatar(child: Text(widget.classroom.instructorName[0])),
          title: Text(widget.classroom.instructorName, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
          trailing: const Icon(Icons.mail_outline),
        ),
        const SizedBox(height: 32),
        Text(isArabic ? 'الطلاب' : 'Students', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        const Divider(),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(isArabic ? 'لا يوجد طلاب منضمون بعد' : 'No students joined yet', style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.isDark);

  final TabBar _tabBar;
  final bool isDark;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkCard : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
