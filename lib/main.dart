import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:developer' as developer;
import 'dart:io';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MaterialApp(home: WebViewExample()));
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({Key? key}) : super(key: key);

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController controller;
  String _connectionStatus = 'http://example.com';
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
    initialization();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(_connectionStatus)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    //..loadRequest(Uri.parse(_connectionStatus));
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 5));
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: controller),
    );
  }

  Future<void> _initNetworkInfo() async {
    String? wifiIPv4;
    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
      if (wifiIPv4 != null) {
        await testConnection(wifiIPv4, 18086);
      }
    } catch (e) {
      developer.log('Failed to get WiFi IPv4', error: e);
      wifiIPv4 = 'Failed to get WiFi IPv4';
    }
    // setState(() {
    //   _connectionStatus = '$wifiIPv4';
    // });
  }

  testConnection(String ipAddress, int port) async {
    bool isConnected = false;

    try {
      List<String> parts = ipAddress.split('.');
      for (int i = 1; i <= 255 && !isConnected; i++) {
        String newIP = "${parts[0]}.${parts[1]}.${parts[2]}.$i";
        try {
          final socket = await Socket.connect(newIP, port,
              timeout: const Duration(seconds: 2));
          setState(() {
            _connectionStatus = 'http://$newIP:$port';
          });
          socket.close();
          isConnected = true;
          controller.loadRequest(Uri.parse(_connectionStatus));
        } catch (e) {
          print("Connection failed to $newIP on port $port: $e");
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}
