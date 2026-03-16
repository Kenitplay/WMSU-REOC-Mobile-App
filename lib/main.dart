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
                  onLoadStop: (controller, url) {
                    final u = url?.toString() ?? "";
                    if (u.startsWith("https://reoph.site")) {
                      _connectionCheckTimer?.cancel();
                    }
                    // Optimization and Restrictions
                    controller.evaluateJavascript(
                      source:
                          "(function(){var css=document.createElement('style');css.textContent='*{-webkit-user-select:none!important;user-select:none!important;-webkit-touch-callout:none!important;-webkit-user-drag:none!important;will-change:auto!important;}::-webkit-scrollbar{display:none!important;width:0!important;height:0!important;}';document.head.appendChild(css);document.addEventListener('selectstart',e=>e.preventDefault(),true);document.addEventListener('contextmenu',e=>e.preventDefault(),true);document.addEventListener('copy',e=>e.preventDefault(),true);document.addEventListener('cut',e=>e.preventDefault(),true);document.addEventListener('paste',e=>e.preventDefault(),true);var touchStartTime=0;document.addEventListener('touchstart',e=>{touchStartTime=Date.now()},true);document.addEventListener('touchend',e=>{if(Date.now()-touchStartTime>500){e.preventDefault();}},true);window.oncontextmenu=()=>false;window.oncopy=()=>false;})()",
                    );
                  },
                  onDownloadStartRequest:
                      (controller, downloadStartRequest) async {
                    final url = downloadStartRequest.url.toString();
                    await FlutterDownloader.enqueue(
                      url: url,
                      savedDir: "/storage/emulated/0/Download",
                      showNotification: true,
                      openFileFromNotification: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Downloading file..."),
                      ),
                    );
                  },
                  onLoadError: (controller, url, code, message) async {
                    await controller.loadFile(
                      assetFilePath: _offlineAsset,
                    );
                    _startConnectionCheckTimer();
                  },
                ),
              ),
      ),
    );
  }
}
