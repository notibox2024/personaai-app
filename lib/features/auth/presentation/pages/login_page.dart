import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/login_footer.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/widgets/svg_asset.dart';
import 'dart:math' as math;
import 'package:flutter/rendering.dart';

/// Trang đăng nhập chính
class LoginPage extends StatefulWidget { // Thay đổi thành StatefulWidget để có animation
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> 
    with TickerProviderStateMixin { // Thêm TickerProvider để sử dụng animation
  
  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation cho floating effect (lên xuống nhẹ)
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    // Animation cho rotation (xoay chậm)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Animation cho fade in/out
    _fadeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Bắt đầu animations
    _floatingController.repeat(reverse: true);
    _rotationController.repeat();
    _fadeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light 
          ? Brightness.light
          : Brightness.light,
        statusBarBrightness: theme.brightness == Brightness.light
          ? Brightness.dark
          : Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Layer 1: Base gradient background
            Container(
              decoration: BoxDecoration(
                gradient: _buildBaseGradient(theme.brightness),
              ),
            ),
            
            // Layer 2: Animated geometric shapes
            _buildAnimatedShapes(theme.brightness),
            
            // Layer 3: Floating brand icons - enhanced với nhiều icon hơn
            _buildFloatingIcons(theme.brightness),
            
            // Layer 4: Main content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header transparent - không có background
                  const LoginHeader(),
                  
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        
                        // Form card với advanced glass morphism effect
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.15 : 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.3 : 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 25,
                                    offset: const Offset(0, 15),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.1 : 0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: LoginForm(
                                  onLoginSuccess: () => _handleLoginSuccess(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Footer
                        const LoginFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Layer 1: Tạo base gradient background
  LinearGradient _buildBaseGradient(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.3, 0.7, 1.0],
        colors: [
          Color(0xFFFF6B00), // Cam đậm
          Color(0xFFFF4100), // Cam brand chính
          Color(0xFFFF2D00), // Cam đậm hơn
          Color(0xFFE63900), // Cam tối
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.4, 0.8, 1.0],
        colors: [
          Color(0xFF994100), // Cam tối cho dark theme
          Color(0xFFCC3300), // Cam đỏ tối
          Color(0xFF802200), // Cam nâu tối
          Color(0xFF661100), // Cam đậm nhất
        ],
      );
    }
  }
  
  /// Layer 2: Animated geometric shapes
  Widget _buildAnimatedShapes(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Circle shape 1 - top right
            Positioned(
              top: -50,
              right: -50,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? KienlongBankColors.primary : KienlongBankColors.primary)
                            .withValues(alpha: _fadeAnimation.value * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Hexagon shape - center left
            Positioned(
              top: 300,
              left: -80,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 2 * 3.14159,
                child: CustomPaint(
                  size: const Size(160, 160),
                  painter: HexagonPainter(
                    color: (isDark ? KienlongBankColors.secondary : KienlongBankColors.secondary)
                        .withValues(alpha: _fadeAnimation.value * 0.08),
                  ),
                ),
              ),
            ),
            
            // Triangle shape - bottom right
            Positioned(
              bottom: 100,
              right: -30,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: TrianglePainter(
                    color: (isDark ? KienlongBankColors.tertiary : KienlongBankColors.primary)
                        .withValues(alpha: _fadeAnimation.value * 0.06),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Layer 3: Floating brand icons - enhanced với nhiều icon hơn
  Widget _buildFloatingIcons(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_floatingAnimation, _rotationAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // KienlongBank icon 1 - floating chính
            Positioned(
              top: 150 + _floatingAnimation.value,
              right: 30,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.5,
                child: Opacity(
                  opacity: 0.12 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 65,
                    height: 65,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 2 - floating ngược chiều
            Positioned(
              bottom: 250 - _floatingAnimation.value,
              left: 25,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.8,
                child: Opacity(
                  opacity: 0.08 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 45,
                    height: 45,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 3 - floating chậm ở giữa trái
            Positioned(
              top: 350 + (_floatingAnimation.value * 0.7),
              left: -10,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.3,
                child: Opacity(
                  opacity: 0.06 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 35,
                    height: 35,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 4 - floating nhanh ở giữa phải
            Positioned(
              top: 280 + (_floatingAnimation.value * 1.3),
              right: -5,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 1.2,
                child: Opacity(
                  opacity: 0.09 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 50,
                    height: 50,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 5 - floating nhỏ ở top center
            Positioned(
              top: 80 + (_floatingAnimation.value * 0.5),
              left: MediaQuery.of(context).size.width / 2 - 15,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.6,
                child: Opacity(
                  opacity: 0.05 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 30,
                    height: 30,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 6 - floating ở bottom center
            Positioned(
              bottom: 120 - (_floatingAnimation.value * 0.6),
              left: MediaQuery.of(context).size.width / 2 + 40,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.4,
                child: Opacity(
                  opacity: 0.07 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 38,
                    height: 38,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 7 - floating nhỏ góc trái trên
            Positioned(
              top: 60 + (_floatingAnimation.value * 0.8),
              left: 15,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.9,
                child: Opacity(
                  opacity: 0.04 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 25,
                    height: 25,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            
            // KienlongBank icon 8 - floating góc phải dưới
            Positioned(
              bottom: 80 - (_floatingAnimation.value * 0.4),
              right: 15,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.7,
                child: Opacity(
                  opacity: 0.06 * _fadeAnimation.value,
                  child: SvgAsset.kienlongbankIcon(
                    width: 42,
                    height: 42,
                    color: isDark ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Xử lý đăng nhập thành công
  void _handleLoginSuccess(BuildContext context) {
    // Điều hướng đến trang chính
    Navigator.of(context).pushReplacementNamed('/main');
  }
}

/// Custom painter cho hình hexagon
class HexagonPainter extends CustomPainter {
  final Color color;
  
  HexagonPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * 3.14159 / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter cho hình triangle
class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 