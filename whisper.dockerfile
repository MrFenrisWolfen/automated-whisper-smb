# Basisimage
FROM ubuntu:22.04

# Benötigte Programme
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    sudo \
    python3.9 \
    python3-distutils \
    python3-pip \
    ffmpeg

# PIP commands
RUN pip install --upgrade pip

# Installation von Whisper und Pytorch
RUN pip install -U openai-whisper
RUN pip3 install torch torchvision torchaudio

# Herunterladen der Scripts von Github
COPY scripts/start.sh /start.sh

# Mache Script ausführbar
RUN chmod +x /start.sh

# Startbefehl, um das Skript beim Container-Start auszuführen
CMD ["bash", "/start.sh"]
