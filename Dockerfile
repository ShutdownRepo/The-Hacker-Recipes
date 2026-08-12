# syntax=docker/dockerfile:1.7

# First container to build the npm project
FROM node:22-bookworm-slim AS builder

ENV NODE_ENV=production \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

WORKDIR /app

# VitePress needs Git to retrieve repository metadata during the build.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

RUN npm ci --include=dev

COPY . .

RUN npm run docs:build


# This container is used to self-host the website via an nginx-unprivileged container.
FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

LABEL org.opencontainers.image.title="The Hacker Recipes" \
      org.opencontainers.image.description="The Hacker Recipes self-hosted static website" \
      org.opencontainers.image.source="https://github.com/The-Hacker-Recipes/The-Hacker-Recipes"

COPY --chown=101:101 docker/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder --chown=101:101 /app/docs/.vitepress/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=5s \
            --retries=3 \
            CMD wget --spider -q http://127.0.0.1:8080/ || exit 1

USER 101:101

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]