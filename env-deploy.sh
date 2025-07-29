#!/bin/bash

# Claude Code Environment Setup Script
# Purpose: Automatically configure environment variables for Claude Code on macOS and Linux

set -e  # Exit on error

# Colors for output
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file path
CONFIG_STORE="$HOME/.claude_configs.json"

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

# Function to display current environment variables
display_current_env() {
    print_info "当前环境变量状态："
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Get current shell type for proper variable display
    CURRENT_SHELL=$(basename "$SHELL")
    
    if [[ "$CURRENT_SHELL" == "fish" ]]; then
        # Fish shell syntax
        echo "ANTHROPIC_BASE_URL=$(set -q ANTHROPIC_BASE_URL && echo $ANTHROPIC_BASE_URL || echo '(未设置)')"
        echo "ANTHROPIC_API_KEY=$(set -q ANTHROPIC_API_KEY && echo '****'${ANTHROPIC_API_KEY: -4} || echo '(未设置)')"
        echo "ANTHROPIC_AUTH_TOKEN=$(set -q ANTHROPIC_AUTH_TOKEN && echo $ANTHROPIC_AUTH_TOKEN || echo '(未设置)')"
    else
        # Bash/Zsh syntax
        if [ -n "$ANTHROPIC_BASE_URL" ]; then
            echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
        else
            echo "ANTHROPIC_BASE_URL=(未设置)"
        fi
        
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            echo "ANTHROPIC_API_KEY=****${ANTHROPIC_API_KEY: -4}"
        else
            echo "ANTHROPIC_API_KEY=(未设置)"
        fi
        
        if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
            echo "ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN"
        else
            echo "ANTHROPIC_AUTH_TOKEN=(未设置)"
        fi
    fi
    
    echo -e "${BLUE}----------------------------------------${NC}"
}

# Function to check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_error "需要安装 jq 工具"
        if [[ "$OS" == "macOS" ]]; then
            print_info "请运行: brew install jq"
        else
            print_info "请运行: sudo apt-get install jq (Ubuntu/Debian) 或 sudo yum install jq (CentOS/RHEL)"
        fi
        exit 1
    fi
}

# Function to initialize config store if not exists
init_config_store() {
    if [ ! -f "$CONFIG_STORE" ]; then
        echo '{"configs":{},"active":null}' > "$CONFIG_STORE"
        print_info "初始化配置存储文件: $CONFIG_STORE"
    fi
}

# Function to add a new configuration
add_config() {
    local config_name="$1"
    local api_key="$2"
    local base_url="$3"
    
    if [ -z "$config_name" ] || [ -z "$api_key" ]; then
        print_error "缺少参数: 配置名称和API密钥都是必需的"
        echo "使用方法: $0 add <config-name> <api-key> [base-url]"
        exit 1
    fi
    
    check_jq
    init_config_store
    
    # Check if config name already exists
    if jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
        print_warning "配置 '$config_name' 已存在，将被覆盖"
    fi
    
    # Use default base URL if not provided
    if [ -z "$base_url" ]; then
        base_url="https://api.anthropic.com"
        print_info "使用默认的 Base URL: $base_url"
    else
        print_info "使用自定义 Base URL: $base_url"
    fi
    
    # Add the config
    jq --arg name "$config_name" --arg key "$api_key" --arg url "$base_url" \
       '.configs[$name] = {"api_key": $key, "base_url": $url}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    print_success "已添加配置: $config_name"
    
    # If this is the first config, set it as active
    if [ "$(jq -r '.active' "$CONFIG_STORE")" == "null" ]; then
        jq --arg name "$config_name" '.active = $name' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
        print_info "已将 '$config_name' 设置为活动配置"
    fi
}

# Function to list all configurations
list_configs() {
    check_jq
    init_config_store
    
    local active_config=$(jq -r '.active' "$CONFIG_STORE")
    
    print_info "已保存的配置:"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    if [ "$(jq -r '.configs | length' "$CONFIG_STORE")" -eq 0 ]; then
        echo "没有保存的配置"
    else
        jq -r '.configs | keys[]' "$CONFIG_STORE" | while read -r config_name; do
            local api_key=$(jq -r ".configs.\"$config_name\".api_key" "$CONFIG_STORE")
            local base_url=$(jq -r ".configs.\"$config_name\".base_url" "$CONFIG_STORE")
            
            if [ "$config_name" == "$active_config" ]; then
                echo -e "* ${GREEN}$config_name${NC} (API密钥: ****${api_key: -4})"
                echo -e "  Base URL: $base_url"
            else
                echo -e "  $config_name (API密钥: ****${api_key: -4})"
                echo -e "  Base URL: $base_url"
            fi
            echo
        done
    fi
    
    echo -e "${BLUE}----------------------------------------${NC}"
    
    if [ "$active_config" != "null" ]; then
        print_info "当前活动配置: $active_config"
    else
        print_warning "当前没有活动配置"
    fi
}

