# Installation

## Docker

```bash
docker pull drpsychick/arkserver:latest
```

Run with default settings:
```bash
docker run -d \
    -v steam:/home/steam/.steam/steamapps \
    -v ark:/ark \
    -p 27015:27015 -p 27015:27015/udp \
    -p 7778:7778 -p 7778:7778/udp \
    -p 7777:7777 -p 7777:7777/udp \
    drpsychick/arkserver
```

If the exposed ports are modified (in the case of multiple containers/servers on the same host) the `arkmanager` config will need to be modified to reflect the change as well. This is required so that `arkmanager` can properly check the server status and so that the ARK server itself can properly publish its IP address and query port to steam.

## Docker Compose

A ready-to-use [docker-compose.yml](docker-compose.yml) is included:

```bash
docker compose up -d
```

Edit the environment variables in the compose file to customize your server. See [Configuration](Configuration.md) for all available options.

## Kubernetes

A StatefulSet is recommended over a Deployment — ARK servers are stateful and need persistent storage for save data, config, and server files.

### Key Concepts

**fsGroup**: The image runs as user `steam` (UID/GID `1001`). Set `securityContext.fsGroup: 1001` so mounted volumes are writable.

**Secrets**: Store `am_ark_ServerAdminPassword`, `am_ark_ServerPassword`, and `am_arkopt_clusterid` in a Kubernetes Secret and reference via `secretKeyRef` rather than plaintext env vars.

**Shared Server Files**: Set `ARKSERVER_SHARED=/arkserver` and mount a separate PVC at `/arkserver` to share the game binary across multiple map instances. Each instance still needs its own `/arkserver/ShooterGame/Saved` mount. See [Clustering](Clustering.md).

**Custom Ports**: When running multiple instances on the same node or behind a shared LoadBalancer IP, each server needs unique `am_ark_Port`, `am_ark_QueryPort`, and `am_ark_RCONPort` values. Set `am_arkNoPortDecrement=true` to prevent arkmanager from auto-adjusting ports.

**Mods**: Pass Steam Workshop mod IDs via `am_ark_GameModIds` as a comma-separated string. Mods are downloaded on first start and updated when `am_arkAutoUpdateOnStart=true`.

**Resources**: ARK servers are memory-heavy. Plan for 12-16Gi memory per instance. The server files themselves need ~250Gi of storage.

**Session Affinity**: Use `sessionAffinity: ClientIP` on the Service with a long timeout (3+ hours) to keep players connected to the same backend during long sessions.

### Single Instance

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: arkserver
spec:
  serviceName: arkserver
  replicas: 1
  selector:
    matchLabels:
      app: arkserver
  template:
    metadata:
      labels:
        app: arkserver
    spec:
      securityContext:
        fsGroup: 1001
      containers:
        - name: arkserver
          image: drpsychick/arkserver:latest
          ports:
            - containerPort: 27015
              protocol: UDP
              name: query
            - containerPort: 7778
              protocol: UDP
              name: game
            - containerPort: 7778
              protocol: TCP
              name: game-tcp
            - containerPort: 32330
              protocol: TCP
              name: rcon
            - containerPort: 8080
              protocol: TCP
              name: health
          env:
            - name: am_ark_SessionName
              value: "My ARK Server"
            - name: am_serverMap
              value: TheIsland
            - name: am_ark_ServerAdminPassword
              valueFrom:
                secretKeyRef:
                  name: ark-secrets
                  key: admin-password
            - name: am_ark_MaxPlayers
              value: "20"
            - name: am_arkAutoUpdateOnStart
              value: "true"
            - name: HEALTH_SERVER
              value: "true"
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 120
            periodSeconds: 30
            timeoutSeconds: 10
          livenessProbe:
            httpGet:
              path: /livez
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          resources:
            requests:
              memory: 12Gi
              cpu: 2000m
            limits:
              memory: 16Gi
          volumeMounts:
            - name: ark-data
              mountPath: /ark
  volumeClaimTemplates:
    - metadata:
        name: ark-data
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 50Gi
---
apiVersion: v1
kind: Service
metadata:
  name: arkserver
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  selector:
    app: arkserver
  ports:
    - port: 27015
      targetPort: 27015
      protocol: UDP
      name: query
    - port: 7778
      targetPort: 7778
      protocol: UDP
      name: game
    - port: 7778
      targetPort: 7778
      protocol: TCP
      name: game-tcp
    - port: 32330
      targetPort: 32330
      protocol: TCP
      name: rcon
    - port: 8080
      targetPort: 8080
      protocol: TCP
      name: health
