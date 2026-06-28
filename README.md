# DevOps Shell Project

这是一个基于 Shell 编写的 Linux 服务器自动化巡检工具，用于练习和展示 DevOps 基础能力。

该工具可以自动检查 Linux 服务器的服务状态、端口监听、磁盘使用率、可用内存、HTTP 状态码、Nginx 配置和错误日志，并生成巡检报告。

## 功能特性

- 检查系统基础信息
- 检查系统负载
- 检查根分区磁盘使用率
- 检查 available 可用内存
- 检查指定服务是否运行
- 检查常见端口是否监听
- 检查本机 HTTP 状态码
- 检查 Nginx 主配置文件
- 检查 Nginx 配置语法
- 收集 Nginx 最近错误日志
- 自动生成巡检报告
- 根据巡检结果返回退出码

## 项目结构

```text
devops-shell-project/
├── server_check.sh      # 服务器巡检脚本
├── README.md            # 项目说明文档
└── .gitignore           # Git 忽略规则
```

## 环境要求

- Linux 系统
- Bash
- systemd
- curl
- ss
- awk
- sed
- tee
- Nginx，可选，但脚本包含 Nginx 检查项

## 使用方法

克隆项目：

```bash
git clone https://github.com/你的用户名/devops-shell-project.git
```

进入项目目录：

```bash
cd devops-shell-project
```

直接执行巡检：

```bash
bash server_check.sh
```

检查指定服务：

```bash
bash server_check.sh nginx ssh docker
```

## 示例输出

```text
DevOps 服务器巡检报告
======================================
主机名：server01
检查时间：Sat Jun 27 15:30:00 CST 2026

[OK] 磁盘使用率正常：/ 45%
[OK] 可用内存正常：2048MB
[OK] 服务运行正常：nginx
[OK] 服务运行正常：ssh
[ERROR] 服务未运行：docker
[OK] 端口正在监听：22
[OK] 端口正在监听：80
[WARNING] 端口未监听：443
```

## 报告文件

脚本执行后会自动生成巡检报告文件，格式类似：

```text
server_check_20260627_153000.txt
```

报告文件已通过 `.gitignore` 忽略，不提交到 Git 仓库。

## 退出码说明

| 退出码 | 含义 |
|---|---|
| 0 | 巡检完成，未发现明显异常 |
| 2 | 巡检完成，但发现 WARNING 或 ERROR |

## 技术点

- Shell 变量
- Shell 函数
- for 循环
- 数组
- if 条件判断
- 命令退出码
- tee 输出到屏幕和文件
- awk / sed 文本处理
- systemctl 服务检查
- ss 端口检查
- curl HTTP 状态码检查
- Git 版本管理

## 后续优化方向

- 支持 `-h` 或 `--help` 查看帮助
- 支持自定义磁盘阈值
- 支持自定义内存阈值
- 支持自定义端口列表
- 支持 Docker 容器状态检查
- 支持 crontab 定时巡检
- 支持输出 JSON 格式
- 支持邮件或企业微信告警
- 支持批量巡检多台服务器
