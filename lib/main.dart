import 'package:flutter/material.dart';
import 'models/vpn_config_model.dart';
import 'services/api_service.dart';
import 'services/vpn_service.dart';
import 'widgets/config_tile.dart';
import 'widgets/connect_button.dart';
import 'widgets/stats_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ViraVpnApp());
}

class ViraVpnApp extends StatelessWidget {
  const ViraVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vira VPN Windows',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF161B26),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final VpnService _vpnService = VpnService();

  List<VpnConfigModel> _configs = [];
  VpnConfigModel? _selectedConfig;
  bool _isLoadingConfigs = true;
  String? _errorMessage;

  VpnConnectionState _connectionState = VpnConnectionState.disconnected;
  VpnTrafficStats _stats = const VpnTrafficStats();

  @override
  void initState() {
    super.initState();
    _vpnService.initialize();
    _vpnService.stateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
    });
    _vpnService.statsStream.listen((stats) {
      if (mounted) setState(() => _stats = stats);
    });
    _loadConfigs();
  }

  @override
  void dispose() {
    _vpnService.dispose();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoadingConfigs = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _apiService.fetchConfigs();
      if (!mounted) return;
      setState(() {
        _configs = fetched;
        if (_configs.isNotEmpty) {
          _selectedConfig = _configs.first;
        }
        _isLoadingConfigs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingConfigs = false;
      });
    }
  }

  Future<void> _pingSingleConfig(int index) async {
    if (index < 0 || index >= _configs.length) return;
    setState(() {
      _configs[index] = _configs[index].copyWith(isPinging: true);
    });

    final pingResult = await _vpnService.measurePing(_configs[index]);
    if (!mounted) return;

    setState(() {
      _configs[index] = _configs[index].copyWith(
        ping: pingResult,
        isPinging: false,
      );
      if (_selectedConfig?.id == _configs[index].id) {
        _selectedConfig = _configs[index];
      }
    });
  }

  Future<void> _pingAllConfigs() async {
    for (int i = 0; i < _configs.length; i++) {
      _pingSingleConfig(i);
    }
  }

  Future<void> _toggleConnection() async {
    if (_connectionState == VpnConnectionState.connected ||
        _connectionState == VpnConnectionState.connecting) {
      await _vpnService.disconnect();
      return;
    }

    if (_selectedConfig == null) {
      _showSnack('لطفاً ابتدا یک سرور از لیست انتخاب کنید.');
      return;
    }

    try {
      await _vpnService.connect(_selectedConfig!);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_moon_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 10),
            Text(
              'Vira VPN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تست پینگ همه سرورها',
            onPressed: _configs.isEmpty ? null : _pingAllConfigs,
            icon: const Icon(Icons.network_check_rounded),
          ),
          IconButton(
            tooltip: 'بروزرسانی لیست کانفیگ‌ها',
            onPressed: _isLoadingConfigs ? null : _loadConfigs,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 780;
            final controlPanel = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConnectButton(
                  state: _connectionState,
                  onTap: _toggleConnection,
                ),
                const SizedBox(height: 16),
                if (_selectedConfig != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'سرور انتخاب‌شده: ${_selectedConfig!.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                StatsPanel(stats: _stats),
              ],
            );

            final serverListPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'لیست سرورها (${_configs.length})',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _configs.isEmpty ? null : _pingAllConfigs,
                      icon: const Icon(Icons.speed_rounded, size: 18),
                      label: const Text('پینگ همه'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildConfigList()),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  SizedBox(width: 340, child: controlPanel),
                  const SizedBox(width: 22),
                  Expanded(child: serverListPanel),
                ],
              );
            }

            return Column(
              children: [
                controlPanel,
                const SizedBox(height: 18),
                Expanded(child: serverListPanel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfigList() {
    if (_isLoadingConfigs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 42),
            const SizedBox(height: 10),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadConfigs,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (_configs.isEmpty) {
      return const Center(
        child: Text('هیچ کانفیگی از API دریافت نشد.'),
      );
    }

    return ListView.builder(
      itemCount: _configs.length,
      itemBuilder: (context, index) {
        final cfg = _configs[index];
        return ConfigTile(
          config: cfg,
          isSelected: _selectedConfig?.id == cfg.id,
          onTap: () => setState(() => _selectedConfig = cfg),
          onPingTap: () => _pingSingleConfig(index),
        );
      },
    );
  }
}
