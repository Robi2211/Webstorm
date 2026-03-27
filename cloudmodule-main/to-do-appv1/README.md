# Todo App v1 (Docker/Podman)

## Ziel
Die To-Do-App v1 mit Podman starten, anschließend als Pod zusammenfassen und optional nach Kubernetes übertragen.

## Docker-Compose Fehlerbehebung (Windows)
Wenn du unter Windows diesen Befehl verwendest:

```cmd
docker compose -f https://gitlab.com/thomas-staub/cloudmodules/m169/demobeispiele/to-do-appv1/-/raw/main/docker-compose-git.yaml up -d
```

kann der Fehler `CreateFile ... https:\...\.env` auftreten. Ursache: Compose behandelt die URL als lokalen Pfad. Das gilt sowohl für `docker compose` als auch für das ältere `docker-compose`.

Verwende stattdessen eine lokale Compose-Datei aus diesem Repository:

`<workspace-root>` muss durch den tatsächlichen lokalen Ordner ersetzt werden, der `cloudmodule-main` enthält (z. B. `C:\Users\username\Projects`).
Beispiel für den vollständigen Pfad: `C:\Users\username\Projects\cloudmodule-main\to-do-appv1`.

```cmd
cd <workspace-root>\cloudmodule-main\to-do-appv1
docker compose -f docker-compose-git.yaml up -d
```

Alternativ (ohne GitLab-Registry-Login) direkt Docker-Hub-Images:

```cmd
cd <workspace-root>\cloudmodule-main\to-do-appv1
docker compose -f docker-compose-docker-hub.yaml up -d
```

## 1) Start mit Podman (ohne Pod)
Im Verzeichnis `to-do-appv1` ausführen:

```bash
podman build -t todo-frontend:v1 ./web-frontend
podman build -t todo-redis-master:v1 ./redis-master
podman build -t todo-redis-slave:v1 ./redis-slave

podman network create todo-net

podman run -d --name redis-master --network todo-net todo-redis-master:v1
podman run -d --name redis-slave --network todo-net todo-redis-slave:v1
podman run -d --name todo-app --network todo-net -p 3000:3000 todo-frontend:v1
```

Test:

```bash
curl http://localhost:3000/health
```

## 2) In einen Pod zusammenfassen

```bash
podman pod create --name todo-pod -p 3000:3000

podman run -d --pod todo-pod --name redis-master todo-redis-master:v1
podman run -d --pod todo-pod --name redis-slave \
  --add-host redis-master:127.0.0.1 \
  todo-redis-slave:v1
podman run -d --pod todo-pod --name todo-app \
  --add-host redis-master:127.0.0.1 \
  --add-host redis-slave:127.0.0.1 \
  todo-frontend:v1
```

Test:

```bash
curl http://localhost:3000/health
```

## 3) Optional: Pod nach Kubernetes übertragen

Podman-Kubernetes-Manifest erzeugen:

```bash
podman generate kube todo-pod > todo-pod.yaml
```

Danach auf Kubernetes anwenden:

```bash
kubectl apply -f todo-pod.yaml
kubectl get pods
```

Hinweis: Für ein echtes Cluster müssen die verwendeten Images (`todo-frontend:v1`, `todo-redis-master:v1`, `todo-redis-slave:v1`) in einer Registry verfügbar sein (z. B. Docker Hub/Quay), damit Kubernetes sie ziehen kann.
