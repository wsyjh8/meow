# PR-C Dockerfile - multi-stage build for NestJS API
#
# Build context: apps/api (run `docker build -t meow-api:latest apps/api/`)
#
# Stage 1 (builder): full node:20 image to install all deps + nest build TS → dist/
# Stage 2 (runtime): node:20-alpine to ship a smaller production image with only
#                    runtime deps + dist/.
#
# NOT included in image (留 PR-D, see scope §0.5.1):
#   - apps/api/cdn-mock/  (audio mp3 files; in repo only as .gitkeep placeholder)
#   - apps/api/data/pronunciation/  (wav files; not in repo at all)
#
# These two assets are PR-A 起的预存生产化债务。PR-C 不在范围内修. PR-D 候选:
#   (a) audio mp3 + pronunciation wav 接 COS public-read URL
#   (b) 或 docker volume mount 把这两个目录从 server host 挂进 container
# 当前 Dockerfile 故意 NOT COPY 这两个目录, 避免传空目录让 release 用户误以为
# audio file 能 serve.

FROM node:20 AS builder
WORKDIR /app

# Copy manifests first for better layer caching
COPY package*.json ./
RUN npm ci

# Then copy source + build
COPY . .
RUN npm run build  # nest build → dist/

# ------------------------------------------------------------------------------

FROM node:20-alpine AS runtime
WORKDIR /app

# Production deps only (smaller image)
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Compiled NestJS bundle
COPY --from=builder /app/dist ./dist

# Note: audio-pipeline-staging is dev-only fixture (PR-B3 dev fallback removed
# in PR-C); excluded here. cdn-mock and data/pronunciation are NOT copied for
# the reasons above (PR-D scope).

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "dist/main.js"]
