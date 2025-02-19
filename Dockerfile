# 使用官方的 Golang 镜像作为基础构建镜像，指定平台为 amd64 和 arm64
FROM --platform=$BUILDPLATFORM golang:1.23 AS builder

# 设置容器内的工作目录
WORKDIR /app

# 将源代码复制到容器中
COPY . .

# 下载依赖项
RUN go mod download

# 构建二进制文件，根据目标平台进行交叉编译
ARG TARGETPLATFORM
RUN CGO_ENABLED=0 GOOS=linux GOARCH=$(echo $TARGETPLATFORM | cut -d '/' -f2) go build -v -o gotify-bark ./cmd/gotify-bark

# 使用轻量级的 Alpine 镜像作为最终基础镜像，指定平台为 amd64 和 arm64
FROM --platform=$TARGETPLATFORM alpine:latest

# 设置容器内的工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /app/gotify-bark .
# 设置二进制文件执行权限（可选，为了确保）
RUN chmod +x gotify-bark

# 暴露应用程序运行的端口
EXPOSE 8080

# 设置容器的入口点
ENTRYPOINT ["./gotify-bark"]

# 保留原有的 VOLUME 和 HEALTHCHECK（如果有的话，这里假设原 Dockerfile 中有相关内容，你可以根据实际情况调整）
VOLUME ["/app/data"]
HEALTHCHECK --interval=5s --timeout=3s CMD curl -f http://localhost:8080 || exit 1
