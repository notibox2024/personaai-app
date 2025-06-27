/// Helper service để xử lý webview URLs và validation
class WebViewHelper {
  /// Kiểm tra xem URL có hợp lệ không
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Làm sạch URL để hiển thị
  static String cleanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      return url;
    }
  }

  /// Lấy domain từ URL
  static String getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Kiểm tra xem URL có phải là secure không
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  /// Thêm https:// nếu URL không có scheme
  static String normalizeUrl(String url) {
    if (url.isEmpty) return url;
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    
    return url;
  }

  /// Kiểm tra xem URL có phải là internal navigation không
  static bool isInternalNavigation(String url) {
    return url.startsWith('/') && !url.startsWith('//');
  }

  /// Lấy title mặc định từ domain
  static String getDefaultTitle(String url) {
    final domain = getDomain(url);
    return domain.isNotEmpty ? domain : 'Đang tải...';
  }
} 