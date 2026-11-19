import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_vless/flutter_vless.dart';
import '../models/vpn_config_model.dart';

enum VpnConnectionState {
  disconnected,
  connecting,
  connected,
}

class VpnTrafficStats {
  final int downloadSpeed; // bytes per second
  final int uploadSpeed;   // bytes per second
  final int totalDownload; // bytes
  final int totalUpload;   // bytes
  final String duration;

  const VpnTrafficStats({
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    this.totalDownload = 0,
    this.totalUpload = 0,
    this.duration = '00:00:00',
  });
}

class VpnService {
  late final FlutterVless _flutterVless;
  bool _initialized = false;

  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnTrafficStats>.broadcast();

  Stream<VpnConnectionState> get stateStream => _stateController.stream;
  Stream<VpnTrafficStats> get statsStream => _statsController.stream;

  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  VpnConnectionState get currentState => _currentState;

  VpnTrafficStats _currentStats = const VpnTrafficStats();
  VpnTrafficStats get currentStats => _currentStats;

  VpnService() {
    _flutterVless = FlutterVless(
      onStatusChanged: (VlessStatus status) {
        final stateText = status.state.toUpperCase();
        if (stateText.contains('CONNECTED') && !stateText.contains('DIS')) {
          _updateState(VpnConnectionState.connected);
        } else if (stateText.contains('CONNECTING')) {
          _updateState(VpnConnectionState.connecting);
        } else {
          _updateState(VpnConnectionState.disconnected);
        }

        _currentStats = VpnTrafficStats(
          downloadSpeed: status.downloadSpeed,
          uploadSpeed: status.uploadSpeed,
          totalDownload: status.download,
          totalUpload: status.upload,
          duration: status.duration,
        );
        _statsController.add(_currentStats);
      },
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _flutterVless.initializeVless();
      _initialized = true;
    } on MissingPluginException {
      // Handled gracefully if native plugin channel is unavailable on desktop build
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> connect(VpnConfigModel config) async {
    await initialize();
    _updateState(VpnConnectionState.connecting);

    try {
      await _flutterVless.startVless(
        remark: config.title,
        config: config.fullConfiguration,
        proxyOnly: false,
      );
      _updateState(VpnConnectionState.connected);
    } on MissingPluginException {
      throw Exception(
        'هسته نیتیو flutter_vless در این نسخه ویندوز رجیستر نشده است. مطمئن شوید فایل‌های هسته V2Ray/Xray در کنار فایل exe قرار دارند.',
      );
    } catch (e) {
      _updateState(VpnConnectionState.disconnected);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _flutterVless.stopVless();
    } catch (_) {}
    _updateState(VpnConnectionState.disconnected);
    _currentStats = const VpnTrafficStats();
    _statsController.add(_currentStats);
  }

  Future<int> measurePing(VpnConfigModel config) async {
    // 1. Try native flutter_vless delay check first
    try {
      final delay = await _flutterVless
          .getServerDelay(config: config.fullConfiguration)
          .timeout(const Duration(seconds: 5));
      if (delay > 0) {
        return delay;
      }
    } catch (_) {}

    // 2. Fallback to real TCP handshake latency measurement (works natively on Windows)
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        config.server,
        config.port,
        timeout: const Duration(seconds: 4),
      );
      stopwatch.stop();
      await socket.close();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return -1;
    }
  }

  void _updateState(VpnConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
    _statsController.close();
  }
}
