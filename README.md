# airlattice nginx

Nginx reverse proxy with Let's Encrypt TLS for:
- ai.airlattice.com -> 5173
- cash.airlattice.com -> 8081

## Prereqs
- DNS A/AAAA records point both domains to this server.
- Shared Docker network: `nginx-net`.
- app containers join `nginx-net` and are reachable by their service names.

## One-time setup (manual)
1) Create shared network (if not already):
   - `docker network create nginx-net`

2) Update app compose files to use the same network and service names used in nginx:
   - `ai_app` on port 5173
   - `cash_app` on port 8081
   - Example snippet:
     - `networks: { nginx-net: { external: true } }`
     - service `networks: [nginx-net]`

3) Initialize certificates (first time only):
   - `chmod +x scripts/init-certbot.sh`
   - `EMAIL=you@airlattice.com scripts/init-certbot.sh`

4) Start all services:
   - `docker compose up -d`

## Notes
- Nginx will redirect HTTP to HTTPS except for the ACME challenge path.
- Certbot container renews certificates every 12 hours.
- If your app service names differ, update `proxy_pass` targets in `nginx/conf.d/airlattice.conf`.
