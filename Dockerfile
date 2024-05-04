FROM ruby:3.1-bullseye

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends lsb-release debian-archive-keyring ca-certificates gnupg gnupg2 apt-transport-https \
    dnsutils net-tools curl less screen rsync telnet wget \
    cron supervisor openssh-server logrotate git-core vim bzip2 locales \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  && { \
      echo '[program:cron]'; \
      echo 'command=/usr/sbin/cron -f'; \
  } >> /etc/supervisor/conf.d/cron.conf \
  \
  && mkdir -p /var/log/supervisor \
  && { \
    echo '[supervisord]'; \
    echo 'nodaemon=true'; \
  } >> /etc/supervisor/conf.d/supervisord.conf \
  \
  && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en: \
  \
  && mkdir -p /var/run/sshd \
  && { \
    echo '[program:sshd]'; \
    echo 'command=/usr/sbin/sshd -D'; \
  } >> /etc/supervisor/conf.d/sshd.conf

ENV LC_ALL en_US.UTF-8

RUN set -ex \
  && curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list \
  && echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900" > /etc/apt/preferences.d/99nginx \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y nginx \
  && { \
    echo '[program:nginx]'; \
    echo 'command=nginx -g "daemon off;"'; \
  } >> /etc/supervisor/conf.d/nginx.conf \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
  && mkdir -p /root/.ssh \
  && { \
    echo 'Host *'; \
    echo 'ServerAliveInterval=15'; \
    echo 'ServerAliveCountMax=6'; \
    echo 'ForwardAgent yes'; \
  } >> /root/.ssh/config \
  && mkdir -p /root/.bash.d \
  && touch /root/.app.bash \
  && { \
    echo 'source ~/.app.bash'; \
    echo "export TERM=xterm"; \
    echo "export PATH=$(echo $PATH)"; \
    echo "unset HISTFILE"; \
  } >> /root/.bashrc

WORKDIR /app

EXPOSE 22 80 3000
CMD ["sh", "-c", "env >> /etc/environment ; /usr/bin/supervisord"]
