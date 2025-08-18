#!/bin/zsh

# Claude代理站切换工具
# 功能: 管理多个Claude代理站配置，支持快速切换不同的API端点和认证信息
# 使用方法: source claude_proxy_switcher.sh 然后使用 claude_proxy 命令
# 作者: 开发助手
# 版本: 2.4 - 添加颜色格式和图标，提升用户体验

# ==================== 颜色和图标定义 ====================
# ANSI 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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
ICON_CONFIG='⚙️'
ICON_SWITCH='🔄'
ICON_ADD='➕'
ICON_REMOVE='🗑️'
ICON_STATUS='📊'
ICON_HELP='❓'
ICON_INIT='🚀'
ICON_LIST='📋'
ICON_KEY='🔑'
ICON_TOKEN='🎫'
ICON_URL='🔗'

# ==================== 配置文件路径定义 ====================
CLAUDE_CONFIG_DIR="$HOME/.claude_proxy"          # 配置目录
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/config.json"  # 主配置文件
CLAUDE_CURRENT_FILE="$CLAUDE_CONFIG_DIR/current"     # 当前使用的代理ID文件

# ==================== 辅助函数 ====================
# 彩色输出函数
print_success() { echo -e "${GREEN}${ICON_SUCCESS} $1${NC}"; }
print_error() { echo -e "${RED}${ICON_ERROR} $1${NC}"; }
print_warning() { echo -e "${YELLOW}${ICON_WARNING} $1${NC}"; }
print_info() { echo -e "${BLUE}${ICON_INFO} $1${NC}"; }
print_header() { echo -e "${BOLD}${CYAN}$1${NC}"; }
print_subheader() { echo -e "${BOLD}${WHITE}$1${NC}"; }

# ==================== 核心函数 ====================

