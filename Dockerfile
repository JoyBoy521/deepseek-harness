FROM node:22

ENV CI=true

WORKDIR /app

COPY . .

RUN corepack enable && \
    pnpm config set registry https://registry.npmmirror.com && \
    pnpm install --frozen-lockfile

EXPOSE 3000
CMD ["pnpm", "dsh", "web"]