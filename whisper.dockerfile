# Base-Image
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Benötigte Programme
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo \
    python3.9 \
    python3-distutils \
    python3-pip \
    ffmpeg \
    curl \
    cron

# PIP upgrade
RUN pip install --upgrade pip

# Installation von Whisper und Pytorch
RUN pip install -U openai-whisper
RUN pip3 install torch torchvision torchaudio

# Kopieren der Scripts in den Container root
COPY scripts/check_for_new_files.sh /check.sh
COPY scripts/start.sh /start.sh

# Startbefehl, um das start-Skript beim Container-Start auszuführen
CMD ["bash", "/start.sh"]