# Function to use a specific configuration
use_config() {
    local config_name="$1"
    
    if [ -z "$config_name" ]; then
        print_error "缺少参数: 配置名称是必需的"
        echo "使用方法: $0 use <config-name>"
        exit 1
    fi
    
    check_jq
    init_config_store
    
    # Check if config exists
    if ! jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
        print_error "配置 '$config_name' 不存在"
        echo "运行 '$0 list' 查看所有配置"
        exit 1
    fi
    
    # Set as active config
    jq --arg name "$config_name" '.active = $name' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    # Get API key and base URL
    ANTHROPIC_API_KEY=$(jq -r ".configs.\"$config_name\".api_key" "$CONFIG_STORE")
    ANTHROPIC_BASE_URL=$(jq -r ".configs.\"$config_name\".base_url" "$CONFIG_STORE")
    
    print_success "已切换到配置: $config_name"
    
    # Apply the configuration
    detect_os_and_shell
    add_env_vars
    update_claude_json
    activate_config
    verify_config
    
    print_success "已应用配置 '$config_name'"
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}║    请关闭终端后重新打开，开始 claude code 使用～        ║${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
}

# Function to update a configuration
update_config() {
    local config_name=""
    local new_api_key=""
    local new_base_url=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --api-key)
                new_api_key="$2"
                shift 2
                ;;
            --base-url)
                new_base_url="$2"
                shift 2
                ;;
            *)
                if [ -z "$config_name" ]; then
                    config_name="$1"
                    shift
                else
                    print_error "未知参数: $1"
                    echo "使用方法: $0 update <config-name> [--api-key <new-api-key>] [--base-url <new-base-url>]"
                    exit 1
                fi
                ;;
        esac
    done
    
    # Validate parameters
    if [ -z "$config_name" ]; then
        print_error "缺少参数: 配置名称是必需的"
        echo "使用方法: $0 update <config-name> [--api-key <new-api-key>] [--base-url <new-base-url>]"
        exit 1
    fi
    
    if [ -z "$new_api_key" ] && [ -z "$new_base_url" ]; then
        print_error "至少需要指定一个更新参数: --api-key 或 --base-url"
        echo "使用方法: $0 update <config-name> [--api-key <new-api-key>] [--base-url <new-base-url>]"
        exit 1
    fi
    
    check_jq
    init_config_store
    
    # Check if config exists
    if ! jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
        print_error "配置 '$config_name' 不存在"
        echo "运行 '$0 list' 查看所有配置"
        exit 1
    fi
    
    # Get current config values
    current_api_key=$(jq -r ".configs.\"$config_name\".api_key" "$CONFIG_STORE")
    current_base_url=$(jq -r ".configs.\"$config_name\".base_url" "$CONFIG_STORE")
    
    # Use current values if not specified
    update_api_key="${new_api_key:-$current_api_key}"
    update_base_url="${new_base_url:-$current_base_url}"
    
    # Display what will be updated
    print_info "正在更新配置 '$config_name':"
    echo -e "${BLUE}----------------------------------------${NC}"
    if [ -n "$new_api_key" ]; then
        echo "API密钥: ****${current_api_key: -4} → ****${new_api_key: -4}"
    else
        echo "API密钥: ****${current_api_key: -4} (不变)"
    fi
    
    if [ -n "$new_base_url" ]; then
        echo "Base URL: $current_base_url → $new_base_url"
    else
        echo "Base URL: $current_base_url (不变)"
    fi
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Update the config
    jq --arg name "$config_name" --arg key "$update_api_key" --arg url "$update_base_url" \
       '.configs[$name] = {"api_key": $key, "base_url": $url}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    print_success "配置 '$config_name' 已更新"
    
    # If this is the active config, apply the changes
    active_config=$(jq -r '.active' "$CONFIG_STORE")
    if [ "$active_config" == "$config_name" ]; then
        print_info "检测到正在更新当前活动配置，正在应用更改..."
        
        # Set the updated values
        ANTHROPIC_API_KEY="$update_api_key"
        ANTHROPIC_BASE_URL="$update_base_url"
        
        # Apply the configuration
        detect_os_and_shell
        add_env_vars
        update_claude_json
        activate_config
        verify_config
        
        print_success "已应用更新后的配置 '$config_name'"
        echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                          ║${NC}"
        echo -e "${RED}║    请关闭终端后重新打开，开始 claude code 使用～        ║${NC}"
        echo -e "${RED}║                                                          ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    else
        print_info "配置已更新，但未应用（不是当前活动配置）"
        print_info "运行 '$0 use $config_name' 来应用此配置"
    fi
}

