import 'package:flutter/material.dart';
import '../theme.dart';

class GlowButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GlowButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [primary, accent]),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.6),
              blurRadius: 20,
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}