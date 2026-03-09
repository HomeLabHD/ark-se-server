# Documentation

| Guide | Description |
|-------|-------------|
| [Install](Install.md) | Docker, Docker Compose & Kubernetes setup |
| [Configuration](Configuration.md) | Environment variables & volume mounts |
| [Health Server](HealthServer.md) | Optional RCON health endpoint |
| [Clustering](Clustering.md) | Multi-map cluster with shared transfers |

## Templates

| File | Description |
|------|-------------|
| [docker-compose.yml](docker/docker-compose.yml) | Ready-to-use Compose file |
| [k8s/statefulset.yaml](k8s/statefulset.yaml) | Single-instance StatefulSet with health probes |
| [k8s/service.yaml](k8s/service.yaml) | LoadBalancer Service with session affinity |
| [k8s/network-policy.yaml](k8s/network-policy.yaml) | Ingress rules for game, RCON & health ports |
| [k8s/admin-list-server.yaml](k8s/admin-list-server.yaml) | HTTP admin/whitelist/banlist server (nginx + njs) |
