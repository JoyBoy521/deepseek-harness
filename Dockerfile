FROM node:22-alpine

ENV CI=true

WORKDIR /app

# 先复制生产依赖
COPY node_modules_prod ./node_modules

# 再复制项目文件
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps ./apps
COPY packages ./packages
COPY patches ./patches
COPY scripts ./scripts

EXPOSE 3000
CMD ["pnpm", "dsh", "web"]
