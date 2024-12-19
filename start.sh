#!/bin/bash

# Setze die Umgebungsvariable f  r das Modell
export MODEL=${MODEL:-tiny}

# Stelle den SMB zugriff sicher
chmod 777 /app/audio/data -R

# F  ge den Crontab-Eintrag hinzu (inkl. PATH und SHELL)
(
    echo "PATH=/usr/local/bin:/usr/bin:/bin"
    echo "SHELL=/bin/bash"
    crontab -l 2>/dev/null
    echo "*/1 * * * * MODEL=$MODEL /bin/bash /check.sh >> /var/log/check.log 2>&1"
) | crontab -

# Debug-Ausgabe:  ^|berpr  fe die Crontab
echo "Aktuelle Crontab:"
crontab -l

# Starte den Cron-Dienst im Vordergrund
cron -f

