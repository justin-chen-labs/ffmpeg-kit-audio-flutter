# FFmpegKit Audio for Flutter

### 1. Features

- Updated Android and MacOS bindings to work with Flutter 3.27.3
- Includes both `FFmpeg` and `FFprobe`
- Audio version of FFmpegKit
- Supports
    - `Android`, `iOS` and `macOS`
    - FFmpeg `v6.0.2`
    - `arm-v7a`, `arm-v7a-neon`, `arm64-v8a`, `x86` and `x86_64` architectures on Android
    - `Android API Level 24` or later
      - `API Level 16` on LTS releases
    - iOS architectures with enabled libraries (per build commands):
      - Enabled: `arm64`
      - Disabled: `armv7`, `armv7s`, `arm64-mac-catalyst`, `arm64-simulator`, `arm64e`, `i386`, `x86_64`, `x86_64-mac-catalyst`
    - `iOS SDK 12.1` or later
      - `iOS SDK 12` on LTS releases
    - `arm64` and `x86_64` architectures on macOS
    - `macOS SDK 10.15` or later
      - `macOS SDK 10.12` on LTS releases
    - Can process Storage Access Framework (SAF) Uris on Android
    - Supports HTTPS protocol on all platforms
    - 25 external libraries

      `dav1d`, `fontconfig`, `freetype`, `fribidi`, `gmp`, `gnutls`, `kvazaar`, `lame`, `libass`, `libiconv`, `libilbc`
      , `libtheora`, `libvorbis`, `libvpx`, `libwebp`, `libxml2`, `opencore-amr`, `opus`, `shine`, `snappy`, `soxr`
      , `speex`, `twolame`, `vo-amrwbenc`, `zimg`

    - 4 external libraries with GPL license

      `vid.stab`, `x264`, `x265`, `xvidcore`

    - Enabled external libraries according to build commands for iOS/macOS:

      `lame`, `x264`, `opus`, `libvorbis`, `opencore-amr`, `speex`

- Licensed under `LGPL 3.0` by default, some packages licensed by `GPL v3.0` effectively

---

### 2. Installation

Add `ffmpeg_kit_audio_flutter` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  ffmpeg_kit_audio_flutter: 1.0.1
```

### 3. Platform Support
The following table shows Android API level, iOS deployment target and macOS deployment target requirements in
ffmpeg_kit_flutter_new releases.

| LTS Release | Android | API Level | iOS Minimum Deployment Target | macOS Minimum Deployment Target |
| --- | --- | --- | --- | --- |
| 24 | 14 | 10.15 | 12 | 12 |

### 4. Using
Execute FFmpeg commands.
```
FFmpegKit.execute("-i input.mp3 output.mp3");
```

