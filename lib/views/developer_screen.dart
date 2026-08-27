import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import 'developer_playground.dart';

// Control panel for the Phase 2 AI-edit pipeline. This widget is NOT a
// target of AI edits (see developer_playground.dart for that) — it just
// talks to tools/dev_agent/server.js over the LAN.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final _serverController = TextEditingController(text: 'http://192.168.1.38:4000');
  // Shared secret for the LAN-only dev_agent service (tools/dev_agent). Fine to
  // ship in-app: devices are controlled and this only unlocks the dev-agent
  // code-edit pipeline, not the production API.
  final _tokenController = TextEditingController(text: 'd9b8fba2c609a89f1574e27247d2dd6d51c5875ff00530db');
  final _requestController = TextEditingController();

  String _status = 'idle';
  final List<String> _log = [];
  Timer? _pollTimer;
  bool _busy = false;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _serverController.dispose();
    _tokenController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final server = _serverController.text.trim();
    final token = _tokenController.text.trim();
    final text = _requestController.text.trim();
    if (server.isEmpty || token.isEmpty || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server, token, and request are all required')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _status = 'sending';
      _log.clear();
    });

    try {
      final resp = await http.post(
        Uri.parse('$server/request'),
        headers: {'Content-Type': 'application/json', 'x-agent-token': token},
        body: jsonEncode({'text': text}),
      );
      if (resp.statusCode != 200) {
        setState(() {
          _busy = false;
          _status = 'error';
          _log.add('Request rejected (${resp.statusCode}): ${resp.body}');
        });
        return;
      }
      final jobId = jsonDecode(resp.body)['jobId'] as String;
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll(server, token, jobId));
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'error';
        _log.add('Could not reach server: $e');
      });
    }
  }

  Future<void> _poll(String server, String token, String jobId) async {
    try {
      final resp = await http.get(
        Uri.parse('$server/status/$jobId'),
        headers: {'x-agent-token': token},
      );
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body);
      setState(() {
        _status = data['state'] as String;
        _log
          ..clear()
          ..addAll((data['log'] as List).map((e) => e.toString()));
        if (data['error'] != null) _log.add('error: ${data['error']}');
      });
      if (_status == 'done' || _status == 'error') {
        _pollTimer?.cancel();
        setState(() => _busy = false);
      }
    } catch (_) {
      // transient network hiccup while polling; next tick retries
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.mainBackground,
        iconTheme: const IconThemeData(color: AppColors.yellow),
        title: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [AppColors.yellow, AppColors.green, AppColors.red],
            ).createShader(bounds);
          },
          child: Text(
            "Developer",
            style: GoogleFonts.permanentMarker(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'The goal is to include everyone at Max High Reach in our digital '
              'development. Here you will be able to make your edits to the '
              'apps / server / data we use.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.yellow.withOpacity(0.85),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: AppColors.yellow,
                collapsedIconColor: AppColors.yellow,
                leading: Icon(Icons.settings, color: AppColors.yellow.withOpacity(0.8)),
                title: Text(
                  'Connection settings',
                  style: TextStyle(color: AppColors.yellow.withOpacity(0.8)),
                ),
                childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                children: [
                  _label('Dev agent server'),
                  _textField(_serverController, 'http://192.168.1.38:4000'),
                  const SizedBox(height: 12),
                  _label('Agent token'),
                  _textField(_tokenController, 'shared secret', obscure: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _label('Live playground'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.yellow.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const DeveloperPlayground(),
            ),
            const SizedBox(height: 20),
            _label('Describe a change'),
            _textField(_requestController, 'e.g. make the playground text red and bigger', lines: 3),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.mainBackground,
              ),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit to AI'),
            ),
            const SizedBox(height: 16),
            _label('Status: $_status'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.main,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _log.isEmpty ? '(no activity yet)' : _log.join('\n'),
                style: TextStyle(color: AppColors.yellow.withOpacity(0.8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
      );

  Widget _textField(TextEditingController controller, String hint, {bool obscure = false, int lines = 1}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : lines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.yellow.withOpacity(0.4)),
        filled: true,
        fillColor: AppColors.main,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      ),
    );
  }
}