# 通用的代理环境变量设置函数
_claude_set_proxy_env() {
    local proxy_id="$1"
    local show_output="${2:-true}"
    
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
    
    # 根据参数决定是否显示输出
    if [ "$show_output" = "true" ]; then
        print_success "已切换到代理: ${BOLD}$proxy_name${NC} ${GRAY}($proxy_url)${NC}"
        print_subheader "${ICON_CONFIG} 环境变量已设置:"
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

# ==================== 主函数 ====================
# 功能: Claude代理切换工具的主入口函数
# 参数: $1 - 命令 (list|switch|add|remove|status|init|help)
#       $2-$n - 根据不同命令的具体参数
# 返回: 根据具体命令的返回值
# 说明: 统一的命令行接口，支持所有代理管理功能，使用局部函数保持代码可读性
claude_proxy() {
    local command="$1"
    shift
    
    # ==================== 局部函数定义 ====================
    
    # 初始化配置函数
    local _init_claude_config() {
        # 创建配置目录
        if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
            mkdir -p "$CLAUDE_CONFIG_DIR"
        fi
        
        # 创建默认配置文件
        if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
            cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
{
  "proxies": {
    "proxy1": {
      "name": "代理站1",
      "url": "https://your-proxy1.com",
      "api_key": "your-api-key-1",
      "auth_token": "your-auth-token-1"
    },
    "proxy2": {
      "name": "代理站2", 
      "url": "https://your-proxy2.com",
      "api_key": "your-api-key-2",
      "auth_token": "your-auth-token-2"
    }
  }
}
EOF
            print_success "配置文件已创建: $CLAUDE_CONFIG_FILE"
            print_info "请编辑配置文件添加你的代理站信息"
        fi
    }
    
    # 列表显示函数
    local _claude_list() {
        if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
            print_warning "配置文件不存在，正在初始化..."
            _init_claude_config
            return
        fi
        
        print_header "${ICON_LIST} 可用的Claude代理站"
        echo -e "${GRAY}===========================================${NC}"
        
        # 获取当前使用的代理ID
        local current=""
        if [ -f "$CLAUDE_CURRENT_FILE" ]; then
            current=$(cat "$CLAUDE_CURRENT_FILE")
        fi
        
        # 使用jq解析JSON并列出所有代理配置
        if command -v jq >/dev/null 2>&1; then
            jq -r '.proxies | to_entries[] | "\(.key): \(.value.name) (\(.value.url))"' "$CLAUDE_CONFIG_FILE" | while read line; do
                proxy_id=$(echo "$line" | cut -d':' -f1)
                proxy_info=$(echo "$line" | cut -d':' -f2-)
                if [ "$proxy_id" = "$current" ]; then
                    echo -e "${GREEN}${ICON_CURRENT} ${BOLD}$proxy_id${NC}${GREEN}:$proxy_info ${YELLOW}[当前使用]${NC}"
                else
                    echo -e "${BLUE}${ICON_PROXY} ${BOLD}$proxy_id${NC}${BLUE}:$proxy_info${NC}"
                fi
            done
        else
            print_error "需要安装jq来解析配置文件"
            print_info "macOS: ${BOLD}brew install jq${NC}"
            print_info "Ubuntu: ${BOLD}sudo apt-get install jq${NC}"
        fi
    }
    

    
    # 代理切换函数
    local _claude_switch() {
        local proxy_id="$1"
        
        # 检查参数
        if [ -z "$proxy_id" ]; then
            print_error "用法: claude_proxy switch <proxy_id>"
            print_info "使用 ${BOLD}claude_proxy list${NC} 查看可用的代理ID"
            return 1
        fi
        
        # 检查配置文件
        if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
            print_warning "配置文件不存在，正在初始化..."
            _init_claude_config
            return 1
        fi
        
        # 检查jq工具
        if ! command -v jq >/dev/null 2>&1; then
            print_error "需要安装jq来管理配置文件"
            print_info "macOS: ${BOLD}brew install jq${NC}"
            print_info "Ubuntu: ${BOLD}sudo apt-get install jq${NC}"
            return 1
        fi
        
        # 检查代理是否存在
        local proxy_exists=$(jq -r ".proxies | has(\"$proxy_id\")" "$CLAUDE_CONFIG_FILE")
        if [ "$proxy_exists" != "true" ]; then
            print_error "代理 '$proxy_id' 不存在"
            print_info "使用 ${BOLD}claude_proxy list${NC} 查看可用的代理"
            return 1
        fi
        
        # 调用通用设置函数
        _claude_set_proxy_env "$proxy_id" "true"
    }
    
    # 添加代理函数
    local _claude_add() {
        local proxy_id="$1"
        local proxy_name="$2"
        local proxy_url="$3"
        local api_key="$4"
        local auth_token="$5"
        
        # 检查参数
        if [ -z "$proxy_id" ] || [ -z "$proxy_name" ] || [ -z "$proxy_url" ]; then
            print_error "用法: claude_proxy add <proxy_id> <proxy_name> <proxy_url> [api_key] [auth_token]"
            print_info "示例: ${BOLD}claude_proxy add myproxy '我的代理' 'https://api.myproxy.com' 'sk-xxx' 'auth-token-xxx'${NC}"
            print_warning "注意: api_key和auth_token至少需要提供一个"
            return 1
        fi
        
        # 验证认证参数
        if [ -z "$api_key" ] && [ -z "$auth_token" ]; then
            print_error "必须提供api_key或auth_token中的至少一个"
            return 1
        fi
        
        # 确保配置文件存在
        _init_claude_config
        
        # 检查jq工具
        if ! command -v jq >/dev/null 2>&1; then
            print_error "需要安装jq来管理配置文件"
            print_info "macOS: ${BOLD}brew install jq${NC}"
            print_info "Ubuntu: ${BOLD}sudo apt-get install jq${NC}"
            return 1
        fi
        
        # 检查代理是否已存在
        local proxy_exists=$(jq -r ".proxies | has(\"$proxy_id\")" "$CLAUDE_CONFIG_FILE")
        if [ "$proxy_exists" = "true" ]; then
            print_warning "代理 '$proxy_id' 已存在，将被覆盖"
        fi
        
        # 构建新配置
        local new_proxy='{}'
        new_proxy=$(echo "$new_proxy" | jq --arg name "$proxy_name" '.name = $name')
        new_proxy=$(echo "$new_proxy" | jq --arg url "$proxy_url" '.url = $url')
        
        if [ -n "$api_key" ]; then
            new_proxy=$(echo "$new_proxy" | jq --arg key "$api_key" '.api_key = $key')
        fi
        
        if [ -n "$auth_token" ]; then
            new_proxy=$(echo "$new_proxy" | jq --arg token "$auth_token" '.auth_token = $token')
        fi
        
        # 添加到配置文件
        local temp_file=$(mktemp)
        jq --arg id "$proxy_id" --argjson proxy "$new_proxy" '.proxies[$id] = $proxy' "$CLAUDE_CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CLAUDE_CONFIG_FILE"
        
        print_success "代理 '${BOLD}$proxy_id${NC}' 已成功添加到配置文件"
    }
    
    # 删除代理函数
    local _claude_remove() {
        local proxy_id="$1"
        
        # 检查参数
        if [ -z "$proxy_id" ]; then
            print_error "用法: claude_proxy remove <proxy_id>"
            return 1
        fi
        
        # 检查配置文件
        if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
            print_error "配置文件不存在"
            return 1
        fi
        
        # 检查jq工具
        if ! command -v jq >/dev/null 2>&1; then
            print_error "需要安装jq来管理配置文件"
            return 1
        fi
        
        # 检查代理是否存在
        local proxy_exists=$(jq -r ".proxies | has(\"$proxy_id\")" "$CLAUDE_CONFIG_FILE")
        if [ "$proxy_exists" != "true" ]; then
            print_error "代理 '$proxy_id' 不存在"
            return 1
        fi
        
        # 获取代理名称
        local proxy_name=$(jq -r ".proxies[\"$proxy_id\"].name" "$CLAUDE_CONFIG_FILE")
        
        # 确认删除
        print_warning "确定要删除代理 '${BOLD}$proxy_id${NC}' ${GRAY}($proxy_name)${NC} 吗? [y/N]"
        read -r confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "取消删除操作"
            return 0
        fi
        
        # 删除代理
        local temp_file=$(mktemp)
        jq --arg id "$proxy_id" 'del(.proxies[$id])' "$CLAUDE_CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CLAUDE_CONFIG_FILE"
        
        # 如果删除的是当前代理，清除环境变量
        if [ -f "$CLAUDE_CURRENT_FILE" ]; then
            local current=$(cat "$CLAUDE_CURRENT_FILE")
            if [ "$current" = "$proxy_id" ]; then
                unset ANTHROPIC_BASE_URL
                unset ANTHROPIC_API_KEY
                unset ANTHROPIC_AUTH_TOKEN
                unset CLAUDE_PROXY_ID
                rm -f "$CLAUDE_CURRENT_FILE"
                print_info "已清除当前代理的环境变量"
            fi
        fi
        
        print_success "代理 '${BOLD}$proxy_id${NC}' 已成功删除"
    }
    
    # 状态查看函数
    local _claude_status() {
        print_header "${ICON_STATUS} 当前Claude代理状态"
        echo -e "${GRAY}===========================================${NC}"
        
        # 显示当前代理信息
        if [ -n "$CLAUDE_PROXY_ID" ]; then
            echo -e "${CYAN}${ICON_CURRENT} 当前代理:${NC} ${BOLD}${GREEN}$CLAUDE_PROXY_ID${NC}"
            
            if [ -f "$CLAUDE_CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
                local proxy_name=$(jq -r ".proxies[\"$CLAUDE_PROXY_ID\"].name" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
                if [ "$proxy_name" != "null" ] && [ -n "$proxy_name" ]; then
                    echo -e "${CYAN}${ICON_PROXY} 代理名称:${NC} ${BOLD}$proxy_name${NC}"
                fi
            fi
        else
            echo -e "${CYAN}${ICON_CURRENT} 当前代理:${NC} ${RED}未设置${NC}"
        fi
        
        echo ""
        print_subheader "${ICON_CONFIG} 环境变量"
        echo -e "${GRAY}-------------------------------------------${NC}"
        
        # 显示环境变量状态
        if [ -n "$ANTHROPIC_BASE_URL" ]; then
            echo -e "${CYAN}${ICON_URL} ANTHROPIC_BASE_URL:${NC} ${YELLOW}$ANTHROPIC_BASE_URL${NC}"
        else
            echo -e "${CYAN}${ICON_URL} ANTHROPIC_BASE_URL:${NC} ${RED}未设置${NC}"
        fi
        
        if [ -n "$CLAUDE_PROXY_ID" ]; then
            echo -e "${CYAN}${ICON_PROXY} CLAUDE_PROXY_ID:${NC} ${YELLOW}$CLAUDE_PROXY_ID${NC}"
        else
            echo -e "${CYAN}${ICON_PROXY} CLAUDE_PROXY_ID:${NC} ${RED}未设置${NC}"
        fi
        
        # 安全显示认证信息
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            echo -e "${CYAN}${ICON_KEY} ANTHROPIC_API_KEY:${NC} ${YELLOW}${ANTHROPIC_API_KEY:0:10}...${NC}"
        else
            echo -e "${CYAN}${ICON_KEY} ANTHROPIC_API_KEY:${NC} ${RED}未设置${NC}"
        fi
        
        if [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
            echo -e "${CYAN}${ICON_TOKEN} ANTHROPIC_AUTH_TOKEN:${NC} ${YELLOW}${ANTHROPIC_AUTH_TOKEN:0:10}...${NC}"
        else
            echo -e "${CYAN}${ICON_TOKEN} ANTHROPIC_AUTH_TOKEN:${NC} ${RED}未设置${NC}"
        fi
    }
    
    # 帮助信息函数 - 演示多种多行输出方式
    local _claude_help() {
        print_header "${ICON_HELP} Claude代理切换工具 v2.4"
        
        # 方式1: 使用 printf 多行输出（推荐，支持格式化和转义）
        printf '%b\n' \
            "${GRAY}===========================================${NC}" \
            "" \
            "$(print_info "功能: 管理多个Claude代理站配置，支持快速切换不同的API端点和认证信息")" \
            "" \
            "$(print_subheader "${ICON_CONFIG} 用法: claude_proxy <命令> [参数...]")" \
            "" \
            "$(print_subheader "${ICON_LIST} 可用命令:")" \
            "  ${GREEN}list, ls${NC}              列出所有可用的代理配置" \
            "  ${GREEN}switch, use${NC} <id>      切换到指定的代理" \
            "  ${GREEN}add${NC} <id> <name> <url> [api_key] [auth_token]" \
            "                        添加新的代理配置" \
            "  ${GREEN}remove, rm${NC} <id>       删除指定的代理配置" \
            "  ${GREEN}status${NC}                显示当前代理状态和环境变量" \
            "  ${GREEN}init${NC}                  初始化配置文件" \
            "  ${GREEN}help${NC}                  显示此帮助信息" \
            "" \
            "$(print_subheader "${ICON_CONFIG} 环境变量映射:")" \
            "  ${CYAN}${ICON_URL} ANTHROPIC_BASE_URL${NC}    -> 代理站的API端点URL" \
            "  ${CYAN}${ICON_KEY} ANTHROPIC_API_KEY${NC}     -> API密钥（如果配置了）" \
            "  ${CYAN}${ICON_TOKEN} ANTHROPIC_AUTH_TOKEN${NC}  -> 认证令牌（如果配置了）" \
            "  ${CYAN}${ICON_PROXY} CLAUDE_PROXY_ID${NC}       -> 当前使用的代理ID" \
            "" \
            "$(print_subheader "${ICON_INFO} 示例:")" \
            "  ${BOLD}claude_proxy list${NC}                    # 列出所有代理" \
            "  ${BOLD}claude_proxy switch proxy1${NC}           # 切换到proxy1" \
            "  ${BOLD}claude_proxy add myproxy \"我的代理\" \"https://api.example.com\" \"sk-xxx\"${NC}" \
            "  ${BOLD}claude_proxy status${NC}                  # 查看当前状态" \
            "" \
            "$(print_subheader "${ICON_WARNING} 注意:")" \
            "  ${GRAY}• 配置文件位置: ~/.claude_proxy/config.json${NC}" \
            "  ${GRAY}• 需要安装jq工具来解析JSON配置文件${NC}" \
            "  ${GRAY}• api_key和auth_token至少需要提供一个${NC}" \
            "  ${GRAY}• 认证信息在显示时会被部分隐藏以保护安全${NC}" \
            "  ${GRAY}• 使用局部函数定义，保持代码可读性的同时确保私有化${NC}"
    }
    
    # ==================== 命令分发 ====================
    
    # 自动初始化（如果需要）
    if [[ "$command" == "init" || (("$command" == "list" || "$command" == "ls" || "$command" == "switch" || "$command" == "use") && ! -f "$CLAUDE_CONFIG_FILE") ]]; then
        _init_claude_config
        if [[ "$command" == "init" ]]; then
            return 0
        fi
    fi
    
    # 根据命令执行相应操作
    case "$command" in
        "list"|"ls")
            _claude_list
            ;;
        "switch"|"use")
            _claude_switch "$@"
            ;;
        "add")
            _claude_add "$@"
            ;;
        "remove"|"rm")
            _claude_remove "$@"
            ;;
        "status")
            _claude_status
            ;;
        "init")
            print_success "配置初始化完成"
            ;;
        "help"|"--help"|"-h"|"")
            _claude_help
            ;;
        *)
            print_error "未知命令: $command"
            print_info "使用 '${BOLD}claude_proxy help${NC}' 查看帮助信息"
            return 1
            ;;
    esac
}

