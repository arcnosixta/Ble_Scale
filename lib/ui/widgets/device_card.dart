import 'package:flutter/material.dart';
import '../theme.dart';

class DeviceCard extends StatelessWidget {
  final dynamic device;
  final VoidCallback onTap;

  const DeviceCard({
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.scale, color: accent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                device.name ?? "Unknown",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white38)
          ],
        ),
      ),
    );
  }
}