# Function to remove a configuration
remove_config() {
    local config_name="$1"
    
    if [ -z "$config_name" ]; then
        print_error "缺少参数: 配置名称是必需的"
        echo "使用方法: $0 remove <config-name>"
        exit 1
    fi
    
    check_jq
    init_config_store
    
    # Check if config exists
    if ! jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
        print_error "配置 '$config_name' 不存在"
        exit 1
    fi
    
    # Check if it's the active config
    active_config=$(jq -r '.active' "$CONFIG_STORE")
    if [ "$active_config" == "$config_name" ]; then
        print_warning "正在删除当前活动配置"
        jq '.active = null' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    fi
    
    # Remove the config
    jq --arg name "$config_name" 'del(.configs[$name])' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    print_success "已删除配置: $config_name"
    
    # If there are other configs, set the first one as active
    if [ "$(jq -r '.active' "$CONFIG_STORE")" == "null" ] && [ "$(jq -r '.configs | length' "$CONFIG_STORE")" -gt 0 ]; then
        new_active=$(jq -r '.configs | keys[0]' "$CONFIG_STORE")
        jq --arg name "$new_active" '.active = $name' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
        print_info "已将 '$new_active' 设置为活动配置"
    fi
}

# Function to switch configuration interactively
switch_config() {
    check_jq
    init_config_store
    
    # Check if there are any configs
    if [ "$(jq -r '.configs | length' "$CONFIG_STORE")" -eq 0 ]; then
        print_error "没有保存的配置"
        return 1
    fi
    
    # Get all config names and active config
    local configs=($(jq -r '.configs | keys[]' "$CONFIG_STORE"))
    local active_config=$(jq -r '.active' "$CONFIG_STORE")
    local count=${#configs[@]}
    local selected=0
    
    # Find the index of the currently active config
    for i in "${!configs[@]}"; do
        if [ "${configs[$i]}" == "$active_config" ]; then
            selected=$i
            break
        fi
    done
    
    # Function to display the menu
    display_menu() {
        clear
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}     选择要使用的 Claude Code 配置      ${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo
        echo -e "${YELLOW}使用 ↑/↓ 方向键选择，回车确认，ESC 退出${NC}"
        echo
        
        for i in "${!configs[@]}"; do
            local name=${configs[$i]}
            local api_key=$(jq -r ".configs.\"$name\".api_key" "$CONFIG_STORE")
            local base_url=$(jq -r ".configs.\"$name\".base_url" "$CONFIG_STORE")
            
            # Highlight selected item
            if [ "$i" -eq "$selected" ]; then
                echo -e "${GREEN}→ $name${NC}"
                if [ "$name" == "$active_config" ]; then
                    echo -e "   ${GREEN}[当前活动配置]${NC}"
                fi
            else
                echo -e "  $name"
                if [ "$name" == "$active_config" ]; then
                    echo -e "   ${BLUE}[当前活动配置]${NC}"
                fi
            fi
            echo "   API密钥: ****${api_key: -4}"
            echo "   Base URL: $base_url"
            echo
        done
    }
    
    # Initial display
    display_menu
    
    # Read arrow keys and handle selection
    while true; do
        # Read single character without requiring Enter
        read -rsn1 key
        
        case "$key" in
            $'\x1b')  # ESC sequence
                read -rsn2 key
                case "$key" in
                    '[A') # Up arrow
                        if [ "$selected" -gt 0 ]; then
                            selected=$((selected - 1))
                        else
                            selected=$((count - 1))  # Wrap to bottom
                        fi
                        display_menu
                        ;;
                    '[B') # Down arrow
                        if [ "$selected" -lt $((count - 1)) ]; then
                            selected=$((selected + 1))
                        else
                            selected=0  # Wrap to top
                        fi
                        display_menu
                        ;;
                esac
                ;;
            '') # Enter key
                local selected_name=${configs[$selected]}
                clear
                echo -e "${GREEN}选择了配置: $selected_name${NC}"
                use_config "$selected_name"
                return 0
                ;;
            'q'|'Q') # Q to quit
                clear
                echo "已取消选择"
                return 0
                ;;
            $'\x1b') # ESC key alone
                clear
                echo "已取消选择"
                return 0
                ;;
        esac
    done
}

