FROM node:20-alpine

ENV NODE_ENV=production
WORKDIR /app

# Install only production dependencies (layer is cached until package files change)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# config.js lives next to src/ because src/app.js requires '../config'
COPY config.js ./config.js
COPY src ./src

# Run as the unprivileged user that ships with the node image
USER node

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/api/health || exit 1

CMD ["node", "src/server.js"]
