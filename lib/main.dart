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

class _LockScreenPageState extends State<LockScreenPage> with WidgetsBindingObserver {
  String _status = "Not started";
  bool _accessibilityEnabled = false;
  bool _justLocked = false;
  bool _firstResume = true;
  final MethodChannel _channel = MethodChannel('com.example.auto_lock/device_policy');

  @override
  void initState() {
    super.initState();
    _justLocked = false;
    _firstResume = true;
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibilityStatus();
    // Auto-lock on first app open
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _accessibilityEnabled && _firstResume) {
        setState(() => _justLocked = true);
        _lockViaAccessibility();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background — next resume should lock
      _firstResume = false;
      _justLocked = false; // Reset so next manual lock can trigger again
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      if (!_firstResume && _accessibilityEnabled && !_justLocked) {
        // Not the first time the app has been open, and we didn't just lock
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _lockViaAccessibility();
        });
      }
      if (_firstResume) {
        _firstResume = false;
      }
    }
  }

  Future<void> _checkAccessibilityStatus() async {
    developer.log("Checking accessibility service status...", name: "AutoLock");
    try {
      bool enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled') ?? false;
      developer.log("Accessibility enabled: $enabled", name: "AutoLock");
      if (mounted) {
        setState(() {
          _accessibilityEnabled = enabled;
          _status = enabled
              ? "✓ Accessibility service enabled. Ready to lock!"
              : "✗ Accessibility service not enabled.\nTap the button below to enable it in Settings.";
        });
      }
    } catch (e) {
      developer.log("Error checking accessibility status: $e", name: "AutoLock", error: e);
      if (mounted) {
        setState(() {
          _status = "Error: $e";
        });
      }
    }
  }

  Future<void> _openAccessibilitySettings() async {
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> _lockViaAccessibility() async {
    developer.log("Locking screen via AccessibilityService...", name: "AutoLock");
    setState(() {
      _status = "Locking screen...";
    });

    try {
      bool success = await _channel.invokeMethod<bool>('lockViaAccessibility') ?? false;
      if (mounted) {
        if (success) {
          setState(() {
            _status = "✓ Screen locked! (biometrics preserved)";
          });
          developer.log("lockViaAccessibility() succeeded", name: "AutoLock");
        } else {
          setState(() {
            _status = "✗ Failed to lock.\nMake sure the accessibility service is enabled in Settings.";
          });
          developer.log("lockViaAccessibility() failed", name: "AutoLock");
        }
      }
    } catch (e, stack) {
      developer.log("Error in _lockViaAccessibility: $e\n$stack", name: "AutoLock", error: e, stackTrace: stack);
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step 1: Enable accessibility service
              ElevatedButton.icon(
                onPressed: _openAccessibilitySettings,
                icon: const Icon(Icons.accessibility),
                label: const Text('Enable Accessibility Service'),
              ),
              const SizedBox(height: 12),
              // Step 2: Lock screen (only if accessibility is enabled)
              ElevatedButton.icon(
                onPressed: _accessibilityEnabled ? () {
                  setState(() => _justLocked = true);
                  _lockViaAccessibility();
                } : null,
                icon: const Icon(Icons.lock),
                label: const Text('Lock Screen (Preserve Biometrics)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accessibilityEnabled ? Colors.green.shade600 : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              // Status text
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Info about biometric preservation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  "ℹ The accessibility service method uses GLOBAL_ACTION_LOCK_SCREEN,\n"
                  "which mimics a natural power-button press.\n"
                  "Biometric unlock (fingerprint/face) remains active after locking.",
                  style: TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