# ==================== 脚本初始化 ====================
# 使用匿名函数进行初始化，避免污染全局环境
() {
    # 创建配置目录
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        mkdir -p "$CLAUDE_CONFIG_DIR"
    fi
    
    # 如果配置文件不存在，创建默认配置
    if [ ! -f "$CLAUDE_CONFIG_FILE" ]; then
        cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
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
EOF
    fi
}

# ==================== 自动恢复上次使用的代理 ====================
# 如果存在上次使用的代理记录，自动恢复环境变量
() {

    
    # 检查文件和工具
    if [ -f "$CLAUDE_CURRENT_FILE" ] && [ -f "$CLAUDE_CONFIG_FILE" ] && command -v jq >/dev/null 2>&1; then
        local current_proxy_id=$(cat "$CLAUDE_CURRENT_FILE")
        if [ -n "$current_proxy_id" ]; then
            # 检查代理是否仍然存在于配置文件中
            local proxy_exists=$(jq -r ".proxies | has(\"$current_proxy_id\")" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
            if [ "$proxy_exists" = "true" ]; then
                _claude_set_proxy_env "$current_proxy_id" "false"
                # 显示恢复信息
                local proxy_name=$(jq -r ".proxies[\"$current_proxy_id\"].name" "$CLAUDE_CONFIG_FILE" 2>/dev/null)
                print_success "已自动恢复上次使用的代理: ${BOLD}$proxy_name${NC} ${GRAY}($current_proxy_id)${NC}"
            else
                # 如果代理不存在了，清除记录文件
                rm -f "$CLAUDE_CURRENT_FILE"
                print_warning "上次使用的代理 '$current_proxy_id' 已不存在，已清除记录"
            fi
        fi
    fi
}

# ==================== 脚本加载完成 ====================
print_success "Claude代理切换工具已加载完成 (v2.4)"
print_info "添加了颜色格式和图标，提升用户体验"
print_info "使用 '${BOLD}claude_proxy help${NC}' 查看帮助信息"