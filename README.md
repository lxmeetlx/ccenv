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
ccenv add <name> <api-key> [base-url]     # Add new configuration
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
ccenv help                                # Show help information
```

### Short Aliases

```bash
ccenv a work sk-xxx        # Same as: ccenv add work sk-xxx
ccenv l                    # Same as: ccenv list  
ccenv s                    # Same as: ccenv switch
ccenv u work               # Same as: ccenv use work
```

## 💡 Examples

### Typical Workflow

```bash
# Setup work environment
ccenv add work sk-ant-api03-work-key-here

# Setup development environment with custom server
ccenv add dev sk-ant-api03-dev-key-here https://dev-api.example.com

# Setup China mirror
ccenv add china sk-ant-api03-china-key https://api.aicodemirror.com/api/claudecode

# Switch between environments
ccenv use work      # Switch to work
ccenv use dev       # Switch to development  
ccenv switch        # Interactive picker

# Check current status
ccenv list
```

### Advanced Usage

```bash
# Update existing configuration
ccenv update work --api-key sk-ant-api03-new-work-key
ccenv update dev --base-url https://new-dev-api.example.com

# Import from current environment
export ANTHROPIC_API_KEY="sk-ant-api03-xxx"
export ANTHROPIC_BASE_URL="https://api.example.com"
ccenv import  # Will prompt to save as new configuration

# Health check
ccenv use work
# Verify your configuration is working
claude --version
```

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