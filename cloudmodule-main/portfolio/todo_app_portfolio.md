Portfolio: Todo-App — Deployment, Hosts und Podman (Robin Blaser)

Datum: 2026-03-27

Ziel
- Die Version v2 meiner Todo-App sichtbar machen: als Docker-Image auf Docker Hub veröffentlichen und in Kubernetes deployen.
- Kurz dokumentieren, warum Zugriffe über Hostname vs. IP unterschiedlich reagieren.
- Todo-App mit Podman laufen lassen und dokumentieren.

1) Problemursache: Warum `docker push ...:v2` den Fehler "tag does not exist" gab
- Der Fehler bedeutet: Lokal existiert kein Docker-Image mit dem Tag `robin223567/todo-app:v2`.
- Lösung: Zuerst das Image lokal bauen und mit genau diesem Tag versehen, dann pushen.

2) Image bauen, taggen und zu Docker Hub pushen (PowerShell)
- Wechsle in das Verzeichnis der v2-Web-Frontend-Quelle (enthält `Dockerfile`, `bin/todo-app` und `public`):

```powershell
cd "C:\Users\robin\Downloads\cloudmodule-main (1)\cloudmodule-main\to-do-appv2\web-frontendv2"
# Image bauen und direkt taggen
docker build -t robin223567/todo-app:v2 .
# anmelden (interaktiv)
docker login
# pushen
docker push robin223567/todo-app:v2
```

Hinweise:
- Falls du Podman statt Docker verwendest, sind die Befehle fast identisch (podman build / podman login / podman push). Verwende als Image-Name `docker.io/USERNAME/REPO:TAG` falls nötig:

```powershell
podman build -t docker.io/robin223567/todo-app:v2 .
podman login docker.io
podman push docker.io/robin223567/todo-app:v2
```

- Wenn das Repo auf Docker Hub noch nicht existiert, wird es beim Push meist automatisch als öffentliches Repo angelegt (sofern dein Account das erlaubt).

3) Deployment in Kubernetes auf v2 setzen
- Wenn das Image auf Docker Hub verfügbar ist, update das Deployment (Namespace `to-do-app`):

```powershell
# Variante A: Direkt das Deployment aktualisieren
kubectl set image deployment/todo-app-deployment todo-app=robin223567/todo-app:v2 -n to-do-app
kubectl rollout status deployment/todo-app-deployment -n to-do-app

# Variante B: Falls du die bereits vorhandene Datei todo-app-deploy-v2.yaml hast (sie referenziert image: robin223567/todo-app:v2):
kubectl apply -f "C:\Users\robin\Downloads\cloudmodule-main (1)\cloudmodule-main\to-do-app-k8s\todo-app-deploy-v2.yaml" -n to-do-app
kubectl rollout status deployment/todo-app-deployment -n to-do-app
```

- Kontrolle:

```powershell
kubectl get pods -n to-do-app
kubectl describe pod <pod-name> -n to-do-app
kubectl logs <ein-pod-name> -n to-do-app
```

4) Warum sehe ich in der Webseite weiterhin v1 / eine andere Seite?
- Häufige Ursachen:
  - Das Image `v2` wurde nie gebaut/gepusht (siehe Schritt 2).
  - Browser-Cache: Erzwungenes Neu-Laden (Shift+Reload oder Inkognito) nötig.
  - Ingress/Host-Header: Wenn du einen Ingress mit Host-Regeln konfiguriert hast (z.B. host: my-app.com), dann muss die Anfrage den Host-Header `my-app.com` enthalten – reine IP-Aufrufe (z. B. http://127.0.0.1) werden von der Ingress-Regel nicht an die App weitergeleitet und liefern einen Fehler oder anderes Default-Backend.
  - Falsche Hosts-Einträge: Wenn Kubernetes (oder der Ingress-Controller) in einer VM / WSL läuft, muss `my-app.com` auf die IP dieser VM/Ingress-Controller zeigen, nicht unbedingt auf `127.0.0.1`.

5) Hosts-Datei (Windows) – welches Mapping ist richtig?
- Deine Datei (`C:\Windows\System32\drivers\etc\hosts`) enthält aktuell:

  127.0.0.1 my-app.com

