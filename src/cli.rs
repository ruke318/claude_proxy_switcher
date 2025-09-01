//! 命令行接口模块
//! 
//! 使用clap库定义所有命令行参数和子命令

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "claude_px")]
#[command(about = "Claude代理站切换工具 - Rust版本")]
#[command(version = "1.0.0")]
#[command(author = "开发助手")]
#[command(long_about = "Claude代理站切换工具\n\n这是一个用于管理和切换Claude API代理配置的命令行工具。\n支持多个代理站点配置，可以快速切换不同的API端点和认证信息。\n\n使用示例:\n  claude_px list                    # 列出所有代理配置\n  claude_px switch my-proxy         # 切换到指定代理\n  claude_px add new-proxy \"新代理\" https://api.example.com --api-key sk-xxx\n  claude_px status                  # 查看当前状态\n\n配置文件位置: ~/.claude_proxy_config.json")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// 列出所有可用的代理配置
    /// 
    /// 显示所有已配置的代理站点，包括当前激活的代理。
    /// 支持交互式选择模式，可以通过方向键选择并切换代理。
    #[command(alias = "ls")]
    #[command(long_about = "列出所有可用的代理配置\n\n显示格式包括:\n- 代理ID和名称\n- 代理URL\n- 当前状态（激活/未激活）\n\n使用交互模式可以直接选择和切换代理，支持搜索过滤功能。")]
    List,
    
    /// 切换到指定的代理
    /// 
    /// 激活指定的代理配置，设置相应的环境变量。
    /// 会自动配置 CLAUDE_API_BASE_URL 和相关认证信息。
    #[command(alias = "use")]
    #[command(long_about = "切换到指定的代理配置\n\n此命令会:\n1. 设置 CLAUDE_API_BASE_URL 环境变量\n2. 配置 API 密钥和认证令牌\n3. 更新当前激活状态\n\n示例:\n  claude_px switch my-proxy\n  claude_px use official-api")]
    Switch {
        /// 要切换到的代理配置ID
        /// 
        /// 必须是已存在的代理配置ID，可以通过 'claude_px list' 查看所有可用ID
        #[arg(help = "代理配置ID（使用 'claude_px list' 查看可用选项）")]
        proxy_id: String,
    },
    
    /// 添加新的代理配置
    /// 
    /// 创建一个新的代理站点配置，包括URL、认证信息等。
    /// 添加后可以使用 'claude_px switch' 命令切换到此代理。
    #[command(long_about = "添加新的代理配置\n\n创建一个新的代理站点配置，支持以下参数:\n- 代理ID: 唯一标识符，用于后续切换\n- 名称: 显示名称，便于识别\n- URL: 代理站点的API端点\n- API密钥: 可选的API认证密钥\n- 认证令牌: 可选的认证令牌\n\n示例:\n  claude_px add my-proxy \"我的代理\" https://api.example.com\n  claude_px add official \"官方API\" https://api.anthropic.com --api-key sk-xxx")]
    Add {
        /// 代理配置的唯一标识符
        /// 
        /// 用于后续切换和管理，建议使用简短且有意义的名称
        #[arg(help = "代理配置ID（唯一标识符，如: my-proxy, official）")]
        proxy_id: String,
        
        /// 代理的显示名称
        /// 
        /// 用于在列表中显示，可以使用中文或更详细的描述
        #[arg(help = "代理显示名称（如: \"我的代理站\", \"官方API\"）")]
        name: String,
        
        /// 代理站点的API基础URL
        /// 
        /// 完整的API端点地址，通常以 https:// 开头
        #[arg(help = "代理API端点URL（如: https://api.example.com）")]
        url: String,
        
        /// API访问密钥（可选）
        /// 
        /// 某些代理站点需要的API密钥，通常以 sk- 开头
        #[arg(long, help = "API密钥（可选，格式如: sk-xxxxxxxx）")]
        api_key: Option<String>,
        
        /// 认证令牌（可选）
        /// 
        /// 某些代理站点使用的认证令牌
        #[arg(long, help = "认证令牌（可选，用于特殊认证方式）")]
        auth_token: Option<String>,
    },
    
    /// 删除指定的代理配置
    /// 
    /// 从配置文件中永久删除指定的代理配置。
    /// 如果删除的是当前激活的代理，会自动清除相关环境变量。
    #[command(alias = "rm")]
    #[command(long_about = "删除指定的代理配置\n\n此操作会:\n1. 从配置文件中移除代理配置\n2. 如果是当前激活代理，清除环境变量\n3. 操作不可撤销，请谨慎使用\n\n示例:\n  claude_px remove my-proxy\n  claude_px rm old-config")]
    Remove {
        /// 要删除的代理配置ID
        /// 
        /// 必须是已存在的代理配置ID，删除后不可恢复
        #[arg(help = "要删除的代理配置ID（使用 'claude_px list' 查看）")]
        proxy_id: String,
    },
    
    /// 显示当前代理状态和环境变量
    /// 
    /// 查看当前激活的代理配置和相关的环境变量设置。
    /// 用于调试和确认当前配置状态。
    #[command(long_about = "显示当前代理状态和环境变量\n\n显示信息包括:\n- 当前激活的代理配置\n- CLAUDE_API_BASE_URL 环境变量\n- API密钥状态（已设置/未设置）\n- 认证令牌状态\n- 配置文件路径和状态\n\n用于调试连接问题和确认配置正确性。")]
    Status,
    
    /// 重新加载配置文件
    /// 
    /// 从磁盘重新读取配置文件，刷新内存中的配置。
    /// 用于在外部修改配置文件后同步更改。
    #[command(long_about = "重新加载配置文件\n\n此命令会:\n1. 重新读取配置文件\n2. 验证配置格式\n3. 更新内存中的配置\n4. 重新应用当前激活的代理设置\n\n适用场景:\n- 手动编辑了配置文件\n- 配置文件被其他程序修改\n- 需要刷新配置状态")]
    Reload,
    
    /// 初始化配置文件
    /// 
    /// 创建默认的配置文件和目录结构。
    /// 如果配置文件已存在，会提示是否覆盖。
    #[command(long_about = "初始化配置文件\n\n此命令会:\n1. 创建配置文件目录（如果不存在）\n2. 生成默认配置文件\n3. 设置基本的配置结构\n4. 添加示例代理配置\n\n首次使用时建议运行此命令进行初始化。\n如果配置文件已存在，会询问是否覆盖。")]
    Init,
}