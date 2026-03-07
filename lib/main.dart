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
  import 'package:flutter_inappwebview/flutter_inappwebview.dart';
  import 'package:flutter_downloader/flutter_downloader.dart';
  import 'package:permission_handler/permission_handler.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

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
    static const Duration _noConnectionDelay = Duration(seconds: 10);

    Timer? _connectionTimer;

    Future<void> requestPermissions() async {
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.photos.request();
      }
    }

    void _scheduleNoConnectionFallback(InAppWebViewController controller) {
      _connectionTimer?.cancel();
      _connectionTimer = Timer(_noConnectionDelay, () async {
        if (!mounted) return;

        await controller.loadFile(
          assetFilePath: "assets/no_connection.html",
        );
      });
    }

    @override
    void initState() {
      super.initState();
      requestPermissions();
    }

    @override
    void dispose() {
      _connectionTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: InAppWebView(
            // Start by showing the custom "Connecting" HTML so the
            // default browser error page is never visible first.
            initialFile: "assets/connecting.html",
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccess: true,
              allowContentAccess: true,
              useOnDownloadStart: true,
            ),
            onWebViewCreated: (controller) {
              // Try to load the real site in the background.
              controller.loadUrl(
                urlRequest: URLRequest(url: WebUri(_loginUrl)),
              );
            },
            androidOnPermissionRequest:
                (controller, origin, resources) async {
              return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT,
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
            onLoadStop: (controller, url) {
              final current = url?.toString() ?? "";
              // Only cancel the timer when the real site has loaded.
              if (current.startsWith("https://reoph.site")) {
                _connectionTimer?.cancel();
              }
            },
            onLoadError:
                (controller, url, code, message) async {
              await controller.loadFile(
                assetFilePath: "assets/connecting.html",
              );
              _scheduleNoConnectionFallback(controller);
            },
          ),
        ),
      );
    }
  }



