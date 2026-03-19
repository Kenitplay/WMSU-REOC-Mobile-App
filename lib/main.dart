// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: WebViewPage(),
//     );
//   }
// }

// class WebViewPage extends StatefulWidget {
//   const WebViewPage({super.key});

//   @override
//   State<WebViewPage> createState() => _WebViewPageState();
// }

// class _WebViewPageState extends State<WebViewPage> {
//   late final WebViewController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..loadRequest(Uri.parse('https://reoph.site/login'));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         // SafeArea prevents content from going under the status bar
//         child: ScrollConfiguration(
//           behavior: const ScrollBehavior().copyWith(overscroll: false),
//           child: WebViewWidget(controller: _controller),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
// Add this import for Uri decoding
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.white,
  ));

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const String _loginUrl = "https://reoph.site/login";
  static const String _offlineAsset = "assets/internet.html";
  static const Duration _connectionCheckInterval = Duration(seconds: 4);

  bool? _isOnline;
  InAppWebViewController? _webController;
  Timer? _connectionCheckTimer;
  
  bool _isPageReloading = false;
  String? _lastLoadedUrl;
  bool _isFirstLoad = true;

  // List of unwanted download patterns (add more as needed)
  final List<String> _blockedPatterns = [
    'scrollbar',
    'scroll-bar',
    'scrollbar.css',
    'scrollbar.js',
    'fuckscroll',
    'custom-scroll',
    'scroll',
    'bar',
    '.css',
    '.js',
  ];

  // List of allowed file extensions for actual downloads
  final List<String> _allowedExtensions = [
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', 
    '.ppt', '.pptx', '.jpg', '.jpeg', '.png', 
    '.gif', '.zip', '.rar', '.mp4', '.mp3',
  ];

  // Helper method to clean filename from URL encoding
  String _getCleanFileName(String url) {
    try {
      // Parse the URL
      final uri = Uri.parse(url);
      
      // Get the path segments and decode them
      final segments = uri.pathSegments;
      
      if (segments.isNotEmpty) {
        // Get the last segment (filename)
        final encodedFileName = segments.last;
        
        // Decode URL encoding (like %20 to space)
        final decodedFileName = Uri.decodeComponent(encodedFileName);
        
        // Split off any query parameters if they're still there
        final cleanFileName = decodedFileName.split('?').first;
        
        // If the filename is empty or just "/", use a default
        if (cleanFileName.isEmpty || cleanFileName == '/') {
          return 'download_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        return cleanFileName;
      }
      
      // If no path segments, try to extract filename from the whole URL
      final urlParts = url.split('/');
      if (urlParts.isNotEmpty) {
        final lastPart = urlParts.last.split('?').first;
        if (lastPart.isNotEmpty) {
          return Uri.decodeComponent(lastPart);
        }
      }
    } catch (e) {
      debugPrint('Error parsing filename: $e');
    }
    
    // Fallback
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.photos.request();
    }
  }

  Future<void> _checkConnection() async {
    try {
      await InternetAddress.lookup("reoph.site");
      if (mounted) setState(() => _isOnline = true);
    } on SocketException catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  void _startConnectionCheckTimer() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (_) async {
      if (!mounted) return;
      try {
        await InternetAddress.lookup("reoph.site");
        if (!mounted) return;
        _connectionCheckTimer?.cancel();
        await _webController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(_loginUrl)),
        );
      } on SocketException catch (_) {}
    });
  }

  // Check if URL should be blocked (unwanted downloads)
  bool _shouldBlockDownload(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Block if contains any unwanted pattern
    for (final pattern in _blockedPatterns) {
      if (lowerUrl.contains(pattern)) {
        debugPrint('🔴 Blocked unwanted pattern "$pattern" in: $url');
        return true;
      }
    }
    
    return false;
  }

  // Check if URL is a legitimate downloadable file
  bool _isAllowedFileDownload(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Check if it ends with any allowed extension
    for (final ext in _allowedExtensions) {
      if (lowerUrl.endsWith(ext) || lowerUrl.contains('$ext?')) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _checkConnection();
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: true,
        left: false,
        right: false,
        child: _isOnline == null
            ? const SizedBox.expand()
            : Container(
                color: Colors.white,
                child: InAppWebView(
                  initialUrlRequest:
                      _isOnline! ? URLRequest(url: WebUri(_loginUrl)) : null,
                  initialFile: _isOnline! ? null : _offlineAsset,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowFileAccess: true,
                    allowContentAccess: true,
                    useOnDownloadStart: true,
                    transparentBackground: true,
                    domStorageEnabled: true,
                    disallowOverScroll: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webController = controller;
                    if (_isOnline == false) _startConnectionCheckTimer();
                  },
                  
                  onLoadStart: (controller, url) {
                    final currentUrl = url?.toString();
                    setState(() {
                      _isPageReloading = _lastLoadedUrl == currentUrl && !_isFirstLoad;
                      _lastLoadedUrl = currentUrl;
                      _isFirstLoad = false;
                    });
                  },
                  
                  onLoadStop: (controller, url) {
                    final u = url?.toString() ?? "";
                    if (u.startsWith("https://reoph.site")) {
                      _connectionCheckTimer?.cancel();
                    }
                    
                    setState(() {
                      _isPageReloading = false;
                    });
                    
                    // Inject CSS to hide scrollbars (this might help prevent scrollbar downloads)
                    controller.evaluateJavascript(source: """
                      (function() {
                        var style = document.createElement('style');
                        style.textContent = `
                          *::-webkit-scrollbar {
                            display: none !important;
                            width: 0 !important;
                            height: 0 !important;
                            background: transparent !important;
                          }
                          * {
                            scrollbar-width: none !important;
                            -ms-overflow-style: none !important;
                          }
                        `;
                        document.head.appendChild(style);
                        
                        // Prevent any scrollbar-related downloads
                        var links = document.getElementsByTagName('link');
                        for (var i = 0; i < links.length; i++) {
                          var link = links[i];
                          if (link.rel === 'stylesheet' && 
                              (link.href.includes('scroll') || link.href.includes('bar'))) {
                            link.disabled = true;
                          }
                        }
                      })();
                    """);
                    
                    // Original restrictions
                    controller.evaluateJavascript(
                      source:
                          "(function(){var css=document.createElement('style');css.textContent='*{-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;-webkit-user-drag:none!important;will-change:auto!important;}::-webkit-scrollbar{display:none!important;width:0!important;height:0!important;}#progress-bar{position:fixed;top:0;left:0;right:0;height:3px;background:linear-gradient(to right,#c62828,#ff5722);width:0;transition:width 0.3s ease;z-index:9999;box-shadow:0 0 10px rgba(198,40,40,0.7);}#progress-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.3);display:none;z-index:9998;justify-content:center;align-items:center;}#loading-spinner{width:50px;height:50px;border:4px solid rgba(198,40,40,0.3);border-top:4px solid #c62828;border-radius:50%;animation:spin 1s linear infinite;}@keyframes spin{0%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}.hidden{display:none!important;}';document.head.appendChild(css);var progressBar=document.createElement('div');progressBar.id='progress-bar';var overlay=document.createElement('div');overlay.id='progress-overlay';var spinner=document.createElement('div');spinner.id='loading-spinner';overlay.appendChild(spinner);document.body.appendChild(progressBar);document.body.appendChild(overlay);var isSubmitting=false;function showProgress(){if(!isSubmitting){isSubmitting=true;overlay.style.display='flex';progressBar.style.width='30%';setTimeout(()=>{if(isSubmitting)progressBar.style.width='60%';},500);}}function hideProgress(){isSubmitting=false;progressBar.style.width='100%';setTimeout(()=>{overlay.style.display='none';progressBar.style.width='0%';},800);}document.addEventListener('submit',()=>{showProgress();},true);window.addEventListener('load',hideProgress);document.addEventListener('selectstart',e=>e.preventDefault(),true);document.addEventListener('contextmenu',e=>e.preventDefault(),true);document.addEventListener('copy',e=>e.preventDefault(),true);document.addEventListener('cut',e=>e.preventDefault(),true);document.addEventListener('paste',e=>e.preventDefault(),true);var touchStartTime=0;document.addEventListener('touchstart',e=>{touchStartTime=Date.now()},true);document.addEventListener('touchend',e=>{if(Date.now()-touchStartTime>500){e.preventDefault();}},true);window.oncontextmenu=()=>false;window.oncopy=()=>false;})()",
                    );
                  },
                  
                  onDownloadStartRequest: (controller, downloadStartRequest) async {
                    final url = downloadStartRequest.url.toString();
                    
                    debugPrint('📥 Download attempt: $url');
                    
                    // BLOCK ALL DOWNLOADS DURING PAGE LOAD
                    if (_isPageReloading || _isFirstLoad) {
                      debugPrint('⛔ Blocked download during page load: $url');
                      return;
                    }
                    
                    // Check for unwanted patterns (scrollbar, etc.)
                    if (_shouldBlockDownload(url)) {
                      debugPrint('⛔ Blocked unwanted download: $url');
                      return;
                    }
                    
                    // Only allow specific file types
                    if (!_isAllowedFileDownload(url)) {
                      debugPrint('⛔ Blocked non-file download: $url');
                      return;
                    }
                    
                    // Get clean filename (without %20 encoding)
                    final fileName = _getCleanFileName(url);
                    
                    // Ask user confirmation for actual downloads
                    final shouldDownload = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Download File'),
                        content: Text('Download "$fileName"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Download'),
                          ),
                        ],
                      ),
                    );
                    
                    if (shouldDownload != true) {
                      debugPrint('⛔ User cancelled download');
                      return;
                    }
                    
                    // Proceed with download
                    try {
                      await FlutterDownloader.enqueue(
                        url: url,
                        savedDir: "/storage/emulated/0/Download",
                        fileName: fileName,
                        showNotification: true,
                        openFileFromNotification: true,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Downloading $fileName"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Download error: $e');
                    }
                  },
                  
                  onLoadError: (controller, url, code, message) async {
                    // Check if it's actually a network issue before showing offline page
                    try {
                      await InternetAddress.lookup("reoph.site");
                      // Connection exists, so it's not a network error - don't show offline page
                      return;
                    } on SocketException catch (_) {
                      // No connection, show offline page
                      await controller.loadFile(
                        assetFilePath: _offlineAsset,
                      );
                      _startConnectionCheckTimer();
                    }
                  },
                ),
              ),
      ),
    );
  }
}