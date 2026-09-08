FROM node:22              # ← 改这个（glibc）

ENV CI=true
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches ./patches    # ← 保留，install 需要
COPY scripts ./scripts    # ← 保留，postinstall 需要

RUN corepack enable && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm install --frozen-lockfile

COPY . .

EXPOSE 3000
CMD ["pnpm", "dsh", "web"]