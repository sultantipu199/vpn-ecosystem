import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/account_card.dart';

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
  bool _isConnected = false;

  // ডেমো সাবস্ক্রিপশন ডাটা (ব্যাকএন্ড কানেক্ট করলে ডাইনামিকালি সেট হবে)
  final String _user = "232248";
  final String _pass = "08859";
  final String _tier = "Premium";
  late int _expiryTime;

  @override
  void initState() {
    super.initState();
    // ডেমো: বর্তমান সময়ের সাথে ৬০ মিনিট যোগ
    _expiryTime = DateTime.now().add(const Duration(minutes: 60)).millisecondsSinceEpoch;
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
        title: const Text("Session Expired"),
        content: const Text("Your allocated subscription time has ended. Please renew to continue."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
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
      ),
      body: Column(
        children: [
          AccountCard(
            username: _user,
            password: _pass,
            tier: _tier,
            expiresAt: _expiryTime,
            onExpired: _handleKillSwitch,
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
