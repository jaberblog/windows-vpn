import 'package:flutter/material.dart';
import '../models/vpn_config_model.dart';

class ConfigTile extends StatelessWidget {
  final VpnConfigModel config;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPingTap;

  const ConfigTile({
    super.key,
    required this.config,
    required this.isSelected,
    required this.onTap,
    required this.onPingTap,
  });

  IconData _protocolIcon() {
    switch (config.protocol.toUpperCase()) {
      case 'VLESS':
        return Icons.bolt_rounded;
      case 'VMESS':
        return Icons.shield_outlined;
      case 'TROJAN':
        return Icons.security_rounded;
      default:
        return Icons.vpn_lock_rounded;
    }
  }

  Color _pingColor(int? ping) {
    if (ping == null || ping < 0) return Colors.redAccent;
    if (ping < 180) return const Color(0xFF00E676);
    if (ping < 400) return const Color(0xFFFFB300);
    return Colors.deepOrangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            // Protocol / Server Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _protocolIcon(),
                color: isSelected ? const Color(0xFF60A5FA) : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title & Server Address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          config.protocol,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${config.server}:${config.port}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Ping Display & Refresh Button
            InkWell(
              onTap: onPingTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: config.isPinging
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 15,
                            color: config.ping == null
                                ? Colors.white54
                                : _pingColor(config.ping),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            config.ping == null
                                ? 'پینگ'
                                : (config.ping! < 0
                                    ? 'Timeout'
                                    : '${config.ping} ms'),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: config.ping == null
                                  ? Colors.white70
                                  : _pingColor(config.ping),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
