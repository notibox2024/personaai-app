import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'themes/themes.dart';
import 'app_layout.dart';
import 'shared/shared_exports.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_exports.dart';
import 'shared/services/background_message_handler.dart';
import 'shared/services/app_lifecycle_service.dart';
import 'shared/services/device_info_service.dart';
import 'shared/services/token_manager.dart';
import 'shared/services/performance_monitor.dart';

void main() async {
  final logger = Logger();
  // Chạy app trong error zone để catch async errors
  runZonedGuarded<Future<void>>(() async {
    // Đảm bảo Flutter widgets đã được khởi tạo
    WidgetsFlutterBinding.ensureInitialized();
    
    logger.i('🚀 PersonaAI App Starting...');
    
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('✅ Firebase initialized');
    
    // Cấu hình Firebase Messaging background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Khởi tạo Firebase service
    await FirebaseService().initialize();
    logger.i('✅ Firebase service initialized');
    
    // Khởi tạo Device Info Service
    await DeviceInfoService().initialize();
    logger.i('✅ Device info service initialized');
    
    // Khởi tạo Token Manager
    await TokenManager().initialize();
    logger.i('✅ Token manager initialized');
    
    // Khởi tạo Performance Monitor
    await PerformanceMonitor().initialize();
    logger.i('✅ Performance monitor initialized');
    
    // Khởi tạo demo notification service
    NotificationDemoService().initialize();
    await NotificationDemoService().addDemoNotifications();
    logger.i('✅ Notification service initialized');
    
    // Khởi tạo App Lifecycle Service
    await AppLifecycleService().initialize();
    logger.i('✅ App lifecycle service initialized');
    
    // Cấu hình Crashlytics error handling
    FlutterError.onError = (errorDetails) {
      FirebaseService().recordFlutterError(errorDetails);
    };
    
    // Catch errors that happen outside of the Flutter context
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseService().recordError(error, stack, reason: 'PlatformDispatcher error');
      return true;
    };
    
    // Khởi tạo API service
    ApiService().initialize(
      baseUrl: 'https://api.personaai.com', // Thay đổi theo API thực tế của bạn
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 5),
    );
    logger.i('✅ API service initialized');
    
    logger.i('🎯 All services initialized successfully!');
    
    // Chạy app
    runApp(const PersonaAIApp());
  }, (error, stackTrace) {
    // Log async errors to Firebase Crashlytics
    logger.e('Async error caught: $error');
    // Note: Firebase may not be initialized yet when this runs,
    // so we print to console as fallback
  });
}

class PersonaAIApp extends StatefulWidget {
  const PersonaAIApp({super.key});

  @override
  State<PersonaAIApp> createState() => _PersonaAIAppState();
}

class _PersonaAIAppState extends State<PersonaAIApp> {
  final logger = Logger();
  
  // Theme mode state management
  ThemeMode _themeMode = ThemeMode.system;
  
  // Services
  late final AuthService _authService;
  late final BackgroundTokenRefreshService _backgroundRefreshService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize auth services
      _authService = AuthService();
      _backgroundRefreshService = BackgroundTokenRefreshService();
      
      // Initialize background service
      await _backgroundRefreshService.initialize();
      
