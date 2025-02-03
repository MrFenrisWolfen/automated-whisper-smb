#!/bin/bash

# pfade definieren
VOLUME_DIR="/app/audio/data/0_settings/"
SCRIPT_SRC="/check.sh"
SCRIPT_DEST="$VOLUME_DIR/check.sh"
SETTINGS_FILE="$VOLUME_DIR/settings.txt"

# volume erstellen
mkdir -p "$VOLUME_DIR"
mkdir -p "$VOLUME_DIR/log"

# script ins volume kopieren
cp "$SCRIPT_SRC" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"

# Standard-Settings anlegen, falls sie nicht existieren
if [ ! -f "$SETTINGS_FILE" ]; then
cat <<'EOL' > "$SETTINGS_FILE"
# Modell für Whisper
# Empfohlen ist medium (standard) bei kompatibilitätsproblemen können tiny oder turbo ausprobiert werden.
# Mögliche models und GPU-VRAM verbrauch: 
# tiny (~ 1GB), base (~ 1 GB), small (~ 2 GB), medium (~ 5 GB), large (~ 10 GB), turbo (~ 6 GB)

MODEL=medium

# Sprachen (Komma-separiert, z.B. en,de)
# Erstellt auch für jede Sprache einen einzelnen Durchlauf.

LANGUAGES=de,en

# -----------------------------------------------------------------------------------------------------------
# Benutzerdefinierter befehl der statt dem standard Befehl ausgeführt werden soll per Datei
# (nur zu debugging zwecken, Befehl anpassen und Hashtag entfernen)
#
# \"$TARGET_FILE\" = Video / Audiodateien innerhalb des Verzeichnisses
# --output_dir \"$OUTPUT_DIR\" = Ausgabeordner der Dateien mit namen der "verarbeiteten Datei/Sprachkürzel"
# --language $LANGUAGE = enthält für jeden der durchläufe das spezifische Länderkürzel
# (bei de,fr,en = 1. Durchlauf Deutsch, 2. Durchlauf Französisch, 3. Durchlauf Englisch)
#
# CUSTOM_COMMAND="whisper \"$TARGET_FILE\" --model $MODEL --language $LANGUAGE --output_dir \"$OUTPUT_DIR\""
EOL
fi

# Crontab aktualisieren
CRON_JOB="*/1 * * * * /bin/bash $SCRIPT_DEST >> $VOLUME_DIR/log/whisper.log 2>&1"

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
