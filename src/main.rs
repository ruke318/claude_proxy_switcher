//! Claude代理站切换工具 - Rust版本
//! 
//! 功能: 管理多个Claude代理站配置，支持快速切换不同的API端点和认证信息
//! 命令: claude_px
//! 作者: 开发助手
//! 版本: 1.0.0

mod config;
mod cli;
mod proxy;
mod ui;
mod env_manager;

use anyhow::Result;
use clap::Parser;
use cli::{Cli, Commands};
use config::ConfigManager;
use proxy::ProxyManager;
use ui::UI;

fn main() -> Result<()> {
    let cli = Cli::parse();
    let config_manager = ConfigManager::new()?;
    let ui = UI::new();

    match cli.command {
        Some(Commands::List) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.list_proxies(false, &ui)?;
        }
        Some(Commands::Switch { proxy_id }) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.switch_proxy(&proxy_id, &ui)?;
        }
        Some(Commands::Add { proxy_id, name, url, api_key, auth_token }) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.add_proxy(&proxy_id, &name, &url, api_key.as_deref(), auth_token.as_deref(), &ui)?;
        }
        Some(Commands::Remove { proxy_id }) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.remove_proxy(&proxy_id, &ui)?;
        }
        Some(Commands::Status) => {
            let proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.show_status(&ui)?;
        }
        Some(Commands::Reload) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.reload_config(&ui)?;
        }
        Some(Commands::Init) => {
            let mut proxy_manager = ProxyManager::new(config_manager)?;
            proxy_manager.init_config(&ui)?;
        }
        None => {
            // 默认启动交互式选择模式 - 不自动恢复代理
            let mut proxy_manager = ProxyManager::new_without_restore(config_manager)?;
            proxy_manager.list_proxies(true, &ui)?;
        }
    }

    Ok(())
}