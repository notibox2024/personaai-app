import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../bloc/auth_bloc.dart';
import '../../../../themes/colors.dart';

/// Logout button widget với confirmation dialog
class LogoutButton extends StatelessWidget {
  final bool compact;
  final String? customText;
  final VoidCallback? onLogoutSuccess;

  const LogoutButton({
    super.key,
    this.compact = false,
    this.customText,
    this.onLogoutSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthBlocState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          onLogoutSuccess?.call();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthRefreshing;
        
        if (compact) {
          return _buildCompactLogoutButton(context, isLoading);
        } else {
          return _buildFullLogoutButton(context, isLoading);
        }
      },
    );
  }

  /// Build compact logout button
  Widget _buildCompactLogoutButton(BuildContext context, bool isLoading) {
    return IconButton(
      onPressed: isLoading ? null : () => _showLogoutConfirmation(context),
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          : Icon(
              TablerIcons.logout,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      tooltip: 'Đăng xuất',
    );
  }

  /// Build full logout button
  Widget _buildFullLogoutButton(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: KienlongBankColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KienlongBankColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : () => _showLogoutConfirmation(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            KienlongBankColors.error,
                          ),
                        ),
                      )
                    else
                      Icon(
                        TablerIcons.logout,
                        color: KienlongBankColors.error,
                        size: 20,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      customText ?? 'Đăng xuất',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: KienlongBankColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LogoutConfirmationDialog(),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogout());
    }
  }
}

/// Logout confirmation dialog
class _LogoutConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KienlongBankColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    TablerIcons.logout,
                    color: KienlongBankColors.error,
                    size: 32,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Xác nhận đăng xuất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.brightness == Brightness.light
                        ? Colors.black87
                        : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Message
                Text(
                  'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? Colors.black54
                        : Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: _buildDialogButton(
                        context: context,
                        text: 'Hủy',
                        isPrimary: false,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Confirm button
                    Expanded(
                      child: _buildDialogButton(
                        context: context,
                        text: 'Đăng xuất',
                        isPrimary: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build dialog button
  Widget _buildDialogButton({
    required BuildContext context,
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? KienlongBankColors.error.withValues(alpha: 0.8)
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? KienlongBankColors.error.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPrimary
                        ? Colors.white
                        : theme.brightness == Brightness.light
                            ? Colors.black87
                            : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 