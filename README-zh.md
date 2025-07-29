# ccenv

🛠️ Claude Code 多环境配置管理工具 - 轻松管理和切换不同的 API 密钥与服务器配置

[English](README.md) | 中文

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()

## ✨ 功能特性

- 🔄 **多配置管理**: 存储并在多个 API 配置间快速切换
- 💾 **安全存储**: 安全管理多个 API 密钥，显示时自动隐藏
- 🌐 **自定义服务器**: 支持官方 Anthropic API 和自定义服务器地址
- 🎯 **交互式选择器**: 可视化配置选择器，支持方向键导航
- 🔍 **健康检查**: 内置诊断功能验证您的配置
- 🐚 **跨Shell支持**: 支持 bash、zsh 和 fish shell
- 🍎 **跨平台**: 兼容 macOS 和 Linux
- 📦 **零依赖**: 纯 bash 脚本，可选 jq 用于 JSON 处理

## 🚀 快速开始

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/install.sh | bash
```

### 手动安装

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/env-deploy.sh -o /usr/local/bin/ccenv
chmod +x /usr/local/bin/ccenv

# 验证安装
ccenv help
```

### 首次设置

```bash
# 添加您的第一个配置
ccenv add work sk-ant-api03-your-api-key-here

# 添加带自定义服务器的配置
ccenv add dev sk-ant-api03-dev-key https://custom-api.example.com

# 列出所有配置
ccenv list

# 切换配置
ccenv use work
```

## 📖 使用方法

### 基本命令

```bash
# 配置管理
ccenv add <名称> <api-密钥> [服务器地址]    # 添加新配置
ccenv list                                # 列出所有配置
ccenv use <名称>                          # 切换到指定配置
ccenv switch                              # 交互式配置选择器
ccenv remove <名称>                       # 删除配置

# 配置更新
ccenv update <名称> --api-key <新密钥>     # 更新 API 密钥
ccenv update <名称> --base-url <新地址>    # 更新服务器地址
ccenv update <名称> --api-key <密钥> --base-url <地址>  # 同时更新

# 实用工具
ccenv import                              # 导入当前环境变量
ccenv help                                # 显示帮助信息
```

### 简短别名

```bash
ccenv a work sk-xxx        # 等同于: ccenv add work sk-xxx
ccenv l                    # 等同于: ccenv list
ccenv s                    # 等同于: ccenv switch
ccenv u work               # 等同于: ccenv use work
```

## 💡 使用示例

### 典型工作流程

```bash
# 设置工作环境
ccenv add work sk-ant-api03-work-key-here

# 设置开发环境（自定义服务器）
ccenv add dev sk-ant-api03-dev-key-here https://dev-api.example.com

# 设置中国镜像
ccenv add china sk-ant-api03-china-key https://api.aicodemirror.com/api/claudecode

# 在环境间切换
ccenv use work      # 切换到工作环境
ccenv use dev       # 切换到开发环境
ccenv switch        # 交互式选择器

# 检查当前状态
ccenv list
```

### 高级用法

```bash
# 更新现有配置
ccenv update work --api-key sk-ant-api03-new-work-key
ccenv update dev --base-url https://new-dev-api.example.com

# 从当前环境导入
export ANTHROPIC_API_KEY="sk-ant-api03-xxx"
export ANTHROPIC_BASE_URL="https://api.example.com"
ccenv import  # 会提示保存为新配置

# 健康检查
ccenv use work
# 验证配置是否正常工作
claude --version
```

## 🔧 配置存储

配置存储在 `~/.claude_configs.json` 中：

```json
{
  "configs": {
    "work": {
      "api_key": "sk-ant-api03-work-key",
      "base_url": "https://api.anthropic.com"
    },
    "dev": {
      "api_key": "sk-ant-api03-dev-key", 
      "base_url": "https://dev-api.example.com"
    }
  },
  "active": "work"
}
```

## 🛠️ 系统要求

- **操作系统**: macOS 或 Linux
- **Shell**: bash、zsh 或 fish
- **可选依赖**: `jq` 用于 JSON 处理（如缺失会自动提示安装）

### 安装 jq

```bash
# macOS
brew install jq

# Ubuntu/Debian  
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## 🔒 安全说明

- API 密钥本地存储在 `~/.claude_configs.json` 中
- 显示时会隐藏密钥（仅显示后4位字符）
- 配置文件具有受限权限 (600)
- 不会通过网络传输存储的凭据

## 🐛 故障排除

### 常见问题

**找不到命令: ccenv**
```bash
# 检查是否正确安装
which ccenv
# 如果找不到，重新安装
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/install.sh | bash
```

**找不到 jq**
```bash
# 根据您的操作系统安装 jq（参见系统要求部分）
brew install jq  # macOS
```

**环境变量不生效**
```bash
# 重启终端或重新加载 shell 配置
source ~/.zshrc    # 对于 zsh
source ~/.bashrc   # 对于 bash
source ~/.config/fish/config.fish  # 对于 fish
```

### 重置配置

```bash
# 删除所有配置，重新开始
rm ~/.claude_configs.json
rm ~/.claude.json
# 手动从 shell 配置文件中删除环境变量
```

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Anthropic](https://www.anthropic.com/) 提供 Claude Code
- [jq](https://stedolan.github.io/jq/) 提供 JSON 处理

---