import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:simply_qr/toast.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var statuses = await [
    Permission.camera,
  ].request();
  if (statuses[Permission.camera] == PermissionStatus.denied)
    SystemNavigator.pop();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simply QR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String data = '';
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: data.isEmpty
          ? QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            )
          : Center(
              child: SelectableText(
                '$data',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  toast('Text copied to clipboard!');
                },
              ),
            ),
    );
  }
  //C:\Program Files\Android\Android Studio\jre\bin\keytool -genkey -v -keystore c:\Users\MyComputer\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pauseCamera();
    } else if (Platform.isIOS) {
      controller.resumeCamera();
    }
  }

  late Timer t;

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(Duration(seconds: 30), (timer) {
      controller.stopCamera();
      SystemNavigator.pop();
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      t.cancel();
      String value = scanData.code;
      if (Uri.parse(value).isAbsolute) {
        data = 'link found, opening browser';
        launch(value).then((value) => SystemNavigator.pop());
      } else {
        data = scanData.code;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    if (t.isActive) t.cancel();
    super.dispose();
  }
}
