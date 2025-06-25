#!/bin/bash
# enhanced_cleanup_ffmpeg_frameworks.sh
# 增强版 FFmpeg Kit Flutter 插件 frameworks 符号链接清理脚本
# 
# 使用方法:
# chmod +x enhanced_cleanup_ffmpeg_frameworks.sh
# ./enhanced_cleanup_ffmpeg_frameworks.sh
#
# 功能:
# 1. 递归清理所有 .framework 目录中的符号链接
# 2. 处理嵌套的符号链接和 Versions 目录结构
# 3. 验证清理结果并提供详细报告
# 4. 支持强制清理模式

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局计数器
TOTAL_SYMLINKS_FOUND=0
TOTAL_SYMLINKS_PROCESSED=0
TOTAL_SYMLINKS_FAILED=0

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo -e "${CYAN}🔍 DEBUG: $1${NC}"
    fi
}

log_progress() {
    echo -e "${MAGENTA}⏳ $1${NC}"
}

# 检查是否是 macOS 系统
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_warning "此脚本在 macOS 上运行效果最佳"
        log_info "其他系统可能需要手动处理某些符号链接"
    fi
}

# 安全地解析符号链接目标
resolve_symlink_target() {
    local symlink_path="$1"
    local base_dir="$2"
    
    if [ ! -L "$symlink_path" ]; then
        return 1
    fi
    
    local target=$(readlink "$symlink_path")
    local resolved_target=""
    
    # 如果是相对路径，转换为绝对路径
    if [[ "$target" != /* ]]; then
        resolved_target="$base_dir/$target"
    else
        resolved_target="$target"
    fi
    
    # 规范化路径
    resolved_target=$(cd "$(dirname "$resolved_target")" 2>/dev/null && pwd)/$(basename "$resolved_target") 2>/dev/null || echo "$target"
    
    echo "$resolved_target"
}

# 递归处理符号链接
process_symlink_recursive() {
    local symlink_path="$1"
    local max_depth="${2:-10}"
    
    if [ $max_depth -le 0 ]; then
        log_error "符号链接递归深度超限: $symlink_path"
        return 1
    fi
    
    if [ ! -L "$symlink_path" ]; then
        log_debug "$symlink_path 不是符号链接"
        return 0
    fi
    
    local symlink_dir=$(dirname "$symlink_path")
    local symlink_name=$(basename "$symlink_path")
    local target=$(resolve_symlink_target "$symlink_path" "$symlink_dir")
    
    log_debug "处理符号链接: $symlink_name -> $target"
    
    # 记录符号链接信息
    echo "$symlink_name -> $target" >> "$symlink_dir/.symlink_backup.txt"
    
    # 删除符号链接
    rm "$symlink_path"
    
    # 查找实际目标
    local actual_target=""
    
    # 尝试多种可能的目标位置
    local possible_targets=(
        "$target"
        "$symlink_dir/$target"
        "$symlink_dir/Versions/A/$symlink_name"
        "$symlink_dir/Versions/Current/$symlink_name"
        "$symlink_dir/../$target"
    )
    
    for possible_target in "${possible_targets[@]}"; do
        if [ -e "$possible_target" ]; then
            actual_target="$possible_target"
            break
        fi
    done
    
    if [ -n "$actual_target" ]; then
        # 如果目标本身也是符号链接，先递归处理它
        if [ -L "$actual_target" ]; then
            log_debug "目标也是符号链接，递归处理: $actual_target"
            if ! process_symlink_recursive "$actual_target" $((max_depth - 1)); then
                log_error "递归处理目标符号链接失败: $actual_target"
                return 1
            fi
        fi
        
        # 复制实际文件/目录
        if cp -R "$actual_target" "$symlink_path" 2>/dev/null; then
            log_debug "成功复制: $actual_target -> $symlink_path"
            ((TOTAL_SYMLINKS_PROCESSED++))
            return 0
        else
            log_error "复制失败: $actual_target -> $symlink_path"
            # 尝试恢复符号链接
            ln -s "$target" "$symlink_path" 2>/dev/null || true
            ((TOTAL_SYMLINKS_FAILED++))
            return 1
        fi
    else
        log_error "找不到符号链接的实际目标: $symlink_path -> $target"
        # 尝试恢复符号链接
        ln -s "$target" "$symlink_path" 2>/dev/null || true
        ((TOTAL_SYMLINKS_FAILED++))
        return 1
    fi
}

# 深度清理单个 framework
deep_cleanup_framework() {
    local framework_path="$1"
    local force_mode="${2:-false}"
    
    if [ ! -d "$framework_path" ]; then
        log_warning "Framework 不存在: $framework_path"
        return 1
    fi
    
    local framework_name=$(basename "$framework_path")
    log_info "🔧 深度处理: $framework_name"
    
    # 进入 framework 目录
    cd "$framework_path"
    
    # 清理之前的备份文件
    rm -f .symlink_backup.txt
    
    local framework_symlinks=0
    
    # 使用 find 递归查找所有符号链接
    while IFS= read -r -d '' symlink; do
        ((TOTAL_SYMLINKS_FOUND++))
        ((framework_symlinks++))
        
        local relative_path=${symlink#$framework_path/}
        log_progress "   处理符号链接 [$framework_symlinks]: $relative_path"
        
        if process_symlink_recursive "$symlink"; then
            log_debug "   ✓ 成功处理: $relative_path"
        else
            log_warning "   ✗ 处理失败: $relative_path"
            if [ "$force_mode" = "true" ]; then
                log_info "   强制模式: 删除失败的符号链接"
                rm -f "$symlink"
            fi
        fi
    done < <(find . -type l -print0 2>/dev/null)
    
    # 返回原目录
    cd - > /dev/null
    
    if [ $framework_symlinks -gt 0 ]; then
        log_success "完成: $framework_name (发现 $framework_symlinks 个符号链接)"
    else
        log_info "完成: $framework_name (没有发现符号链接)"
    fi
    
    return 0
}

# 使用 rsync 清理（推荐方法，如果可用）
cleanup_with_rsync() {
    local framework_path="$1"
    
    if [ ! -d "$framework_path" ] || ! command -v rsync >/dev/null 2>&1; then
        return 1
    fi
    
    local framework_name=$(basename "$framework_path")
    local temp_path="${framework_path}_rsync_temp"
    
    log_info "🔧 使用 rsync 处理: $framework_name"
    
    # 使用 rsync 复制，解析符号链接
    if rsync -avL --delete "$framework_path/" "$temp_path/" 2>/dev/null; then
        # 替换原 framework
        rm -rf "$framework_path"
        mv "$temp_path" "$framework_path"
        log_success "完成: $framework_name (使用 rsync)"
        return 0
    else
        log_warning "rsync 处理失败，回退到深度清理方法: $framework_name"
        rm -rf "$temp_path" 2>/dev/null || true
        return 1
    fi
}

# 清理目录下所有 frameworks
cleanup_frameworks_in_directory() {
    local base_dir="$1"
    local method="$2"  # "rsync", "deep", 或 "force"
    
    if [ ! -d "$base_dir" ]; then
        log_warning "目录不存在: $base_dir"
        return
    fi
    
    log_info "📁 处理目录: $base_dir"
    
    local frameworks=()
    while IFS= read -r -d '' framework; do
        frameworks+=("$framework")
    done < <(find "$base_dir" -name "*.framework" -type d -print0)
    
    local total_frameworks=${#frameworks[@]}
    
    if [ $total_frameworks -eq 0 ]; then
        log_warning "在 $base_dir 中没有找到 .framework 目录"
        return
    fi
    
    log_info "找到 $total_frameworks 个 frameworks"
    
    local processed_frameworks=0
    
    # 处理每个 framework
    for framework in "${frameworks[@]}"; do
        local framework_name=$(basename "$framework")
        echo ""
        log_info "[$((processed_frameworks + 1))/$total_frameworks] 处理: $framework_name"
        
        local success=false
        
        if [ "$method" = "rsync" ] && command -v rsync >/dev/null 2>&1; then
            if cleanup_with_rsync "$framework"; then
                success=true
            fi
        fi
        
        if [ "$success" = false ]; then
            local force_mode=false
            if [ "$method" = "force" ]; then
                force_mode=true
            fi
            
            if deep_cleanup_framework "$framework" "$force_mode"; then
                success=true
            fi
        fi
        
        if [ "$success" = true ]; then
            ((processed_frameworks++))
        fi
    done
    
    echo ""
    log_success "目录 $base_dir 处理完成: $processed_frameworks/$total_frameworks"
}

# 详细验证清理结果
detailed_verify_cleanup() {
    log_info "🔍 详细验证清理结果..."
    
    local directories=()
    
    # 检查 iOS
    if [ -d "ios/Frameworks" ]; then
        directories+=("ios/Frameworks")
    fi
    
    # 检查 macOS
    if [ -d "macos/Frameworks" ]; then
        directories+=("macos/Frameworks")
    fi
    
    local total_remaining_symlinks=0
    
    for dir in "${directories[@]}"; do
        log_info "检查目录: $dir"
        
        local symlinks=()
        while IFS= read -r -d '' symlink; do
            symlinks+=("$symlink")
        done < <(find "$dir" -type l -print0 2>/dev/null)
        
        local dir_symlinks=${#symlinks[@]}
        total_remaining_symlinks=$((total_remaining_symlinks + dir_symlinks))
        
        if [ $dir_symlinks -gt 0 ]; then
            log_warning "在 $dir 中发现 $dir_symlinks 个剩余符号链接:"
            for symlink in "${symlinks[@]}"; do
                local target=$(readlink "$symlink" 2>/dev/null || echo "无法读取")
                local relative_path=${symlink#$dir/}
                echo "    🔗 $relative_path -> $target"
            done
        else
            log_success "$dir 中没有剩余符号链接"
        fi
    done
    
    echo ""
    if [ $total_remaining_symlinks -eq 0 ]; then
        log_success "🎉 所有符号链接已成功清理!"
    else
        log_warning "发现 $total_remaining_symlinks 个剩余符号链接"
        echo ""
        echo "建议操作:"
        echo "1. 运行强制清理模式: $0 --force"
        echo "2. 手动检查剩余的符号链接"
        echo "3. 使用 rsync 方法: $0 --rsync"
    fi
    
    # 显示统计信息
    echo ""
    log_info "📊 处理统计:"
    echo "  总发现符号链接: $TOTAL_SYMLINKS_FOUND"
    echo "  成功处理: $TOTAL_SYMLINKS_PROCESSED"
    echo "  处理失败: $TOTAL_SYMLINKS_FAILED"
    echo "  剩余未处理: $total_remaining_symlinks"
}

# 显示使用帮助
show_help() {
    echo "FFmpeg Kit Flutter 插件 Frameworks 增强清理工具"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h          显示此帮助信息"
    echo "  --debug             启用调试输出"
    echo "  --force             强制清理模式（删除无法处理的符号链接）"
    echo "  --rsync             优先使用 rsync 方法"
    echo "  --deep              使用深度清理方法（默认）"
    echo "  --verify-only       仅验证，不进行清理"
    echo ""
    echo "示例:"
    echo "  $0                  # 标准清理"
    echo "  $0 --force          # 强制清理"
    echo "  $0 --rsync          # 使用 rsync 方法"
    echo "  $0 --debug --force  # 调试模式 + 强制清理"
    echo ""
}

# 主函数
main() {
    local cleanup_method="deep"
    local verify_only=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --debug)
                export DEBUG=1
                ;;
            --force)
                cleanup_method="force"
                ;;
            --rsync)
                cleanup_method="rsync"
                ;;
            --deep)
                cleanup_method="deep"
                ;;
            --verify-only)
                verify_only=true
                ;;
            *)
                log_error "未知选项: $1"
                echo "使用 --help 查看帮助信息"
                exit 1
                ;;
        esac
        shift
    done
    
    echo "🚀 FFmpeg Kit Flutter 插件 Frameworks 增强清理工具"
    echo "================================================"
    echo ""
    
    # 检查系统
    check_macos
    
    # 检查当前目录是否是 Flutter 插件根目录
    if [ ! -f "pubspec.yaml" ]; then
        log_error "请在 Flutter 插件根目录运行此脚本"
        exit 1
    fi
    
    if [ "$verify_only" = true ]; then
        detailed_verify_cleanup
        exit 0
    fi
    
    # 显示清理方法
    case $cleanup_method in
        rsync)
            log_info "使用清理方法: rsync (推荐，如果可用)"
            ;;
        force)
            log_warning "使用清理方法: 强制清理 (删除无法处理的符号链接)"
            ;;
        deep)
            log_info "使用清理方法: 深度清理 (递归处理所有符号链接)"
            ;;
    esac
    
    echo ""
    log_info "开始清理 FFmpeg Kit frameworks..."
    
    # 处理 iOS frameworks
    if [ -d "ios/Frameworks" ]; then
        echo ""
        log_info "📱 处理 iOS frameworks..."
        cleanup_frameworks_in_directory "ios/Frameworks" "$cleanup_method"
    else
        log_warning "未找到 ios/Frameworks 目录"
    fi
    
    # 处理 macOS frameworks
    if [ -d "macos/Frameworks" ]; then
        echo ""
        log_info "💻 处理 macOS frameworks..."
        cleanup_frameworks_in_directory "macos/Frameworks" "$cleanup_method"
    else
        log_warning "未找到 macos/Frameworks 目录"
    fi
    
    echo ""
    
    # 详细验证结果
    detailed_verify_cleanup
    
    echo ""
    log_success "🎉 清理完成!"
    
    if [ $TOTAL_SYMLINKS_FOUND -gt 0 ]; then
        echo ""
        echo "💡 提示:"
        echo "- 符号链接信息已保存到各 framework 的 .symlink_backup.txt 文件中"
        echo "- 如果仍有剩余符号链接，可以尝试 --force 或 --rsync 选项"
        echo "- 使用 --verify-only 可以仅验证清理结果"
    fi
}

# 清理函数（如果脚本被中断）
cleanup_on_exit() {
    log_info "清理临时文件..."
    find . -name "*_rsync_temp" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*_ditto_temp" -type d -exec rm -rf {} + 2>/dev/null || true
}

# 设置退出时清理
trap cleanup_on_exit EXIT

# 运行主函数
main "$@"