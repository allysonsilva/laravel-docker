FROM nginx:1.13

# Pre generate some SSL
# YOU SHOULD REPLACE WITH YOUR OWN CERT.
# RUN openssl req -x509 -nodes -days 3650 \
#     -newkey rsa:2048 -keyout /root/ssl/nginx.key \
#     -out /root/ssl/nginx.crt -subj "/C=Country/ST=State/L=Location/O=Organization/OU=Organizational Unit/CN=*.test" && \
#     openssl dhparam -out /root/ssl/dhparam.pem 2048

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y vim wget curl && \
    apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/*

COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/servers/app.conf /etc/nginx/conf.d/default.conf
COPY ./config/fastcgi.conf /etc/nginx/fastcgi.conf
COPY ./config/mime.types /etc/nginx/mime.types

# Be sure nginx is properly passing to php-fpm and fpm is responding
# HEALTHCHECK --interval=5s --timeout=3s \
#     CMD curl -f http://localhost/ping || exit 1

# Expose webserver port
EXPOSE 80 443 8080

COPY ./docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
