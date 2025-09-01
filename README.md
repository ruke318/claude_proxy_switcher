# Claude代理切换工具 (Rust版本)

🚀 **claude_px** - 一个用Rust重写的Claude代理站切换工具，提供更快的性能和更好的用户体验。

## ✨ 特性

- 🦀 **Rust编写** - 更快的启动速度和更低的资源占用
- 🎯 **交互式选择** - 使用skim提供流畅的交互体验
- 🌈 **彩色输出** - 美观的命令行界面
- 📦 **简单配置** - JSON格式的配置文件
- 🔄 **自动恢复** - 启动时自动恢复上次使用的代理
- 🛡️ **安全管理** - 敏感信息部分隐藏显示

## ✨ 特性

- 🎯 **多代理管理**: 支持添加、删除、列表显示多个代理配置
- 🔄 **快速切换**: 一键切换不同的 Claude 代理站
- 🎨 **美观界面**: 彩色输出和图标，提升用户体验
- ⚙️ **环境变量**: 自动设置 Anthropic 相关环境变量
- 🔒 **安全显示**: 认证信息部分隐藏，保护隐私
- 📝 **JSON配置**: 使用 JSON 格式存储配置，易于管理
- 🚀 **即插即用**: 无需安装，source 即可使用

## 🛠️ 安装

### 前置要求

- **jq**: JSON 处理工具
  ```bash
  # macOS
  brew install jq
  
  # Ubuntu/Debian
  sudo apt-get install jq
  
  # CentOS/RHEL
  sudo yum install jq
  ```

### 快速安装

```bash
# 克隆仓库
git clone https://github.com/your-username/claude-proxy-switcher.git
cd claude-proxy-switcher

# 加载脚本
source claude_proxy_switcher.sh
```

### 持久化配置

将以下内容添加到你的 shell 配置文件中（`~/.zshrc` 或 `~/.bashrc`）：

```bash
# Claude Proxy Switcher
source /path/to/claude_proxy_switcher.sh
```

## 🚀 使用方法

### 基本命令

```bash
# 查看帮助
claude_proxy help

# 列出所有代理
claude_proxy list

# 切换代理
claude_proxy switch <proxy_id>

# 查看当前状态
claude_proxy status

# 初始化配置
claude_proxy init
```

### 管理代理配置

```bash
# 添加新代理
claude_proxy add <id> <name> <url> [api_key] [auth_token]

# 示例：添加一个使用 API Key 的代理
claude_proxy add myproxy "我的代理" "https://api.example.com" "sk-xxx"

# 示例：添加一个使用 Auth Token 的代理
claude_proxy add proxy2 "代理站2" "https://api.proxy2.com" "" "auth-token-xxx"

# 删除代理
claude_proxy remove <proxy_id>
```

## 📋 命令详解

| 命令 | 别名 | 描述 | 示例 |
|------|------|------|------|
| `list` | `ls` | 列出所有可用的代理配置 | `claude_proxy list` |
| `switch` | `use` | 切换到指定的代理 | `claude_proxy switch wenwen` |
| `add` | - | 添加新的代理配置 | `claude_proxy add id "名称" "URL" "key"` |
| `remove` | `rm` | 删除指定的代理配置 | `claude_proxy remove proxy1` |
| `status` | - | 显示当前代理状态和环境变量 | `claude_proxy status` |
| `init` | - | 初始化配置文件 | `claude_proxy init` |
| `help` | - | 显示帮助信息 | `claude_proxy help` |

## ⚙️ 配置文件

配置文件位于 `~/.claude_proxy/config.json`，格式如下：

```json
{
  "proxies": {
    "wenwen": {
      "name": "文文AI",
      "url": "https://api.wenwenai.com",
      "auth_token": "your-auth-token-here"
    },
    "anyrouter": {
      "name": "AnyRouter",
      "url": "https://api.anyrouter.ai",
      "api_key": "your-api-key-here"
    }
  }
}
```

### 配置说明

- `name`: 代理的显示名称
- `url`: 代理站的 API 端点 URL
- `api_key`: API 密钥（可选）
- `auth_token`: 认证令牌（可选）

> **注意**: `api_key` 和 `auth_token` 至少需要提供一个

## 🌍 环境变量

工具会自动设置以下环境变量：

| 环境变量 | 描述 |
|----------|------|
| `ANTHROPIC_BASE_URL` | 代理站的 API 端点 URL |
| `ANTHROPIC_API_KEY` | API 密钥（如果配置了） |
| `ANTHROPIC_AUTH_TOKEN` | 认证令牌（如果配置了） |
| `CLAUDE_PROXY_ID` | 当前使用的代理 ID |

## 📸 界面预览

### 帮助信息
```
❓ Claude代理切换工具 v2.4
===========================================

ℹ️ 功能: 管理多个Claude代理站配置，支持快速切换不同的API端点和认证信息

⚙️ 用法: claude_proxy <命令> [参数...]

📋 可用命令:
  list, ls              列出所有可用的代理配置
  switch, use <id>      切换到指定的代理
  add <id> <name> <url> [api_key] [auth_token]
                        添加新的代理配置
  ...
```

### 代理列表
```
📋 可用的Claude代理站
===========================================
👉 wenwen: 文文AI (https://api.wenwenai.com) [当前使用]
🌐 anyrouter: AnyRouter (https://api.anyrouter.ai)
```

### 状态信息
```
📊 当前Claude代理状态
===========================================
👉 当前代理: wenwen
🌐 代理名称: 文文AI

⚙️ 环境变量
-------------------------------------------
🔗 ANTHROPIC_BASE_URL: https://api.wenwenai.com
🌐 CLAUDE_PROXY_ID: wenwen
🎫 ANTHROPIC_AUTH_TOKEN: auth-token...
```

## 🔧 高级功能

### 批量操作

```bash
# 快速切换到不同代理进行测试
claude_proxy switch wenwen && echo "Testing wenwen..."
claude_proxy switch anyrouter && echo "Testing anyrouter..."
```

### 脚本集成

```bash
#!/bin/bash
# 在脚本中使用
source claude_proxy_switcher.sh
claude_proxy switch wenwen
# 你的 Claude API 调用代码
```

## 🛡️ 安全特性

- ✅ 认证信息在显示时自动截断，只显示前10个字符
- ✅ 配置文件存储在用户主目录下，权限受保护
- ✅ 删除操作需要用户确认
- ✅ 环境变量在切换时自动清理

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 📝 更新日志

### v2.4 (当前版本)
- ✨ 添加彩色输出和图标支持
- 🎨 优化用户界面体验
- 🔧 使用 printf 优化多行输出
- 🛡️ 增强安全性，认证信息部分隐藏

### v2.3
- 🚀 使用局部函数定义，保持代码可读性
- 🔒 确保只有主函数暴露到全局环境
- 📦 改进代码结构和模块化

### v2.2
- 🎯 添加代理管理功能
- ⚙️ 支持环境变量自动设置
- 📝 完善错误处理和用户提示

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢所有贡献者的支持
- 感谢 Claude AI 提供的优秀服务
- 感谢开源社区的无私奉献

---

<div align="center">
  <p>如果这个项目对你有帮助，请给它一个 ⭐️</p>
  <p>Made with ❤️ by <a href="https://github.com/ruke318">ruke318</a></p>
</div>