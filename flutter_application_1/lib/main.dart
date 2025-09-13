import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server Synced Counter',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  static const String counterUrl = 'http://localhost:3000/counter';

  int? _value;
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _fetchCounter();
  }

  Future<void> _fetchCounter() async {
    setState(() => _status = 'Loading…');
    try {
      final res = await http.get(Uri.parse(counterUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _value = (data['value'] as num).toInt();
          _status = null;
        });
      } else {
        setState(() => _status = 'Failed to load: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _applyDelta(int delta) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse(counterUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'delta': delta}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _value = (data['value'] as num).toInt();
          _status = null;
        });
      } else {
        setState(() => _status = 'Update failed: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueText = _value?.toString() ?? '…';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Synced Counter'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _fetchCounter,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_status != null)
            Container(
              width: double.infinity,
              color: Colors.yellow.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(_status!),
            ),
          const SizedBox(height: 24),
          Text(
            valueText,
            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 40,
                onPressed: _busy ? null : () => _applyDelta(-1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 40,
                onPressed: _busy ? null : () => _applyDelta(1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _busy ? null : _fetchCounter,
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}
