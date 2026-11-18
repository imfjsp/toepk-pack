#!/bin/bash
# T'O EPK - instala Pterodactyl (panel 1.x + Wings) en Ubuntu 24.04, en una sola maquina de Google Cloud.
# Lo corre el startup-script de la VM; solo actua la primera vez (marca /root/.toepk-ptero-ok).
# Avance en /var/log/toepk-ptero.log y en la consola serie (lineas "[toepk]").
#
#   Panel:  https://<ip-con-guiones>.sslip.io      (certificado de Let's Encrypt)
#   Wings:  puerto 8080 (API) y 2022 (SFTP)        Minecraft: 25565
#
# No crea la cuenta de administrador: la contrasena la elige el dueno con
#   sudo php /var/www/pterodactyl/artisan p:user:make
set -uo pipefail
exec > >(tee -a /var/log/toepk-ptero.log) 2>&1
[ -f /root/.toepk-ptero-ok ] && { echo "[toepk] Pterodactyl ya instalado"; exit 0; }
say() { echo "[toepk] $*"; echo "$*" > /root/toepk-estado.txt; }
die() { say "ERROR: $*"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
# el startup-script corre sin HOME, y composer lo necesita
export HOME=/root COMPOSER_HOME=/root/.composer COMPOSER_ALLOW_SUPERUSER=1

IP=$(curl -fsS -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
[ -n "$IP" ] || die "sin IP externa"
FQDN="${IP//./-}.sslip.io"
say "1/8 paquetes ($FQDN)"
apt-get update -q
apt-get install -y -q software-properties-common curl apt-transport-https ca-certificates gnupg tar unzip git \
  php8.3 php8.3-common php8.3-cli php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-fpm \
  php8.3-curl php8.3-zip php8.3-intl mariadb-server nginx redis-server certbot python3-certbot-nginx \
  || die "apt fallo"
systemctl enable --now mariadb redis-server php8.3-fpm nginx

say "2/8 composer y panel"
[ -x /usr/local/bin/composer ] || curl -fsS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl
if [ ! -f artisan ]; then
  curl -fsSLo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz || die "descarga del panel"
  tar -xzf panel.tar.gz && rm -f panel.tar.gz
  chmod -R 755 storage/* bootstrap/cache/
fi

say "3/8 base de datos"
DBPASS_FILE=/root/.toepk-dbpass
[ -f $DBPASS_FILE ] || head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' > $DBPASS_FILE
DBPASS=$(cat $DBPASS_FILE)
mysql -u root <<SQL
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASS';
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DBPASS';
CREATE DATABASE IF NOT EXISTS panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

say "4/8 configuracion del panel"
[ -f .env ] || cp .env.example .env
composer install --no-dev --optimize-autoloader -n || die "composer install"
grep -q '^APP_KEY=base64' .env || php artisan key:generate --force
php artisan p:environment:setup -n --author=admin@example.com --url="https://$FQDN" --timezone=America/Santiago \
  --cache=redis --session=redis --queue=redis --redis-host=127.0.0.1 --redis-pass=null --redis-port=6379 \
  --settings-ui=true --telemetry=false || die "environment:setup"
php artisan p:environment:database -n --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl \
  --password="$DBPASS" || die "environment:database"
php artisan migrate --seed --force || die "migrate"
chown -R www-data:www-data /var/www/pterodactyl/*
(crontab -l 2>/dev/null | grep -v 'pterodactyl/artisan'; echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1') | crontab -
cat > /etc/systemd/system/pteroq.service <<'UNIT'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now pteroq.service

say "5/8 HTTPS (Let's Encrypt)"
rm -f /etc/nginx/sites-enabled/default
SSL=yes
certbot certonly --nginx -d "$FQDN" --non-interactive --agree-tos --register-unsafely-without-email || SSL=no
if [ "$SSL" = yes ]; then
  cat > /etc/nginx/sites-available/pterodactyl.conf <<NGX
server { listen 80; server_name $FQDN; return 301 https://\$server_name\$request_uri; }
server {
    listen 443 ssl http2;
    server_name $FQDN;
    root /var/www/pterodactyl/public;
    index index.php;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }
    location ~ /\.ht { deny all; }
}
NGX
  SCHEME=https
else
  say "AVISO: Let's Encrypt fallo; el panel queda en http (sin cifrar) hasta arreglarlo"
  sed -i "s#^APP_URL=.*#APP_URL=http://$FQDN#" .env
  cat > /etc/nginx/sites-available/pterodactyl.conf <<NGX
server {
    listen 80;
    server_name $FQDN;
    root /var/www/pterodactyl/public;
    index index.php;
    client_max_body_size 100m;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }
}
NGX
  SCHEME=http
fi
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
nginx -t && systemctl restart nginx

say "6/8 Docker y Wings"
command -v docker >/dev/null || { curl -fsSL https://get.docker.com/ | CHANNEL=stable bash || die "docker"; }
systemctl enable --now docker
mkdir -p /etc/pterodactyl /var/lib/pterodactyl/volumes
[ -x /usr/local/bin/wings ] || {
  curl -fsSLo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 \
  && chmod u+x /usr/local/bin/wings; } || die "descarga de wings"

say "7/8 nodo, puerto 25565 y servicio de Wings"
cd /var/www/pterodactyl
MEM=$(( $(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) - 2048 ))
php artisan p:location:make -n --short=cl --long="Santiago, Chile" >/dev/null 2>&1 || true
LOC=$(mysql -N -u root panel -e "SELECT id FROM locations WHERE short='cl' LIMIT 1")
NODE=$(mysql -N -u root panel -e "SELECT id FROM nodes WHERE name='toepk' LIMIT 1")
if [ -z "$NODE" ]; then
  php artisan p:node:make -n --name=toepk --description="Servidor T'O EPK" --locationId="$LOC" --fqdn="$FQDN" \
    --public=1 --scheme=$SCHEME --proxy=0 --maintenance=0 --maxMemory="$MEM" --overallocateMemory=0 \
    --maxDisk=40000 --overallocateDisk=0 --uploadSize=100 --daemonListeningPort=8080 --daemonSFTPPort=2022 \
    --daemonBase=/var/lib/pterodactyl/volumes || die "node:make"
  NODE=$(mysql -N -u root panel -e "SELECT id FROM nodes WHERE name='toepk' LIMIT 1")
fi
mysql -u root panel -e "INSERT INTO allocations (node_id, ip, port, created_at, updated_at)
  SELECT $NODE, '0.0.0.0', 25565, NOW(), NOW() FROM DUAL
  WHERE NOT EXISTS (SELECT 1 FROM allocations WHERE node_id=$NODE AND port=25565)"
php artisan p:node:configuration "$NODE" > /etc/pterodactyl/config.yml || die "node:configuration"
cat > /etc/systemd/system/wings.service <<'UNIT'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service
[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now wings

say "8/8 renovacion del certificado y swap"
[ "$SSL" = yes ] && (crontab -l 2>/dev/null | grep -v certbot; echo '0 23 * * * certbot renew --quiet --deploy-hook "systemctl restart nginx wings"') | crontab -
if ! swapon --show | grep -q /swapfile; then
  [ -f /swapfile ] || { fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null; }
  swapon /swapfile || true
  grep -q /swapfile /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
touch /root/.toepk-ptero-ok
say "LISTO panel=$SCHEME://$FQDN nodo=$NODE wings=$(systemctl is-active wings)"
