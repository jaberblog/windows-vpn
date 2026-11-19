import 'dart:convert';
import 'package:flutter_vless/flutter_vless.dart';
import 'package:http/http.dart' as http;
import '../models/vpn_config_model.dart';

class ApiService {
  static const String subscriptionUrl = 'https://virasub.ir/npv/';

  Future<List<VpnConfigModel>> fetchConfigs() async {
    final response = await http
        .get(
          Uri.parse(subscriptionUrl),
          headers: {
            'User-Agent': 'ViraVPN-Windows/1.0',
            'Accept': '*/*',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('خطا در دریافت اطلاعات از سرور (${response.statusCode})');
    }

    final rawBody = utf8.decode(response.bodyBytes).trim();
    if (rawBody.isEmpty) {
      return [];
    }

    final List<String> rawLinks = _extractLinks(rawBody);
    final List<VpnConfigModel> configs = [];

    for (int i = 0; i < rawLinks.length; i++) {
      final link = rawLinks[i].trim();
      if (link.isEmpty) continue;

      final parsed = _parseSingleLink(link, i);
      if (parsed != null) {
        configs.add(parsed);
      }
    }

    return configs;
  }

  List<String> _extractLinks(String body) {
    // 1. Check if JSON
    if (body.startsWith('[') || body.startsWith('{')) {
      try {
        final decoded = jsonDecode(body);
        final List<String> found = [];
        void collectStrings(dynamic node) {
          if (node is String) {
            if (_isSupportedScheme(node.trim())) {
              found.add(node.trim());
            }
          } else if (node is List) {
            for (final item in node) {
              collectStrings(item);
            }
          } else if (node is Map) {
            for (final value in node.values) {
              collectStrings(value);
            }
          }
        }

        collectStrings(decoded);
        if (found.isNotEmpty) return found;
      } catch (_) {}
    }

    // 2. Check if direct links exist without base64 decoding
    final directLines = body
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where(_isSupportedScheme)
        .toList();
    if (directLines.isNotEmpty) {
      return directLines;
    }

    // 3. Try Base64 decoding (standard & URL-safe)
    try {
      String normalized = body.replaceAll(RegExp(r'\s+'), '');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decodedBytes = base64Decode(normalized);
      final decodedText = utf8.decode(decodedBytes, allowMalformed: true);
      return decodedText
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where(_isSupportedScheme)
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _isSupportedScheme(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('vless://') ||
        lower.startsWith('vmess://') ||
        lower.startsWith('trojan://') ||
        lower.startsWith('ss://');
  }

  VpnConfigModel? _parseSingleLink(String uriString, int index) {
    final protocol = uriString.split('://').first.toUpperCase();

    // Try parsing with FlutterVless parser first
    try {
      final parsedUrl = FlutterVless.parseFromURL(uriString);
      final title = parsedUrl.remark.trim().isNotEmpty
          ? Uri.decodeComponent(parsedUrl.remark.trim())
          : 'Server #${index + 1}';
      return VpnConfigModel(
        id: 'cfg_${index}_${uriString.hashCode}',
        title: title,
        server: parsedUrl.address,
        port: parsedUrl.port,
        protocol: protocol,
        rawUri: uriString,
        fullConfiguration: parsedUrl.getFullConfiguration(),
      );
    } catch (_) {
      // Fallback parser for non-vless or custom URI formats
      try {
        if (uriString.toLowerCase().startsWith('vmess://')) {
          final b64 = uriString.substring(8).trim();
          final jsonStr = utf8.decode(base64Decode(base64.normalize(b64)));
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final title = (map['ps'] ?? 'VMess Server #${index + 1}').toString();
          final host = (map['add'] ?? 'unknown').toString();
          final port = int.tryParse((map['port'] ?? '443').toString()) ?? 443;
          return VpnConfigModel(
            id: 'cfg_${index}_${uriString.hashCode}',
            title: title,
            server: host,
            port: port,
            protocol: 'VMESS',
            rawUri: uriString,
            fullConfiguration: uriString,
          );
        }

        final uri = Uri.parse(uriString);
        final fragment = uri.fragment.isNotEmpty
            ? Uri.decodeComponent(uri.fragment)
            : '$protocol Server #${index + 1}';
        return VpnConfigModel(
          id: 'cfg_${index}_${uriString.hashCode}',
          title: fragment,
          server: uri.host.isNotEmpty ? uri.host : 'unknown',
          port: uri.hasPort ? uri.port : 443,
          protocol: protocol,
          rawUri: uriString,
          fullConfiguration: uriString,
        );
      } catch (_) {
        return null;
      }
    }
  }
}