# Detect OS and shell
detect_os_and_shell() {
    print_info "检测操作系统和Shell环境..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    
    # Detect Shell
    CURRENT_SHELL=$(basename "$SHELL")
    
    # Determine config file based on shell
    case "$CURRENT_SHELL" in
        bash)
            if [[ "$OS" == "macOS" ]]; then
                CONFIG_FILE="$HOME/.bash_profile"
            else
                CONFIG_FILE="$HOME/.bashrc"
            fi
            ;;
        zsh)
            CONFIG_FILE="$HOME/.zshrc"
            ;;
        fish)
            CONFIG_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            print_error "不支持的Shell: $CURRENT_SHELL"
            exit 1
            ;;
    esac
    
    print_success "检测完成 - 系统: $OS, Shell: $CURRENT_SHELL"
    print_info "配置文件: $CONFIG_FILE"
}

# Function to add environment variables to config file
add_env_vars() {
    print_info "开始配置环境变量..."
    
    # Create backup
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "已备份原配置文件"
    fi
    
    # Check if variables already exist
    if grep -q "ANTHROPIC_BASE_URL" "$CONFIG_FILE" 2>/dev/null || grep -q "ANTHROPIC_API_KEY" "$CONFIG_FILE" 2>/dev/null; then
        print_warning "检测到已存在的Claude Code环境变量配置"
        print_info "正在清理所有现有配置..."
        
        # Remove ALL existing ANTHROPIC environment variable configurations
        # For bash/zsh: export VARIABLE=...
        # For fish: set -x VARIABLE ...
        if [[ "$CURRENT_SHELL" == "fish" ]]; then
            # Fish shell: remove 'set -x VARIABLE ...' patterns
            # Using -E for extended regex on macOS/BSD sed
            sed -i.tmp -E '/^[[:space:]]*set[[:space:]]+-x[[:space:]]+ANTHROPIC_BASE_URL/d' "$CONFIG_FILE" 2>/dev/null || true
            sed -i.tmp -E '/^[[:space:]]*set[[:space:]]+-x[[:space:]]+ANTHROPIC_API_KEY/d' "$CONFIG_FILE" 2>/dev/null || true
            sed -i.tmp -E '/^[[:space:]]*set[[:space:]]+-x[[:space:]]+ANTHROPIC_AUTH_TOKEN/d' "$CONFIG_FILE" 2>/dev/null || true
        else
            # Bash/Zsh: remove 'export VARIABLE=...' patterns
            # Using -E for extended regex on macOS/BSD sed
            sed -i.tmp -E '/^[[:space:]]*export[[:space:]]+ANTHROPIC_BASE_URL=/d' "$CONFIG_FILE" 2>/dev/null || true
            sed -i.tmp -E '/^[[:space:]]*export[[:space:]]+ANTHROPIC_API_KEY=/d' "$CONFIG_FILE" 2>/dev/null || true
            sed -i.tmp -E '/^[[:space:]]*export[[:space:]]+ANTHROPIC_AUTH_TOKEN=/d' "$CONFIG_FILE" 2>/dev/null || true
        fi
        
        # Also remove the marked sections for backward compatibility
        sed -i.tmp '/# Claude Code Environment Variables/,/# End Claude Code Environment Variables/d' "$CONFIG_FILE" 2>/dev/null || true
        
        # Clean up temporary files
        rm -f "$CONFIG_FILE.tmp"
        
        print_success "已彻底清理所有旧配置，准备写入新配置"
    fi
    
    # Add environment variables based on shell type
    if [[ "$CURRENT_SHELL" == "fish" ]]; then
        cat >> "$CONFIG_FILE" << EOF

# Claude Code Environment Variables
set -x ANTHROPIC_BASE_URL "$ANTHROPIC_BASE_URL"
set -x ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
set -x ANTHROPIC_AUTH_TOKEN ""
# End Claude Code Environment Variables
EOF
    else
        cat >> "$CONFIG_FILE" << EOF

# Claude Code Environment Variables
export ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export ANTHROPIC_AUTH_TOKEN=""
# End Claude Code Environment Variables
EOF
    fi
    
    print_success "环境变量已写入配置文件"
}

