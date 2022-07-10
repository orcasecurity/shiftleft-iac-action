FROM ghcr.io/orcasecurity/orca-cli:1.2.0

RUN apk --no-cache --update add bash nodejs npm

WORKDIR /app
# Docker tries to cache each layer as much as possible, to increase building speed.
# Therefore, commands which change rarely, must be in the beginning.
COPY package*.json ./
# Install dependencies using npm ci instead of npm install to avoid packages updating accidentally
RUN npm ci
# Copy the node_modules to the image:
COPY node_modules ./node_modules

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

