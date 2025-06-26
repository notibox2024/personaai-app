import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../data/models/login_request.dart';
import '../../data/repositories/auth_repository.dart';

/// Widget form đăng nhập
class LoginForm extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const LoginForm({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@kienlongbank.com');
  final _passwordController = TextEditingController(text: '123456');
  final _authRepository = AuthRepository();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// Xử lý đăng nhập
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      
      final response = await _authRepository.login(request);
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
                             backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onLoginSuccess?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Nhập địa chỉ email của bạn',
              prefixIcon: const Icon(TablerIcons.mail),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
                         validator: (value) => _authRepository.validateEmail(value ?? ''),
          ),
          
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(TablerIcons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? TablerIcons.eye_off : TablerIcons.eye,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
                         validator: (value) => _authRepository.validatePassword(value ?? ''),
          ),
          
          const SizedBox(height: 16),
          
          // Remember me & Forgot password
          Row(
            children: [
              // Remember me checkbox
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ghi nhớ đăng nhập',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Forgot password
              TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Login button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Demo credentials info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      TablerIcons.info_circle,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tài khoản demo đã điền sẵn',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài khoản hiện tại: ${_emailController.text}\n'
                  'Bấm "Đăng nhập" để vào trang chủ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài khoản khác:\n'
                  'admin@kienlongbank.com / admin123\n'
                  'test@kienlongbank.com / test123',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Xử lý quên mật khẩu
  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chức năng quên mật khẩu sẽ được phát triển sau'),
        behavior: SnackBarBehavior.floating,
                 backgroundColor: Colors.blue,
      ),
    );
  }
} 