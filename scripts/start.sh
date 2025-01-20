#!/bin/bash

# pfade definieren
VOLUME_DIR="/app/audio/data/0_settings/"
SCRIPT_SRC="/check.sh"
SCRIPT_DEST="$VOLUME_DIR/check.sh"
SETTINGS_FILE="$VOLUME_DIR/settings.txt"

# volume erstellen
mkdir -p "$VOLUME_DIR"

# script ins volume kopieren
cp "$SCRIPT_SRC" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"

# Standard-Settings anlegen, falls sie nicht existieren
if [ ! -f "$SETTINGS_FILE" ]; then
  cat <<EOL > "$SETTINGS_FILE"
# Modell für Whisper
MODEL=medium
# Sprachen (Komma-separiert, z.B. en,de)
LANGUAGES=de,en
# Benutzerdefinierter befehl der statt dem standard Befehl ausgeführt werden soll per Datei
# (nur zu debugging zwecken, Befehl anpassen und Raute entfernen)
# CUSTOM_COMMAND="whisper \"$TARGET_FILE\" --model $MODEL --language $LANGUAGE --output_dir \"$OUTPUT_DIR\""
EOL
fi

# Crontab aktualisieren
CRON_JOB="*/1 * * * * /bin/bash $SCRIPT_DEST >> /var/log/check.log 2>&1"

if ! crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
    # Crontab aktualisieren, wenn der Eintrag nicht existiert
    (
        echo "PATH=/usr/local/bin:/usr/bin:/bin"
        echo "SHELL=/bin/bash"
        crontab -l 2>/dev/null
        echo "$CRON_JOB"
    ) | crontab -
fi

# Debug: Aktuelle Crontab ausgeben
crontab -l

# Cron-Dienst starten
cron -f
