import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

// Models
import '../../data/models/course.dart';

// Widgets
import 'pattern_painter.dart';

/// Widget hiển thị card khóa học với background ảnh hoặc pattern
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final VoidCallback? onEnroll;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background (Image or Pattern)
                _buildCardBackground(theme),
                
                // Dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                
                // Content overlay
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row - Title and Free tag
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              course.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (course.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Miễn phí',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        course.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Bottom row - Info and Level
                      Row(
                        children: [
                          // Info
                          Row(
                            children: [
                              Icon(
                                TablerIcons.clock,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${course.duration.inHours}h',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                TablerIcons.users,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${course.enrolledCount}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Level and Action
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: course.level.color.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  course.level.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onEnroll,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Đăng ký',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBackground(ThemeData theme) {
    // Nếu có ảnh đại diện, sử dụng ảnh
    if (course.thumbnailUrl.isNotEmpty) {
      return Image.network(
        course.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to pattern if image fails to load
          return _buildPatternBackground(theme);
        },
      );
    }
    
    // Nếu không có ảnh, tạo pattern background
    return _buildPatternBackground(theme);
  }

  Widget _buildPatternBackground(ThemeData theme) {
    // Tạo gradient dựa trên category của khóa học
    List<Color> gradientColors;
    
    switch (course.category) {
      case CourseCategory.technical:
        gradientColors = [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
        ];
        break;
      case CourseCategory.leadership:
        gradientColors = [
          const Color(0xFFf093fb),
          const Color(0xFFf5576c),
        ];
        break;
      case CourseCategory.softSkills:
        gradientColors = [
          const Color(0xFF4facfe),
          const Color(0xFF00f2fe),
        ];
        break;
      default:
        gradientColors = [
          theme.colorScheme.primary,
          theme.colorScheme.secondary,
        ];
    }

    // Điều chỉnh màu cho dark theme
    if (theme.brightness == Brightness.dark) {
      gradientColors = gradientColors.map((color) => 
        Color.lerp(color, Colors.black, 0.3) ?? color
      ).toList();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: CustomPaint(
        painter: PatternPainter(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        size: Size.infinite,
      ),
    );
  }
} 