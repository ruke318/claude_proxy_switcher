#!/bin/zsh

# Claude代理站切换工具 - 简化版
# 功能: 交互式选择和切换Claude代理站配置
# 使用方法: source claude_proxy_switcher.sh 然后使用 claude_proxy 命令
# 作者: 开发助手
# 版本: 3.0 - 简化版，只保留交互式选择功能

# ==================== 现代配色方案和图标定义 ====================
# 现代ANSI颜色代码 - 基于流行的终端主题
RED='\033[38;5;196m'        # 鲜艳红色
GREEN='\033[38;5;46m'       # 翠绿色
YELLOW='\033[38;5;226m'     # 明黄色
BLUE='\033[38;5;33m'        # 天蓝色
CYAN='\033[38;5;51m'        # 青蓝色
PURPLE='\033[38;5;129m'     # 紫色
ORANGE='\033[38;5;208m'     # 橙色
PINK='\033[38;5;213m'       # 粉色
WHITE='\033[38;5;255m'      # 纯白色
GRAY='\033[38;5;240m'       # 中灰色
LIGHT_GRAY='\033[38;5;250m' # 浅灰色
DARK_GRAY='\033[38;5;235m'  # 深灰色

# 特殊效果
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m' # No Color

# 渐变色效果（用于标题和重要信息）
GRADIENT_START='\033[38;5;81m'   # 浅蓝
GRADIENT_MID='\033[38;5;117m'    # 中蓝
GRADIENT_END='\033[38;5;153m'    # 深蓝

# 现代Unicode图标集
ICON_SUCCESS='🚀'     # 火箭 - 表示成功启动
ICON_ERROR='💥'       # 爆炸 - 表示错误
ICON_WARNING='⚡'     # 闪电 - 表示警告
ICON_INFO='💡'        # 灯泡 - 表示信息
ICON_PROXY='🌟'       # 星星 - 表示代理
ICON_CURRENT='🎯'     # 靶心 - 表示当前选中
ICON_LIST='📊'        # 图表 - 表示列表
ICON_URL='🔗'         # 链接 - 保持原样
ICON_KEY='🗝️'         # 钥匙 - 表示密钥
ICON_TOKEN='🎫'       # 票据 - 保持原样
ICON_LOADING='⏳'     # 沙漏 - 表示加载
ICON_CONFIG='⚙️'      # 齿轮 - 表示配置
ICON_SWITCH='🔄'      # 循环箭头 - 表示切换

# ==================== 配置文件路径定义 ====================
CLAUDE_CONFIG_DIR="$HOME/.claude_proxy"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/config.json"
CLAUDE_CURRENT_FILE="$CLAUDE_CONFIG_DIR/current"

# ==================== 现代化辅助函数 ====================
# 基础彩色输出函数
print_success() { echo -e "${BOLD}${GREEN}${ICON_SUCCESS} $1${NC}"; }
print_error() { echo -e "${BOLD}${RED}${ICON_ERROR} $1${NC}"; }
print_warning() { echo -e "${BOLD}${ORANGE}${ICON_WARNING} $1${NC}"; }
print_info() { echo -e "${BOLD}${CYAN}${ICON_INFO} $1${NC}"; }
print_loading() { echo -e "${BOLD}${YELLOW}${ICON_LOADING} $1${NC}"; }
print_config() { echo -e "${BOLD}${PURPLE}${ICON_CONFIG} $1${NC}"; }

# 标题和子标题函数
print_header() { echo -e "${BOLD}${GRADIENT_START}$1${NC}"; }
print_subheader() { echo -e "${BOLD}${GRADIENT_MID}$1${NC}"; }
print_title() { echo -e "${BOLD}${UNDERLINE}${GRADIENT_END}$1${NC}"; }

# 特殊效果函数
print_highlight() { echo -e "${BOLD}${REVERSE}${PINK} $1 ${NC}"; }
print_dim() { echo -e "${DIM}${LIGHT_GRAY}$1${NC}"; }
print_emphasis() { echo -e "${BOLD}${ITALIC}${PURPLE}$1${NC}"; }

# 现代化标题效果（用于重要信息）
print_gradient_title() {
    local text="$1"
    echo -e "${GRADIENT_START}▶${GRADIENT_MID}▶${GRADIENT_END}▶ ${BOLD}${WHITE}$text${NC} ${GRADIENT_END}◀${GRADIENT_MID}◀${GRADIENT_START}◀${NC}"
}

# 简洁标题效果
print_modern_title() {
    local text="$1"
    echo -e "${BOLD}${CYAN}✨ $text ${ICON_SUCCESS}${NC}"
}

