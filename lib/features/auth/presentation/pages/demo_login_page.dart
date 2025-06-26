import 'package:flutter/material.dart';
import '../../../../themes/themes.dart';
import 'login_page.dart';

/// Trang demo để test màn hình đăng nhập
class DemoLoginPage extends StatelessWidget {
  const DemoLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KienLongBank Login Demo',
      theme: KienlongBankTheme.lightTheme,
      darkTheme: KienlongBankTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginPage(),
      routes: {
        '/home': (context) => const _HomeDemo(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Màn hình home demo
class _HomeDemo extends StatelessWidget {
  const _HomeDemo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập thành công!'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Chào mừng bạn đến với KienLongBank!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Màn hình đăng nhập đã hoạt động thành công.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 