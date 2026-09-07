FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        tzdata \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        unzip \
        wget \
        zip \
        python3 \
        python3-boto3 \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# NodeJS (validation + CloudFront invalidation)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws

WORKDIR /opt/weblablv
COPY . .

RUN npm install --omit=dev \
    && npm cache clean --force \
    && rm -rf /tmp/*

RUN echo "\n====== Package versions ======" > /root/versions.txt \
    && echo "\n=== AWS CLI version ===" >> /root/versions.txt \
    && aws --version >> /root/versions.txt \
    && echo "\n=== Node version ===" >> /root/versions.txt \
    && node -v >> /root/versions.txt \
    && echo "\n=== NPM version ===" >> /root/versions.txt \
    && npm -v >> /root/versions.txt 2>&1 \
    && echo "\n=== Python version ===" >> /root/versions.txt \
    && python3 --version >> /root/versions.txt \
    && echo "\n================================\n\n" >> /root/versions.txt