```

### Cluster with Shared Server Files

When running multiple maps, use shared PVCs for server binaries and cluster transfer data to avoid duplicating the ~50GB game install per instance:

```yaml
          env:
            - name: ARKSERVER_SHARED
              value: "/arkserver"
            - name: ARKCLUSTER
              value: "true"
            - name: am_arkopt_clusterid
              valueFrom:
                secretKeyRef:
                  name: ark-secrets
                  key: cluster-id
          volumeMounts:
            - name: ark-data
              mountPath: /ark
            - name: ark-saved
              mountPath: /arkserver/ShooterGame/Saved
            - name: ark-cluster
              mountPath: /arkserver/ShooterGame/Saved/clusters
            - name: ark-serverfiles
              mountPath: /arkserver
```

Each instance needs its own `ark-data` and `ark-saved` volumes. The `ark-cluster` and `ark-serverfiles` volumes are shared across all instances in the cluster. For the full clustering guide, see [Clustering](Clustering.md).

### Production Considerations

#### Pod Security

The image runs as the `steam` user (non-root) internally. For hardened clusters:

```yaml
    spec:
      enableServiceLinks: false          # prevents leaking other service endpoints as env vars
      securityContext:
        fsGroup: 1001                    # match steam user GID for volume writes
      containers:
        - name: arkserver
          stdin: true                    # arkmanager expects an interactive TTY
          tty: true                      # required for proper signal handling and console
```

`enableServiceLinks: false` is especially important in namespaces with many services — Kubernetes injects every service as env vars by default, which can collide with `am_` prefixed arkmanager variables.

#### Image Pinning

For production stability, pin the image by digest instead of tag:

```yaml
          image: drpsychick/arkserver@sha256:59e6f0d445fa...
```

This prevents unexpected updates from pulling a new `:latest` during a pod reschedule. Upgrade deliberately by updating the digest.

#### LoadBalancer & Networking

**externalTrafficPolicy**: Use `Cluster` (default) for game servers. `Local` preserves client source IPs but requires the game client to connect to a node that actually runs the pod. `Cluster` routes from any node, which is more reliable for UDP game traffic.

```yaml
spec:
  type: LoadBalancer
  externalTrafficPolicy: Cluster
```

**Shared LoadBalancer IP**: Multiple ARK instances can share a single LoadBalancer IP as long as each uses unique ports. If your CNI/LB controller supports IP sharing annotations (e.g. Cilium's `lbipam.cilium.io/sharing-key`), all map instances can live behind one IP.

**Service Mesh / CNI Considerations**: If you run a service mesh like Istio in ambient mode, TCP health checks from monitoring tools may report false-healthy because the mesh proxy completes TCP handshakes before traffic reaches the pod. This is exactly why the [Health Server](HealthServer.md) exists — it validates actual RCON connectivity rather than just port reachability.

#### Network Policy

If your cluster runs default-deny network policies, ARK servers need the following ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: arkserver-ingress
spec:
  podSelector:
    matchLabels:
      app: arkserver
  policyTypes:
    - Ingress
  ingress:
    # Game + Query (UDP from players)
    - ports:
        - port: 7778
          protocol: UDP
        - port: 27015
          protocol: UDP
    # Game (TCP for Epic crossplay)
    - ports:
        - port: 7778
          protocol: TCP
    # RCON (TCP, restrict to admin sources)
    - from:
        - ipBlock:
            cidr: 10.0.0.0/8     # adjust to your admin CIDR
      ports:
        - port: 32330
          protocol: TCP
    # Health endpoint (for monitoring/probes)
    - ports:
        - port: 8080
          protocol: TCP
```

Restrict RCON ingress to trusted admin CIDRs — RCON provides full server console access.

#### Monitoring with the Health Server

The health server enables proper application-level monitoring. In addition to Kubernetes probes, you can point external monitoring tools at the `/healthz` endpoint:

```
http://arkserver.<namespace>.svc.cluster.local:8080/healthz
```