      logger.i('✅ Auth services initialized');
    } catch (e) {
      logger.e('❌ Error initializing auth services: $e');
    }
  }

  @override
  void dispose() {
    // Dispose services
    _backgroundRefreshService.dispose();
    AppLifecycleService().dispose();
    super.dispose();
  }

  // Function để toggle theme với logic thông minh
  void toggleTheme() {
    setState(() {
      switch (_themeMode) {
        case ThemeMode.system:
          // Khi ở system mode, toggle dựa trên brightness hiện tại
          final currentBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _themeMode = currentBrightness == Brightness.light 
              ? ThemeMode.dark 
              : ThemeMode.light;
          break;
        case ThemeMode.light:
          _themeMode = ThemeMode.dark;
          break;
        case ThemeMode.dark:
          _themeMode = ThemeMode.light;
          break;
      }
      logger.d('Theme changed to: $_themeMode');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC Provider
        BlocProvider<AuthBloc>(
          create: (context) {
            final bloc = AuthBloc(
              authService: _authService,
              backgroundService: _backgroundRefreshService,
            );
            
            // Initialize auth state
            bloc.add(const AuthInitialize());
            
            return bloc;
          },
        ),
      ],
      child: MaterialApp(
        title: 'PersonaAI',
        debugShowCheckedModeBanner: false,
        
        // Theme Configuration - Sử dụng theme system chuyên nghiệp
        theme: KienlongBankTheme.lightTheme,
        darkTheme: KienlongBankTheme.darkTheme,
        themeMode: _themeMode,
        
        // Add global BlocListener inside MaterialApp
        builder: (context, child) {
          return BlocListener<AuthBloc, AuthBlocState>(
            listener: (context, state) {
              // Handle auth state changes globally with ScaffoldMessenger available
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi xác thực: ${state.message}'),
                    backgroundColor: Colors.red,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
              
              if (state is AuthTokenExpired) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
                    backgroundColor: Colors.orange,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
        
        // Navigation
        home: BlocBuilder<AuthBloc, AuthBlocState>(
          builder: (context, state) {
            // Show splash screen during initialization
            if (state is AuthInitial || state is AuthLoading) {
              return const SplashScreen();
            }
            
            // Navigate based on auth state
            if (state is AuthAuthenticated) {
              return AppLayout(onThemeToggle: toggleTheme);
            } else {
              return const ReactiveLoginPage();
            }
          },
        ),
        
        // Routes for manual navigation
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const ReactiveLoginPage(),
          '/demo-login': (context) => const LoginPage(),
          '/main': (context) => AppLayout(onThemeToggle: toggleTheme),
        },
      ),
    );
  }
}

// Legacy MyApp class renamed for backward compatibility
class MyApp extends PersonaAIApp {
  const MyApp({super.key});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.onThemeToggle,
    required this.currentThemeMode,
  });

  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // Helper function để lấy theme mode text
  String _getThemeModeText(ThemeMode mode, Brightness brightness) {
    switch (mode) {
      case ThemeMode.system:
        return 'System (${brightness.name})';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  // Helper function để lấy icon phù hợp với Tabler Icons
  IconData _getThemeIcon(ThemeMode mode, Brightness brightness) {
    switch (mode) {
      case ThemeMode.system:
        return brightness == Brightness.light ? TablerIcons.device_desktop : TablerIcons.device_desktop;
      case ThemeMode.light:
        return TablerIcons.sun;
      case ThemeMode.dark:
        return TablerIcons.moon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    
    // Set system UI overlay style dựa theo theme
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.light
          ? KienlongBankTheme.lightSystemUiOverlayStyle
          : KienlongBankTheme.darkSystemUiOverlayStyle,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              TablerIcons.building_bank,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('KienlongBank HR'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              widget.onThemeToggle();
              
              // Hiển thị thông báo theme đã chuyển
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        _getThemeIcon(widget.currentThemeMode, brightness),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Theme: ${_getThemeModeText(widget.currentThemeMode, brightness)}'
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(_getThemeIcon(widget.currentThemeMode, brightness)),
            tooltip: 'Toggle theme: ${_getThemeModeText(widget.currentThemeMode, brightness)}',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Theme Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getThemeIcon(widget.currentThemeMode, brightness),
                            color: colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KienlongBank Theme System',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Current: ${_getThemeModeText(widget.currentThemeMode, brightness)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: widget.onThemeToggle,
                          icon: Icon(_getThemeIcon(widget.currentThemeMode, brightness)),
                          label: const Text('Toggle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Brand Colors Display
                    Row(
                      children: [
                        Expanded(
                          child: _buildColorCard(
                            'Primary\nNăng động',
                            KienlongBankColors.primary,
                            Colors.white,
                            TablerIcons.flame,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildColorCard(
                            'Secondary\nTin cậy',
                            KienlongBankColors.secondary,
                            Colors.white,
                            TablerIcons.shield_check,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildColorCard(
                            'Tertiary\nBổ trợ',
                            KienlongBankColors.tertiary,
                            Colors.white,
                            TablerIcons.hexagon,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Semantic Colors Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.palette,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Semantic Colors',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildColorCard(
                            'Success',
                            colorScheme.success,
                            colorScheme.onSuccess,
                            TablerIcons.circle_check,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildColorCard(
                            'Warning',
                            colorScheme.warning,
                            colorScheme.onWarning,
                            TablerIcons.alert_triangle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildColorCard(
                            'Error',
                            colorScheme.error,
                            colorScheme.onError,
                            TablerIcons.circle_x,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildColorCard(
                            'Info',
                            colorScheme.info,
                            colorScheme.onInfo,
                            TablerIcons.info_circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Button Styles Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.click,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Button Components',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: _incrementCounter,
                      icon: const Icon(TablerIcons.rocket),
                      label: const Text('Elevated Button'),
                    ),
                    const SizedBox(height: 12),
                    
                    OutlinedButton.icon(
                      onPressed: _incrementCounter,
                      icon: const Icon(TablerIcons.square),
                      label: const Text('Outlined Button'),
                    ),
                    const SizedBox(height: 12),
                    
                    TextButton.icon(
                      onPressed: _incrementCounter,
                      icon: const Icon(TablerIcons.text_size),
                      label: const Text('Text Button'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Input Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.forms,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Input Components',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tên đăng nhập',
                        hintText: 'Nhập tên đăng nhập của bạn',
                        prefixIcon: Icon(TablerIcons.user),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: Icon(TablerIcons.lock),
                        suffixIcon: Icon(TablerIcons.eye),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Counter Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        TablerIcons.hand_click,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Số lần nhấn',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _counter > 10 
                          ? KienlongBankColors.successContainer 
                          : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _counter > 10 ? TablerIcons.trophy : TablerIcons.target,
                            size: 16,
                            color: _counter > 10 
                              ? KienlongBankColors.onSuccessContainer
                              : colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _counter > 10 ? 'Xuất sắc!' : 'Tiếp tục!',
                            style: TextStyle(
                              color: _counter > 10 
                                ? KienlongBankColors.onSuccessContainer
                                : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Theme Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.bulb,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Theme Controls',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionRow(
                      TablerIcons.cursor_text,
                      'Nhấn icon theme ở AppBar để chuyển đổi',
                      context,
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionRow(
                      TablerIcons.toggle_left,
                      'Nhấn nút "Toggle" để thay đổi nhanh',
                      context,
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionRow(
                      TablerIcons.arrows_right_left,
                      'System → Light → Dark → Light...',
                      context,
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionRow(
                      TablerIcons.device_floppy,
                      'Theme tự động lưu cho session hiện tại',
                      context,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // HR Features Preview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          TablerIcons.briefcase,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HR Features Preview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeaturePreview(
                            TablerIcons.clock_hour_4,
                            'Chấm công',
                            'Check-in/out',
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeaturePreview(
                            TablerIcons.calendar_event,
                            'Xin nghỉ phép',
                            'Leave request',
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeaturePreview(
                            TablerIcons.cash,
                            'Lương tháng',
                            'Salary info',
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeaturePreview(
                            TablerIcons.user_circle,
                            'Hồ sơ',
                            'Profile',
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _incrementCounter,
        icon: const Icon(TablerIcons.plus),
        label: const Text('Tăng'),
        tooltip: 'Tăng counter',
      ),
    );
  }

  /// Widget helper để tạo color demo card với icon
  Widget _buildColorCard(String label, Color backgroundColor, Color textColor, IconData icon) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper để tạo instruction row
  Widget _buildInstructionRow(IconData icon, String text, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Widget helper để tạo feature preview
  Widget _buildFeaturePreview(IconData icon, String title, String subtitle, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
