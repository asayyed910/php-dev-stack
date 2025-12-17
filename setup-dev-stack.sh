#!/usr/bin/env bash
set -e

echo "⚠️  This will DELETE existing docker dev stack folders."
echo "    ~/docker/dev-stack"
echo "    ~/docker/certs"
echo "    ~/docker/mysql-data"
echo ""
read -p "Type YES to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "❌ Aborted"
  exit 1
fi

BASE_DIR="$HOME/docker/dev-stack"

echo "🧹 Cleaning old setup..."
rm -rf "$HOME/docker/dev-stack"
rm -rf "$HOME/docker/certs"
rm -rf "$HOME/docker/mysql-data"

echo "📁 Creating directory structure..."
mkdir -p "$BASE_DIR"/{php,nginx,certs,mysql-data}

# ---------------------------
# docker-compose.yml
# ---------------------------
cat > "$BASE_DIR/docker-compose.yml" <<'EOF'
version: "3.8"

services:
  php:
    build: ./php
    container_name: dev_php
    volumes:
      - ~/Projects:/var/www
    working_dir: /var/www
    networks:
      - dev_net
    depends_on:
      - mysql
      - mailhog

  nginx:
    image: nginx:alpine
    container_name: dev_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ~/Projects:/var/www
      - ./nginx:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
    networks:
      - dev_net
    depends_on:
      - php
      - mailhog

  mysql:
    image: mysql:5.7
    container_name: dev_mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: default
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
    ports:
      - "3306:3306"
    volumes:
      - ./mysql-data:/var/lib/mysql
    networks:
      - dev_net

  mailhog:
    image: mailhog/mailhog:latest
    container_name: dev_mailhog
    ports:
      - "1025:1025"
      - "8025:8025"
    networks:
      - dev_net

networks:
  dev_net:
EOF

# ---------------------------
# PHP Dockerfile
# ---------------------------
cat > "$BASE_DIR/php/Dockerfile" <<'EOF'
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev libxml2-dev \
    libzip-dev libicu-dev nodejs npm \
    && docker-php-ext-install pdo pdo_mysql mbstring zip intl gd

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www
EOF

# ---------------------------
# Nginx default.conf
# ---------------------------
cat > "$BASE_DIR/nginx/default.conf" <<'EOF'
server {
    listen 80;
    server_name ~^(?<project>.+)\.test$;

    root /var/www/$project/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}

server {
    listen 443 ssl;
    server_name ~^(?<project>.+)\.test$;

    ssl_certificate     /etc/nginx/certs/dev.test.pem;
    ssl_certificate_key /etc/nginx/certs/dev.test-key.pem;

    root /var/www/$project/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF

# ---------------------------
# Nginx mailhog.conf
# ---------------------------
cat > "$BASE_DIR/nginx/mailhog.conf" <<'EOF'
server {
    listen 80;
    server_name mailhog.test;

    location / {
        proxy_pass http://mailhog:8025;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name mailhog.test;

    ssl_certificate     /etc/nginx/certs/dev.test.pem;
    ssl_certificate_key /etc/nginx/certs/dev.test-key.pem;

    location / {
        proxy_pass http://mailhog:8025;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

echo ""
echo "✅ Dev stack files created successfully"
echo ""
echo "📌 NEXT STEPS (manual, once):"
echo "1. Install mkcert:"
echo "   brew install mkcert && mkcert -install"
echo ""
echo "2. Generate certs:"
echo "   cd $BASE_DIR"
echo "   mkcert \"*.test\""
echo "   mv _wildcard.test.pem certs/dev.test.pem"
echo "   mv _wildcard.test-key.pem certs/dev.test-key.pem"
echo ""
echo "3. Start Docker:"
echo "   cd $BASE_DIR"
echo "   docker-compose up -d --build"
echo ""
echo "4. Open:"
echo "   https://society.test"
echo "   https://mailhog.test"
echo ""
echo "🎉 DONE"

