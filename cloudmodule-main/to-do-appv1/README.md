# Todo-App v1 – Docker & Podman

Demo-Anwendung bestehend aus drei Diensten:
- **web-frontend** – Go-Webserver (Port 3000)
- **redis-master** – Redis-Primärinstanz
- **redis-slave** – Redis-Replikat (verbindet sich mit `redis-master`)

---

## Docker (ursprünglich)

Klonen und starten (Play with Docker):
```sh
# HTTPS
git clone https://gitlab.com/thomas-staub/cloudmodules/m169/demobeispiele/to-do-appv1.git
# SSH (erfordert SSH-Key-Setup)
git clone git@gitlab.com:thomas-staub/cloudmodules/m169/demobeispiele/to-do-appv1.git
docker-compose -f https://gitlab.com/thomas-staub/cloudmodules/m169/demobeispiele/to-do-appv1/-/raw/main/docker-compose-git.yaml up -d
```

---

## Podman

### 1. Podman installieren

**Linux (Debian/Ubuntu):**
```sh
sudo apt update
sudo apt install podman
```

**macOS (Homebrew):**
```sh
brew install podman
podman machine init
podman machine start
```

**Windows:**
1. WSL2 installieren: `wsl --install`
2. Podman-Installer von https://github.com/containers/podman/releases herunterladen und ausführen.
3. Danach:
   ```sh
   podman machine init
   podman machine start
   ```

### 2. Container-Images bauen

Im Wurzelverzeichnis dieses Repos:
```sh
podman build -t todo-app:v1          ./web-frontend
podman build -t redis-master:v1      ./redis-master
podman build -t redis-slave:v1       ./redis-slave
podman build -t redis-slave-pod:v1 -f ./redis-slave/Dockerfile.pod ./redis-slave
```

### 3. App mit podman-compose starten

`podman-compose` liest dieselben Compose-Dateien wie Docker Compose.

```sh
pip install podman-compose        # einmalig installieren
podman-compose -f docker-compose.yaml up -d
```

Öffnen Sie anschließend http://localhost:3000 im Browser.

Stoppen:
```sh
podman-compose -f docker-compose.yaml down
```

---

## Podman Pod

Mit einem Pod werden alle drei Container in einem gemeinsamen Netzwerk-Namensraum zusammengefasst (ähnlich wie in Kubernetes).

### Pod erstellen und Container starten

```sh
# Pod anlegen und Port 3000 nach aussen freigeben
podman pod create --name todo-pod -p 3000:3000

# Redis-Master starten
podman run -d --pod todo-pod --name redis-master redis-master:v1

# Redis-Slave starten (verwendet localhost, da gleicher Pod-Netzwerk-Namensraum)
podman run -d --pod todo-pod --name redis-slave redis-slave-pod:v1

# Web-Frontend starten
podman run -d --pod todo-pod --name web-frontend todo-app:v1
```

> **Hinweis:** Da alle Container im selben Pod laufen, teilen sie sich einen Netzwerk-Namensraum.
> Der Redis-Slave muss daher `localhost` als Master-Adresse verwenden.
> Für den Pod-Betrieb steht ein separates `Dockerfile.pod` und `start-redis-slave-pod.sh` bereit:
> ```sh
> podman build -t redis-slave-pod:v1 -f ./redis-slave/Dockerfile.pod ./redis-slave
> ```
> Ersetzen Sie danach beim `podman run`-Befehl `redis-slave:v1` durch `redis-slave-pod:v1`.

### Pod-Status prüfen
```sh
podman pod ps
podman ps --pod
```

### Pod stoppen und entfernen
```sh
podman pod stop todo-pod
podman pod rm todo-pod
```

---

## Kubernetes-YAML aus dem Pod generieren (optional)

Podman kann aus einem laufenden Pod direkt Kubernetes-Manifeste erzeugen:

```sh
podman generate kube todo-pod > todo-pod.yaml
```

Das erzeugte YAML enthält eine `Pod`-Definition mit allen drei Containern und kann direkt auf einem Kubernetes-Cluster angewendet werden:

```sh
kubectl apply -f todo-pod.yaml
```

Eine fertige Kubernetes-Deployment-Variante dieser Anwendung finden Sie im Ordner `../to-do-app-k8s/`.
 

