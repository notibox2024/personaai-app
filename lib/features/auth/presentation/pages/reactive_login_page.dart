import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:logger/logger.dart';
import '../../../../shared/shared_exports.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/reactive_login_form.dart';
import '../widgets/login_header.dart';
import '../widgets/login_footer.dart';
import '../widgets/custom_painters.dart';
import '../../../../themes/colors.dart';
import '../../../../shared/widgets/svg_asset.dart';

/// Reactive Login Page với AuthBloc integration - Simplified Design
class ReactiveLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const ReactiveLoginPage({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<ReactiveLoginPage> createState() => _ReactiveLoginPageState();
}

class _ReactiveLoginPageState extends State<ReactiveLoginPage> 
    with SingleTickerProviderStateMixin {
  
  final logger = Logger();
  
  // Single animation controller để tránh conflicts
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set current route tracking
    NavigationService().setCurrentRoute('/login');
    
    // Simple single animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Fade animation cho background elements
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation cho subtle effects
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start simple repeating animation
    _animationController.repeat(reverse: true);
    
    // NO MORE AuthBloc.initialize() call - tránh infinite loop
    // AuthBloc đã được initialize bởi main.dart
    logger.d('ReactiveLoginPage initialized without calling AuthInitialize (prevent loop)');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handle forgot password
  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tính năng quên mật khẩu đang được phát triển'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build simple animated background với theme support
  Widget _buildAnimatedBackground(Brightness brightness) {
    return Container(
      decoration: BoxDecoration(
        gradient: _buildBaseGradient(brightness),
      ),
      child: Stack(
        children: [
          // Static geometric shapes - no complex animations
          _buildStaticShapes(brightness),
          
          // Simple floating icons với AnimatedBuilder
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.1,
                child: _buildFloatingIcons(brightness),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Base gradient với theme support
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

  /// Static shapes - không animation phức tạp
  Widget _buildStaticShapes(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Circle shape - top right
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? KienlongBankColors.primary : KienlongBankColors.primary)
                      .withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Hexagon shape - center left
        Positioned(
          top: 300,
          left: -80,
          child: CustomPaint(
            size: const Size(160, 160),
            painter: HexagonPainter(
              color: (isDark ? KienlongBankColors.secondary : KienlongBankColors.secondary)
                  .withValues(alpha: 0.06),
            ),
          ),
        ),
        
        // Triangle shape - bottom right  
        Positioned(
          bottom: 100,
          right: -30,
          child: CustomPaint(
            size: const Size(120, 120),
            painter: TrianglePainter(
              color: (isDark ? KienlongBankColors.tertiary : KienlongBankColors.primary)
                  .withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  /// Simple floating icons - static positions
  Widget _buildFloatingIcons(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return Stack(
      children: [
        // KienlongBank icon 1
        Positioned(
          top: 150,
          right: 30,
          child: SvgAsset.kienlongbankIcon(
            width: 65,
            height: 65,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        
        // KienlongBank icon 2
        Positioned(
          bottom: 250,
          left: 25,
          child: SvgAsset.kienlongbankIcon(
            width: 45,
            height: 45,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        
        // KienlongBank icon 3
        Positioned(
          top: 350,
          left: -10,
          child: SvgAsset.kienlongbankIcon(
            width: 35,
            height: 35,
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }

  /// Build loading overlay
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Đang khởi tạo...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build connection status indicator
  Widget _buildConnectionStatus() {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        if (state is AuthError && state.message.contains('kết nối')) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TablerIcons.wifi_off,
                  color: Colors.red.shade300,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kiểm tra kết nối mạng',
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.light 
          ? Brightness.light
          : Brightness.light,
        statusBarBrightness: brightness == Brightness.light
          ? Brightness.dark
          : Brightness.dark,
      ),
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthBlocState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Navigation is handled by main.dart BlocListener to avoid conflicts
              // widget.onLoginSuccess?.call(); // Removed to prevent duplicate navigation
              logger.i('✅ Login successful, navigation handled centrally');
            }
          },
          child: Stack(
            children: [
              // Animated background layer
              _buildAnimatedBackground(brightness),
              
              // Main content
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Header transparent
                    const LoginHeader(),
                    
                    // Form content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          
                          // Connection Status
                          _buildConnectionStatus(),
                          
                          // Form card với glass morphism effect
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: brightness == Brightness.light ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: brightness == Brightness.light ? 0.3 : 0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 25,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: brightness == Brightness.light ? 0.1 : 0.05),
                                      blurRadius: 5,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: ReactiveLoginForm(
                                    onLoginSuccess: widget.onLoginSuccess,
                                    onForgotPassword: _handleForgotPassword,
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
              
              // Loading Overlay
              BlocBuilder<AuthBloc, AuthBlocState>(
                builder: (context, state) {
                  if (state is AuthInitial) {
                    return _buildLoadingOverlay();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 