import 'package:ffmpeg_kit_https_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_https_flutter/return_code.dart';
import 'package:flutter/material.dart';

import 'ffmpeg_convert_page.dart';
import 'ffmpeg_https_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFmpeg Kit Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _output = 'Ready to test FFmpeg';
  bool _isLoading = false;

  void _testFFmpeg() async {
    setState(() {
      _isLoading = true;
      _output = 'Testing FFmpeg...';
    });

    try {
      // 测试FFmpeg版本信息
      await FFmpegKit.execute('-version').then((session) async {
        final returnCode = await session.getReturnCode();
        final output = await session.getOutput();

        setState(() {
          if (ReturnCode.isSuccess(returnCode)) {
            _output =
                'FFmpeg is working!\n\nVersion info:\n${output ?? 'No output'}';
          } else {
            _output = 'FFmpeg test failed with return code: $returnCode';
          }
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFmpeg Kit Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFFmpeg,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test FFmpeg'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FfmpegConvertPage()));
              },
              child: const Text('Test convert audio'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
