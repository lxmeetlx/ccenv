#!/bin/bash

# Claude Code Environment Setup Script
# Purpose: Automatically configure environment variables for Claude Code on macOS and Linux
# Version: 1.1.0

set -e  # Exit on error

# Version and update configuration
SCRIPT_VERSION="1.1.0"
GITHUB_REPO="lxmeetlx/ccenv"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/env-deploy.sh"
UPDATE_CHECK_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

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

# Function to quickly add a new configuration
quick_add_config() {
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
    
    # Add the config (with empty auth_token and default models)
    jq --arg name "$config_name" --arg key "$api_key" --arg url "$base_url" \
       --arg main_model "" --arg fast_model "" \
       '.configs[$name] = {"api_key": $key, "base_url": $url, "auth_token": "", "main_model": $main_model, "fast_model": $fast_model}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
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
            local auth_token=$(jq -r ".configs.\"$config_name\".auth_token" "$CONFIG_STORE")
            
            # 显示配置名称和状态
            if [ "$config_name" == "$active_config" ]; then
                echo -e "* ${GREEN}$config_name${NC}"
            else
                echo -e "  $config_name"
            fi
            
            # 显示Base URL
            echo -e "  Base URL: $base_url"
            
            # 显示API密钥状态
            if [ -n "$api_key" ] && [ "$api_key" != "null" ] && [ "$api_key" != "" ]; then
                echo -e "  API密钥: ****${api_key: -4}"
            else
                echo -e "  API密钥: ${YELLOW}(未设置)${NC}"
            fi
            
            # 显示认证令牌状态
            if [ -n "$auth_token" ] && [ "$auth_token" != "null" ] && [ "$auth_token" != "" ]; then
                echo -e "  认证令牌: ****${auth_token: -4}"
            else
                echo -e "  认证令牌: ${YELLOW}(未设置)${NC}"
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
    
    # Get API key, base URL, auth token, and models
    ANTHROPIC_API_KEY=$(jq -r ".configs.\"$config_name\".api_key" "$CONFIG_STORE")
    ANTHROPIC_BASE_URL=$(jq -r ".configs.\"$config_name\".base_url" "$CONFIG_STORE")
    ANTHROPIC_AUTH_TOKEN=$(jq -r ".configs.\"$config_name\".auth_token // \"\"" "$CONFIG_STORE")
    local main_model=$(jq -r ".configs.\"$config_name\".main_model // empty" "$CONFIG_STORE")
    local fast_model=$(jq -r ".configs.\"$config_name\".fast_model // empty" "$CONFIG_STORE")
    
    print_success "已切换到配置: $config_name"
    
    # Apply the configuration
    detect_os_and_shell
    add_env_vars
    update_claude_json
    
    # Apply model settings (always call to ensure cleanup of empty models)
    apply_model_settings "$main_model" "$fast_model"
    if [ -n "$main_model" ] && [ -n "$fast_model" ] && [ "$main_model" != "null" ] && [ "$fast_model" != "null" ]; then
        print_info "已应用模型设置: 主模型=$main_model, 轻量级模型=$fast_model"
    else
        print_info "已清除模型环境变量（使用默认模型）"
    fi
    
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
    
    # Get current model settings to preserve them
    current_main_model=$(jq -r ".configs.\"$config_name\".main_model // \"\"" "$CONFIG_STORE")
    current_fast_model=$(jq -r ".configs.\"$config_name\".fast_model // \"\"" "$CONFIG_STORE")
    current_auth_token=$(jq -r ".configs.\"$config_name\".auth_token // \"\"" "$CONFIG_STORE")
    
    # Update the config while preserving all fields
    jq --arg name "$config_name" --arg key "$update_api_key" --arg url "$update_base_url" \
       --arg main_model "$current_main_model" --arg fast_model "$current_fast_model" \
       --arg auth_token "$current_auth_token" \
       '.configs[$name] = {"api_key": $key, "base_url": $url, "auth_token": $auth_token, "main_model": $main_model, "fast_model": $fast_model}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    print_success "配置 '$config_name' 已更新"
    
    # If this is the active config, apply the changes
    active_config=$(jq -r '.active' "$CONFIG_STORE")
    if [ "$active_config" == "$config_name" ]; then
        print_info "检测到正在更新当前活动配置，正在应用更改..."
        
        # Set the updated values
        ANTHROPIC_API_KEY="$update_api_key"
        ANTHROPIC_BASE_URL="$update_base_url"
        ANTHROPIC_AUTH_TOKEN=$(jq -r ".configs.\"$config_name\".auth_token // \"\"" "$CONFIG_STORE")
        
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
set -x ANTHROPIC_AUTH_TOKEN "$ANTHROPIC_AUTH_TOKEN"
# End Claude Code Environment Variables
EOF
    else
        cat >> "$CONFIG_FILE" << EOF

# Claude Code Environment Variables
export ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL"
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
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
    export ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
    
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
    
    # Check if any relevant environment variables are set
    local has_vars=false
    
    # Display current values
    echo -e "${BLUE}----------------------------------------${NC}"
    echo "检测到以下环境变量:"
    
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo "ANTHROPIC_API_KEY: ****${ANTHROPIC_API_KEY: -4}"
        has_vars=true
    else
        echo "ANTHROPIC_API_KEY: (未设置)"
    fi
    
    if [ -n "$ANTHROPIC_BASE_URL" ]; then
        echo "ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
        has_vars=true
    else
        local default_base_url="https://api.anthropic.com"
        echo "ANTHROPIC_BASE_URL: $default_base_url (默认值)"
        ANTHROPIC_BASE_URL="$default_base_url"
    fi
    
    if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
        echo "ANTHROPIC_AUTH_TOKEN: ****${ANTHROPIC_AUTH_TOKEN: -4}"
        has_vars=true
    else
        echo "ANTHROPIC_AUTH_TOKEN: (未设置)"
    fi
    
    if [ -n "$ANTHROPIC_MODEL" ]; then
        echo "ANTHROPIC_MODEL: $ANTHROPIC_MODEL"
        has_vars=true
    else
        echo "ANTHROPIC_MODEL: (未设置)"
    fi
    
    if [ -n "$ANTHROPIC_SMALL_FAST_MODEL" ]; then
        echo "ANTHROPIC_SMALL_FAST_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
        has_vars=true
    else
        echo "ANTHROPIC_SMALL_FAST_MODEL: (未设置)"
    fi
    
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Check if at least one variable is set
    if [ "$has_vars" = false ]; then
        print_warning "当前环境中没有设置任何 Claude Code 相关的环境变量"
        print_info "您仍然可以保存一个基础配置"
    fi
    
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
        
        # Add the config (including model settings from environment)
        # Use environment variables if set, otherwise preserve existing values or use defaults
        local import_api_key="${ANTHROPIC_API_KEY:-}"
        local import_base_url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
        local import_auth_token="${ANTHROPIC_AUTH_TOKEN:-}"
        local import_main_model="${ANTHROPIC_MODEL:-}"
        local import_fast_model="${ANTHROPIC_SMALL_FAST_MODEL:-}"
        
        # If config exists and we're overwriting, show what's being updated
        if jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
            print_info "正在用当前环境变量覆盖配置 '$config_name':"
            echo -e "${BLUE}----------------------------------------${NC}"
            echo "API密钥: ${import_api_key:+****${import_api_key: -4}}"
            echo "Base URL: $import_base_url"
            echo "认证令牌: ${import_auth_token:+****${import_auth_token: -4}}"
            echo "主模型: ${import_main_model:-"(未设置)"}"
            echo "轻量级模型: ${import_fast_model:-"(未设置)"}"
            echo -e "${BLUE}----------------------------------------${NC}"
        fi
        
        jq --arg name "$config_name" --arg key "$import_api_key" --arg url "$import_base_url" \
           --arg auth_token "$import_auth_token" --arg main_model "$import_main_model" --arg fast_model "$import_fast_model" \
           '.configs[$name] = {"api_key": $key, "base_url": $url, "auth_token": $auth_token, "main_model": $main_model, "fast_model": $fast_model}' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
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

# Function to add configuration interactively
add_config_interactive() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                          ║${NC}"
    echo -e "${BLUE}║                  交互式配置添加向导                       ║${NC}"
    echo -e "${BLUE}║                                                          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Step 1: 配置名称
    print_info "步骤 1/4: 输入配置名称"
    echo -n "请输入配置名称 (例如: work, personal, dev): "
    read -r config_name
    
    # 验证配置名称
    while [ -z "$config_name" ]; do
        print_error "配置名称不能为空"
        echo -n "请重新输入配置名称: "
        read -r config_name
    done
    
    print_success "配置名称: $config_name"
    echo
    
    # Step 2: Base URL
    print_info "步骤 2/4: 输入 API 服务器地址"
    echo "常用选项:"
    echo "  1. 官方服务器: https://api.anthropic.com"
    echo "  2. 自定义地址"
    echo "  3. 跳过 (留空)"
    echo
    echo -n "请选择 (1-3) 或直接输入地址: "
    read -r base_url_choice
    
    case "$base_url_choice" in
        1)
            input_base_url="https://api.anthropic.com"
            ;;
        2)
            echo -n "请输入自定义服务器地址: "
            read -r input_base_url
            ;;
        3|"")
            input_base_url=""
            ;;
        *)
            # 直接输入的地址
            if [[ "$base_url_choice" == http* ]]; then
                input_base_url="$base_url_choice"
            else
                print_warning "输入格式不正确，将留空"
                input_base_url=""
            fi
            ;;
    esac
    
    if [ -n "$input_base_url" ]; then
        print_success "API 服务器地址: $input_base_url"
    else
        print_info "API 服务器地址: (未设置)"
    fi
    echo
    
    # Step 3: API Key
    print_info "步骤 3/4: 输入 API 密钥"
    echo "请输入您的 Claude API 密钥 (格式: sk-ant-api03-xxx)"
    echo -n "API 密钥 (输入时会隐藏): "
    read -s input_api_key
    echo  # 换行
    
    if [ -n "$input_api_key" ]; then
        print_success "API 密钥: ****${input_api_key: -4}"
    else
        print_info "API 密钥: (未设置)"
    fi
    echo
    
    # Step 4: Auth Token
    print_info "步骤 4/4: 输入认证令牌 (可选)"
    echo "如果您使用自定义认证，请输入认证令牌，否则留空"
    echo -n "认证令牌 (可选): "
    read -r input_auth_token
    
    if [ -n "$input_auth_token" ]; then
        print_success "认证令牌: ****${input_auth_token: -4}"
    else
        print_info "认证令牌: (未设置)"
    fi
    echo
    
    # 验证至少有一个配置项不为空
    if [ -z "$input_base_url" ] && [ -z "$input_api_key" ] && [ -z "$input_auth_token" ]; then
        print_error "错误: 至少需要设置一个配置项 (API服务器地址、API密钥、认证令牌)"
        print_info "请重新运行 'ccenv add' 命令"
        return 1
    fi
    
    # 显示配置摘要
    echo -e "${BLUE}════════════════ 配置摘要 ════════════════${NC}"
    echo "配置名称: $config_name"
    echo "API 服务器: ${input_base_url:-"(使用默认)"}"
    echo "API 密钥: ${input_api_key:+****${input_api_key: -4}}"
    echo "认证令牌: ${input_auth_token:+****${input_auth_token: -4}}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo
    
    # 确认保存
    echo -n "确认保存此配置? (y/N): "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 使用默认值填充空配置
        final_base_url="${input_base_url:-https://api.anthropic.com}"
        final_api_key="${input_api_key:-}"
        final_auth_token="${input_auth_token:-}"
        
        # 保存配置 (复用现有的 add_config 逻辑)
        check_jq
        init_config_store
        
        # 检查配置名是否已存在
        if jq -e ".configs.\"$config_name\"" "$CONFIG_STORE" >/dev/null 2>&1; then
            print_warning "配置 '$config_name' 已存在，将被覆盖"
        fi
        
        # 创建配置对象（包含默认模型设置）
        local config_json=$(jq -n \
            --arg api_key "$final_api_key" \
            --arg base_url "$final_base_url" \
            --arg auth_token "$final_auth_token" \
            --arg main_model "" \
            --arg fast_model "" \
            '{
                "api_key": $api_key,
                "base_url": $base_url,
                "auth_token": $auth_token,
                "main_model": $main_model,
                "fast_model": $fast_model
            }')
        
        # 保存配置
        jq --arg name "$config_name" --argjson config "$config_json" \
           '.configs[$name] = $config' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
        
        print_success "配置 '$config_name' 已保存"
        
        # 如果是第一个配置，设为活动配置
        if [ "$(jq -r '.active' "$CONFIG_STORE")" == "null" ]; then
            jq --arg name "$config_name" '.active = $name' "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
            mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
            print_info "已将 '$config_name' 设置为活动配置"
        fi
        
        echo
        echo -e "${GREEN}✓ 配置添加完成！${NC}"
        echo
        echo "接下来您可以:"
        echo "  ccenv use $config_name    # 切换到此配置"
        echo "  ccenv list               # 查看所有配置"
        echo "  ccenv switch             # 交互式选择配置"
        
    else
        print_info "配置添加已取消"
        return 0
    fi
    
    return 0
}

