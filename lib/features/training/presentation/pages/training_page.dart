import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Widgets
import '../widgets/training_header.dart';
import '../widgets/course_card.dart';
import '../widgets/current_learning_section.dart';

// Models
import '../../data/models/course.dart';
import '../../data/models/training_progress.dart';

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
              child: CurrentLearningSection(
                progressList: _getMockProgressList(),
                onContinueCourse: _handleContinueCourse,
              ),
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





  Widget _buildRecommendedCourses() {
    final mockCourses = _getMockCourseList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: mockCourses.map((course) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CourseCard(
              course: course,
              onTap: () => _handleViewCourseDetail(course),
              onEnroll: () => _handleEnrollCourse(course),
            ),
          );
        }).toList(),
      ),
    );
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

  void _handleViewCourseDetail(Course course) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xem chi tiết khóa học: ${course.title}')),
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
        thumbnailUrl: 'https://picsum.photos/400/200?random=1',
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
      Course(
        id: 'python-basics',
        title: 'Python Programming',
        description: 'Lập trình Python từ cơ bản đến thành thạo',
        instructor: 'Lê Văn C',
        thumbnailUrl: 'https://picsum.photos/400/200?random=3',
        duration: const Duration(hours: 25),
        totalLessons: 30,
        level: CourseLevel.beginner,
        category: CourseCategory.technical,
        rating: 4.7,
        enrolledCount: 2100,
        price: 0,
        isFree: true,
        tags: ['Python', 'Programming', 'Backend'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Course(
        id: 'communication-skills',
        title: 'Effective Communication',
        description: 'Nâng cao kỹ năng giao tiếp trong công việc',
        instructor: 'Phạm Thị D',
        thumbnailUrl: '',
        duration: const Duration(hours: 12),
        totalLessons: 15,
        level: CourseLevel.intermediate,
        category: CourseCategory.softSkills,
        rating: 4.5,
        enrolledCount: 750,
        price: 199000,
        isFree: false,
        tags: ['Communication', 'Soft Skills', 'Teamwork'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Course(
        id: 'data-analytics',
        title: 'Data Analytics with Excel',
        description: 'Phân tích dữ liệu hiệu quả với Excel',
        instructor: 'Hoàng Văn E',
        thumbnailUrl: '',
        duration: const Duration(hours: 18),
        totalLessons: 22,
        level: CourseLevel.intermediate,
        category: CourseCategory.technical,
        rating: 4.4,
        enrolledCount: 680,
        price: 0,
        isFree: true,
        tags: ['Excel', 'Data Analysis', 'Business'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}

