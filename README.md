# homelab-monitoring

## Architecture

- nginx: TLS termination + auth gateway
- authelia: authentication & session
- postgres: auth storage
- prometheus: metrics
- grafana: visualization

Networks:

- auth_net (internal)
- monitor_net (internal)