# Function to manage model settings
manage_models() {
    local subcommand="$1"
    
    case "$subcommand" in
        set)
            set_models "$2" "$3"
            ;;
        show)
            show_models
            ;;
        reset)
            reset_models
            ;;
        *)
            print_error "未知的models子命令: $subcommand"
            echo "用法: ccenv models <set|show|reset> [参数...]"
            echo
            echo "子命令:"
            echo "  set <main-model> <fast-model>    设置主模型和轻量级模型"
            echo "  show                             显示当前模型设置"
            echo "  reset                            重置为默认模型"
            echo
            echo "示例:"
            echo "  ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307"
            echo "  ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview"
            echo "  ccenv models show"
            echo "  ccenv models reset"
            return 1
            ;;
    esac
}

# Function to set model configuration
set_models() {
    local main_model="$1"
    local fast_model="$2"
    
    if [ -z "$main_model" ] || [ -z "$fast_model" ]; then
        print_error "缺少参数: 需要指定主模型和轻量级模型"
        echo "用法: ccenv models set <主模型> <轻量级模型>"
        echo
        echo "示例:"
        echo "  ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307"
        echo "  ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview"
        return 1
    fi
    
    check_jq
    init_config_store
    
    # 获取当前活动配置
    local active_config=$(jq -r '.active' "$CONFIG_STORE")
    
    if [ "$active_config" == "null" ] || [ -z "$active_config" ]; then
        print_error "没有活动配置，请先添加并激活一个配置"
        echo "运行 'ccenv add' 来创建配置"
        return 1
    fi
    
    # 更新配置中的模型设置
    jq --arg config "$active_config" --arg main "$main_model" --arg fast "$fast_model" \
       '.configs[$config].main_model = $main | .configs[$config].fast_model = $fast' \
       "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
    mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
    
    print_success "已设置模型配置:"
    echo "  配置名称: $active_config"
    echo "  主模型: $main_model"
    echo "  轻量级模型: $fast_model"
    
    # 应用到当前环境
    apply_model_settings "$main_model" "$fast_model"
    
    print_info "模型设置已应用到当前环境"
    echo "请重新打开终端或运行以下命令使设置生效:"
    echo "  source ~/.zshrc (zsh) 或 source ~/.bashrc (bash)"
}

