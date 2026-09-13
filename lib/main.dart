import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/account_card.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VpnHomeScreen(),
  ));
}

class VpnHomeScreen extends StatefulWidget {
  const VpnHomeScreen({Key? key}) : super(key: key);

  @override
  State<VpnHomeScreen> createState() => _VpnHomeScreenState();
}

class _VpnHomeScreenState extends State<VpnHomeScreen> {
  static const _channel = MethodChannel('com.tunnel.vpn/core');
  final _storage = const FlutterSecureStorage();

  bool _isConnected = false;
  bool _isLoading = false;

  String _user = "232248";
  String _pass = "08859";
  String _tier = "Premium";
  late int _expiryTime;
  String _serverUrl = "https://vpn-license-backend.onrender.com";
  String _deviceHwid = "";

  @override
  void initState() {
    super.initState();
    // Default 60 mins demo expiry
    _expiryTime = DateTime.now().add(const Duration(minutes: 60)).millisecondsSinceEpoch;
    _initDeviceAndSession();
  }

  Future<void> _initDeviceAndSession() async {
    // Generate or fetch persistent HWID
    var hwid = await _storage.read(key: 'device_hwid');
    if (hwid == null) {
      hwid = "HWID-${Random().nextInt(900000) + 100000}-${DateTime.now().millisecondsSinceEpoch}";
      await _storage.write(key: 'device_hwid', value: hwid);
    }
    setState(() {
      _deviceHwid = hwid!;
    });

    // Check saved server URL
    final savedUrl = await _storage.read(key: 'server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
    }
  }

  Future<void> _toggleVpn() async {
    if (_isConnected) {
      await _channel.invokeMethod('stopVpn');
      setState(() => _isConnected = false);
    } else {
      await _channel.invokeMethod('startVpn');
      setState(() => _isConnected = true);
    }
  }

  void _handleKillSwitch() {
    if (_isConnected) {
      _channel.invokeMethod('stopVpn');
      setState(() => _isConnected = false);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Session Expired", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Your allocated subscription time has ended. Please renew to continue.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.amberAccent)),
          )
        ],
      ),
    );
  }

  void _showLoginDialog() {
    final userController = TextEditingController(text: _user);
    final passController = TextEditingController(text: _pass);
    final serverController = TextEditingController(text: _serverUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Connect to Backend Server", style: TextStyle(color: Colors.amberAccent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serverController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Server URL",
                  labelStyle: TextStyle(color: Colors.white60),
                  hintText: "https://your-backend.onrender.com",
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              try {
                final api = ApiService(baseUrl: serverController.text.trim());
                final userModel = await api.login(
                  username: userController.text.trim(),
                  password: passController.text.trim(),
                  hwid: _deviceHwid,
                );

                await _storage.write(key: 'server_url', value: serverController.text.trim());
                await _storage.write(key: 'saved_user', value: userController.text.trim());

                setState(() {
                  _user = userModel.username;
                  _pass = passController.text.trim();
                  _tier = userModel.tier;
                  _expiryTime = userModel.expiresAt;
                  _serverUrl = serverController.text.trim();
                  _isLoading = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Authenticated successfully with HWID bound!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: ${e.toString().replaceAll('Exception: ', '')}"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Authenticate", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        title: const Text("Enterprise Tunnel"),
        backgroundColor: const Color(0xFF1E1E2C),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.amberAccent),
            tooltip: "Server Login & HWID Binding",
            onPressed: _showLoginDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : Column(
              children: [
                AccountCard(
                  username: _user,
                  password: _pass,
                  tier: _tier,
                  expiresAt: _expiryTime,
                  onExpired: _handleKillSwitch,
                ),
                if (_deviceHwid.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "DEVICE BINDING: ${_deviceHwid.substring(0, min(24, _deviceHwid.length))}...",
                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                  ),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? Colors.redAccent : Colors.greenAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: _toggleVpn,
                    child: Text(
                      _isConnected ? "DISCONNECT" : "CONNECT",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
    );
  }
}
