import 'package:flutter/material.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/login_footer.dart';

/// Trang đăng nhập chính
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với logo - có thể cuộn
            const LoginHeader(),
            
            // Form content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  
                  // Form card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: LoginForm(
                        onLoginSuccess: () => _handleLoginSuccess(context),
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
    );
  }
  
  /// Xử lý đăng nhập thành công
  void _handleLoginSuccess(BuildContext context) {
    // Điều hướng đến trang chính
    Navigator.of(context).pushReplacementNamed('/main');
  }
} 