# Function to show current model settings
show_models() {
    print_info "当前模型设置:"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # 显示环境变量中的当前设置
    if [ -n "$ANTHROPIC_MODEL" ]; then
        echo "主模型 (ANTHROPIC_MODEL): $ANTHROPIC_MODEL"
    else
        echo "主模型 (ANTHROPIC_MODEL): (未设置)"
    fi
    
    if [ -n "$ANTHROPIC_SMALL_FAST_MODEL" ]; then
        echo "轻量级模型 (ANTHROPIC_SMALL_FAST_MODEL): $ANTHROPIC_SMALL_FAST_MODEL"
    else
        echo "轻量级模型 (ANTHROPIC_SMALL_FAST_MODEL): (未设置)"
    fi
    
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # 显示配置文件中的设置
    check_jq
    init_config_store
    
    local active_config=$(jq -r '.active' "$CONFIG_STORE")
    
    if [ "$active_config" != "null" ] && [ -n "$active_config" ]; then
        echo
        print_info "活动配置 '$active_config' 中的模型设置:"
        echo -e "${BLUE}----------------------------------------${NC}"
        
        local main_model=$(jq -r ".configs.\"$active_config\".main_model // empty" "$CONFIG_STORE")
        local fast_model=$(jq -r ".configs.\"$active_config\".fast_model // empty" "$CONFIG_STORE")
        
        if [ -n "$main_model" ]; then
            echo "主模型: $main_model"
        else
            echo "主模型: (未设置)"
        fi
        
        if [ -n "$fast_model" ]; then
            echo "轻量级模型: $fast_model"
        else
            echo "轻量级模型: (未设置)"
        fi
        
        echo -e "${BLUE}----------------------------------------${NC}"
    fi
}

