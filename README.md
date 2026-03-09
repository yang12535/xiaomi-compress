# xiaomi-compress

小米视频压缩工具 - 使用 FFmpeg 将 MOV 视频批量压缩为 MKV (2K→1080p)

## 功能

- 批量处理 `.mov` 文件
- 2K 分辨率压缩至 1080p
- CRF 32 质量设置
- 音频直接复制（不重新编码）
- 单任务 8 线程，限制 50% CPU 使用
- 严格检查成功后删除源文件

## 使用方法

1. 将待压缩的 `.mov` 文件放入 `input/` 目录
2. 运行：
   ```bash
   docker-compose up
   ```
3. 压缩后的文件在 `output/` 目录

## 目录结构

```
.
├── input/          # 放置待压缩的 mov 文件
├── output/         # 压缩后的 mkv 文件
├── logs/           # 压缩日志
├── compress.sh     # 压缩脚本
├── analyze.sh      # 分析脚本
├── start.sh        # 启动脚本
└── docker-compose.yml
```

## 配置

修改 `docker-compose.yml` 可调整：
- CPU 限制（默认 8 核）
- 内存限制（默认 4G）

## 依赖

- Docker
- Docker Compose