# 优雅分隔线
print_elegant_separator() {
    echo -e "${DIM}${LIGHT_GRAY}╭─────────────────────────────────────────────────────────────────────────────╮${NC}"
}

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
        print_modern_title "代理切换成功"
        print_success "已切换到代理: ${BOLD}${PURPLE}$proxy_name${NC} ${DIM}${LIGHT_GRAY}($proxy_url)${NC}"
        print_config "环境变量配置:"
        echo -e "  ${BOLD}${BLUE}${ICON_URL} ANTHROPIC_BASE_URL${NC} ${DIM}→${NC} ${UNDERLINE}${CYAN}$proxy_url${NC}"
        echo -e "  ${BOLD}${PURPLE}${ICON_PROXY} CLAUDE_PROXY_ID${NC} ${DIM}→${NC} ${BOLD}${PINK}$proxy_id${NC}"
        
        if [ "$api_key" != "null" ] && [ -n "$api_key" ]; then
            echo -e "  ${BOLD}${ORANGE}${ICON_KEY} ANTHROPIC_API_KEY${NC} ${DIM}→${NC} ${YELLOW}${api_key:0:10}${DIM}...${NC}"
        fi
        
        if [ "$auth_token" != "null" ] && [ -n "$auth_token" ]; then
            echo -e "  ${BOLD}${GREEN}${ICON_TOKEN} ANTHROPIC_AUTH_TOKEN${NC} ${DIM}→${NC} ${YELLOW}${auth_token:0:10}${DIM}...${NC}"
        fi
        
        print_dim "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
        print_error "需要安装 ${BOLD}jq${NC} 来解析配置文件"
        print_info "${BOLD}${BLUE}macOS:${NC} ${UNDERLINE}brew install jq${NC}"
        print_info "${BOLD}${ORANGE}Ubuntu:${NC} ${UNDERLINE}sudo apt-get install jq${NC}"
        return 1
    fi
    
    if ! command -v fzf >/dev/null 2>&1; then
        print_error "需要安装 ${BOLD}fzf${NC} 来启用交互式选择"
        print_info "${BOLD}${BLUE}macOS:${NC} ${UNDERLINE}brew install fzf${NC}"
        print_info "${BOLD}${ORANGE}Ubuntu:${NC} ${UNDERLINE}sudo apt install fzf${NC}"
        return 1
    fi
    
    # 获取当前使用的代理ID
    local current=""
    if [ -f "$CLAUDE_CURRENT_FILE" ]; then
        current=$(cat "$CLAUDE_CURRENT_FILE")
    fi
    
    print_modern_title "Claude 代理选择器"
    print_elegant_separator
    
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
        
        echo -e "\033[1;35m🚀 代理配置详情\033[0m"
        echo -e "\033[2;37m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo ""
        echo -e "\033[1;36m🆔 代理ID:\033[0m \033[1;95m\$proxy_id\033[0m"
        echo -e "\033[1;34m📝 代理名称:\033[0m \033[1;32m\$name\033[0m"
        echo -e "\033[1;33m🔗 代理网址:\033[0m \033[4;36m\$url\033[0m"
        echo -e "\033[1;91m🔑 API密钥:\033[0m \033[33m\$safe_api_key\033[0m"
        echo -e "\033[1;92m🎫 认证令牌:\033[0m \033[33m\$safe_auth_token\033[0m"
        echo ""
        echo -e "\033[2;37m💡 提示: 敏感信息已脱敏处理\033[0m"
        
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
    
    # 使用fzf进行选择（现代化配色方案）
    local selected=$(echo "$fzf_options" | fzf \
        --height=85% \
        --layout=reverse \
        --border=rounded \
        --border-label=" 🚀 Claude 代理选择器 " \
        --border-label-pos=2 \
        --prompt="✨ 选择代理 › " \
        --header="🎯 使用 ↑↓ 选择，Enter 确认，ESC 取消 | 右侧显示详细配置信息" \
        --header-lines=0 \
        --info=inline \
        --preview-window=right:58%:wrap:border-left \
        --preview="'$preview_script' {}" \
        --preview-label=" 🔍 配置详情 " \
        --preview-label-pos=2 \
        --color="fg:#f8fafc,bg:#0f172a,hl:#06b6d4,fg+:#ffffff,bg+:#1e293b,hl+:#22d3ee,info:#f59e0b,prompt:#8b5cf6,pointer:#ec4899,marker:#10b981,spinner:#f97316,header:#a855f7,border:#475569,preview-bg:#020617,preview-fg:#e2e8f0,label:#64748b,gutter:#1e293b,selected-bg:#312e81,selected-fg:#c7d2fe" \
        --bind="ctrl-u:preview-page-up,ctrl-d:preview-page-down,ctrl-r:reload(echo '$fzf_options'),ctrl-/:toggle-preview" \
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
            print_success "已自动恢复上次使用的代理: ${BOLD}${PURPLE}$proxy_name${NC} ${DIM}${LIGHT_GRAY}($current_proxy_id)${NC}"
        else
            # 如果代理不存在了，清除记录文件
            rm -f "$CLAUDE_CURRENT_FILE"
            print_warning "上次使用的代理 ${BOLD}'$current_proxy_id'${NC} 已不存在，已清除记录"
        fi
    fi
fi

# 显示使用说明
print_modern_title "Claude 代理切换工具已加载"
print_elegant_separator
print_emphasis "输入 ${BOLD}${CYAN}claude_proxy${NC} 开始使用"