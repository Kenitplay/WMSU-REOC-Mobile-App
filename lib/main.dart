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
    static const String _offlineAsset = "assets/offline.html";
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
          top: false,
          bottom: false,
          left: false,
          right: false,
          child: _isOnline == null
              ? const SizedBox.expand()
              : Container(
                  color: Colors.white,
                  child: InAppWebView(
                  initialUrlRequest: _isOnline!
                      ? URLRequest(url: WebUri(_loginUrl))
                      : null,
                  initialFile: _isOnline! ? null : _offlineAsset,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowFileAccess: true,
                    allowContentAccess: true,
                    useOnDownloadStart: true,
                    transparentBackground: false,
                    domStorageEnabled: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webController = controller;
                    if (_isOnline == false) _startConnectionCheckTimer();
                  },
                  androidOnPermissionRequest:
                      (controller, origin, resources) async {
                    return PermissionRequestResponse(
                      resources: resources,
                      action: PermissionRequestResponseAction.GRANT,
                    );
                  },
                  onLoadStop: (controller, url) {
                    final u = url?.toString() ?? "";
                    if (u.startsWith("https://reoph.site")) {
                      _connectionCheckTimer?.cancel();
                    }
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
                  onLoadError:
                      (controller, url, code, message) async {
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



