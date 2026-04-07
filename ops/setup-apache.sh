#!/usr/bin/env bash
set -euo pipefail

domain="${1:?domain required}"
upstream_port="${2:?upstream port required}"

site_conf="/etc/apache2/sites-available/${domain}.conf"
ssl_conf="/etc/apache2/sites-available/${domain}-le-ssl.conf"

default_cert_file="/etc/letsencrypt/live/${domain}/fullchain.pem"
default_cert_key_file="/etc/letsencrypt/live/${domain}/privkey.pem"

if [[ -f "${default_cert_file}" && -f "${default_cert_key_file}" ]]; then
  cert_file="${default_cert_file}"
  cert_key_file="${default_cert_key_file}"
elif [[ -f "${ssl_conf}" ]]; then
  cert_file="$(awk '/SSLCertificateFile/ { print $2; exit }' "${ssl_conf}")"
  cert_key_file="$(awk '/SSLCertificateKeyFile/ { print $2; exit }' "${ssl_conf}")"
else
  cert_file="${default_cert_file}"
  cert_key_file="${default_cert_key_file}"
fi

cat > "${site_conf}" <<EOF
<VirtualHost *:80>
    ServerName ${domain}
    ServerAlias www.${domain}

    RewriteEngine On
    RewriteCond %{SERVER_NAME} =www.${domain} [OR]
    RewriteCond %{SERVER_NAME} =${domain}
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOF

cat > "${ssl_conf}" <<EOF
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName ${domain}
    ServerAlias www.${domain}

    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"
    ProxyPass / http://127.0.0.1:${upstream_port}/
    ProxyPassReverse / http://127.0.0.1:${upstream_port}/

    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile ${cert_file}
    SSLCertificateKeyFile ${cert_key_file}
</VirtualHost>
</IfModule>
EOF

a2enmod proxy proxy_http headers rewrite ssl >/dev/null
apache2ctl configtest
systemctl reload apache2
