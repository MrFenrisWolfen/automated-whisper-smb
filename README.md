# automated-whisper-smb

This is an Dockerfile, Docker-Compose and Script for running an openai-whisper instance
which is creating subtitles in english and german for files on an network drive fully automated

SETUP:

1. Clone this repo to your desired folder (as example your actual working DIR)

git clone https://github.com/MrFenrisWolfen/automated-whisper-smb.git

2. Start the docker-compose file:

IMPORTANT!! the standard model (medium) can be changed inside the compose file to turbo or tiny.
If you have less than 8GB of VRAM you should use TURBO and if you've got no GPU try small or tiny if you dont want to
wait years for a finished subtitle.

If you've got an GPU, start use this command:

sudo docker-compose --profile gpu up -d

Or in case you have to use the CPU:

sudo docker-compose --profile cpu up -d

