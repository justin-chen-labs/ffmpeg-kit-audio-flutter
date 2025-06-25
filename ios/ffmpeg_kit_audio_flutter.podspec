Pod::Spec.new do |s|
  s.name             = 'ffmpeg_kit_audio_flutter'
  s.version          = '0.0.3'
  s.summary          = 'FFmpeg Kit for Flutter'
  s.description      = 'A Flutter plugin for running FFmpeg and FFprobe commands on iOS using prebuilt frameworks.'
  s.homepage         = 'https://github.com/chenjun1127/ffmpeg_kit_audio_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'chenjun1127' => 'your-email@example.com' }

  s.platform         = :ios
  s.requires_arc     = true
  s.static_framework = true

  # 使用简单的 git 源，避免复杂的下载逻辑
  s.source = { :git => 'https://github.com/chenjun1127/ffmpeg_kit_audio_flutter.git', :tag => "v#{s.version}" }

  # 插件 iOS 代码文件路径
  s.source_files        = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  # 依赖 Flutter
  s.dependency 'Flutter'

  # 最低 iOS 版本
  s.ios.deployment_target = '12.0'

  # 修复编码问题的 prepare_command
  s.prepare_command = <<-CMD
    #!/bin/bash
    set -e
    
    # 设置环境变量解决编码问题
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    
    FRAMEWORK_ZIP="ffmpeg-kit-ios-audio.zip"
    DOWNLOAD_URL="https://github.com/chenjun1127/ffmpeg_kit_audio_flutter/releases/download/v#{s.version}/${FRAMEWORK_ZIP}"
    
    echo "Downloading framework from GitHub Release..."
    
    # 使用 --silent 和 --show-error 减少输出，避免编码问题
    if ! curl --silent --show-error --fail --location --output "$FRAMEWORK_ZIP" "$DOWNLOAD_URL"; then
      echo "Error: Failed to download framework"
      exit 1
    fi
    
    echo "Creating Frameworks directory..."
    mkdir -p Frameworks
    
    echo "Extracting frameworks..."
    if ! unzip -q -o "$FRAMEWORK_ZIP" -d temp_frameworks 2>/dev/null; then
      echo "Error: Failed to extract framework"
      rm -f "$FRAMEWORK_ZIP" 2>/dev/null || true
      exit 1
    fi
    
    echo "Copying xcframework files..."
    # 使用更简单的查找和复制方式
    if find temp_frameworks -name "*.xcframework" -type d -print0 | while IFS= read -r -d '' framework; do
      cp -R "$framework" Frameworks/ 2>/dev/null || exit 1
    done; then
      echo "Frameworks copied successfully"
    else
      echo "Error: No xcframework files found or copy failed"
      rm -f "$FRAMEWORK_ZIP" 2>/dev/null || true
      rm -rf temp_frameworks 2>/dev/null || true
      exit 1
    fi
    
    echo "Cleaning up..."
    rm -f "$FRAMEWORK_ZIP" 2>/dev/null || true
    rm -rf temp_frameworks 2>/dev/null || true
    
    echo "Framework preparation completed"
  CMD

  # 使用解压后 Frameworks 目录下的所有 .xcframework
  s.vendored_frameworks = 'Frameworks/*.xcframework'

  # 依赖系统框架
  s.frameworks = [
    'AVFoundation',
    'AudioToolbox',
    'CoreMedia',
    'CoreVideo',
    'VideoToolbox',
    'CoreImage',
    'CoreGraphics',
    'OpenGLES',
    'QuartzCore',
    'CoreAudio',
    'MediaPlayer'
  ]

  # 依赖系统库
  s.libraries = [
    'z',
    'bz2',
    'iconv',
    'c++',
    'xml2'
  ]

  # 弱链接框架（可选）
  s.weak_frameworks = [
    'Metal',
    'MetalKit'
  ]

  # Xcode 编译配置
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'OTHER_LDFLAGS' => '-lc++',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'ENABLE_BITCODE' => 'NO'
  }

  # Swift 版本
  s.swift_version = '5.0'
end