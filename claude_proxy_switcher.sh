#!/bin/zsh

# Claude代理站切换工具 - 简化版
# 功能: 交互式选择和切换Claude代理站配置
# 使用方法: source claude_proxy_switcher.sh 然后使用 claude_proxy 命令
# 作者: 开发助手
# 版本: 3.0 - 简化版，只保留交互式选择功能

# ==================== 颜色和图标定义 ====================
# ANSI 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unicode 图标
ICON_SUCCESS='✅'
ICON_ERROR='❌'
ICON_WARNING='⚠️'
ICON_INFO='ℹ️'
ICON_PROXY='🌐'
ICON_CURRENT='👉'
ICON_LIST='📋'
ICON_URL='🔗'
ICON_KEY='🔑'
ICON_TOKEN='🎫'

# ==================== 配置文件路径定义 ====================
CLAUDE_CONFIG_DIR="$HOME/.claude_proxy"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/config.json"
CLAUDE_CURRENT_FILE="$CLAUDE_CONFIG_DIR/current"

# ==================== 辅助函数 ====================
# 彩色输出函数
print_success() { echo -e "${GREEN}${ICON_SUCCESS} $1${NC}"; }
print_error() { echo -e "${RED}${ICON_ERROR} $1${NC}"; }
print_warning() { echo -e "${YELLOW}${ICON_WARNING} $1${NC}"; }
print_info() { echo -e "${BLUE}${ICON_INFO} $1${NC}"; }
print_header() { echo -e "${BOLD}${CYAN}$1${NC}"; }
print_subheader() { echo -e "${BOLD}${WHITE}$1${NC}"; }

# ==================== 核心函数 ====================

