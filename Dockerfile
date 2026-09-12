FROM node:22

ENV CI=true
ENV NODE_OPTIONS=--max-old-space-size=3072

# 构建时由 CI 传入 Git 提交号（见 Jenkinsfile.ci 的 docker build --build-arg）
# 目前只用于写进镜像元数据，方便从镜像反查源码
ARG GIT_COMMIT=unknown

# 装 nginx 反代层
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

COPY nginx-dsh.conf /etc/nginx/conf.d/dsh.conf
COPY docker-entrypoint.sh /usr/local/bin/dsh-entrypoint
RUN chmod +x /usr/local/bin/dsh-entrypoint && rm -f /etc/nginx/sites-enabled/default

WORKDIR /app

COPY . .

RUN corepack enable && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm install --frozen-lockfile && \
    pnpm run build

# 镜像元数据：从镜像可反查源码提交
LABEL org.opencontainers.image.revision=$GIT_COMMIT

EXPOSE 8082
ENTRYPOINT ["/usr/local/bin/dsh-entrypoint"]
