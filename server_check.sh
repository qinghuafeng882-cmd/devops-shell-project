#!/bin/bash
set -u

report="server_check_$(date +%Y%m%d_%H%M%S).txt"
has_problem=0

disk_threshold=80
memory_threshold=500

default_services=("nginx" "ssh" )
ports=("22" "80" "443")

write_log() {
    msg="$1"
    echo "$msg" | tee -a "$report"
}

mark_problem() {
    has_problem=1
}

print_header() {
    echo "======================================" > "$report"
    write_log "DevOps 服务器巡检报告"
    write_log "======================================"
    write_log "主机名：$(hostname)"
    write_log "检查时间：$(date)"
    write_log "报告文件：$report"
    write_log ""
}

check_system_info() {
    write_log "一、系统基础信息"
    write_log "--------------------------------------"

    if [ -f /etc/os-release ]; then
        cat /etc/os-release | head -n 3 | tee -a "$report"
    else
        write_log "[WARNING] /etc/os-release 文件不存在"
        mark_problem
    fi

    write_log ""
}

check_load() {
    write_log "二、系统负载"
    write_log "--------------------------------------"
    uptime | tee -a "$report"
    write_log ""
}

check_disk() {
    mount_point="$1"
    threshold="$2"

    write_log "三、磁盘检查"
    write_log "--------------------------------------"

    disk_usage=$(df -h "$mount_point" | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ -z "$disk_usage" ]; then
        write_log "[ERROR] 无法获取磁盘使用率：$mount_point"
        mark_problem
    elif [ "$disk_usage" -ge "$threshold" ]; then
        write_log "[WARNING] 磁盘使用率较高：$mount_point ${disk_usage}%"
        mark_problem
    else
        write_log "[OK] 磁盘使用率正常：$mount_point ${disk_usage}%"
    fi

    df -h | tee -a "$report"
    write_log ""
}

check_memory() {
    threshold="$1"

    write_log "四、内存检查"
    write_log "--------------------------------------"

    mem_available=$(free -m | awk '/Mem:/ {print $7}')

    if [ -z "$mem_available" ]; then
        write_log "[ERROR] 无法获取 available 内存"
        mark_problem
    elif [ "$mem_available" -lt "$threshold" ]; then
        write_log "[WARNING] 可用内存较低：${mem_available}MB"
        mark_problem
    else
        write_log "[OK] 可用内存正常：${mem_available}MB"
    fi

    free -h | tee -a "$report"
    write_log ""
}

check_service() {
    svc="$1"

    if systemctl is-active --quiet "$svc"; then
        write_log "[OK] 服务运行正常：$svc"
    else
        write_log "[ERROR] 服务未运行：$svc"
        mark_problem
    fi
}

check_services() {
    write_log "五、服务检查"
    write_log "--------------------------------------"

    if [ "$#" -gt 0 ]; then
        services=("$@")
    else
        services=("${default_services[@]}")
    fi

    for svc in "${services[@]}"; do
        check_service "$svc"
    done

    write_log ""
}

check_port() {
    port="$1"

    if ss -lnt | awk '{print $4}' | grep -q ":$port$"; then
        write_log "[OK] 端口正在监听：$port"
    else
        write_log "[ERROR] 端口未监听：$port"
        mark_problem
    fi
}

check_ports() {
    write_log "六、端口检查"
    write_log "--------------------------------------"

    for port in "${ports[@]}"; do
        check_port "$port"
    done

    write_log ""
}

check_http() {
    url="$1"

    write_log "七、HTTP 检查"
    write_log "--------------------------------------"

    status_code=$(curl -o /dev/null -s -w "%{http_code}" "$url")

    if [ "$status_code" -eq 200 ]; then
        write_log "[OK] HTTP 访问正常：$url 状态码 $status_code"
    else
        write_log "[WARNING] HTTP 访问异常：$url 状态码 $status_code"
        mark_problem
    fi

    write_log ""
}

check_nginx_config() {
    write_log "八、Nginx 配置检查"
    write_log "--------------------------------------"

    if [ -f /etc/nginx/nginx.conf ]; then
        write_log "[OK] Nginx 主配置文件存在"
    else
        write_log "[ERROR] Nginx 主配置文件不存在"
        mark_problem
    fi

    if [ -d /var/log/nginx ]; then
        write_log "[OK] Nginx 日志目录存在"
    else
        write_log "[ERROR] Nginx 日志目录不存在"
        mark_problem
    fi

    if command -v nginx >/dev/null 2>&1; then
        if nginx -t >/dev/null 2>&1; then
            write_log "[OK] Nginx 配置语法正常"
        else
            write_log "[ERROR] Nginx 配置语法错误"
            mark_problem
        fi
    else
        write_log "[WARNING] 未检测到 nginx 命令"
        mark_problem
    fi

    write_log ""
}

collect_nginx_error_log() {
    write_log "九、Nginx 最近错误日志"
    write_log "--------------------------------------"

    if [ -f /var/log/nginx/error.log ]; then
        tail -n 20 /var/log/nginx/error.log | tee -a "$report"
    else
        write_log "[WARNING] /var/log/nginx/error.log 不存在"
        mark_problem
    fi

    write_log ""
}

print_summary() {
    write_log "十、巡检结论"
    write_log "--------------------------------------"

    if [ "$has_problem" -eq 0 ]; then
        write_log "[OK] 巡检完成，未发现明显异常"
        write_log "退出码：0"
        exit 0
    else
        write_log "[WARNING] 巡检完成，发现异常或告警，请查看报告"
        write_log "退出码：2"
        exit 2
    fi
}

main() {
    print_header
    check_system_info
    check_load
    check_disk "/" "$disk_threshold"
    check_memory "$memory_threshold"
    check_services "$@"
    check_ports
    check_http "http://127.0.0.1"
    check_nginx_config
    collect_nginx_error_log
    print_summary
}

main "$@"
