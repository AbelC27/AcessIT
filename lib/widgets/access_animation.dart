// lib/widgets/access_animation.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AccessAnimation extends StatelessWidget {
  final bool success;
  final String message;

  const AccessAnimation({super.key, required this.success, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              success
                  ? 'assets/lottie/success.json'
                  : 'assets/lottie/denied.json',
              width: 120,
              repeat: false,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}