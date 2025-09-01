//! 代理管理核心模块
//! 
//! 负责代理的切换、添加、删除、列表等核心功能

use anyhow::{Context, Result};
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Margin, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Wrap},
    Frame, Terminal,
};

use std::io;
use crate::config::{Config, ConfigManager, ProxyConfig};
use crate::env_manager::EnvManager;
use crate::ui::UI;

/// 代理管理器
pub struct ProxyManager {
    config_manager: ConfigManager,
    env_manager: EnvManager,
}

impl ProxyManager {
    /// 创建新的代理管理器
    pub fn new(config_manager: ConfigManager) -> Result<Self> {
        let env_manager = EnvManager::new();
        
        let manager = Self {
            config_manager,
            env_manager,
        };
        
        // 自动恢复上次使用的代理
        manager.auto_restore_proxy()?;
        
        Ok(manager)
    }
    
    /// 创建新的代理管理器（不自动恢复代理）
    pub fn new_without_restore(config_manager: ConfigManager) -> Result<Self> {
        let env_manager = EnvManager::new();
        Ok(Self {
            config_manager,
            env_manager,
        })
    }
    
    /// 自动恢复上次使用的代理
    fn auto_restore_proxy(&self) -> Result<()> {
        if let Ok(Some(current_proxy_id)) = self.config_manager.load_current_proxy() {
            if let Ok(config) = self.config_manager.load_config() {
                if let Some(proxy_config) = config.proxies.get(&current_proxy_id) {
                    self.env_manager.set_proxy_env(&current_proxy_id, proxy_config, false, &UI::new())?;
                    
                    let ui = UI::new();
                    ui.print_success(&format!(
                        "已自动恢复上次使用的代理: {} ({})", 
                        proxy_config.name, 
                        current_proxy_id
                    ));
                } else {
                    // 如果代理不存在了，清除记录文件
                    let _ = self.config_manager.clear_current_proxy();
                    let ui = UI::new();
                    ui.print_warning(&format!("上次使用的代理 '{}' 已不存在，已清除记录", current_proxy_id));
                }
            }
        }
        Ok(())
    }
    
    /// 列出所有代理（支持交互式选择）
    pub fn list_proxies(&mut self, use_interactive: bool, ui: &UI) -> Result<()> {
        let config = self.config_manager.load_config()
            .context("无法加载配置文件")?;
        
        if config.proxies.is_empty() {
            ui.print_warning("配置文件中没有任何代理配置");
            ui.print_info("使用 'claude_px add' 命令添加代理配置");
            return Ok(());
        }
        
        let current_proxy = self.config_manager.load_current_proxy().unwrap_or(None);
        
        if use_interactive {
            self.interactive_select(&config, current_proxy.as_deref(), ui)?;
        } else {
            self.list_proxies_simple(&config, current_proxy.as_deref(), ui);
        }
        
        Ok(())
    }
    
    /// 简单列表显示
    fn list_proxies_simple(&self, config: &Config, current_proxy: Option<&str>, ui: &UI) {
        ui.print_header("📋 可用的Claude代理站");
        ui.print_separator();
        
        for (proxy_id, proxy_config) in &config.proxies {
            if Some(proxy_id.as_str()) == current_proxy {
                ui.print_current_proxy(proxy_id, &proxy_config.name);
            } else {
                ui.print_proxy(proxy_id, &proxy_config.name, &proxy_config.url);
            }
        }
        
        println!();
        ui.print_info("💡 提示: 使用 'claude_px' (无参数) 启用交互式选择模式");
    }
    