# Function to reset models to default
reset_models() {
    print_info "重置模型为默认设置..."
    
    # 设置默认模型
    local default_main=""
    local default_fast=""
    
    check_jq
    init_config_store
    
    # 获取当前活动配置
    local active_config=$(jq -r '.active' "$CONFIG_STORE")
    
    if [ "$active_config" != "null" ] && [ -n "$active_config" ]; then
        # 更新配置中的模型设置
        jq --arg config "$active_config" \
           'del(.configs[$config].main_model) | del(.configs[$config].fast_model)' \
           "$CONFIG_STORE" > "$CONFIG_STORE.tmp"
        mv "$CONFIG_STORE.tmp" "$CONFIG_STORE"
        
        print_success "已重置模型为默认设置"
        echo "  主模型: $default_main"
        echo "  轻量级模型: $default_fast"
        
        # 应用到当前环境
        apply_model_settings "$default_main" "$default_fast"
        
        print_info "请重新打开终端或运行以下命令使设置生效:"
        echo "  source ~/.zshrc (zsh) 或 source ~/.bashrc (bash)"
    else
        print_error "没有活动配置，无法重置模型设置"
    fi
}

# Function to apply model settings to environment
apply_model_settings() {
    local main_model="$1"
    local fast_model="$2"
    
    # 检测当前shell和配置文件
    detect_os_and_shell
    
    # 备份配置文件
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 移除旧的模型设置（包括注释标记）
    if [[ "$CURRENT_SHELL" == "fish" ]]; then
        sed -i.tmp -E '/^[[:space:]]*set[[:space:]]+-x[[:space:]]+ANTHROPIC_MODEL/d' "$CONFIG_FILE" 2>/dev/null || true
        sed -i.tmp -E '/^[[:space:]]*set[[:space:]]+-x[[:space:]]+ANTHROPIC_SMALL_FAST_MODEL/d' "$CONFIG_FILE" 2>/dev/null || true
    else
        sed -i.tmp -E '/^[[:space:]]*export[[:space:]]+ANTHROPIC_MODEL=/d' "$CONFIG_FILE" 2>/dev/null || true
        sed -i.tmp -E '/^[[:space:]]*export[[:space:]]+ANTHROPIC_SMALL_FAST_MODEL=/d' "$CONFIG_FILE" 2>/dev/null || true
    fi
    
    # 移除模型配置的注释标记
    sed -i.tmp '/# Claude Models Configuration/,/# End Claude Models Configuration/d' "$CONFIG_FILE" 2>/dev/null || true
    
    # 清理临时文件
    rm -f "$CONFIG_FILE.tmp"
    
    # 只有当模型值非空时才写入环境变量
    if [ -n "$main_model" ] && [ -n "$fast_model" ]; then
        # 添加新的模型设置
        if [[ "$CURRENT_SHELL" == "fish" ]]; then
            cat >> "$CONFIG_FILE" << EOF

# Claude Models Configuration
set -x ANTHROPIC_MODEL "$main_model"
set -x ANTHROPIC_SMALL_FAST_MODEL "$fast_model"
# End Claude Models Configuration
EOF
        else
            cat >> "$CONFIG_FILE" << EOF

# Claude Models Configuration
export ANTHROPIC_MODEL="$main_model"
export ANTHROPIC_SMALL_FAST_MODEL="$fast_model"
# End Claude Models Configuration
EOF
        fi
        
        # 在当前会话中也设置这些变量
        export ANTHROPIC_MODEL="$main_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$fast_model"
    else
        # 如果模型值为空，则从当前会话中移除这些变量
        unset ANTHROPIC_MODEL
        unset ANTHROPIC_SMALL_FAST_MODEL
    fi
}

