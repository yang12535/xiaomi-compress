#!/bin/bash
# 设置安全选项
set -euo pipefail

# 确保脚本可执行
chmod +x /compress.sh 2>/dev/null

# 输出环境信息到日志
LOG_DIR="/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/startup-$(date +%Y%m%d).log"

echo "===== 容器启动 [$(date)] =====" | tee "$LOG_FILE"
echo "执行用户: $(id)" | tee -a "$LOG_FILE"
echo "工作目录: $(pwd)" | tee -a "$LOG_FILE"
echo "PATH: $PATH" | tee -a "$LOG_FILE"

# 启动主脚本
echo "启动压缩脚本..." | tee -a "$LOG_FILE"
exec /compress.sh 2>&1 | tee -a "$LOG_FILE"
