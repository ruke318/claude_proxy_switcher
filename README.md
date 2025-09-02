# Claude代理切换工具

🚀 **Claude Proxy Switcher** - 一个现代化的Claude代理站切换工具，提供优雅的交互式界面和流畅的用户体验。

## ✨ 特性

- 🎯 **交互式选择** - 使用 fzf 提供现代化的交互体验，支持模糊搜索和实时预览
- 🌈 **现代化界面** - 优雅的配色方案和图标设计，告别传统的"大白块"显示
- 🔄 **智能恢复** - 启动时自动恢复上次使用的代理配置
- 📊 **详细预览** - 交互界面中实时显示代理详细信息，包括URL、ID和认证状态
- ⚙️ **环境变量管理** - 自动设置和清理 Anthropic 相关环境变量
- 🔒 **安全显示** - 认证信息智能脱敏，保护隐私安全
- 📝 **JSON配置** - 使用 JSON 格式存储配置，易于管理和备份
- 🚀 **即插即用** - 无需安装，source 即可使用，支持所有主流 Shell

## 🛠️ 安装

### 前置要求

- **jq**: JSON 处理工具
- **fzf**: 模糊搜索工具（用于交互式选择）
  ```bash
  # macOS
  brew install jq fzf
  
  # Ubuntu/Debian
  sudo apt-get install jq fzf
  
  # CentOS/RHEL
  sudo yum install jq fzf
  ```

### 快速安装

```bash
# 克隆仓库
git clone https://github.com/ruke318/claude_proxy_switcher.git
cd claude_proxy_switcher

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

```bash
# 启动交互式代理选择器
claude_proxy
```

这将打开一个现代化的交互界面，支持：
- 🔍 **模糊搜索**: 输入关键词快速筛选代理
- 👁️ **实时预览**: 右侧面板显示代理详细信息
- ⌨️ **键盘导航**: 使用方向键或 Ctrl+J/K 导航
- ✨ **优雅界面**: 现代化配色和图标设计

### 管理代理配置

代理配置通过直接编辑配置文件进行管理：

```bash
# 编辑配置文件
vim ~/.claude_proxy/config.json
```

## 🎯 核心功能

工具专注于提供最佳的交互式代理选择体验：

- **🚀 一键启动**: 只需运行 `claude_proxy` 即可打开交互界面
- **🔍 智能搜索**: 支持模糊搜索，快速定位目标代理
- **👁️ 实时预览**: 选择代理时实时显示详细信息
- **⚡ 快速切换**: Enter 键确认切换，Esc 键退出
- **🔄 自动恢复**: 启动时自动恢复上次使用的代理

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

### 🎯 交互式选择界面

现代化的交互界面提供了优雅的用户体验：

![Claude代理选择器界面](https://github.com/ruke318/claude_proxy_switcher/raw/main/screenshots/interactive-ui.png)

**界面特点：**
- 🎨 **现代配色**: 深色主题配合青色高亮，视觉舒适
- 📋 **代理列表**: 左侧显示所有可用代理，支持模糊搜索
- 👁️ **详细预览**: 右侧实时显示选中代理的详细信息
- 🔍 **智能搜索**: 支持按代理名称、URL等关键词快速筛选
- ⌨️ **快捷操作**: 方向键导航，Enter确认，Esc退出

### 🚀 工具加载效果

```
🚀 已自动恢复上次使用的代理: yinhe (yinhe)
✨ Claude 代理切换工具已加载 🚀
╭─────────────────────────────────────────────────────────────────────────────╮
输入 claude_proxy 开始使用
```

### 📊 代理切换成功

```
✨ 代理切换成功 🚀
╭─────────────────────────────────────────────────────────────────────────────╮
👉 当前代理: yinhe
🌐 代理名称: 银河AI
🔗 代理URL: https://api.yinhe.com
🆔 代理ID: yinhe
🎫 认证令牌: sk-AkFB3***
```

## 🔧 高级使用

### 脚本集成

```bash
#!/bin/bash
# 在脚本中使用
source claude_proxy_switcher.sh
# 环境变量会自动设置，可直接使用 Claude API
```

### 配置备份

```bash
# 备份配置文件
cp ~/.claude_proxy/config.json ~/.claude_proxy/config.json.backup

# 恢复配置文件
cp ~/.claude_proxy/config.json.backup ~/.claude_proxy/config.json
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

### v2.5 (当前版本)
- ✨ **界面革新**: 全新现代化交互界面设计
- 🎨 **视觉优化**: 移除"大白块"，采用优雅的图标和配色方案
- 🔍 **交互增强**: 集成 fzf 提供模糊搜索和实时预览功能
- 📊 **信息展示**: 右侧面板实时显示代理详细信息
- 🎯 **用户体验**: 支持键盘导航和快捷操作
- 🌈 **配色升级**: 深色主题配合青色高亮，视觉更舒适

### v2.4
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