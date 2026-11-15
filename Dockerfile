FROM php:8.4-fpm

COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions bcmath intl opcache pcntl pdo_mysql pdo_pgsql mysqli zip @composer \
    && apt-get update \
    && apt-get install -y --no-install-recommends nginx git unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

RUN cat > /etc/nginx/conf.d/ethiodeploy.conf <<'EOF'
server {
    listen __PORT__;
    listen [::]:__PORT__;

    root /app;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

RUN printf '#!/bin/sh\nset -e\nsed -i "s/__PORT__/${PORT:-3000}/g" /etc/nginx/conf.d/ethiodeploy.conf\nphp-fpm -D\nexec nginx -g "daemon off;"\n' > /start.sh \
    && chmod +x /start.sh

CMD ["/start.sh"]