Returns `200` with `{"status": "healthy"}` when RCON is responsive, `503` with `{"status": "unhealthy"}` when the server is still loading, crashed, or RCON is unreachable. This is the same RCON `ListPlayers` command that server admins use to check who's online — the health server just wraps it in HTTP for automation.

#### RCON Administration

The image includes `arkmanager` which provides RCON access for server administration. Common commands via `kubectl exec`:

```bash
# List connected players
kubectl exec -it arkserver-0 -- arkmanager rconcmd "ListPlayers"

# Broadcast a message to all players
kubectl exec -it arkserver-0 -- arkmanager broadcast "Server restarting in 15 minutes"

# Save the world
kubectl exec -it arkserver-0 -- arkmanager saveworld

# Graceful shutdown (warns players, saves, then stops)
kubectl exec -it arkserver-0 -- arkmanager stop --warn --saveworld
```

The health server uses this same `arkmanager rconcmd` mechanism under the hood — if `ListPlayers` succeeds, the server is up and accepting game connections.

#### HTTP Admin List Server

ARK supports loading admin lists, whitelists, and ban lists from HTTP URLs instead of local files. This is useful in Kubernetes where multiple server instances need to share the same lists without mounting the same config volume.

The pattern uses an nginx deployment with [njs](https://nginx.org/en/docs/njs/) to serve Steam IDs from a Kubernetes Secret. The same approach works for any list type — cheater IDs, exclusive join lists, ban lists, etc.

**Secret** — Store Steam IDs in a Secret (or use an External Secrets Operator to sync from Vault):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ark-admin-ids
stringData:
  admins.txt: |
    # One Steam ID per line (hex32 format)
    # Comments and blank lines are ignored
    01234567890ABCDEF
    FEDCBA9876543210
```

**ConfigMap — nginx config**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ark-admin-list-nginx-conf
data:
  nginx.conf: |
    load_module modules/ngx_http_js_module.so;

    events {}
    http {
      js_path /etc/nginx/njs/;
      js_import main from main.mjs;

      server {
        listen 8080;

        location /AllowedCheaterSteamIDs.txt {
          js_content main.serve_ids;
        }
        location /PlayersJoinNoCheckList.txt {
          js_content main.serve_ids;
        }
        location /PlayersExclusiveJoinList.txt {
          js_content main.serve_ids;
        }
        location / {
          return 404;
        }
      }
    }
```

**ConfigMap — njs script** that reads, deduplicates, and serves Steam IDs:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ark-admin-list-njs
data:
  main.mjs: |
    import fs from "fs";

    const DATA_DIR = "/vault-data";

    function loadSteamIds() {
      let ids = new Set();
      try {
        let files = fs.readdirSync(DATA_DIR);
        for (let f of files) {
          let content = fs.readFileSync(`${DATA_DIR}/${f}`, "utf8");
          for (let line of content.split("\n")) {
            line = line.trim();
            if (line && !line.startsWith("#") && /^[0-9A-Fa-f]{16,}$/.test(line)) {
              ids.add(line);
            }
          }
        }
      } catch (e) {
        // secret not mounted or empty
      }
      return Array.from(ids);
    }

    function serve_ids(r) {
      let ids = loadSteamIds();
      r.headersOut["Content-Type"] = "text/plain";
      r.return(200, ids.join("\n") + "\n");
    }

    export default { serve_ids };
```

**Deployment**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ark-admin-list-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ark-admin-list-server
  template:
    metadata:
      labels:
        app: ark-admin-list-server
    spec:
      containers:
        - name: nginx
          image: docker.io/nginx:alpine
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
            - name: njs
              mountPath: /etc/nginx/njs/
            - name: steam-ids
              mountPath: /vault-data
              readOnly: true
      volumes:
        - name: nginx-conf
          configMap:
            name: ark-admin-list-nginx-conf
        - name: njs
          configMap:
            name: ark-admin-list-njs
        - name: steam-ids
          secret:
            secretName: ark-admin-ids
---
apiVersion: v1
kind: Service
metadata:
  name: ark-admin-list-server
spec:
  selector:
    app: ark-admin-list-server
  ports:
    - port: 8080
      targetPort: 8080
```

Then configure your ARK server to load lists from the service URL:

```bash
am_arkopt_ExclusiveJoin="http://ark-admin-list-server:8080/PlayersExclusiveJoinList.txt"
```

The same pattern works for any text-based list ARK supports. Add more endpoints and Secret keys as needed.
