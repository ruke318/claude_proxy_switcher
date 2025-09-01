//! 环境变量管理模块
//! 
//! 负责设置和清除ANTHROPIC相关的环境变量

use anyhow::Result;
use std::env;
use colored::Colorize;
use crate::config::ProxyConfig;
use crate::ui::UI;

/// 环境变量管理器
pub struct EnvManager;

impl EnvManager {
    /// 创建新的环境变量管理器
    pub fn new() -> Self {
        Self
    }
    
    /// 设置代理相关的环境变量
    pub fn set_proxy_env(&self, proxy_id: &str, config: &ProxyConfig, show_output: bool, ui: &UI) -> Result<()> {
        // 清除现有的认证环境变量
        self.clear_auth_env();
        
        // 设置基础URL和代理ID
        env::set_var("ANTHROPIC_BASE_URL", &config.url);
        env::set_var("CLAUDE_PROXY_ID", proxy_id);
        
        // 设置API密钥（如果存在）
        if let Some(api_key) = &config.api_key {
            if !api_key.is_empty() {
                env::set_var("ANTHROPIC_API_KEY", api_key);
            }
        }
        
        // 设置认证令牌（如果存在）
        if let Some(auth_token) = &config.auth_token {
            if !auth_token.is_empty() {
                env::set_var("ANTHROPIC_AUTH_TOKEN", auth_token);
            }
        }
        
        // 根据参数决定是否显示输出
        if show_output {
            ui.print_success(&format!("已切换到代理: {} ({})", config.name.as_str().bold(), config.url));
            ui.print_subheader("⚙️ 环境变量已设置:");
            
            ui.print_env_var("ANTHROPIC_BASE_URL", Some(&config.url), "🔗");
            ui.print_env_var("CLAUDE_PROXY_ID", Some(proxy_id), "🌐");
            
            if let Some(api_key) = &config.api_key {
                if !api_key.is_empty() {
                    ui.print_env_var("ANTHROPIC_API_KEY", Some(api_key), "🔑");
                }
            }
            
            if let Some(auth_token) = &config.auth_token {
                if !auth_token.is_empty() {
                    ui.print_env_var("ANTHROPIC_AUTH_TOKEN", Some(auth_token), "🎫");
                }
            }
        }
        
        Ok(())
    }
    
    /// 清除所有认证相关的环境变量
    pub fn clear_auth_env(&self) {
        env::remove_var("ANTHROPIC_API_KEY");
        env::remove_var("ANTHROPIC_AUTH_TOKEN");
    }
    
    /// 清除所有代理相关的环境变量
    pub fn clear_all_env(&self) {
        env::remove_var("ANTHROPIC_BASE_URL");
        env::remove_var("ANTHROPIC_API_KEY");
        env::remove_var("ANTHROPIC_AUTH_TOKEN");
        env::remove_var("CLAUDE_PROXY_ID");
    }
    
    /// 获取当前环境变量状态
    pub fn get_env_status(&self) -> EnvStatus {
        EnvStatus {
            base_url: env::var("ANTHROPIC_BASE_URL").ok(),
            api_key: env::var("ANTHROPIC_API_KEY").ok(),
            auth_token: env::var("ANTHROPIC_AUTH_TOKEN").ok(),
            proxy_id: env::var("CLAUDE_PROXY_ID").ok(),
        }
    }
    
    /// 显示当前环境变量状态
    pub fn show_env_status(&self, ui: &UI) {
        let status = self.get_env_status();
        
        ui.print_subheader("⚙️ 环境变量");
        ui.print_short_separator();
        
        ui.print_env_var("ANTHROPIC_BASE_URL", status.base_url.as_deref(), "🔗");
        ui.print_env_var("CLAUDE_PROXY_ID", status.proxy_id.as_deref(), "🌐");
        ui.print_env_var("ANTHROPIC_API_KEY", status.api_key.as_deref(), "🔑");
        ui.print_env_var("ANTHROPIC_AUTH_TOKEN", status.auth_token.as_deref(), "🎫");
    }
}

/// 环境变量状态
#[derive(Debug)]
pub struct EnvStatus {
    pub base_url: Option<String>,
    pub api_key: Option<String>,
    pub auth_token: Option<String>,
    pub proxy_id: Option<String>,
}

impl Default for EnvManager {
    fn default() -> Self {
        Self::new()
    }
}