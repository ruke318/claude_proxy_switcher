//! 配置管理模块
//! 
//! 负责处理JSON配置文件的读写和代理配置管理

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

/// 单个代理配置
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyConfig {
    pub name: String,
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auth_token: Option<String>,
}

/// 完整的配置文件结构
#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub proxies: HashMap<String, ProxyConfig>,
}

/// 配置管理器
#[derive(Debug, Clone)]
pub struct ConfigManager {
    config_file: PathBuf,
    current_file: PathBuf,
}

impl ConfigManager {
    /// 创建新的配置管理器
    pub fn new() -> Result<Self> {
        let home_dir = dirs::home_dir()
            .context("无法获取用户主目录")?;
        
        let config_dir = home_dir.join(".claude_proxy");
        let config_file = config_dir.join("config.json");
        
        // 确保配置目录存在
        if !config_dir.exists() {
            fs::create_dir_all(&config_dir)
                .context("无法创建配置目录")?;
        }
        
        Ok(Self {
            config_file,
            current_file: config_dir.join("current"),
        })
    }
    
    /// 获取配置文件路径
    pub fn config_file(&self) -> &Path {
        &self.config_file
    }
    
    /// 读取当前使用的代理ID
    pub fn load_current_proxy(&self) -> Result<Option<String>> {
        if !self.current_file.exists() {
            return Ok(None);
        }
        
        let content = fs::read_to_string(&self.current_file)
            .context("无法读取当前代理文件")?;
        
        let proxy_id = content.trim();
        if proxy_id.is_empty() {
            Ok(None)
        } else {
            Ok(Some(proxy_id.to_string()))
        }
    }
    
    /// 保存当前使用的代理ID
    pub fn save_current_proxy(&self, proxy_id: &str) -> Result<()> {
        fs::write(&self.current_file, proxy_id)
            .context("无法保存当前代理ID")?;
        
        Ok(())
    }
    
    /// 清除当前代理记录
    pub fn clear_current_proxy(&self) -> Result<()> {
        if self.current_file.exists() {
            fs::remove_file(&self.current_file)
                .context("无法删除当前代理文件")?;
        }
        Ok(())
    }
    
    /// 读取配置文件
    pub fn load_config(&self) -> Result<Config> {
        if !self.config_file.exists() {
            return Ok(self.create_default_config()?);
        }
        
        let content = fs::read_to_string(&self.config_file)
            .context("无法读取配置文件")?;
        
        let config: Config = serde_json::from_str(&content)
            .context("配置文件格式错误")?;
        
        Ok(config)
    }
    
    /// 保存配置文件
    pub fn save_config(&self, config: &Config) -> Result<()> {
        let content = serde_json::to_string_pretty(config)
            .context("无法序列化配置")?;
        
        fs::write(&self.config_file, content)
            .context("无法写入配置文件")?;
        
        Ok(())
    }
    
    /// 创建默认配置
    pub fn create_default_config(&self) -> Result<Config> {
        let mut proxies = HashMap::new();
        
        proxies.insert("wenwen".to_string(), ProxyConfig {
            name: "文文AI".to_string(),
            url: "https://api.wenwenai.com".to_string(),
            api_key: None,
            auth_token: Some("your-auth-token-here".to_string()),
        });
        
        proxies.insert("anyrouter".to_string(), ProxyConfig {
            name: "AnyRouter".to_string(),
            url: "https://api.anyrouter.ai".to_string(),
            api_key: Some("your-api-key-here".to_string()),
            auth_token: None,
        });
        
        let config = Config { proxies };
        
        // 保存默认配置
        self.save_config(&config)?;
        
        Ok(config)
    }
    

    
    /// 检查配置文件是否存在
    pub fn config_exists(&self) -> bool {
        self.config_file.exists()
    }
}