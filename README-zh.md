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
ccenv add                                 # 交互式配置向导
ccenv quick-add <名称> <api-密钥> [服务器地址] # 快速添加配置
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
ccenv models <set|show|reset>             # 管理模型设置
ccenv check-update                        # 检查新版本
ccenv upgrade                             # 升级到最新版本
ccenv version                             # 显示版本信息
ccenv help                                # 显示帮助信息
```

### 简短别名

```bash
ccenv a                    # 等同于: ccenv add
ccenv l                    # 等同于: ccenv list
ccenv s                    # 等同于: ccenv switch
ccenv u work               # 等同于: ccenv use work
```

## 🧙‍♂️ 交互式配置添加向导

`ccenv add` 命令提供逐步交互式向导来添加配置：

```bash
ccenv add
```

### 功能特性:
- **逐步指导**: 逐项提示配置内容
- **智能预设**: 提供常用服务器选项（官方、自定义）
- **输入验证**: 确保至少设置一个配置项
- **安全输入**: API密钥输入时自动隐藏
- **配置预览**: 保存前显示配置摘要
- **错误处理**: 验证输入并提供有用的反馈

### 工作流程:
1. **配置名称**: 输入配置的唯一名称
2. **API服务器**: 从预设选项中选择或输入自定义地址
3. **API密钥**: 输入Claude API密钥（输入时隐藏保护）
4. **认证令牌**: 可选的认证令牌
5. **确认保存**: 预览所有设置后确认保存

这非常适合初次使用的用户或需要设置复杂配置的场景。

## 🤖 模型管理

ccenv 支持通过 `models` 命令管理 Claude 模型设置：

### 命令:
- `ccenv models set <主模型> <轻量级模型>` - 设置主模型和轻量级模型
- `ccenv models show` - 显示当前模型设置
- `ccenv models reset` - 重置为默认 Claude 模型

### 示例:
```bash
# 设置官方 Claude 模型
ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307

# 设置自定义模型（如第三方API）
ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview

# 查看当前设置
ccenv models show

# 重置为默认设置
ccenv models reset
```

### 环境变量:
- `ANTHROPIC_MODEL` - 用于复杂任务的主模型
- `ANTHROPIC_SMALL_FAST_MODEL` - 用于快速任务的轻量级模型

模型设置按配置存储，在切换配置时会自动应用相应的模型设置。

## 💡 使用示例

### 典型工作流程

```bash
# 交互式配置添加（逐步向导）
ccenv add

# 快速设置工作环境
ccenv quick-add work sk-ant-api03-work-key-here

# 设置开发环境（自定义服务器）
ccenv quick-add dev sk-ant-api03-dev-key-here https://dev-api.example.com

# 设置备用服务器
ccenv quick-add alt sk-ant-api03-alt-key https://custom-api.example.com

# 在环境间切换
ccenv use work      # 切换到工作环境
ccenv use dev       # 切换到开发环境
ccenv switch        # 交互式选择器

# 检查当前状态
ccenv list
```

### 高级用法

```bash
# 交互式添加新配置
ccenv add

# 更新现有配置
ccenv update work --api-key sk-ant-api03-new-work-key
ccenv update dev --base-url https://new-dev-api.example.com

# 从当前环境导入
export ANTHROPIC_API_KEY="sk-ant-api03-xxx"
export ANTHROPIC_BASE_URL="https://api.example.com"
ccenv import  # 会提示保存为新配置

# 管理模型设置
ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307  # 设置 Claude 模型
ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview         # 设置自定义模型
ccenv models show                         # 显示当前模型设置
ccenv models reset                        # 重置为默认模型

# 保持 ccenv 更新
ccenv check-update                        # 检查是否有新版本
ccenv upgrade                             # 升级到最新版本
ccenv version                             # 显示当前版本

# 健康检查
ccenv use work
# 验证配置是否正常工作
claude --version
```

## 🔄 更新 ccenv

### 检查更新

```bash
ccenv check-update
```

这将比较您当前的版本与GitHub上的最新版本。

### 升级到最新版本

```bash
ccenv upgrade
```

升级过程将会：
- 从 GitHub 下载最新版本
- 备份您当前的版本（带时间戳）
- 用新版本替换脚本
- 设置正确的权限
- 验证安装

### 版本信息

```bash
ccenv version
```

显示当前版本和 GitHub 仓库链接。

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