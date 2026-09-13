import 'dart:async';
import 'package:flutter/material.dart';

class AccountCard extends StatefulWidget {
  final String username;
  final String password;
  final String tier;
  final int expiresAt;
  final VoidCallback onExpired;

  const AccountCard({
    Key? key,
    required this.username,
    required this.password,
    required this.tier,
    required this.expiresAt,
    required this.onExpired,
  }) : super(key: key);

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  Timer? _timer;
  String _remainingDisplay = "...";

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = widget.expiresAt - now;

      if (diff <= 0) {
        timer.cancel();
        setState(() => _remainingDisplay = "EXPIRED");
        widget.onExpired();
      } else {
        final duration = Duration(milliseconds: diff);
        final days = duration.inDays;
        final hours = duration.inHours % 24;
        final mins = duration.inMinutes % 60;
        final secs = duration.inSeconds % 60;

        setState(() {
          _remainingDisplay = days > 0
              ? "${days}d ${hours}h ${mins}m"
              : "${mins}m ${secs}s";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "⭐ ACCOUNT INFORMATION ⭐",
              style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          Text("USERNAME: ${widget.username}", style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 6),
          Text("PASSWORD: ${widget.password}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text("SUBSCRIPTION: ${widget.tier}", style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
          const SizedBox(height: 6),
          Text("EXPIRATION: $_remainingDisplay", style: const TextStyle(color: Colors.orangeAccent, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
