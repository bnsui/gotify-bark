# 第一阶段：构建阶段
# 使用官方的Golang镜像作为基础镜像，设置构建平台
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS builder

# 设置容器内的工作目录
WORKDIR /app

# 优化：将 go mod 和 go sum 文件单独复制并下载依赖，利用缓存策略
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码到容器中
COPY . .

# 构建二进制文件，使用 CGO_ENABLED=0 以静态编译，支持跨平台
ARG TARGETPLATFORM
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d / -f2) go build -ldflags="-w -s" -v -o gotify-bark ./cmd/gotify-bark

# 第二阶段：运行阶段
# 使用更小的基础镜像
FROM alpine:latest

# 设置容器内的工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /app/gotify-bark .

# 暴露应用程序运行的端口
EXPOSE 8080

# 设置数据存储的挂载点
VOLUME /app/data

# 设置健康检查命令，假设应用有 /status 端点
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/status || exit 1

# 设置容器的入口点
ENTRYPOINT ["./gotify-bark"]
