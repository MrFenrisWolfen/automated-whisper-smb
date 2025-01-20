#!/bin/bash

# pfad des scripts
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# timestamp
echo " " >> $SCRIPT_DIR/log/check.log
echo "==========================================" >> $SCRIPT_DIR/log/check.log
echo " Durchgang gestartet: $(date '+%Y-%m-%d %H:%M:%S')" >> $SCRIPT_DIR/log/check.log
echo "==========================================" >> $SCRIPT_DIR/log/check.log

# prüfen ob die Lock-Datei existiert und abbruch falls ja
SCRIPT_LOCK="$SCRIPT_DIR/script.lock"
if [ -f "$SCRIPT_LOCK" ]; then
  echo "Das Script ist bereits in Verwendung, stoppe erneutes Starten." >> $SCRIPT_DIR/log/check.log
  exit 0
fi

# Lock-Datei erstellen
touch "$SCRIPT_LOCK"

# settings laden
SETTINGS_FILE="$(dirname "$(realpath "$0")")/settings.txt"
if [ -f "$SETTINGS_FILE" ]; then
  source "$SETTINGS_FILE"
fi

# standardwerte falls keine settings vorhanden sein sollten
MODEL="${MODEL:-tiny}"
LANGUAGES="${LANGUAGES:-de}"
echo "MODEL ist: $MODEL" >> $SCRIPT_DIR/log/check.log
echo "LANGUAGES ist: $LANGUAGES" >> $SCRIPT_DIR/log/check.log

# CUSTOM_COMMAND gesetzt?
if [ -n "$CUSTOM_COMMAND" ]; then
echo "CUSTOM_COMMAND ist: $CUSTOM_COMMAND" >> $SCRIPT_DIR/log/check.log
else
echo "Verwende Standard-Befehl" >> $SCRIPT_DIR/log/check.log
fi

#Settings und Ordner freigeben
chmod -R 777 "$SCRIPT_DIR"
chmod -R 777 /app/audio/data

# Verzeichnis, das überprüft werden soll
WATCH_DIR="/app/audio/data"										# Ordner mit den Videodateien Optimieren! -- nur eine variable nötig?

# Datei, in der die zuletzt bekannten Dateien gespeichert werden
LAST_STATE_FILE="$SCRIPT_DIR/Last_State.txt"

# Temporäre Lock-Dateien
LOCK_DIR="$SCRIPT_DIR"                    # Ordner mit den Videodateien Optimieren!

# Erstelle die State-Datei, falls sie nicht existiert
if [ ! -f "$LAST_STATE_FILE" ]; then
  # Datei leeren
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
  echo "Neue Dateien gefunden!" >> $SCRIPT_DIR/log/check.log

  # Finde die neuen Dateien
  NEW_FILES=$(comm -13 <(echo "$LAST_FILES") <(echo "$CURRENT_FILES"))
  echo "Neue Dateien: $NEW_FILES" >> $SCRIPT_DIR/log/check.log


# funktion um zu prüfen ob eine datei vollständig kopiert wurde
  is_file_complete() {
  local file="$1"
  local size1 size2
  size1=$(stat --format="%s" "$file")
  sleep 2  # warten um die dateigröße erneut zu prüfen
  size2=$(stat --format="%s" "$file")
  [[ "$size1" -eq "$size2" ]]  # vergleiche die beiden Größen
  }


  while IFS= read -r TARGET_FILE; do
    if [ -n "$TARGET_FILE" ]; then

      # Prüfen, ob die Datei vollständig kopiert wurde
      if ! is_file_complete "$TARGET_FILE"; then
      echo "Datei wird noch kopiert: $TARGET_FILE" >> $SCRIPT_DIR/log/check.log
      continue
      fi

      # erstellen der datei basierten lock datei
      LOCK_FILE="$LOCK_DIR/$(basename "$TARGET_FILE").lock"

      # Prüfen, ob die Datei bereits in Bearbeitung ist
      if [ -f "$LOCK_FILE" ]; then
        echo "Überspringe Datei (bereits in Bearbeitung): $TARGET_FILE" >> $SCRIPT_DIR/log/check.log
        continue
      fi

      # Lock-Datei erstellen
      touch "$LOCK_FILE"
      echo "Verarbeite Datei: $TARGET_FILE" >> $SCRIPT_DIR/log/check.log

      # Eingabeverzeichnis und Dateiname ohne Endung
      TARGET_DIR=$(dirname "$TARGET_FILE")
      BASENAME=$(basename "$TARGET_FILE" | sed 's/\.[^.]*$//')

		  for LANGUAGE in $(echo "$LANGUAGES" | tr ',' '\n'); do
		  OUTPUT_DIR="$TARGET_DIR/${BASENAME}-${LANGUAGE}"
    		  echo "starte verarbeitung für $LANGUAGE" >> $SCRIPT_DIR/log/check.log

       		  # Prüfen, ob ein benutzerdefiniertes Kommando existiert
      		  if [ -n "$CUSTOM_COMMAND" ]; then
        
		  	# CUSTOM_COMMAND verwenden
        	  	COMMAND=$(eval echo "$CUSTOM_COMMAND")
        	  	echo "Verwende benutzerdefinierten Befehl: $COMMAND" >> $SCRIPT_DIR/log/check.log
		  else
    		  	# Standard command verwenden
		  	COMMAND="whisper \"$TARGET_FILE\" --model $MODEL --language $LANGUAGE --output_dir \"$OUTPUT_DIR\""
     		  	echo "Verwende Standard-Befehl: $COMMAND" >> $SCRIPT_DIR/log/check.log
		  fi

    		  # Ausführung
		  eval "$COMMAND" 
		  done

      # Lock-Datei entfernen
      rm -f "$LOCK_FILE"

    fi
  done <<< "$NEW_FILES"

  # Aktuellen Zustand speichern
  echo "$CURRENT_FILES" > "$LAST_STATE_FILE"
else
  echo "Keine neuen Dateien gefunden."  >> $SCRIPT_DIR/log/check.log
fi

# Lock-Datei entfernen, wenn das Skript beendet ist
rm -f "$SCRIPT_LOCK"
