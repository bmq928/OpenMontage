FROM python:3-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/root/.opencode/bin:${PATH}" \
    OPENCODE_CONFIG_CONTENT='{"permission":"allow"}'

# System deps: make (make setup), git + curl (opencode install, setup), ffmpeg (README prerequisite + render engine), build tools (Pillow/numpy wheels fallback)
RUN apt-get update && apt-get install -y --no-install-recommends \
    make \
    git \
    curl \
    ca-certificates \
    gnupg \
    ffmpeg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js 22 (README asks 18+; HyperFrames runtime needs >=22)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node --version && npm --version \
    && npx skills add JuliusBrussee/caveman vercel-labs/agent-browser mvanhorn/last30days-skill -g 

WORKDIR /app

COPY . .

# Full setup per README (pip reqs + remotion npm + piper-tts + hyperframes warm + .env)
RUN make setup

# opencode CLI
RUN curl -fsSL https://opencode.ai/install | bash \
    && ln -sf /root/.opencode/bin/opencode /usr/local/bin/opencode \
    && opencode --version


EXPOSE 4096

WORKDIR /app

CMD opencode serve --hostname 0.0.0.0 --port 4096
