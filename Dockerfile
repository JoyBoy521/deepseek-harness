FROM node:22-alpine

ENV CI=true

WORKDIR /app

# ============ Alpine 换阿里云源 ============
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# ============ npm 换淘宝镜像 ============
RUN npm config set registry https://registry.npmmirror.com

# ============ 全局安装 pnpm ============
RUN npm install -g pnpm@11.7.0

# ============ pnpm 换淘宝镜像 ============
RUN pnpm config set registry https://registry.npmmirror.com

# ============ 复制依赖清单 ============
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches ./patches
COPY scripts ./scripts

# ============ 安装依赖 ============
RUN pnpm install --frozen-lockfile

# ============ 复制代码 ============
COPY . .

EXPOSE 3000
CMD ["pnpm", "dsh", "web"]
