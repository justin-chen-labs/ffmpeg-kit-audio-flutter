import 'dart:io';

import 'package:ffmpeg_kit_https_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_https_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_https_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FfmpegConvertPage extends StatefulWidget {
  const FfmpegConvertPage({super.key});

  @override
  State<FfmpegConvertPage> createState() => _FfmpegConvertPageState();
}

class _FfmpegConvertPageState extends State<FfmpegConvertPage> {
  String _log = "点击开始转码";
  String _info = "";

  Future<File> _copyAssetToFile(String assetPath, String filename) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _runFFmpeg() async {
    setState(() {
      _log = "准备文件...";
      _info = "";
    });

    // 1. 复制 assets mp3 到临时目录
    File inputFile = await _copyAssetToFile(
        'assets/EternalFlame_TheBangles.mp3', 'test.mp3');
    String inputPath = inputFile.path;

    // 2. 输出路径
    final tempDir = await getTemporaryDirectory();
    String outputPath = '${tempDir.path}/output.wav';

    setState(() {
      _log = "开始转码...";
    });

    // 3. 执行转码命令，mp3转wav
    String command = '-y -i "$inputPath" "$outputPath"';

    await FFmpegKit.execute(command).then((session) async {
      final ReturnCode? returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _log = "转码成功，输出文件路径:\n$outputPath";
        });

        // 4. 获取输出音频信息
        final infoSession = await FFprobeKit.getMediaInformation(outputPath);
        final infoResult = infoSession.getMediaInformation();
        if (infoResult != null) {
          setState(() {
            _info = infoResult.getAllProperties().toString();
          });
        }
      } else {
        setState(() {
          _log = "转码失败，错误码：$returnCode";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FFmpeg-kit MP3转码 Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runFFmpeg,
              child: const Text("开始转码并获取信息"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text('$_log\n\n$_info'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