# 设置代理环境变量
_claude_set_proxy_env() {
    local proxy_id="$1"
    local silent="$2"  # 静默模式参数
    
    # 获取代理信息
    local proxy_name=$(jq -r ".proxies[\"$proxy_id\"].name" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
    local proxy_url=$(jq -r ".proxies[\"$proxy_id\"].url" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
    local api_key=$(jq -r ".proxies[\"$proxy_id\"].api_key" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
    local auth_token=$(jq -r ".proxies[\"$proxy_id\"].auth_token" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
    
    # 重置认证环境变量
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN
    
    # 设置环境变量
    export ANTHROPIC_BASE_URL="$proxy_url"
    export CLAUDE_PROXY_ID="$proxy_id"
    
    if [ "$api_key" != "null" ] && [ -n "$api_key" ]; then
        export ANTHROPIC_API_KEY="$api_key"
    fi
    
    if [ "$auth_token" != "null" ] && [ -n "$auth_token" ]; then
        export ANTHROPIC_AUTH_TOKEN="$auth_token"
    fi
    
    # 保存当前代理ID
    echo "$proxy_id" > "$CLAUDE_CURRENT_FILE"
    
    # 只在非静默模式下显示详细信息
    if [ "$silent" != "true" ]; then
        # 显示切换结果
        print_success "已切换到代理: ${BOLD}$proxy_name${NC} ${GRAY}($proxy_url)${NC}"
        print_subheader "环境变量已设置:"
        echo -e "  ${CYAN}${ICON_URL} ANTHROPIC_BASE_URL${NC}=${YELLOW}$proxy_url${NC}"
        echo -e "  ${CYAN}${ICON_PROXY} CLAUDE_PROXY_ID${NC}=${YELLOW}$proxy_id${NC}"
        
        if [ "$api_key" != "null" ] && [ -n "$api_key" ]; then
            echo -e "  ${CYAN}${ICON_KEY} ANTHROPIC_API_KEY${NC}=${YELLOW}${api_key:0:10}...${NC}"
        fi
        
        if [ "$auth_token" != "null" ] && [ -n "$auth_token" ]; then
            echo -e "  ${CYAN}${ICON_TOKEN} ANTHROPIC_AUTH_TOKEN${NC}=${YELLOW}${auth_token:0:10}...${NC}"
        fi
    fi
}

# 交互式选择代理
_claude_interactive_select() {
    # 检查配置文件
    if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
        print_error "配置文件不存在: $CLAUDE_CONFIG_FILE"
        print_info "请手动创建配置文件或使用旧版本的 init 命令"
        return 1
    fi
    
    # 检查必要工具
    if ! command -v jq >/dev/null 2>&1; then
        print_error "需要安装jq来解析配置文件"
        print_info "macOS: ${BOLD}brew install jq${NC}"
        print_info "Ubuntu: ${BOLD}sudo apt-get install jq${NC}"
        return 1
    fi
    
    if ! command -v fzf >/dev/null 2>&1; then
        print_error "需要安装fzf来启用交互式选择"
        print_info "macOS: ${BOLD}brew install fzf${NC}"
        print_info "Ubuntu: ${BOLD}sudo apt install fzf${NC}"
        return 1
    fi
    
    # 获取当前使用的代理ID
    local current=""
    if [ -f "$CLAUDE_CURRENT_FILE" ]; then
        current=$(cat "$CLAUDE_CURRENT_FILE")
    fi
    
    print_header "${ICON_LIST} 选择Claude代理站"
    echo -e "${GRAY}===========================================${NC}"
    
    # 生成fzf选项列表
    local fzf_options=$(jq -r '.proxies | to_entries[] | "\(.key): \(.value.name) (\(.value.url))"' "$CLAUDE_CONFIG_FILE" | while read line; do
        proxy_id=$(echo "$line" | cut -d':' -f1)
        proxy_info=$(echo "$line" | cut -d':' -f2-)
        if [ "$proxy_id" = "$current" ]; then
            echo "👉 $proxy_id:$proxy_info [当前使用]"
        else
            echo "🌐 $proxy_id:$proxy_info"
        fi
    done)
    
    # 创建临时预览脚本
    local preview_script=$(mktemp)
    cat > "$preview_script" << EOF
#!/bin/bash
proxy_id=\$(echo "\$1" | sed 's/^[👉🌐] //g' | cut -d':' -f1)

# 安全处理敏感信息
safe_mask() {
    local value="\$1"
    local show_chars="\${2:-6}"
    
    if [ "\$value" = "null" ] || [ -z "\$value" ]; then
        echo "未设置"
    elif [ \${#value} -le \$show_chars ]; then
        echo "\${value:0:3}***"
    else
        echo "\${value:0:\$show_chars}***"
    fi
}

# 获取代理信息并进行安全处理
if [ -f "$CLAUDE_CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
    proxy_data=\$(jq -r ".proxies[\"\$proxy_id\"]" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
    
    if [ "\$proxy_data" != "null" ] && [ -n "\$proxy_data" ]; then
        name=\$(echo "\$proxy_data" | jq -r '.name // "未命名"')
        url=\$(echo "\$proxy_data" | jq -r '.url // "未设置"')
        api_key=\$(echo "\$proxy_data" | jq -r '.api_key // null')
        auth_token=\$(echo "\$proxy_data" | jq -r '.auth_token // null')
        
        safe_api_key=\$(safe_mask "\$api_key" 8)
        safe_auth_token=\$(safe_mask "\$auth_token" 8)
        
        echo "📋 代理配置详情"
        echo "═══════════════════════════════════════"
        echo ""
        echo "🆔 代理ID: \$proxy_id"
        echo "📝 代理名称: \$name"
        echo "🔗 代理网址: \$url"
        echo "🔑 API密钥: \$safe_api_key"
        echo "🎫 认证令牌: \$safe_auth_token"
        echo ""
        echo "💡 提示: 敏感信息已脱敏处理"
        
        if [ -f "$CLAUDE_CURRENT_FILE" ]; then
            current_id=\$(cat "$CLAUDE_CURRENT_FILE" 2>/dev/null)
            if [ "\$current_id" = "\$proxy_id" ]; then
                echo "✅ 当前正在使用此代理"
            fi
        fi
    else
        echo "❌ 无法读取代理信息"
        echo "代理ID: \$proxy_id 不存在或配置文件损坏"
    fi
else
    echo "❌ 配置文件不存在或jq工具未安装"
    echo "请检查配置文件: $CLAUDE_CONFIG_FILE"
fi
EOF
    chmod +x "$preview_script"
    
    # 使用fzf进行选择
    local selected=$(echo "$fzf_options" | fzf \
        --height=80% \
        --layout=reverse \
        --border=rounded \
        --border-label=" 🌐 Claude代理站选择器 " \
        --border-label-pos=2 \
        --prompt="🔍 选择代理 › " \
        --header="💡 使用 ↑↓ 选择，Enter 确认，ESC 取消 | 右侧显示详细配置信息" \
        --header-lines=0 \
        --info=inline \
        --preview-window=right:55%:wrap \
        --preview="'$preview_script' {}" \
        --preview-label=" 📋 配置详情 " \
        --preview-label-pos=2 \
        --color="fg:#e4e4e7,bg:#18181b,hl:#3b82f6,fg+:#ffffff,bg+:#27272a,hl+:#60a5fa,info:#fbbf24,prompt:#06b6d4,pointer:#f59e0b,marker:#10b981,spinner:#8b5cf6,header:#a855f7,border:#374151,preview-bg:#111827,preview-fg:#f3f4f6,label:#9ca3af" \
        --bind="ctrl-u:preview-page-up,ctrl-d:preview-page-down,ctrl-r:reload(echo '$fzf_options')" \
        --no-mouse)
    
    # 清理临时文件
    rm -f "$preview_script"
    
    if [ -n "$selected" ]; then
        # 提取代理ID
        local selected_id=$(echo "$selected" | sed 's/^[👉🌐] //g' | cut -d':' -f1)
        print_info "您选择了代理: ${BOLD}$selected_id${NC}"
        
        # 切换到选中的代理
        _claude_set_proxy_env "$selected_id"
        return 0
    else
        print_info "未选择任何代理"
        return 0
    fi
}

# ==================== 主函数 ====================
# Claude代理切换工具的主入口函数 - 简化版
claude_proxy() {
    # 直接启动交互式选择模式
    _claude_interactive_select
}

# ==================== 自动恢复上次使用的代理 ====================
# 如果存在上次使用的代理记录，自动恢复环境变量
if [ -f "$CLAUDE_CURRENT_FILE" ] && [ -f "$CLAUDE_CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
    current_proxy_id=$(cat "$CLAUDE_CURRENT_FILE")
    if [ -n "$current_proxy_id" ]; then
        # 检查代理是否仍然存在于配置文件中
        proxy_exists=$(jq -r ".proxies | has(\"$current_proxy_id\")" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
        if [ "$proxy_exists" = "true" ]; then
            _claude_set_proxy_env "$current_proxy_id" "true"  # 静默模式
            proxy_name=$(jq -r ".proxies[\"$current_proxy_id\"].name" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
            print_success "已自动恢复上次使用的代理: ${BOLD}$proxy_name${NC} ${GRAY}($current_proxy_id)${NC}"
        else
            # 如果代理不存在了，清除记录文件
            rm -f "$CLAUDE_CURRENT_FILE"
            print_warning "上次使用的代理 '$current_proxy_id' 已不存在，已清除记录"
        fi
    fi
fi

# 显示使用说明
echo -e "${GREEN}${ICON_SUCCESS} Claude代理切换工具已加载 (简化版)${NC}"