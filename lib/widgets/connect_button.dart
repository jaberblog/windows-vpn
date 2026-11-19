import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class ConnectButton extends StatefulWidget {
  final VpnConnectionState state;
  final VoidCallback onTap;

  const ConnectButton({
    super.key,
    required this.state,
    required this.onTap,
  });

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _primaryColor() {
    switch (widget.state) {
      case VpnConnectionState.connected:
        return const Color(0xFF00E676);
      case VpnConnectionState.connecting:
        return const Color(0xFFFFB300);
      case VpnConnectionState.disconnected:
        return const Color(0xFF3B82F6);
    }
  }

  String _statusLabel() {
    switch (widget.state) {
      case VpnConnectionState.connected:
        return 'متصل شد (قطع اتصال)';
      case VpnConnectionState.connecting:
        return 'در حال اتصال...';
      case VpnConnectionState.disconnected:
        return 'اتصال';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _primaryColor();
    final isAnimating = widget.state != VpnConnectionState.disconnected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = isAnimating ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 152,
                  height: 152,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.45),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isAnimating ? 0.35 : 0.15),
                        blurRadius: isAnimating ? 32 : 16,
                        spreadRadius: isAnimating ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.95),
                            color.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: widget.state == VpnConnectionState.connecting
                          ? const Padding(
                              padding: EdgeInsets.all(34),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3.5,
                              ),
                            )
                          : const Icon(
                              Icons.power_settings_new_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _statusLabel(),
            key: ValueKey(widget.state),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
