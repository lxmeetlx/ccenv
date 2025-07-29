#!/bin/bash

# ccenv Installation Script
# Purpose: Install ccenv (Claude Code Environment Manager) on macOS and Linux

set -e  # Exit on error

# Colors for output
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="ccenv"
GITHUB_REPO="lxmeetlx/ccenv"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/env-deploy.sh"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "建议不要以 root 用户运行此安装脚本"
        print_info "如果遇到权限问题，脚本会提示您使用 sudo"
    fi
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    else
        print_error "不支持的操作系统: $OSTYPE"
        print_info "ccenv 支持 macOS 和 Linux 系统"
        exit 1
    fi
    print_info "检测到操作系统: $OS"
}

# Function to check dependencies
check_dependencies() {
    print_info "检查依赖项..."
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        print_error "curl 未安装，无法下载脚本"
        if [[ "$OS" == "macOS" ]]; then
            print_info "请安装 Xcode Command Line Tools: xcode-select --install"
        else
            print_info "请安装 curl: sudo apt-get install curl (Ubuntu/Debian) 或 sudo yum install curl (CentOS/RHEL)"
        fi
        exit 1
    fi
    
    # Check jq (optional but recommended)
    if ! command -v jq &> /dev/null; then
        print_warning "jq 未安装，ccenv 的某些功能需要 jq"
        print_info "安装建议:"
        if [[ "$OS" == "macOS" ]]; then
            echo "  macOS: brew install jq"
        else
            echo "  Ubuntu/Debian: sudo apt-get install jq"
            echo "  CentOS/RHEL: sudo yum install jq"
        fi
        echo "  ccenv 运行时会提示您安装 jq（如果需要）"
    else
        print_success "jq 已安装"
    fi
}

# Function to create install directory if needed
prepare_install_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "创建安装目录: $INSTALL_DIR"
        if ! sudo mkdir -p "$INSTALL_DIR" 2>/dev/null; then
            print_error "无法创建安装目录: $INSTALL_DIR"
            print_info "请检查权限或手动创建目录"
            exit 1
        fi
    fi
}

# Function to download and install ccenv
install_ccenv() {
    local temp_file=$(mktemp)
    local install_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    print_info "从 GitHub 下载 ccenv..."
    
    # Download the script
    if ! curl -fsSL "$SCRIPT_URL" -o "$temp_file"; then
        print_error "下载失败: $SCRIPT_URL"
        print_info "请检查网络连接或稍后重试"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Verify the downloaded file
    if [ ! -s "$temp_file" ]; then
        print_error "下载的文件为空"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Check if it's a valid shell script
    if ! head -n 1 "$temp_file" | grep -q "#!/bin/bash"; then
        print_error "下载的文件不是有效的 Bash 脚本"
        rm -f "$temp_file"
        exit 1
    fi
    
    print_success "下载完成"
    
    # Install the script
    print_info "安装 ccenv 到 $install_path..."
    
    # Check if ccenv already exists
    if [ -f "$install_path" ]; then
        print_warning "ccenv 已存在，将被覆盖"
        if ! sudo rm -f "$install_path"; then
            print_error "无法删除现有的 ccenv"
            rm -f "$temp_file"
            exit 1
        fi
    fi
    
    # Copy and set permissions
    if ! sudo cp "$temp_file" "$install_path"; then
        print_error "安装失败: 无法复制文件到 $install_path"
        rm -f "$temp_file"
        exit 1
    fi
    
    if ! sudo chmod +x "$install_path"; then
        print_error "安装失败: 无法设置执行权限"
        rm -f "$temp_file"
        exit 1
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    print_success "ccenv 安装完成!"
}

# Function to verify installation
verify_installation() {
    print_info "验证安装..."
    
    local install_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    # Check if file exists
    if [ ! -f "$install_path" ]; then
        print_error "ccenv 文件不存在: $install_path"
        return 1
    fi
    
    # Check and fix permissions if needed
    if [ ! -x "$install_path" ]; then
        print_warning "检测到权限问题，正在修复..."
        if ! sudo chmod +x "$install_path"; then
            print_error "无法设置执行权限"
            return 1
        fi
        print_success "权限已修复"
    fi
    
    # Check if command is available in PATH
    if ! command -v ccenv &> /dev/null; then
        print_error "ccenv 命令未找到"
        print_info "请确保 $INSTALL_DIR 在您的 PATH 中"
        print_info "或者重新打开终端窗口"
        return 1
    fi
    
    # Test ccenv help command
    if ccenv help &> /dev/null; then
        print_success "ccenv 安装验证成功"
        return 0
    else
        print_warning "ccenv 已安装但可能无法正常工作"
        print_info "请检查文件权限: ls -la $install_path"
        return 1
    fi
}

# Function to show next steps
show_next_steps() {
    echo
    echo -e "${GREEN}🎉 安装完成！${NC}"
    echo
    echo -e "${BLUE}接下来的步骤:${NC}"
    echo "1. 如果这是首次安装，请重新打开终端或运行:"
    echo -e "   ${YELLOW}source ~/.zshrc${NC} (zsh) 或 ${YELLOW}source ~/.bashrc${NC} (bash)"
    echo
    echo "2. 开始使用 ccenv:"
    echo -e "   ${YELLOW}ccenv help${NC}                    # 查看帮助"
    echo -e "   ${YELLOW}ccenv add work sk-ant-api03-xxx${NC}   # 添加配置"
    echo -e "   ${YELLOW}ccenv list${NC}                   # 列出配置"
    echo -e "   ${YELLOW}ccenv switch${NC}                 # 交互式切换"
    echo
    echo "3. 如果遇到问题，请查看:"
    echo -e "   GitHub: ${BLUE}https://github.com/${GITHUB_REPO}${NC}"
    echo
}

# Function to handle installation errors
handle_error() {
    print_error "安装过程中出现错误"
    echo
    echo "常见解决方案:"
    echo "1. 检查网络连接"
    echo "2. 确保有足够的权限（可能需要 sudo）"
    echo "3. 检查磁盘空间"
    echo "4. 手动安装:"
    echo "   curl -fsSL $SCRIPT_URL -o ccenv"
    echo "   chmod +x ccenv"
    echo "   sudo mv ccenv $INSTALL_DIR/"
    echo
    echo "如果问题持续存在，请在 GitHub 上报告问题:"
    echo "https://github.com/${GITHUB_REPO}/issues"
}

# Main installation function
main() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                          ║${NC}"
    echo -e "${BLUE}║                    ccenv 安装程序                       ║${NC}"
    echo -e "${BLUE}║              Claude Code 环境管理工具                    ║${NC}"
    echo -e "${BLUE}║                                                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Trap errors
    trap handle_error ERR
    
    # Run installation steps
    check_root
    detect_os
    check_dependencies
    prepare_install_dir
    install_ccenv
    
    # Verify installation
    if verify_installation; then
        show_next_steps
    else
        print_warning "安装可能不完整，请检查错误信息"
        echo
        echo "手动验证安装:"
        echo "  which ccenv"
        echo "  ccenv help"
    fi
}

# Run main function
main "$@"

# Exit successfully
exit 0