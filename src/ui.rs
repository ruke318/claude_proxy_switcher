//! 用户界面模块
//! 
//! 负责彩色输出、图标显示和用户交互界面

use colored::*;
use std::io::{self, Write};

/// 用户界面管理器
pub struct UI;

impl UI {
    /// 创建新的UI实例
    pub fn new() -> Self {
        Self
    }
    
    /// 打印成功信息
    pub fn print_success(&self, message: &str) {
        println!("{} {}", "✅".green(), message);
    }
    
    /// 打印错误信息
    pub fn print_error(&self, message: &str) {
        eprintln!("{} {}", "❌".red(), message.red());
    }
    
    /// 打印警告信息
    pub fn print_warning(&self, message: &str) {
        println!("{} {}", "⚠️".yellow(), message.yellow());
    }
    
    /// 打印信息
    pub fn print_info(&self, message: &str) {
        println!("{} {}", "ℹ️".blue(), message.blue());
    }
    
    /// 打印标题
    pub fn print_header(&self, message: &str) {
        println!("{}", message.bold().cyan());
    }
    
    /// 打印子标题
    pub fn print_subheader(&self, message: &str) {
        println!("{}", message.bold().white());
    }
    
    /// 打印分隔线
    pub fn print_separator(&self) {
        println!("{}", "===========================================".dimmed());
    }
    
    /// 打印短分隔线
    pub fn print_short_separator(&self) {
        println!("{}", "-------------------------------------------".dimmed());
    }
    
    /// 打印当前代理信息
    pub fn print_current_proxy(&self, proxy_id: &str, proxy_name: &str) {
        println!(
            "{} {} {}", 
            "👉".green(), 
            format!("{}:", proxy_id).bold().green(),
            format!("{} [当前使用]", proxy_name).yellow()
        );
    }
    
    /// 打印普通代理信息
    pub fn print_proxy(&self, proxy_id: &str, proxy_name: &str, url: &str) {
        println!(
            "{} {} {}", 
            "🌐".blue(), 
            format!("{}:", proxy_id).bold().blue(),
            format!("{} ({})", proxy_name, url).blue()
        );
    }
    
    /// 打印环境变量信息
    pub fn print_env_var(&self, name: &str, value: Option<&str>, icon: &str) {
        match value {
            Some(val) => {
                let display_val = if name.contains("KEY") || name.contains("TOKEN") {
                    // 对敏感信息进行部分隐藏
                    if val.len() > 10 {
                        format!("{}...", &val[..10])
                    } else {
                        val.to_string()
                    }
                } else {
                    val.to_string()
                };
                println!(
                    "  {} {}: {}", 
                    icon.cyan(), 
                    name.cyan(),
                    display_val.yellow()
                );
            }
            None => {
                println!(
                    "  {} {}: {}", 
                    icon.cyan(), 
                    name.cyan(),
                    "未设置".red()
                );
            }
        }
    }
    
    /// 询问用户确认
    pub fn ask_confirmation(&self, message: &str) -> bool {
        print!("{} {} [y/N]: ", "⚠️".yellow(), message.yellow());
        io::stdout().flush().unwrap();
        
        let mut input = String::new();
        match io::stdin().read_line(&mut input) {
            Ok(_) => {
                let input = input.trim().to_lowercase();
                input == "y" || input == "yes"
            }
            Err(_) => false,
        }
    }
    

}

impl Default for UI {
    fn default() -> Self {
        Self::new()
    }
}