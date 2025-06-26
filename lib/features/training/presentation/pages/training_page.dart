import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

// Widgets
import '../widgets/training_header.dart';

// Models
import '../../data/models/course.dart';
import '../../data/models/training_progress.dart';

// Shared widgets
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/status_chip.dart';

/// Trang đào tạo chính của ứng dụng
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar color to match header gradient
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons on primary background
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: theme.colorScheme.outline,
      ),
    );
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            // Scrollable Header (extends to status bar)
            SliverToBoxAdapter(
              child: TrainingHeader(
                onHistoryTap: _showTrainingHistory,
                employeeName: 'Nguyễn Văn An',
                completedCourses: 12,
                inProgressCourses: 5,
                certificates: 3,
              ),
            ),

            // Top spacing for content
            SliverToBoxAdapter(
              child: SafeArea(
                top: false, // Header already handles top safe area
                child: const SizedBox(height: 16),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Current Learning Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Đang học',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(
              child: _buildCurrentLearningSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Recommended Courses Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Khóa học đề xuất',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleSeeAllCourses,
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(
              child: _buildRecommendedCourses(),
            ),

            // Bottom spacing with safe area
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ),
          ],
        ),
      ),
    );
  }



    Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: TablerIcons.player_play,
              label: 'Tiếp tục học',
              onTap: _handleContinueLearning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: TablerIcons.search,
              label: 'Khám phá',
              onTap: _handleExplore,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: TablerIcons.certificate,
              label: 'Chứng chỉ',
              onTap: _handleCertificates,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLearningSection() {
    final mockProgress = _getMockProgressList();
    
    if (mockProgress.isEmpty) {
      return _buildEmptyState(
        icon: TablerIcons.book_off,
        title: 'Chưa có khóa học nào',
        subtitle: 'Hãy đăng ký khóa học đầu tiên của bạn',
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        scrollDirection: Axis.horizontal,
        itemCount: mockProgress.length,
        itemBuilder: (context, index) {
          final progress = mockProgress[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index < mockProgress.length - 1 ? 0 : 0),
            child: _buildProgressCard(progress),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(TrainingProgress progress) {
    final theme = Theme.of(context);
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Flutter Development',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                                 StatusChip(
                   text: progress.status.displayName,
                   color: _getStatusColor(progress.status),
                 ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.completedLessons}/${progress.totalLessons} bài học • ${progress.progressPercentage.toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  TablerIcons.clock,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.totalStudyTime.inHours}h ${progress.totalStudyTime.inMinutes.remainder(60)}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _handleContinueCourse(progress),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCourses() {
    final mockCourses = _getMockCourseList();
    
    return SizedBox(
      height: 310,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        scrollDirection: Axis.horizontal,
        itemCount: mockCourses.length,
        itemBuilder: (context, index) {
          final course = mockCourses[index];
                      return Container(
              width: 300,
              margin: EdgeInsets.only(right: index < mockCourses.length - 1 ? 0 : 0),
              child: _buildCourseCard(course),
            );
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final theme = Theme.of(context);
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                course.category.icon,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                                         StatusChip(
                       text: course.level.displayName,
                       color: course.level.color,
                     ),
                     const Spacer(),
                     if (course.isFree)
                       const StatusChip(
                         text: 'Miễn phí',
                         color: Colors.green,
                       ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      TablerIcons.clock,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${course.duration.inHours}h',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      TablerIcons.users,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${course.enrolledCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                                 const SizedBox(height: 12),
                 SizedBox(
                   width: double.infinity,
                   child: OutlinedButton(
                     onPressed: () => _handleEnrollCourse(course),
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       minimumSize: const Size(0, 32),
                       textStyle: theme.textTheme.bodySmall?.copyWith(
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                     child: const Text('Đăng ký'),
                   ),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TrainingStatus status) {
    switch (status) {
      case TrainingStatus.notStarted:
        return Colors.grey;
      case TrainingStatus.inProgress:
        return Colors.blue;
      case TrainingStatus.completed:
        return Colors.green;
      case TrainingStatus.suspended:
        return Colors.orange;
    }
  }

  // =============== EVENT HANDLERS ===============

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _handleContinueLearning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tiếp tục khóa học gần nhất')),
    );
  }

  void _handleExplore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Khám phá khóa học mới')),
    );
  }

  void _handleCertificates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xem chứng chỉ của tôi')),
    );
  }

  void _handleSeeAllCourses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Xem tất cả khóa học')),
    );
  }

  void _handleContinueCourse(TrainingProgress progress) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tiếp tục khóa học ${progress.courseId}')),
    );
  }

  void _handleEnrollCourse(Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng ký khóa học: ${course.title}')),
    );
  }

  void _showTrainingHistory() {
    // TODO: Navigate to training history page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mở lịch sử học tập')),
    );
  }

  // =============== MOCK DATA ===============

  List<TrainingProgress> _getMockProgressList() {
    return [
      TrainingProgress(
        id: '1',
        courseId: 'flutter-101',
        userId: 'user1',
        completedLessons: 8,
        totalLessons: 15,
        progressPercentage: 53.3,
        totalStudyTime: const Duration(hours: 12, minutes: 30),
        lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
        enrolledAt: DateTime.now().subtract(const Duration(days: 7)),
        status: TrainingStatus.inProgress,
        lessonProgresses: [],
      ),
      TrainingProgress(
        id: '2',
        courseId: 'dart-basics',
        userId: 'user1',
        completedLessons: 3,
        totalLessons: 10,
        progressPercentage: 30.0,
        totalStudyTime: const Duration(hours: 5, minutes: 15),
        lastAccessedAt: DateTime.now().subtract(const Duration(days: 1)),
        enrolledAt: DateTime.now().subtract(const Duration(days: 3)),
        status: TrainingStatus.inProgress,
        lessonProgresses: [],
      ),
    ];
  }

  List<Course> _getMockCourseList() {
    return [
      Course(
        id: 'react-101',
        title: 'React Fundamentals',
        description: 'Học React từ cơ bản đến nâng cao',
        instructor: 'Nguyễn Văn A',
        thumbnailUrl: '',
        duration: const Duration(hours: 20),
        totalLessons: 25,
        level: CourseLevel.beginner,
        category: CourseCategory.technical,
        rating: 4.8,
        enrolledCount: 1250,
        price: 0,
        isFree: true,
        tags: ['React', 'JavaScript', 'Frontend'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Course(
        id: 'leadership-101',
        title: 'Leadership Skills',
        description: 'Phát triển kỹ năng lãnh đạo hiệu quả',
        instructor: 'Trần Thị B',
        thumbnailUrl: '',
        duration: const Duration(hours: 15),
        totalLessons: 18,
        level: CourseLevel.intermediate,
        category: CourseCategory.leadership,
        rating: 4.6,
        enrolledCount: 890,
        price: 299000,
        isFree: false,
        tags: ['Leadership', 'Management', 'Soft Skills'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }
} 