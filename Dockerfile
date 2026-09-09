FROM node:22

ENV CI=true
ENV NODE_OPTIONS=--max-old-space-size=3072

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

EXPOSE 8082
ENTRYPOINT ["/usr/local/bin/dsh-entrypoint"]