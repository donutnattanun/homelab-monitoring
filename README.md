# homelab-monitoring
This project demonstrates a production-style authentication and monitoring architecture using open-source components, designed for local homelab / internal infrastructure use.

The focus is not on UI polish, but on network isolation, auth boundaries, reverse proxy design

# Quick Start
  1.Clone Repository
``` bash
   git clone https://github.com/donutnattanun/homelab-monitoring
   cd homelab-monitoring
```
  2.One-Command Setup
```bash
  make up
```
### 🛠️ Makefile Commands

| Command        | Description                 |
| -------------- | --------------------------- |
| `make setup`   | setup env, cert, secrets   |
| `make up`      | setup + docker compose up   |
| `make down`    | stop containers             |
| `make restart` | restart system            |
| `make logs`    | monitor logs  realtime        |
| `make clean`   | clean (DB + secrets) |

## Architecture
```text
                ┌────────────┐
                │   Browser  │
                └─────┬──────┘
                      │ HTTPS
                ┌─────▼──────┐
                │   NGINX    │  ← Single public entrypoint
                │ReverseProxy│
                └───┬─────┬──┘
                    │     │
        auth_net ───┘     └─── monitor_net
          │                      │
   ┌──────▼──────┐       ┌───────▼────────┐
   │   Authelia  │       │   Grafana      │
   │ (Auth Core) │◄────▶│(Auth via Proxy)│
   └──────┬──────┘       └────────┬───────┘
          │                       │
   ┌──────▼──────┐        ┌───────▼────────┐
   │ PostgreSQL  │        │ Prometheus     │
   │ (Auth DB)   │        │ Node Exporter  │
   └─────────────┘        └────────────────┘

```
## Key Design Decisions
1. Single Public Entry Point (NGINX)

- Only NGINX exposes ports to the host

- All backend services are private Docker networks

- Prevents accidental service exposure

2. Centralized Authentication (Authelia)

- Authelia acts as a dedicated auth service

- NGINX uses auth_request to validate sessions

- Applications never implement auth logic themselves

3. Network Segmentation

| Network       | Purpose                      | Visibility    |
| ------------- | ---------------------------- | ------------- |
| `auth_net`    | Auth services (Authelia, DB) | Semi-internal |
| `monitor_net` | Monitoring stack             | Internal only |

This mirrors real infra separation between identity and workload domains.
4. Grafana Auth via Reverse Proxy

Grafana does not manage users directly.

Auth flow:

1. Request hits NGINX

2. NGINX checks session with Authelia

3. If allowed → injects user via header

4. Grafana trusts proxy (GF_AUTH_PROXY_ENABLED=true)

This avoids duplicated user databases and simplifies SSO.

## Services Overview

| Service       | Role                                |
| ------------- | ----------------------------------- |
| NGINX         | TLS termination + reverse proxy     |
| Authelia      | Authentication & session validation |
| PostgreSQL    | Authelia storage backend            |
| Grafana       | Monitoring UI (proxy-auth)          |
| Prometheus    | Metrics aggregation                 |
| Node Exporter | Host metrics                        |

## TLS Strategy (Important)

This project uses self-signed certificates for local development.

⚠️ Browsers will show a security warning.
This is expected.

### Why?

- This is a local homelab / infra demo

- Certificate trust is not the focus

- Avoids forcing users to install custom CAs

In production, certificates should be issued by a trusted CA (e.g. Let’s Encrypt).

