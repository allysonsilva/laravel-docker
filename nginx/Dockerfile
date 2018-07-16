# docker build -t webserver:1.0 -f Dockerfile .
FROM nginx:1.15

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y vim wget curl openssl && \
    apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/*

# Pre generate some SSL
# YOU SHOULD REPLACE WITH YOUR OWN CERT.
RUN mkdir /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt -subj "/C=BR/ST=State/L=Location/O=Organization/OU=Organizational Unit/CN=*.web" && \
    openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/servers/app.conf /etc/nginx/conf.d/default.conf
COPY ./config/fastcgi.conf /etc/nginx/fastcgi.conf
COPY ./config/mime.types /etc/nginx/mime.types

# Be sure nginx is properly passing to php-fpm and fpm is responding
# HEALTHCHECK --interval=5s --timeout=3s \
#     CMD curl -f http://localhost/ || exit 1

# Expose webserver port
EXPOSE 80 443

COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
