import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LockScreenPage(),
    );
  }
}

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  String _status = "Not started";
  final MethodChannel _channel = MethodChannel('com.example.auto_lock/device_policy');

  @override
  void initState() {
    super.initState();
    _checkAndLock();
  }

  Future<void> _checkDeviceOwnerStatus() async {
    developer.log("Checking device owner status...", name: "AutoLock");
    setState(() {
      _status = "Checking...";
    });
    
    try {
      bool isDeviceOwner = await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;
      bool isAdminActive = await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
      
      developer.log("isDeviceOwner: $isDeviceOwner, isAdminActive: $isAdminActive", name: "AutoLock");
      
      if (mounted) {
        setState(() {
          _status = "Device Admin Active: $isAdminActive\n"
              "Device Owner: $isDeviceOwner\n"
              "${isDeviceOwner ? '✓ Ready to lock!' : '✗ Run set_device_owner.sh via ADB'}";
        });
      }
    } catch (e) {
      developer.log("Error checking status: $e", name: "AutoLock", error: e);
      if (mounted) {
        setState(() {
          _status = "Error: $e";
        });
      }
    }
  }

  Future<void> _checkAndLock() async {
    developer.log("Button pressed, starting _checkAndLock", name: "AutoLock");
    setState(() {
      _status = "Checking permission...";
    });

    try {
      bool isAdminActive = await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
      developer.log("isAdminActive: $isAdminActive", name: "AutoLock");

      if (isAdminActive) {
        setState(() {
          _status = "Admin active. Locking screen...";
        });
        developer.log("Device admin active. Calling lockNow()...", name: "AutoLock");
        
        bool success = await _channel.invokeMethod<bool>('lockNow') ?? false;
        
        if (mounted) {
          if (success) {
            setState(() {
              _status = "✓ Screen locked!";
            });
            developer.log("lockNow() succeeded", name: "AutoLock");
          } else {
            setState(() {
              _status = "✗ lockNow() failed.\nIs your app the Device Owner?";
            });
            developer.log("lockNow() failed", name: "AutoLock");
          }
        }
      } else {
        setState(() {
          _status = "Device admin not active. Activating...";
        });
        developer.log("Device admin not active. Will need to activate first.", name: "AutoLock");
        
        // On Flutter, we can't easily trigger the device admin intent from Dart.
        // User needs to activate via Settings > Security > Device admin apps
        if (mounted) {
          setState(() {
            _status = "Please activate device admin:\n"
                "Settings > Security > Device admin apps\n"
                "Enable 'AutoLock Admin'";
          });
        }
      }
    } catch (e, stack) {
      developer.log("Error in _checkAndLock: $e\n$stack", name: "AutoLock", error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _status = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Lock App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _checkAndLock,
              child: const Text('Grant Admin & Lock Screen'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkDeviceOwnerStatus,
              child: const Text('Check Device Owner Status'),
            ),
            const SizedBox(height: 24),
            Text(
              _status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
