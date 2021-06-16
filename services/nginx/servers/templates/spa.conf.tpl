server {
    set $host_path $APP_PATH_SRC/dist;

    # Certification location
    include snippets/ssl-certificates.conf;

    # Strong TLS + TLS Best Practices
    include snippets/ssl.conf;

    # Redirect www to non-www
    include snippets/www-to-non-www.conf;

    # server listen (HTTPS)
    listen 443 ssl http2;

    # # Matches with: sub.yourdomain.tld && client.sub.yourdomain.tld
    # server_name ~^(?<subdomain>client\.sub|sub)\.(?<domain>yourdomain\.tld)$;

    # # Matches: app.yourdomain.tld && mobile.yourdomain.tld
    # server_name ~^(?<subdomain>app|mobile)\.(?<domain>yourdomain\.tld)$;

    server_name .yourdomain.tld;

    root $host_path;

    index index.html;

    location / {
        sendfile off;
        open_file_cache off;
        include snippets/no-caching.conf;

        try_files $uri $uri/ @index;
    }

    location @index {
        include snippets/no-caching.conf;

        try_files /index.html$is_args$query_string =404;
    }

    # Several logs can be specified on the same level
    error_log /var/log/nginx/error.stderr.log warn;

    # Sets the path, format, and configuration for a buffered log write
    access_log /var/log/nginx/access.stdout.log main_json;

    include snippets/deny.conf;
    include snippets/cache-static.conf;
}
