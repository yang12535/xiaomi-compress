#!/bin/bash
OUTPUT_FILE="${1:-/logs/video_analysis.txt}"

echo "### 视频参数分析报告 ($(date))" > "$OUTPUT_FILE"
echo "系统信息: $(uname -a)" >> "$OUTPUT_FILE"
echo "FFmpeg版本: $(ffmpeg -version | head -n1)" >> "$OUTPUT_FILE"
echo "----------------------------------------" >> "$OUTPUT_FILE"

find /input -type f -name "*.mov" -print0 | while IFS= read -r -d '' video; do
    echo "分析文件: $video" >> "$OUTPUT_FILE"
    ffprobe -v error \
        -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate,bit_rate \
        -show_entries format=format_name,duration,size \
        -of default=nw=1:nk=1 \
        "$video" >> "$OUTPUT_FILE"
    echo "----------------------------------------" >> "$OUTPUT_FILE"
done

echo "✅ 分析完成. 报告保存在: $OUTPUT_FILE"
