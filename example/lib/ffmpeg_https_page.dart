import 'dart:io';

import 'package:ffmpeg_kit_https_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_https_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FfmpegHttpsPage extends StatefulWidget {
  const FfmpegHttpsPage({super.key});

  @override
  State<FfmpegHttpsPage> createState() => _FfmpegHttpsPageState();
}

class _FfmpegHttpsPageState extends State<FfmpegHttpsPage> {
  String _output = '点击“检查 HTTPS 支持”开始';
  bool _checking = false;
  String? _imagePath;

  Future<void> checkHttpsSupport() async {
    setState(() {
      _checking = true;
      _output = '正在检查 HTTPS 支持...';
    });

    final session = await FFmpegKit.execute('-protocols');
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();

    if (ReturnCode.isSuccess(returnCode)) {
      if (logs?.contains('https') ?? false) {
        setState(() {
          _output = '✅ FFmpeg 支持 HTTPS 协议';
        });
      } else {
        setState(() {
          _output = '❌ FFmpeg 不支持 HTTPS 协议';
        });
      }
    } else {
      setState(() {
        _output = '❌ 命令执行失败，错误码：$returnCode';
      });
    }

    setState(() {
      _checking = false;
    });
  }

  Future<void> captureFrameFromHttps() async {
    setState(() {
      _checking = true;
      _output = '开始处理网络视频截图...';
      _imagePath = null;
    });

    const url = 'https://media.w3.org/2010/05/sintel/trailer.mp4';

    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputFile = '${directory.path}/frame.jpg';
      // 从视频的第5秒开始，截取1帧图像
      final command = '-y -i "$url" -ss 5 -frames:v 1 -update 1 "$outputFile"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _output = '✅ 截图保存成功，路径：$outputFile';
          _imagePath = outputFile;
        });
      } else {
        setState(() {
          _output = '❌ 截图失败，错误码：$returnCode';
          _imagePath = null;
        });
      }
    } catch (e) {
      setState(() {
        _output = '❌ 截图异常：$e';
        _imagePath = null;
      });
    }

    setState(() {
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FFmpeg HTTPS 支持示例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_output, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checking ? null : checkHttpsSupport,
              child: const Text('检查 HTTPS 支持'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checking ? null : captureFrameFromHttps,
              child: const Text('从 HTTPS 视频截取一帧'),
            ),
            const SizedBox(height: 24),
            if (_imagePath != null)
              Expanded(
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
