#!/bin/bash
LOG_DIR="/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/compress-$(date +%Y%m%d).log"

echo "===== 视频压缩启动 [$(date)] =====" | tee "$LOG_FILE"
echo "配置: mov→mkv | 2K→1080p | CRF32 | 音频copy | 单任务8线程 | 50%CPU | 严格检查成功后删源" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 生成待处理列表到数组
mapfile -t VIDEOS < <(find /input -type f -name "*.mov" 2>/dev/null)
total=${#VIDEOS[@]}

if [ "$total" -eq 0 ]; then
    echo "没有待处理的 mov 文件，退出" | tee -a "$LOG_FILE"
    exit 0
fi

echo "总计: $total 个 mov 文件，单任务8线程" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 处理单个文件（单线程循环）
idx=1
for video in "${VIDEOS[@]}"; do
    [ -z "$video" ] && continue
    [ ! -f "$video" ] && continue
    
    filename=$(basename "$video" .mov)
    dirpath=$(dirname "$video")
    relative_path="${dirpath#/input}"
    output_dir="/output${relative_path}"
    
    mkdir -p "$output_dir" || {
        echo "[$(date +%H:%M:%S)] [任务$idx] 错误: 无法创建目录 $output_dir" | tee -a "$LOG_FILE"
        continue
    }
    
    output_file="$output_dir/${filename}.mkv"
    
    # 跳过已存在的
    if [ -f "$output_file" ]; then
        output_size=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
        if [ "$output_size" -gt 10240 ]; then
            echo "[$(date +%H:%M:%S)] [任务$idx] 跳过已存在: ${relative_path}/${filename}.mkv" | tee -a "$LOG_FILE"
            idx=$((idx + 1))
            continue
        else
            echo "[$(date +%H:%M:%S)] [任务$idx] 删除无效旧文件: ${relative_path}/${filename}.mkv" | tee -a "$LOG_FILE"
            rm -f "$output_file"
        fi
    fi
    
    input_size=$(stat -c%s "$video" 2>/dev/null || echo 0)
    echo "[$(date +%H:%M:%S)] [任务$idx] 开始: ${relative_path}/${filename}.mov ($(numfmt --to=iec $input_size))" | tee -a "$LOG_FILE"
    
    temp_output="$output_dir/.${filename}.tmp.mkv"
    
    # 单任务8线程编码
    ffmpeg -hide_banner -v error -stats \
        -i "$video" \
        -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
        -c:v libx265 -preset medium -crf 32 -threads 8 \
        -c:a copy \
        -pix_fmt yuv420p \
        -movflags +faststart \
        "$temp_output" 2>&1 | tee -a "$LOG_FILE"
    
    ret=${PIPESTATUS[0]}
    
    if [ "$ret" -eq 0 ] && [ -f "$temp_output" ]; then
        output_size=$(stat -c%s "$temp_output" 2>/dev/null || echo 0)
        if [ "$output_size" -gt 1048576 ]; then
            if ffprobe -v error -show_format -show_streams "$temp_output" > /dev/null 2>&1; then
                mv "$temp_output" "$output_file"
                if [ -f "$output_file" ]; then
                    rm -f "$video"
                    echo "[$(date +%H:%M:%S)] [任务$idx] ✓ 完成: ${relative_path}/${filename}.mkv ($(numfmt --to=iec $output_size))" | tee -a "$LOG_FILE"
                else
                    echo "[$(date +%H:%M:%S)] [任务$idx] ✗ 移动失败: ${relative_path}/${filename}.mov" | tee -a "$LOG_FILE"
                fi
            else
                echo "[$(date +%H:%M:%S)] [任务$idx] ✗ 文件无效(ffprobe失败): ${relative_path}/${filename}.mov" | tee -a "$LOG_FILE"
                rm -f "$temp_output"
            fi
        else
            echo "[$(date +%H:%M:%S)] [任务$idx] ✗ 文件过小($(numfmt --to=iec $output_size)): ${relative_path}/${filename}.mov" | tee -a "$LOG_FILE"
            rm -f "$temp_output"
        fi
    else
        echo "[$(date +%H:%M:%S)] [任务$idx] ✗ 压缩失败(ffmpeg退出码:$ret): ${relative_path}/${filename}.mov" | tee -a "$LOG_FILE"
        rm -f "$temp_output"
    fi
    
    idx=$((idx + 1))
done

echo "" | tee -a "$LOG_FILE"
echo "===== 全部完成 [$(date)] =====" | tee -a "$LOG_FILE"
exit 0
