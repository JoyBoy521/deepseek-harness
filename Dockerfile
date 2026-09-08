FROM node:22-alpine

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches ./patches
COPY scripts ./scripts
RUN corepack enable && pnpm install --frozen-lockfile

COPY . .

EXPOSE 3000

CMD ["pnpm", "dsh", "web"]