FROM node:22

ENV CI=true

WORKDIR /app

COPY . .

RUN corepack enable && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm install --frozen-lockfile && \
    pnpm run build

EXPOSE 3080
CMD ["pnpm", "dsh", "web", "--patch", "/app/docker-patch.yml"]