# Function to update .claude.json
update_claude_json() {
    print_info "更新 ~/.claude.json 配置..."
    
    check_jq
    
    # Execute the jq command
    print_info "添加API密钥到Claude配置..."
    
    # Get the last 20 characters of the API key
    KEY_SUFFIX="${ANTHROPIC_API_KEY: -20}"
    
    # Create .claude.json if it doesn't exist
    if [ ! -f "$HOME/.claude.json" ]; then
        echo '{}' > "$HOME/.claude.json"
        print_info "创建新的 ~/.claude.json 文件"
    fi
    
    # Update the JSON file
    if (cat ~/.claude.json 2>/dev/null || echo 'null') | jq --arg key "$KEY_SUFFIX" '(. // {}) | .customApiKeyResponses.approved |= ([.[]?, $key] | unique)' > ~/.claude.json.tmp; then
        mv ~/.claude.json.tmp ~/.claude.json
        print_success "Claude配置已更新"
        
        # Display the updated customApiKeyResponses
        print_info "更新后的 customApiKeyResponses 内容:"
        echo -e "${BLUE}----------------------------------------${NC}"
        jq '.customApiKeyResponses' ~/.claude.json 2>/dev/null || echo "{}"
        echo -e "${BLUE}----------------------------------------${NC}"
    else
        print_error "更新Claude配置失败"
        rm -f ~/.claude.json.tmp
        return 1
    fi
}

# Function to source the config file
activate_config() {
    print_info "激活配置..."
    
    # Export variables for current session
    export ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL"
    export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
    export ANTHROPIC_AUTH_TOKEN=""
    
    print_success "环境变量已在当前会话中激活"
    print_info "要在新的终端会话中使用，请运行以下命令："
    
    if [[ "$CURRENT_SHELL" == "fish" ]]; then
        echo -e "${GREEN}source $CONFIG_FILE${NC}"
    else
        echo -e "${GREEN}source $CONFIG_FILE${NC}"
    fi
    
    print_info "或者重新打开终端窗口"
}