- Das funktioniert nur, wenn der Ingress/Proxy auf dem Host-Loopback (127.0.0.1) erreichbar ist. Häufig ist der Ingress jedoch in einer VM (z. B. minikube, k3d, WSL-VM) mit einer anderen IP, z. B. 192.168.99.100 oder 10.158.33.141. In diesem Fall muss der Eintrag so lauten:

  10.158.33.141 my-app.com

- Prüfen: Finde die IP des Clusters/Ingress (z. B. für minikube `minikube ip`, für Docker Desktop k8s sind oft Port-Forwards aktiv). Bei einem Ingress-Controller wie Traefik/NGINX, prüfe `kubectl get svc -n ingress-nginx` o.ä. und nimm die EXTERNAL-IP oder NodePort-Mapping.

6) Beispiel: Testen lokal ohne Ingress
- Du kannst temporär Port-Forwarding nutzen, dann erreichst du die App per localhost, unabhängig vom Host-Header:

```powershell
# Service-Port forwarden: lokal 8080 -> service-port 3000
kubectl port-forward svc/todo-app-service 8080:3000 -n to-do-app
# dann im Browser: http://localhost:8080
```

7) Todo-App mit Podman laufen lassen (einfacher Test)
- Build lokal mit Podman (im v2-Ordner):

```powershell
cd "C:\Users\robin\Downloads\cloudmodule-main (1)\cloudmodule-main\to-do-appv2\web-frontendv2"
podman build -t todo-app:v2 .
# Lokales starten (Port 3000 nach außen):
podman run -d --name todo-app -p 3000:3000 todo-app:v2
# anschauen logs:
podman logs -f todo-app
```

- Pod-Variante (mehrere Container im Pod):

```powershell
# Pod erstellen mit Portfreigabe
podman pod create --name todo-pod -p 3000:3000
# Redis und App im gleichen Pod starten (nur als Beispiel)
podman run -d --pod todo-pod --name redis redis:6
podman run -d --pod todo-pod --name todo-app todo-app:v2
```

8) Kurzer Portfolio-Eintrag (fertiger Text, zum Kopieren ins Portfolio)

Titel: "Todo-App: Deployment v2, Hosts und Podman"

Inhalt (Kurzfassung):
Heute habe ich die Version v2 meiner Todo-App vorbereitet und getestet. Wichtigste Erkenntnisse:
- Der Fehler beim Push (`tag does not exist`) entstand, weil das lokale Image nicht mit dem Tag `robin223567/todo-app:v2` vorhanden war. Lösung: Image lokal bauen und mit dem richtigen Tag versehen, dann pushen.
- Für Kubernetes-Updates kann ich `kubectl set image ...` oder das Deployment-Manifest (`todo-app-deploy-v2.yaml`) verwenden. Nach dem Push des Images zum Registry-Host war ein `kubectl rollout status` nötig, um zu bestätigen, dass alle Pods auf v2 laufen.
- Hostname-basiertes Routing (Ingress) benötigt, dass die Domain (z. B. `my-app.com`) auf die IP des Ingress-Controllers zeigt. Ein Eintrag in `C:\Windows\System32\drivers\etc\hosts` kann das sichtbar machen; die IP muss jedoch die des Clusters/VM sein, nicht zwingend `127.0.0.1`.
- Für lokale Tests ist Podman eine gute Alternative zu Docker. Mit `podman build` und `podman run` ließ sich die App als Container und in einem Pod starten.

Schlussfolgerung: Ich habe die Build-/Push-/Deploy-Pipeline überprüft und dokumentiert. Nächste Schritte: Image pushen, Deployment aktualisieren und mit `kubectl rollout status` die erfolgreiche Migration auf v2 verifizieren.


---

Ende des Portfolio-Eintrags.

Wenn du möchtest, kann ich jetzt:
- dir die genauen PowerShell-Befehle hier ausführen (lokal auf deinem Rechner kannst du sie kopieren und ausführen),
- oder die `hosts`-Datei im Repo kommentiert anpassen (ich kann einen Vorschlag in die Datei schreiben, aber das Ändern der System-Hosts benötigt Adminrechte beim Anwenden auf deinem PC).

Sag mir, welches der nächsten Schritte ich jetzt für dich ausführen oder näher erklären soll.
