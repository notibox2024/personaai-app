import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../bloc/auth_bloc.dart';
import '../../../../themes/colors.dart';

/// Widget hiển thị trạng thái authentication
class AuthStatusWidget extends StatelessWidget {
  final bool showTokenInfo;
  final bool compact;

  const AuthStatusWidget({
    super.key,
    this.showTokenInfo = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthBlocState>(
      builder: (context, state) {
        if (compact) {
          return _buildCompactStatus(context, state);
        } else {
          return _buildFullStatus(context, state);
        }
      },
    );
  }

  /// Build compact status indicator
  Widget _buildCompactStatus(BuildContext context, AuthBlocState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    IconData icon;
    Color color;
    String tooltip;
    
    switch (state.runtimeType) {
      case AuthAuthenticated:
        final authState = state as AuthAuthenticated;
        if (authState.isTokenNearExpiry) {
          icon = TablerIcons.clock_exclamation;
          color = colorScheme.warning;
          tooltip = 'Token sắp hết hạn';
        } else {
          icon = TablerIcons.shield_check;
          color = colorScheme.success;
          tooltip = 'Đã xác thực';
        }
        break;
      case AuthLoading:
      case AuthRefreshing:
        icon = TablerIcons.loader;
        color = colorScheme.primary;
        tooltip = 'Đang xử lý...';
        break;
      case AuthError:
        icon = TablerIcons.shield_x;
        color = colorScheme.error;
        tooltip = 'Lỗi xác thực';
        break;
      case AuthUnauthenticated:
      default:
        icon = TablerIcons.shield_off;
        color = colorScheme.onSurfaceVariant;
        tooltip = 'Chưa xác thực';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  /// Build full status display
  Widget _buildFullStatus(BuildContext context, AuthBlocState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(context, state),
              if (state is AuthAuthenticated) ...[
                const SizedBox(height: 12),
                _buildUserInfo(context, state),
                if (showTokenInfo) ...[
                  const SizedBox(height: 12),
                  _buildTokenInfo(context, state),
                ],
              ],
              if (state is AuthError) ...[
                const SizedBox(height: 8),
                _buildErrorInfo(context, state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build status header
  Widget _buildStatusHeader(BuildContext context, AuthBlocState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    switch (state.runtimeType) {
      case AuthAuthenticated:
        final authState = state as AuthAuthenticated;
        if (authState.isTokenNearExpiry) {
          icon = TablerIcons.clock_exclamation;
          color = colorScheme.warning;
          title = 'Token sắp hết hạn';
          subtitle = 'Đang tự động làm mới...';
        } else {
          icon = TablerIcons.shield_check;
          color = colorScheme.success;
          title = 'Đã xác thực';
          subtitle = 'Phiên đăng nhập hợp lệ';
        }
        break;
      case AuthLoading:
        icon = TablerIcons.loader;
        color = colorScheme.primary;
        title = 'Đang khởi tạo...';
        subtitle = 'Thiết lập kết nối';
        break;
      case AuthRefreshing:
        icon = TablerIcons.refresh;
        color = colorScheme.primary;
        title = 'Đang làm mới';
        subtitle = 'Cập nhật token xác thực';
        break;
      case AuthError:
        final errorState = state as AuthError;
        icon = TablerIcons.shield_x;
        color = colorScheme.error;
        title = 'Lỗi xác thực';
        subtitle = errorState.message;
        break;
      case AuthUnauthenticated:
      default:
        icon = TablerIcons.shield_off;
        color = colorScheme.onSurfaceVariant;
        title = 'Chưa xác thực';
        subtitle = 'Vui lòng đăng nhập';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build user info
  Widget _buildUserInfo(BuildContext context, AuthAuthenticated state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = state.user;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              (user.displayName?.isNotEmpty == true) 
                  ? user.displayName![0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build token info
  Widget _buildTokenInfo(BuildContext context, AuthAuthenticated state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = state.user;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                TablerIcons.key,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin token',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTokenRow(
            'Đăng nhập lúc',
            _formatDateTime(user.loginAt),
            theme,
            colorScheme,
          ),
          _buildTokenRow(
            'Hết hạn lúc',
            _formatDateTime(user.expiresAt),
            theme,
            colorScheme,
          ),
          _buildTokenRow(
            'Ghi nhớ',
            user.rememberMe ? 'Có' : 'Không',
            theme,
            colorScheme,
          ),
        ],
      ),
    );
  }

  /// Build token info row
  Widget _buildTokenRow(String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            ': $value',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Build error info
  Widget _buildErrorInfo(BuildContext context, AuthError state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.alert_triangle,
            color: colorScheme.onErrorContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthClearError());
            },
            icon: Icon(
              TablerIcons.x,
              color: colorScheme.onErrorContainer,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày nữa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ nữa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút nữa';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} giây nữa';
    } else {
      return 'Đã hết hạn';
    }
  }
} 