# Function to verify configuration
verify_config() {
    print_info "验证配置..."
    
    # Check if variables are set
    if [ -n "$ANTHROPIC_BASE_URL" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
        print_success "环境变量验证成功"
        echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
        echo "ANTHROPIC_API_KEY: ****${ANTHROPIC_API_KEY: -4}"
        echo "ANTHROPIC_AUTH_TOKEN: ${ANTHROPIC_AUTH_TOKEN:-\"\"}"
    else
        print_error "环境变量验证失败"
        return 1
    fi
    
    # Check .claude.json
    if [ -f "$HOME/.claude.json" ]; then
        if jq -e '.customApiKeyResponses.approved' "$HOME/.claude.json" &>/dev/null; then
            print_success "Claude配置文件验证成功"
        else
            print_warning "Claude配置文件存在但可能不完整"
        fi
    else
        print_error "Claude配置文件不存在"
    fi
}

# Function to import current environment variables
import_current_config() {
    print_info "读取当前环境变量..."
    
    # Check if environment variables are set
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        print_error "当前环境中没有设置 ANTHROPIC_API_KEY 变量"
        return 1
    fi
    
    # Display current values
    echo -e "${BLUE}----------------------------------------${NC}"
    echo "检测到以下环境变量:"
    echo "ANTHROPIC_API_KEY: ****${ANTHROPIC_API_KEY: -4}"
    
    if [ -n "$ANTHROPIC_BASE_URL" ]; then
        echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
    else
        ANTHROPIC_BASE_URL="https://api.anthropic.com"
        echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL (默认值)"
    fi
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Ask if user wants to save as a new config
    print_info "是否要将当前环境变量保存为新配置? (y/n)"
    read -r save_config
    
    if [[ "$save_config" =~ ^[Yy]$ ]]; then
        print_info "请输入配置名称:"
        read -r config_name
        
        if [ -z "$config_name" ]; then
            print_error "配置名称不能为空"
            return 1
        fi
        
        # Save the config
        check_jq
        init_config_store
        
        # Check if config name already exists
        if jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
            print_warning "配置 '$config_name' 已存在，将被覆盖"
        fi
        
        # Add the config
        jq --arg name "$config_name" --arg key "$ANTHROPIC_API_KEY" --arg url "$ANTHROPIC_BASE_URL" \
           '.configs[$name] = {"api_key": $key, "base_url": $url}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
        
        print_success "已添加配置: $config_name"
        
        # If this is the first config, set it as active
        if [ "$(jq -r '.active' "$CONFIG_STORE")" == "null" ]; then
            jq --arg name "$config_name" '.active = $name' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
            mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
            print_info "已将 '$config_name' 设置为活动配置"
        fi
    else
        print_info "未保存配置"
    fi
    
    return 0
}

# Show help information
show_help() {
    echo "用法: $0 <命令> [参数...]"
    echo
    echo "命令:"
    echo "  add <name> <api-key> [base-url]                       添加或更新一个配置"
    echo "  list                                                  列出所有配置"
    echo "  use <name>                                            切换到指定配置"
    echo "  switch                                                交互式选择并切换配置"
    echo "  update <name> [--api-key <key>] [--base-url <url>]    更新指定配置的密钥或URL"
    echo "  remove <name>                                         删除一个配置"
    echo "  import                                                读取当前环境变量并可选择保存为配置"
    echo "  help                                                  显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 add work sk-ant-api03-abcd1234                             # 添加一个名为'work'的配置，使用默认URL"
    echo "  $0 add dev sk-ant-api03-abcd1234 https://dev-api.example.com  # 添加使用自定义URL的配置"
    echo "  $0 list                                                       # 列出所有配置"
    echo "  $0 use work                                                   # 切换到'work'配置"
    echo "  $0 switch                                                     # 交互式选择并切换配置"
    echo "  $0 update work --api-key sk-ant-api03-newkey1234              # 更新work配置的API密钥"
    echo "  $0 update work --base-url https://new-api.example.com         # 更新work配置的Base URL"
    echo "  $0 update work --api-key sk-ant-api03-new --base-url https://new-api.com  # 同时更新密钥和URL"
    echo "  $0 import                                                     # 读取并可选保存当前环境变量"
    echo
    echo "传统用法 (向后兼容):"
    echo "  $0 <api-key> [base-url]          直接设置API密钥，可选择指定自定义base-url"
    echo "  例如: $0 sk-ant-api03-abcd1234 https://custom-api.example.com"
}

# Main execution
main() {
    # Header
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Claude Code 多配置管理工具${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    # Display current environment variables
    display_current_env
    echo
    
    # Process commands
    if [ $# -eq 0 ]; then
        print_error "缺少命令参数"
        show_help
        exit 1
    fi
    
    command="$1"
    shift
    
    case "$command" in
        add)
            add_config "$1" "$2" "$3"
            ;;
        list)
            list_configs
            ;;
        use)
            use_config "$1"
            ;;
        switch)
            switch_config
            ;;
        update)
            update_config "$@"
            ;;
        remove)
            remove_config "$1"
            ;;
        import)
            import_current_config
            ;;
        help)
            show_help
            ;;
        *)
            # Legacy support: treat first argument as API key for direct setup
            if [[ "$command" =~ ^[A-Za-z0-9_-]+$ ]]; then
                print_warning "检测到传统方式调用，将直接设置API密钥"
                ANTHROPIC_API_KEY="$command"
                
                # Check if a second argument is provided as base_url
                if [ -n "$1" ] && [[ "$1" == http* ]]; then
                    ANTHROPIC_BASE_URL="$1"
                    print_info "使用自定义 Base URL: $ANTHROPIC_BASE_URL"
                else
                    ANTHROPIC_BASE_URL="https://api.aicodemirror.com/api/claudecode"
                    print_info "使用默认 Base URL: $ANTHROPIC_BASE_URL"
                fi
                
                # Execute traditional flow
                detect_os_and_shell
                add_env_vars
                update_claude_json
                activate_config
                verify_config
                
                print_success "Claude Code环境配置完成！"
                echo -e "${BLUE}========================================${NC}"
                
                echo
                echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
                echo -e "${RED}║                                                          ║${NC}"
                echo -e "${RED}║    请关闭终端后重新打开，开始 claude code 使用～        ║${NC}"
                echo -e "${RED}║                                                          ║${NC}"
                echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
                echo
                exit 0
            else
                print_error "未知命令: $command"
                show_help
                exit 1
            fi
            ;;
    esac
}

# Run main function
main "$@"

# Exit successfully
exit 0