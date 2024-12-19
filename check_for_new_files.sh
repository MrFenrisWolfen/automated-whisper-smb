#!/bin/bash

# Standardwert für das Modell, falls keine Umgebungsvariable gesetzt ist
MODEL="${MODEL:-tiny}"
echo "MODEL ist: $MODEL" >> /var/log/check.log
SCRIPT_DIR=$(dirname "$(realpath "$0")")
SCRIPT_LOCK="$SCRIPT_DIR/script.lock"

# Prüfen, ob die Lock-Datei existiert
if [ -f "$SCRIPT_LOCK" ]; then
  echo "Das Script ist bereits in Verwendung, stoppe erneutes Starten."
  exit 0
fi

# Lock-Datei erstellen
touch "$SCRIPT_LOCK"

# Verzeichnis, das überprüft werden soll
WATCH_DIR="/app/audio/data"										# Ordner mit den Videodateien Optimieren! -- nur eine variable nötig?
# Datei, in der die zuletzt bekannten Dateien gespeichert werden
LAST_STATE_FILE="$SCRIPT_DIR/Last_State.txt"
# Temporäre Lock-Dateien
LOCK_DIR="/app/audio/data"											# Ordner mit den Videodateien Optimieren!

# Erstelle die State-Datei, falls sie nicht existiert
if [ ! -f "$LAST_STATE_FILE" ]; then
  # Anstatt die aktuellen Dateien direkt zu speichern, mache die Datei leer
  > "$LAST_STATE_FILE"
fi

# Funktion, um alle aktuellen Video-/Audiodateien zu listen
get_current_files() {
  find "$WATCH_DIR" -type f \( -name "*.mp4" -o -name "*.avi" -o -name "*.mkv" -o -name "*.mp3" -o -name "*.wav" \) | sort
}

# Erstelle die State-Datei, falls sie nicht existiert
if [ ! -f "$LAST_STATE_FILE" ]; then
  get_current_files > "$LAST_STATE_FILE"
fi

# Aktuelle Dateien abrufen
CURRENT_FILES=$(get_current_files)
# Zuletzt bekannte Dateien abrufen
LAST_FILES=$(cat "$LAST_STATE_FILE")


# Vergleiche die aktuellen und letzten Zustände
if [ "$CURRENT_FILES" != "$LAST_FILES" ]; then
  echo "Neue Dateien gefunden!"

  # Finde die neuen Dateien
  NEW_FILES=$(comm -13 <(echo "$LAST_FILES") <(echo "$CURRENT_FILES"))
  echo "Neue Dateien: $NEW_FILES"


# Funktion, um zu prüfen, ob eine Datei vollständig kopiert wurde
is_file_complete() {
  local file="$1"
  local size1 size2
  size1=$(stat --format="%s" "$file")
  sleep 2  # Warten, um die Dateigröße erneut zu prüfen
  size2=$(stat --format="%s" "$file")
  [[ "$size1" -eq "$size2" ]]  # Vergleiche die beiden Größen
}


  while IFS= read -r TARGET_FILE; do
    if [ -n "$TARGET_FILE" ]; then

      # Prüfen, ob die Datei vollständig kopiert wurde
      if ! is_file_complete "$TARGET_FILE"; then
      echo "Datei wird noch kopiert: $TARGET_FILE"
      continue
      fi

      LOCK_FILE="$LOCK_DIR/$(basename "$TARGET_FILE").lock"

      # Prüfen, ob die Datei bereits in Bearbeitung ist
      if [ -f "$LOCK_FILE" ]; then
        echo "Überspringe Datei (bereits in Bearbeitung): $TARGET_FILE"
        continue
      fi

      # Lock-Datei erstellen
      touch "$LOCK_FILE"
      echo "Verarbeite Datei: $TARGET_FILE"

      # Eingabeverzeichnis und Dateiname ohne Endung
      TARGET_DIR=$(dirname "$TARGET_FILE")
      BASENAME=$(basename "$TARGET_FILE" | sed 's/\.[^.]*$//')

      # Dynamische Output-Ordner im gleichen Verzeichnis wie die Eingabedatei
      OUTPUT_DIR="$TARGET_DIR/${BASENAME}-en"
      OUTPUT_DIR_DE="$TARGET_DIR/${BASENAME}-de"

      # Command für Englisch
      COMMAND1="whisper \"$TARGET_FILE\" --model $MODEL --language en --output_dir \"$OUTPUT_DIR\""

      # Command für Deutsch
      COMMAND2="whisper \"$TARGET_FILE\" --model $MODEL --language de --output_dir \"$OUTPUT_DIR_DE\""

      # Commands ausführen
      echo "Starte Verarbeitung für Englisch..."
      eval "$COMMAND1"
      chmod 777 /app/audio/data -R

      echo "Starte Verarbeitung für Deutsch..."
      eval "$COMMAND2"
      chmod 777 /app/audio/data -R


      # Lock-Datei entfernen
      rm -f "$LOCK_FILE"

    fi
  done <<< "$NEW_FILES"

  # Aktuellen Zustand speichern
  echo "$CURRENT_FILES" > "$LAST_STATE_FILE"
else
  echo "Keine neuen Dateien gefunden."
fi

# Lock-Datei entfernen, wenn das Skript beendet ist
rm -f "$SCRIPT_LOCK"
