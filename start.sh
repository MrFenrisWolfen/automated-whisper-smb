#!/bin/bash

# Setze die Umgebungsvariable für das Modell
export MODEL=${MODEL:-medium}

# Füge den Cronjob hinzu (falls noch nicht vorhanden)
(crontab -l 2>/dev/null; echo "*/1 * * * * MODEL=$MODEL /bin/bash /check.sh >> /var/log/check.log 2>&1") | crontab -

# Starte den Cron-Dienst im Vordergrund
cron -f
