# ccenv

🛠️ Multi-environment configuration manager for Claude Code - Easily manage and switch between different API keys and server configurations

English | [中文](README-zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg)]()

## ✨ Features

- 🔄 **Multi-Config Management**: Store and switch between multiple API configurations instantly
- 💾 **Secure Storage**: Safely manage multiple API keys with masked display
- 🌐 **Custom Servers**: Support for official Anthropic API and custom base URLs  
- 🎯 **Interactive Selector**: Visual configuration picker with arrow key navigation
- 🔍 **Health Check**: Built-in diagnostics to verify your setup
- 🐚 **Cross-Shell**: Works with bash, zsh, and fish shells
- 🍎 **Cross-Platform**: macOS and Linux compatible
- 📦 **Zero Dependencies**: Pure bash script with optional jq for JSON handling

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/install.sh | bash
```

### Manual Installation

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/env-deploy.sh -o /usr/local/bin/ccenv
chmod +x /usr/local/bin/ccenv

# Verify installation
ccenv help
```

### First-Time Setup

```bash
# Add your first configuration
ccenv add work sk-ant-api03-your-api-key-here

# Add configuration with custom server
ccenv add dev sk-ant-api03-dev-key https://custom-api.example.com

# List all configurations
ccenv list

# Switch between configurations
ccenv use work
```

## 📖 Usage

### Basic Commands

```bash
# Configuration Management
ccenv add                                 # Interactive configuration wizard
ccenv quick-add <name> <api-key> [base-url] # Quick add configuration
ccenv list                                # List all configurations  
ccenv use <name>                          # Switch to configuration
ccenv switch                              # Interactive configuration selector
ccenv remove <name>                       # Delete configuration

# Configuration Updates
ccenv update <name> --api-key <new-key>   # Update API key
ccenv update <name> --base-url <new-url>  # Update base URL
ccenv update <name> --api-key <key> --base-url <url>  # Update both

# Utilities
ccenv import                              # Import current environment variables
ccenv models <set|show|reset>             # Manage model settings
ccenv check-update                        # Check for new version
ccenv upgrade                             # Upgrade to latest version
ccenv version                             # Show version information
ccenv help                                # Show help information
```

### Short Aliases

```bash
ccenv a                    # Same as: ccenv add
ccenv l                    # Same as: ccenv list  
ccenv s                    # Same as: ccenv switch
ccenv u work               # Same as: ccenv use work
```

## 🧙‍♂️ Interactive Configuration Wizard

The `ccenv add` command provides a step-by-step interactive wizard to add configurations:

```bash
ccenv add
```

### Features:
- **Step-by-step guidance**: Prompts for each configuration item
- **Smart defaults**: Offers common server options (official, custom)
- **Validation**: Ensures at least one configuration item is provided
- **Secure input**: Hides API keys during entry
- **Configuration preview**: Shows summary before saving
- **Error handling**: Validates inputs and provides helpful feedback

### Workflow:
1. **Configuration Name**: Enter a unique name for your configuration
2. **API Server**: Choose from preset options or enter custom URL
3. **API Key**: Enter your Claude API key (input hidden for security)
4. **Auth Token**: Optional authentication token
5. **Review & Confirm**: Preview all settings before saving

This is perfect for first-time users or when you need to set up complex configurations with multiple options.

## 🤖 Model Management

ccenv supports managing Claude model settings through the `models` command:

### Commands:
- `ccenv models set <main-model> <fast-model>` - Set both main and lightweight models
- `ccenv models show` - Display current model settings
- `ccenv models reset` - Reset to default Claude models

### Examples:
```bash
# Set official Claude models
ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307

# Set custom models (e.g., for third-party APIs)
ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview

# View current settings
ccenv models show

# Reset to defaults
ccenv models reset
```

### Environment Variables:
- `ANTHROPIC_MODEL` - Main model for complex tasks
- `ANTHROPIC_SMALL_FAST_MODEL` - Lightweight model for quick tasks

Model settings are stored per configuration and applied when switching between configurations.

## 💡 Examples

### Typical Workflow

```bash
# Interactive configuration creation (step-by-step wizard)
ccenv add

# Quick setup work environment
ccenv quick-add work sk-ant-api03-work-key-here

# Setup development environment with custom server
ccenv quick-add dev sk-ant-api03-dev-key-here https://dev-api.example.com

# Setup alternative server
ccenv quick-add alt sk-ant-api03-alt-key https://custom-api.example.com

# Switch between environments
ccenv use work      # Switch to work
ccenv use dev       # Switch to development  
ccenv switch        # Interactive picker

# Check current status
ccenv list
```

### Advanced Usage

```bash
# Add new configuration interactively
ccenv add

# Update existing configuration
ccenv update work --api-key sk-ant-api03-new-work-key
ccenv update dev --base-url https://new-dev-api.example.com

# Import from current environment
export ANTHROPIC_API_KEY="sk-ant-api03-xxx"
export ANTHROPIC_BASE_URL="https://api.example.com"
ccenv import  # Will prompt to save as new configuration

# Manage model settings
ccenv models set claude-3-5-sonnet-20241022 claude-3-haiku-20240307  # Set Claude models
ccenv models set kimi-k2-turbo-preview kimi-k2-turbo-preview         # Set custom models
ccenv models show                         # Show current model settings
ccenv models reset                        # Reset to default models

# Keep ccenv updated
ccenv check-update                        # Check if new version available
ccenv upgrade                             # Upgrade to latest version
ccenv version                             # Show current version

# Health check
ccenv use work
# Verify your configuration is working
claude --version
```

## 🔄 Updating ccenv

### Check for Updates

```bash
ccenv check-update
```

This will compare your current version with the latest release on GitHub.

### Upgrade to Latest Version

```bash
ccenv upgrade
```

The upgrade process will:
- Download the latest version from GitHub
- Backup your current version (with timestamp)
- Replace the script with the new version
- Set proper permissions
- Verify the installation

### Version Information

```bash
ccenv version
```

Shows current version and GitHub repository link.

## 🔧 Configuration Storage

Configurations are stored in `~/.claude_configs.json`:

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

## 🛠️ Requirements

- **OS**: macOS or Linux
- **Shell**: bash, zsh, or fish
- **Optional**: `jq` for JSON processing (auto-installed prompt if missing)

### Installing jq

```bash
# macOS
brew install jq

# Ubuntu/Debian  
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq
```

## 🔒 Security

- API keys are stored locally in `~/.claude_configs.json`
- Keys are masked when displayed (only last 4 characters shown)
- Configuration file has restricted permissions (600)
- No network transmission of stored credentials

## 🐛 Troubleshooting

### Common Issues

**Command not found: ccenv**
```bash
# Check if installed correctly
which ccenv
# If not found, reinstall
curl -fsSL https://raw.githubusercontent.com/lxmeetlx/ccenv/main/install.sh | bash
```

**jq not found**
```bash
# Install jq based on your OS (see Requirements section)
brew install jq  # macOS
```

**Environment variables not working**
```bash
# Restart your terminal or source your shell config
source ~/.zshrc    # For zsh
source ~/.bashrc   # For bash
source ~/.config/fish/config.fish  # For fish
```

### Reset Configuration

```bash
# Remove all configurations and start fresh
rm ~/.claude_configs.json
rm ~/.claude.json
# Remove environment variables from shell config manually
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Anthropic](https://www.anthropic.com/) for Claude Code
- [jq](https://stedolan.github.io/jq/) for JSON processing

---