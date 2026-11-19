import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class StatsPanel extends StatelessWidget {
  final VpnTrafficStats stats;

  const StatsPanel({super.key, required this.stats});

  String _formatBytes(int bytes, {bool isSpeed = false}) {
    final suffix = isSpeed ? '/s' : '';
    if (bytes < 1024) return '$bytes B$suffix';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB$suffix';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB$suffix';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF00E676),
                  label: 'سرعت دانلود',
                  value: _formatBytes(stats.downloadSpeed, isSpeed: true),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  label: 'سرعت آپلود',
                  value: _formatBytes(stats.uploadSpeed, isSpeed: true),
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: Colors.white.withValues(alpha: 0.07),
          ),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.cloud_download_outlined,
                  iconColor: const Color(0xFF34D399),
                  label: 'حجم دانلود',
                  value: _formatBytes(stats.totalDownload),
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.cloud_upload_outlined,
                  iconColor: const Color(0xFF60A5FA),
                  label: 'حجم آپلود',
                  value: _formatBytes(stats.totalUpload),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
