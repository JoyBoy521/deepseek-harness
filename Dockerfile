FROM node:22-alpine

ENV CI=true

WORKDIR /app

# 直接复制完整 node_modules
COPY node_modules ./node_modules

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps ./apps
COPY packages ./packages
COPY patches ./patches
COPY scripts ./scripts

EXPOSE 3000
CMD ["pnpm", "dsh", "web"]