    /// 交互式选择 - 使用 ratatui 实现
    fn interactive_select(&mut self, config: &Config, current_proxy: Option<&str>, ui: &UI) -> Result<()> {
        // 设置终端
        enable_raw_mode()?;
        let mut stdout = io::stdout();
        execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
        let backend = CrosstermBackend::new(stdout);
        let mut terminal = Terminal::new(backend)?;
        
        // 准备代理列表数据
        let proxy_items: Vec<(String, ProxyConfig)> = config.proxies.iter()
            .map(|(id, config)| (id.clone(), config.clone()))
            .collect();
        
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        let mut search_input = String::new();
        let mut search_mode = false;
        
        let result = loop {
            terminal.draw(|f| {
                self.draw_ui(f, &proxy_items, &mut list_state, current_proxy, &search_input, search_mode);
            })?;
            
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    if search_mode {
                        match key.code {
                            KeyCode::Enter => {
                                search_mode = false;
                            }
                            KeyCode::Esc => {
                                search_mode = false;
                                search_input.clear();
                            }
                            KeyCode::Backspace => {
                                search_input.pop();
                            }
                            KeyCode::Char(c) => {
                                search_input.push(c);
                            }
                            _ => {}
                        }
                    } else {
                        match key.code {
                            KeyCode::Char('q') | KeyCode::Esc => {
                                break None;
                            }
                            KeyCode::Char('/') => {
                                search_mode = true;
                            }
                            KeyCode::Down => {
                                let filtered_items = self.filter_proxies(&proxy_items, &search_input);
                                if !filtered_items.is_empty() {
                                    let i = match list_state.selected() {
                                        Some(i) => {
                                            if i >= filtered_items.len() - 1 {
                                                0
                                            } else {
                                                i + 1
                                            }
                                        }
                                        None => 0,
                                    };
                                    list_state.select(Some(i));
                                }
                            }
                            KeyCode::Up => {
                                let filtered_items = self.filter_proxies(&proxy_items, &search_input);
                                if !filtered_items.is_empty() {
                                    let i = match list_state.selected() {
                                        Some(i) => {
                                            if i == 0 {
                                                filtered_items.len() - 1
                                            } else {
                                                i - 1
                                            }
                                        }
                                        None => 0,
                                    };
                                    list_state.select(Some(i));
                                }
                            }
                            KeyCode::Enter => {
                                let filtered_items = self.filter_proxies(&proxy_items, &search_input);
                                if let Some(i) = list_state.selected() {
                                    if i < filtered_items.len() {
                                        break Some(filtered_items[i].0.clone());
                                    }
                                }
                            }
                            _ => {}
                        }
                    }
                }
            }
        };
        
        // 恢复终端
        disable_raw_mode()?;
        execute!(
            terminal.backend_mut(),
            LeaveAlternateScreen,
            DisableMouseCapture
        )?;
        terminal.show_cursor()?;
        
        // 处理选择结果
        if let Some(selected_proxy_id) = result {
            ui.print_success(&format!("🎉 已选择代理: {}", selected_proxy_id));
            self.switch_proxy(&selected_proxy_id, ui)?;
        } else {
            ui.print_info("🚫 已取消选择");
        }
        
        Ok(())
    }
    
    /// 绘制 ratatui UI 界面
    fn draw_ui(
        &self,
        f: &mut Frame,
        proxy_items: &[(String, ProxyConfig)],
        list_state: &mut ListState,
        current_proxy: Option<&str>,
        search_input: &str,
        search_mode: bool,
    ) {
        // 获取过滤后的代理列表
        let filtered_items = self.filter_proxies(proxy_items, search_input);
        
        // 计算弹出窗口大小（35%宽度，40%高度，带最小尺寸限制）
        let area = f.area();
        let popup_width = std::cmp::min(std::cmp::max((area.width * 35) / 100, 150), area.width);
        let popup_height = std::cmp::min(std::cmp::max((area.height * 40) / 100, 40), area.height);
        let popup_x = if area.width > popup_width { (area.width - popup_width) / 2 } else { 0 };
        let popup_y = if area.height > popup_height { (area.height - popup_height) / 2 } else { 0 };
        
        let popup_area = Rect {
            x: popup_x,
            y: popup_y,
            width: popup_width,
            height: popup_height,
        };
        
        // 清除弹出窗口区域
        f.render_widget(Clear, popup_area);
        
        // 弹出窗口主框架
        let popup_block = Block::default()
            .title("🚀 Claude Proxy 选择器")
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Cyan));
        f.render_widget(popup_block, popup_area);
        
        // 弹出窗口内部布局：上方内容区域 + 底部帮助信息（3行）
        let inner_area = popup_area.inner(Margin { vertical: 1, horizontal: 1 });
        let main_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Min(0), Constraint::Length(3)])
            .split(inner_area);
        
        // 内容区域：左侧列表 + 右侧详情
        let content_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Percentage(50), // 左侧占50%
                Constraint::Percentage(50)  // 右侧占50%
            ])
            .split(main_chunks[0]);
        
        // 左侧：代理列表
        let items: Vec<ListItem> = filtered_items
            .iter()
            .enumerate()
            .map(|(i, (proxy_id, proxy_config))| {
                let is_current = Some(proxy_id.as_str()) == current_proxy;
                let is_selected = list_state.selected() == Some(i);
                
                let status_icon = if is_current { "✅" } else { "🔘" };
                let status_text = if is_current { " ⭐ 当前" } else { "" };
                
                // 格式化URL显示
                let display_url = if let Ok(parsed_url) = url::Url::parse(&proxy_config.url) {
                    if let Some(host) = parsed_url.host_str() {
                        if host.starts_with("www.") {
                            host[4..].to_string()
                        } else {
                            host.to_string()
                        }
                    } else {
                        proxy_config.url.clone()
                    }
                } else {
                    proxy_config.url.clone()
                };
                
                let content = format!(
                    "{} {} │ {} │ {}{}",
                    status_icon,
                    proxy_id.to_uppercase(),
                    proxy_config.name,
                    display_url,
                    status_text
                );
                
                let style = if is_selected {
                    Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD)
                } else if is_current {
                    Style::default().fg(Color::Green)
                } else {
                    Style::default()
                };
                
                ListItem::new(Line::from(Span::styled(content, style)))
            })
            .collect();
        
        let list_title = if search_mode {
            format!("🔍 代理列表 (搜索: {})", search_input)
        } else {
            "📋 Claude 代理列表".to_string()
        };
        
        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title(list_title)
            )
            .highlight_style(
                Style::default()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD)
            );
        
        f.render_stateful_widget(list, content_chunks[0], list_state);
        
        // 右侧：详细信息
        let detail_content = if let Some(selected_index) = list_state.selected() {
            if selected_index < filtered_items.len() {
                let (proxy_id, proxy_config) = &filtered_items[selected_index];
                
                // 创建美化的JSON显示
                let mut json_lines = Vec::new();
                json_lines.push("┌─ 📋 代理配置信息 ─────────────────┐".to_string());
                json_lines.push("│".to_string());
                json_lines.push("│ {".to_string());
                
                // ID
                json_lines.push(format!("│   \"🆔 id\": \"{}\",", proxy_id));
                
                // Name
                json_lines.push(format!("│   \"📝 name\": \"{}\",", proxy_config.name));
                
                // URL
                json_lines.push(format!("│   \"🌐 url\": \"{}\",", proxy_config.url));
                
                // API Key (masked)
                if let Some(api_key) = &proxy_config.api_key {
                    let masked_key = if api_key.len() > 8 {
                        format!("{}***{}", &api_key[..4], &api_key[api_key.len()-4..])
                    } else {
                        "***".to_string()
                    };
                    json_lines.push(format!("│   \"🔑 api_key\": \"{}\",", masked_key));
                }
                
                // Auth Token (masked)
                if let Some(auth_token) = &proxy_config.auth_token {
                    let masked_token = if auth_token.len() > 8 {
                        format!("{}***{}", &auth_token[..4], &auth_token[auth_token.len()-4..])
                    } else {
                        "***".to_string()
                    };
                    json_lines.push(format!("│   \"🎫 auth_token\": \"{}\",", masked_token));
                }
                
                // Current status
                let is_current = Some(proxy_id.as_str()) == current_proxy;
                let status_icon = if is_current { "✅" } else { "⭕" };
                json_lines.push(format!("│   \"📊 is_current\": {}", if is_current { "true" } else { "false" }));
                
                json_lines.push("│ }".to_string());
                json_lines.push("│".to_string());
                json_lines.push(format!("└─ 状态: {} {} ─────────────────────┘", status_icon, if is_current { "当前激活" } else { "未激活" }));
                
                json_lines.join("\n")
            } else {
                "┌─ ⚠️  提示 ─────────────────────────┐\n│                                    │\n│        无选中项                    │\n│                                    │\n└────────────────────────────────────┘".to_string()
            }
        } else {
            "┌─ 💡 使用提示 ──────────────────────┐\n│                                    │\n│   请选择一个代理查看详细信息       │\n│                                    │\n│   ⬆️⬇️ 上下选择                     │\n│   Enter 确认切换                   │\n│   / 搜索模式                       │\n│   ESC 退出                         │\n│                                    │\n└────────────────────────────────────┘".to_string()
        };
        
        let detail_paragraph = Paragraph::new(detail_content)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("📄 代理详细信息")
            )
            .wrap(Wrap { trim: true });
        
        f.render_widget(detail_paragraph, content_chunks[1]);
        
        // 底部帮助信息
        let help_text = if search_mode {
            "Enter: 确认搜索 | Esc: 取消搜索 | 输入: 搜索内容"
        } else {
            "↑↓: 选择 | Enter: 确认 | /: 搜索 | q/Esc: 退出"
        };
        
        let help_paragraph = Paragraph::new(help_text)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("💡 操作提示")
            )
            .style(Style::default().fg(Color::Cyan));
        
        f.render_widget(help_paragraph, main_chunks[1]);
    }
    
    /// 过滤代理列表（排除 api_xxx 项目）
    fn filter_proxies(
        &self,
        proxy_items: &[(String, ProxyConfig)],
        search_input: &str,
    ) -> Vec<(String, ProxyConfig)> {
        proxy_items
            .iter()
            .filter(|(proxy_id, proxy_config)| {
                // 排除 api_xxx 项目
                if proxy_id.starts_with("api_") {
                    return false;
                }
                
                // 如果有搜索输入，进行模糊匹配
                if !search_input.is_empty() {
                    let search_lower = search_input.to_lowercase();
                    proxy_id.to_lowercase().contains(&search_lower)
                        || proxy_config.name.to_lowercase().contains(&search_lower)
                        || proxy_config.url.to_lowercase().contains(&search_lower)
                } else {
                    true
                }
            })
            .cloned()
            .collect()
    }
    
    /// 切换到指定代理
    pub fn switch_proxy(&mut self, proxy_id: &str, ui: &UI) -> Result<()> {
        let config = self.config_manager.load_config()
            .context("无法加载配置文件")?;
        
        let proxy_config = config.proxies.get(proxy_id)
            .context(format!("代理 '{}' 不存在", proxy_id))?;
        
        // 验证认证信息
        if proxy_config.api_key.is_none() && proxy_config.auth_token.is_none() {
            return Err(anyhow::anyhow!("代理 '{}' 缺少认证信息 (api_key 或 auth_token)", proxy_id));
        }
        
        // 设置环境变量
        self.env_manager.set_proxy_env(proxy_id, proxy_config, true, ui)?;
        
        // 保存当前代理ID
        self.config_manager.save_current_proxy(proxy_id)
            .context("无法保存当前代理ID")?;
        
        Ok(())
    }
    
    /// 添加新代理
    pub fn add_proxy(
        &mut self, 
        proxy_id: &str, 
        name: &str, 
        url: &str, 
        api_key: Option<&str>, 
        auth_token: Option<&str>,
        ui: &UI
    ) -> Result<()> {
        // 验证认证参数
        if api_key.is_none() && auth_token.is_none() {
            return Err(anyhow::anyhow!("必须提供api_key或auth_token中的至少一个"));
        }
        
        let mut config = self.config_manager.load_config()
            .context("无法加载配置文件")?;
        
        // 检查代理是否已存在
        if config.proxies.contains_key(proxy_id) {
            ui.print_warning(&format!("代理 '{}' 已存在，将被覆盖", proxy_id));
        }
        
        // 创建新代理配置
        let proxy_config = ProxyConfig {
            name: name.to_string(),
            url: url.to_string(),
            api_key: api_key.map(|s| s.to_string()),
            auth_token: auth_token.map(|s| s.to_string()),
        };
        
        // 添加到配置
        config.proxies.insert(proxy_id.to_string(), proxy_config);
        
        // 保存配置
        self.config_manager.save_config(&config)
            .context("无法保存配置文件")?;
        
        ui.print_success(&format!("代理 '{}' 已成功添加到配置文件", proxy_id));
        
        Ok(())
    }
    
    /// 删除代理
    pub fn remove_proxy(&mut self, proxy_id: &str, ui: &UI) -> Result<()> {
        let mut config = self.config_manager.load_config()
            .context("无法加载配置文件")?;
        
        let proxy_config = config.proxies.get(proxy_id)
            .context(format!("代理 '{}' 不存在", proxy_id))?;
        
        let proxy_name = proxy_config.name.clone();
        
        // 确认删除
        let message = format!("确定要删除代理 '{}' ({}) 吗?", proxy_id, proxy_name);
        if !ui.ask_confirmation(&message) {
            ui.print_info("取消删除操作");
            return Ok(());
        }
        
        // 删除代理
        config.proxies.remove(proxy_id);
        
        // 保存配置
        self.config_manager.save_config(&config)
            .context("无法保存配置文件")?;
        
        // 如果删除的是当前代理，清除环境变量
        if let Ok(Some(current_proxy)) = self.config_manager.load_current_proxy() {
            if current_proxy == proxy_id {
                self.env_manager.clear_all_env();
                let _ = self.config_manager.clear_current_proxy();
                ui.print_info("已清除当前代理的环境变量");
            }
        }
        
        ui.print_success(&format!("代理 '{}' 已成功删除", proxy_id));
        
        Ok(())
    }
    
    /// 显示当前状态
    pub fn show_status(&self, ui: &UI) -> Result<()> {
        ui.print_header("📊 当前Claude代理状态");
        ui.print_separator();
        
        // 显示当前代理信息
        let env_status = self.env_manager.get_env_status();
        
        if let Some(proxy_id) = &env_status.proxy_id {
            ui.print_info(&format!("当前代理: {}", proxy_id));
            
            // 尝试获取代理名称
            if let Ok(config) = self.config_manager.load_config() {
                if let Some(proxy_config) = config.proxies.get(proxy_id) {
                    ui.print_info(&format!("代理名称: {}", proxy_config.name));
                }
            }
        } else {
            ui.print_error("当前代理: 未设置");
        }
        
        println!();
        
        // 显示环境变量状态
        self.env_manager.show_env_status(ui);
        
        Ok(())
    }
    
    /// 重新加载配置
    pub fn reload_config(&mut self, ui: &UI) -> Result<()> {
        ui.print_header("🔄 重新加载Claude代理配置");
        ui.print_separator();
        
        // 验证配置文件
        if !self.config_manager.config_exists() {
            return Err(anyhow::anyhow!("配置文件不存在: {}", self.config_manager.config_file().display()));
        }
        
        // 尝试加载配置文件
        let config = self.config_manager.load_config()
            .context("配置文件格式错误")?;
        
        ui.print_info("配置文件验证通过");
        
        // 重新应用当前代理设置
        if let Ok(Some(current_proxy_id)) = self.config_manager.load_current_proxy() {
            if let Some(proxy_config) = config.proxies.get(&current_proxy_id) {
                ui.print_info("重新应用当前代理配置...");
                self.env_manager.set_proxy_env(&current_proxy_id, proxy_config, false, ui)?;
                ui.print_success(&format!("已重新加载代理: {} ({})", proxy_config.name, current_proxy_id));
            } else {
                ui.print_warning(&format!("当前代理 '{}' 在配置文件中不存在", current_proxy_id));
                ui.print_info("清除当前代理设置...");
                self.env_manager.clear_all_env();
                let _ = self.config_manager.clear_current_proxy();
                ui.print_success("已清除无效的代理设置");
            }
        } else {
            ui.print_info("当前未设置任何代理");
        }
        
        println!();
        ui.print_subheader("📋 可用代理列表:");
        ui.print_short_separator();
        
        // 显示所有可用代理
        if config.proxies.is_empty() {
            ui.print_warning("配置文件中没有任何代理配置");
        } else {
            let current_proxy = self.env_manager.get_env_status().proxy_id;
            for (proxy_id, proxy_config) in &config.proxies {
                if current_proxy.as_ref() == Some(proxy_id) {
                    ui.print_current_proxy(proxy_id, &proxy_config.name);
                } else {
                    ui.print_proxy(proxy_id, &proxy_config.name, &proxy_config.url);
                }
            }
            ui.print_success(&format!("配置重新加载完成 ({} 个代理)", config.proxies.len()));
        }
        
        Ok(())
    }
    
    /// 初始化配置
    pub fn init_config(&mut self, ui: &UI) -> Result<()> {
        if self.config_manager.config_exists() {
            ui.print_warning("配置文件已存在");
            let message = "是否要重新初始化配置文件? (这将覆盖现有配置)";
            if !ui.ask_confirmation(message) {
                ui.print_info("取消初始化操作");
                return Ok(());
            }
        }
        
        // 创建默认配置
        let _config = self.config_manager.create_default_config()
            .context("无法创建默认配置")?;
        
        ui.print_success(&format!("配置文件已创建: {}", self.config_manager.config_file().display()));
        ui.print_info("请编辑配置文件添加你的代理站信息");
        
        Ok(())
    }
}