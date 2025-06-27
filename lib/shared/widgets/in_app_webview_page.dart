import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../themes/colors.dart';
import '../services/webview_helper.dart';

/// Trang webview trong ứng dụng để hiển thị nội dung web
class InAppWebViewPage extends StatefulWidget {
  final String url;
  final String? title;
  
  const InAppWebViewPage({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  InAppWebViewController? _webViewController;
  String _pageTitle = '';
  bool _isLoading = true;
  double _progress = 0.0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title ?? 'Đang tải...';
    _currentUrl = widget.url;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Set status bar style cho trang này
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Always light icons for brand header
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surfaceContainerLowest,
        systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
            ? Brightness.dark 
            : Brightness.light,
        systemNavigationBarDividerColor: theme.colorScheme.outline,
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      floatingActionButton: _isLoading 
        ? null 
        : FloatingActionButton.small(
            onPressed: () => _webViewController?.reload(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            tooltip: 'Tải lại trang',
            child: const Icon(TablerIcons.refresh, size: 18),
          ),
      body: Column(
        children: [
          // Compact Header
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.headerColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56, // Compact height
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        TablerIcons.arrow_left,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    
                    // Title và URL
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pageTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_currentUrl.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  WebViewHelper.isSecureUrl(_currentUrl) 
                                      ? TablerIcons.lock 
                                      : TablerIcons.world,
                                  size: 10,
                                  color: WebViewHelper.isSecureUrl(_currentUrl) 
                                      ? Colors.green.shade100 
                                      : Colors.orange.shade200,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child:                                     Text(
                                      Uri.parse(_currentUrl).host,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ),
                                if (!WebViewHelper.isSecureUrl(_currentUrl))
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade200.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Không an toàn',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade200,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Navigation controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                  IconButton(
                            icon: Icon(
                              TablerIcons.arrow_left,
                              color: _canGoBack 
                                  ? Colors.white 
                                  : Colors.white.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          onPressed: _canGoBack ? () => _webViewController?.goBack() : null,
                          tooltip: 'Quay lại',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                                                  IconButton(
                            icon: Icon(
                              TablerIcons.arrow_right,
                              color: _canGoForward 
                                  ? Colors.white 
                                  : Colors.white.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          onPressed: _canGoForward ? () => _webViewController?.goForward() : null,
                          tooltip: 'Tiến tới',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        
                        // More options
                        PopupMenuButton<String>(
                          icon: const Icon(
                            TablerIcons.dots_vertical,
                            color: Colors.white,
                            size: 16,
                          ),
                          onSelected: (value) => _handleMenuAction(value),
                          tooltip: 'Tùy chọn khác',
                          padding: const EdgeInsets.all(4),
                          iconSize: 16,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'reload',
                              child: Row(
                                children: [
                                  Icon(TablerIcons.refresh, size: 16),
                                  SizedBox(width: 12),
                                  Text('Tải lại'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(TablerIcons.share, size: 16),
                                  SizedBox(width: 12),
                                  Text('Chia sẻ'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'copy_link',
                              child: Row(
                                children: [
                                  Icon(TablerIcons.copy, size: 16),
                                  SizedBox(width: 12),
                                  Text('Sao chép liên kết'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'open_external',
                              child: Row(
                                children: [
                                  Icon(TablerIcons.external_link, size: 16),
                                  SizedBox(width: 12),
                                  Text('Mở trong trình duyệt'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress indicator
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),

          // WebView content
          Expanded(
            child: ClipRRect(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.url),
                ),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  iframeAllow: "camera; microphone",
                  iframeAllowFullscreen: true,
                  supportZoom: true,
                  builtInZoomControls: true,
                  displayZoomControls: false,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  clearCache: false,
                  userAgent: _getUserAgent(),
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                    if (url != null) {
                      _currentUrl = url.toString();
                    }
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                  });
                  
                  // Update navigation state
                  _updateNavigationState();
                  
                  // Get page title
                  final title = await controller.getTitle();
                  if (title != null && title.isNotEmpty) {
                    setState(() {
                      _pageTitle = title;
                    });
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                onTitleChanged: (controller, title) {
                  if (title != null) {
                    setState(() {
                      _pageTitle = title;
                    });
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url;
                  
                  // Allow navigation within the same domain or common web protocols
                  if (url != null) {
                    final uri = Uri.parse(url.toString());
                    if (uri.scheme == 'http' || uri.scheme == 'https') {
                      return NavigationActionPolicy.ALLOW;
                    }
                  }
                  
                  return NavigationActionPolicy.CANCEL;
                },
                onConsoleMessage: (controller, consoleMessage) {
                  // Log console messages for debugging
                  debugPrint('WebView Console: ${consoleMessage.message}');
                },
                onLoadError: (controller, url, code, message) {
                  // Handle load errors
                  _showErrorSnackBar('Lỗi tải trang: $message');
                },
                onLoadHttpError: (controller, url, statusCode, description) {
                  // Handle HTTP errors
                  _showErrorSnackBar('Lỗi HTTP $statusCode: $description');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserAgent() {
    // Return a user agent that identifies this as a mobile app
    return 'PersonaAI-Mobile-App/1.0 (Flutter; Android/iOS)';
  }

  Future<void> _updateNavigationState() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      final canGoForward = await _webViewController!.canGoForward();
      
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'reload':
        _webViewController?.reload();
        break;
      case 'share':
        _shareUrl();
        break;
      case 'copy_link':
        _copyLinkToClipboard();
        break;
      case 'open_external':
        _openInExternalBrowser();
        break;
    }
  }

  void _shareUrl() {
    // TODO: Implement share functionality using share_plus package
    _showInfoSnackBar('Chức năng chia sẻ sẽ được thêm trong phiên bản sau');
  }

  void _copyLinkToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentUrl));
    _showInfoSnackBar('Đã sao chép liên kết');
  }

  void _openInExternalBrowser() async {
    // TODO: Implement external browser opening using url_launcher
    _showInfoSnackBar('Chức năng mở trình duyệt ngoài sẽ được thêm trong phiên bản sau');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
} 