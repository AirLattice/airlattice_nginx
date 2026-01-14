#!/bin/sh
set -eu

if [ -z "${EMAIL:-}" ]; then
  echo "ERROR: Set EMAIL env var, e.g. EMAIL=you@airlattice.com"
  exit 1
fi

DOMAINS="ai.airlattice.com cash.airlattice.com"
RSA_KEY_SIZE=4096
DATA_PATH="./certbot"
STAGING="${STAGING:-0}"

echo "Creating dummy certificates..."
for domain in $DOMAINS; do
  mkdir -p "$DATA_PATH/conf/live/$domain"
  docker compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1 \
      -keyout '/etc/letsencrypt/live/$domain/privkey.pem' \
      -out '/etc/letsencrypt/live/$domain/fullchain.pem' \
      -subj '/CN=localhost'" certbot
done

echo "Starting nginx..."
docker compose up -d nginx

echo "Deleting dummy certificates..."
for domain in $DOMAINS; do
  rm -rf "$DATA_PATH/conf/live/$domain"
done

echo "Requesting real certificates..."
staging_arg=""
if [ "$STAGING" -eq 1 ]; then
  staging_arg="--staging"
fi

docker compose run --rm --entrypoint "certbot" certbot certonly \
  --webroot -w /var/www/certbot \
  $staging_arg \
  --email "$EMAIL" --agree-tos --no-eff-email \
  $(printf -- " -d %s" $DOMAINS)

echo "Reloading nginx..."
docker compose exec nginx nginx -s reload

echo "Done."
