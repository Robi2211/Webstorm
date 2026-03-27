#!/bin/sh
# Verwendet localhost als Redis-Master-Adresse – passend für den Podman-Pod-Betrieb,
# da alle Container im Pod denselben Netzwerk-Namensraum teilen.
redis-server --protected-mode no --replicaof localhost 6379