# Function to check for updates
check_for_updates() {
    print_info "检查更新..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_warning "curl 未安装，无法检查更新"
        return 1
    fi
    
    # Get latest release info from GitHub API
    local latest_info
    if ! latest_info=$(curl -s "$UPDATE_CHECK_URL" 2>/dev/null); then
        print_warning "无法连接到GitHub检查更新"
        return 1
    fi
    
    # Extract version from response (requires jq)
    if command -v jq &> /dev/null; then
        local latest_version=$(echo "$latest_info" | jq -r '.tag_name // empty' 2>/dev/null)
        
        if [ -n "$latest_version" ] && [ "$latest_version" != "null" ]; then
            # Remove 'v' prefix if present
            latest_version=${latest_version#v}
            
            print_info "当前版本: $SCRIPT_VERSION"
            print_info "最新版本: $latest_version"
            
            if [ "$SCRIPT_VERSION" != "$latest_version" ]; then
                print_warning "发现新版本: $latest_version"
                echo "运行 'ccenv upgrade' 来更新到最新版本"
                return 2  # New version available
            else
                print_success "您已使用最新版本"
                return 0
            fi
        else
            print_info "无法获取版本信息"
            return 1
        fi
    else
        print_warning "需要 jq 工具来检查版本信息"
        print_info "或者直接运行 'ccenv upgrade' 来更新"
        return 1
    fi
}

# Function to upgrade ccenv
upgrade_ccenv() {
    print_info "开始更新 ccenv..."
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        print_error "curl 未安装，无法下载更新"
        return 1
    fi
    
    # Get current script path
    local script_path
    if command -v ccenv &> /dev/null; then
        script_path=$(which ccenv)
    else
        script_path="$0"
    fi
    
    print_info "当前脚本路径: $script_path"
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Download latest version
    print_info "从 GitHub 下载最新版本..."
    if ! curl -fsSL "$SCRIPT_URL" -o "$temp_file"; then
        print_error "下载失败: $SCRIPT_URL"
        rm -f "$temp_file"
        return 1
    fi
    
    # Verify download
    if [ ! -s "$temp_file" ]; then
        print_error "下载的文件为空"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check if it's a valid shell script
    if ! head -n 1 "$temp_file" | grep -q "#!/bin/bash"; then
        print_error "下载的文件不是有效的 Bash 脚本"
        rm -f "$temp_file"
        return 1
    fi
    
    # Backup current version
    local backup_file="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
    if [ -f "$script_path" ]; then
        print_info "备份当前版本到: $backup_file"
        if ! sudo cp "$script_path" "$backup_file" 2>/dev/null; then
            print_warning "无法创建备份文件"
        fi
    fi
    
    # Replace the script
    print_info "安装新版本..."
    if ! sudo cp "$temp_file" "$script_path"; then
        print_error "更新失败: 无法替换脚本文件"
        rm -f "$temp_file"
        return 1
    fi
    
    # Set proper permissions (755 = rwxr-xr-x)
    if ! sudo chmod 755 "$script_path"; then
        print_error "更新失败: 无法设置正确权限"
        rm -f "$temp_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    print_success "ccenv 更新完成！"
    
    # Show new version
    if command -v ccenv &> /dev/null; then
        print_info "新版本信息:"
        ccenv version 2>/dev/null || true
    fi
    
    return 0
}

# Function to show version information
show_version() {
    echo "ccenv version $SCRIPT_VERSION"
    echo "GitHub: https://github.com/$GITHUB_REPO"
}

# Show help information
show_help() {
    echo "用法: $0 <命令> [参数...]"
    echo
    echo "命令:"
    echo "  add                                                   交互式添加配置（问答模式）"
    echo "  quick-add <name> <api-key> [base-url]                 快速添加配置"
    echo "  list                                                  列出所有配置"
    echo "  use <name>                                            切换到指定配置"
    echo "  switch                                                交互式选择并切换配置"
    echo "  update <name> [--api-key <key>] [--base-url <url>]    更新指定配置的密钥或URL"
    echo "  remove <name>                                         删除一个配置"
    echo "  import                                                读取当前环境变量并可选择保存为配置"
    echo "  models <set|show|reset> [参数...]                     管理模型设置"
    echo "  check-update                                          检查是否有新版本可用"
    echo "  upgrade                                               升级到最新版本"
    echo "  version                                               显示版本信息"
    echo "  help                                                  显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 add                                                        # 交互式添加配置（推荐）"
    echo "  $0 quick-add work sk-ant-api03-abcd1234                       # 快速添加配置，使用默认URL"
    echo "  $0 quick-add dev sk-ant-api03-abcd1234 https://dev-api.example.com  # 快速添加使用自定义URL的配置"
    echo "  $0 list                                                       # 列出所有配置"
    echo "  $0 use work                                                   # 切换到'work'配置"
    echo "  $0 switch                                                     # 交互式选择并切换配置"
    echo "  $0 update work --api-key sk-ant-api03-newkey1234              # 更新work配置的API密钥"
    echo "  $0 update work --base-url https://new-api.example.com         # 更新work配置的Base URL"
    echo "  $0 update work --api-key sk-ant-api03-new --base-url https://new-api.com  # 同时更新密钥和URL"
    echo "  $0 models set kimi-k2-turbo-preview kimi-k2-turbo-preview     # 设置模型"
    echo "  $0 models show                                                # 显示当前模型设置"
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
        add|a)
            add_config_interactive
            ;;
        quick-add|qa)
            quick_add_config "$1" "$2" "$3"
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
        models)
            manage_models "$@"
            ;;
        check-update)
            check_for_updates
            ;;
        upgrade)
            upgrade_ccenv
            ;;
        version)
            show_version
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
                    ANTHROPIC_BASE_URL="https://api.anthropic.com"
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