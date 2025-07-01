import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../bloc/auth_bloc.dart';
import '../../../../themes/colors.dart';

/// Reactive login form sử dụng AuthBloc
class ReactiveLoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onForgotPassword;

  const ReactiveLoginForm({
    super.key,
    this.onLoginSuccess,
    this.onForgotPassword,
  });

  @override
  State<ReactiveLoginForm> createState() => _ReactiveLoginFormState();
}

class _ReactiveLoginFormState extends State<ReactiveLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle login submission
  void _handleLogin() {
    if (_formKey.currentState?.validate() != true) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    context.read<AuthBloc>().add(
      AuthLogin(
        username: username,
        password: password,
        rememberMe: _rememberMe,
      ),
    );
  }

  /// Handle forgot password
  void _handleForgotPassword() {
    widget.onForgotPassword?.call();
  }

  /// Clear error state
  void _clearError() {
    context.read<AuthBloc>().add(const AuthClearError());
  }

  /// Build glass text field with consistent styling
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.2 : 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.4 : 0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            style: TextStyle(
              color: theme.brightness == Brightness.light ? Colors.white : Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.9 : 0.8),
              ),
              suffixIcon: suffixIcon,
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              errorStyle: TextStyle(
                color: Colors.red[200],
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build glass button with loading state
  Widget _buildGlassButton({
    required String text,
    required VoidCallback? onPressed,
    required Color primaryColor,
    bool isLoading = false,
    double height = 56,
  }) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
                primaryColor.withValues(alpha: theme.brightness == Brightness.light ? 0.6 : 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.4 : 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Login success
          widget.onLoginSuccess?.call();
        } else if (state is AuthError) {
          // Show error in snackbar for immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Đóng',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _clearError();
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading || state is AuthRefreshing;
        final hasError = state is AuthError;
        final isTokenNearExpiry = state is AuthAuthenticated && state.isTokenNearExpiry;
        
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (hasError) _buildErrorBanner((state as AuthError).message),
              
              // Token expiry warning
              if (isTokenNearExpiry) _buildTokenExpiryWarning(),
              
              // Username field
              _buildGlassTextField(
                controller: _usernameController,
                labelText: 'Tên đăng nhập',
                hintText: 'Nhập tên đăng nhập của bạn',
                prefixIcon: TablerIcons.user,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Vui lòng nhập tên đăng nhập';
                  if (value!.length < 3) return 'Tên đăng nhập tối thiểu 3 ký tự';
                  if (value.length > 50) return 'Tên đăng nhập tối đa 50 ký tự';
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Password field
              _buildGlassTextField(
                controller: _passwordController,
                labelText: 'Mật khẩu',
                hintText: 'Nhập mật khẩu của bạn',
                prefixIcon: TablerIcons.lock,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? TablerIcons.eye_off : TablerIcons.eye,
                    color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value?.isEmpty == true) return 'Vui lòng nhập mật khẩu';
                  if (value!.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  if (value.length > 100) return 'Mật khẩu tối đa 100 ký tự';
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Remember me & Forgot password
              Row(
                children: [
                  // Remember me checkbox
                  Expanded(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isLoading ? null : () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _rememberMe 
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.transparent,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
                                width: 2,
                              ),
                            ),
                            child: _rememberMe
                                ? Icon(
                                    TablerIcons.check,
                                    size: 16,
                                    color: theme.brightness == Brightness.light 
                                        ? KienlongBankColors.primary 
                                        : Colors.black,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ghi nhớ đăng nhập',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.9 : 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Forgot password
                  TextButton(
                    onPressed: isLoading ? null : _handleForgotPassword,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.95 : 0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.7 : 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Login button
              _buildGlassButton(
                text: 'Đăng nhập',
                onPressed: isLoading ? null : _handleLogin,
                primaryColor: theme.colorScheme.primary,
                isLoading: isLoading,
              ),
              
              const SizedBox(height: 24),
              
              // Demo credentials info với glass effect
              _buildDemoCredentialsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Cải thiện contrast với màu đậm hơn để dễ đọc trên nền cam
    final textColor = isDark 
        ? Colors.red.shade100  // Rất sáng cho dark theme
        : Colors.red.shade900; // Rất tối cho light theme để contrast cao với nền cam
        
    final iconColor = isDark 
        ? Colors.red.shade50   // Rất sáng cho dark theme
        : Colors.red.shade800; // Tối cho light theme
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.12), // Đậm background hơn để contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: isDark ? 0.5 : 0.35), // Border đậm hơn
          width: 1.5, // Border dày hơn để nổi bật
        ),
        // Bỏ shadow theo yêu cầu
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.alert_circle,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700, // Font weight cao hơn để contrast tốt
                // Bỏ text shadow theo yêu cầu
              ),
            ),
          ),
          IconButton(
            onPressed: _clearError,
            icon: Icon(
              TablerIcons.x,
              color: iconColor,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenExpiryWarning() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Cải thiện contrast với màu đậm hơn để dễ đọc trên nền cam
    final textColor = isDark 
        ? Colors.orange.shade100  // Rất sáng cho dark theme
        : Colors.orange.shade900; // Rất tối cho light theme để contrast cao với nền cam
        
    final iconColor = isDark 
        ? Colors.orange.shade50   // Rất sáng cho dark theme
        : Colors.orange.shade800; // Tối cho light theme
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.12), // Đậm background hơn để contrast
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: isDark ? 0.5 : 0.35), // Border đậm hơn
          width: 1.5, // Border dày hơn để nổi bật
        ),
        // Bỏ shadow theo yêu cầu
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.clock_exclamation,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Phiên đăng nhập sắp hết hạn. Đang tự động làm mới...',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700, // Font weight cao hơn để contrast tốt
                // Bỏ text shadow theo yêu cầu
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCredentialsSection() {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0 : 0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.25 : 0.2),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    TablerIcons.info_circle,
                    color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thông tin đăng nhập demo',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.9 : 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Demo credentials
              _buildDemoCredential('demo', '123456'),
              _buildDemoCredential('admin', 'admin123'),
              _buildDemoCredential('test', 'test123'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCredential(String username, String password) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            TablerIcons.user,
            color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.7 : 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$username / $password',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: theme.brightness == Brightness.light ? 0.8 : 0.7),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 