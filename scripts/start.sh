#!/bin/bash

# Pfade definieren
VOLUME_DIR="/app/audio/data/0_settings/"
SCRIPT_SRC="/check.sh"
SCRIPT_DEST="$VOLUME_DIR/check.sh"
SETTINGS_FILE="$VOLUME_DIR/settings.txt"

# Volume sicherstellen
mkdir -p "$VOLUME_DIR"

# Script ins Volume kopieren
cp "$SCRIPT_SRC" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"

# Standard-Settings anlegen, falls sie nicht existieren
if [ ! -f "$SETTINGS_FILE" ]; then
  cat <<EOL > "$SETTINGS_FILE"
# Modell für Whisper
MODEL=medium
# Sprachen (Komma-separiert, z.B. en,de)
LANGUAGES=de,en
EOL
fi

# Crontab aktualisieren
(
    echo "PATH=/usr/local/bin:/usr/bin:/bin"
    echo "SHELL=/bin/bash"
    crontab -l 2>/dev/null
    echo "*/1 * * * * /bin/bash $SCRIPT_DEST >> /var/log/check.log 2>&1"
) | crontab -

# Debug: Aktuelle Crontab ausgeben
crontab -l

# Cron-Dienst starten
cron -f
