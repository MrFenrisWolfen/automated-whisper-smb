# automated-whisper-smb

This is an Dockerfile, Docker-Compose and Script for running an openai-whisper instance
which is creating subtitles in english and german for files on an network drive fully automated

SETUP:

1. Clone this repo to your desired folder (as example your actual working DIR)

```
git clone https://github.com/MrFenrisWolfen/automated-whisper-smb.git
```


2. Start the docker-compose file:

IMPORTANT!! the standard model (medium) can be changed inside the compose file to turbo or tiny.
If you have less than 8GB of VRAM you should use TURBO and if you've got no GPU try small or tiny if you dont want to
wait years for a finished subtitle.

If you've got an GPU, start use this command:

```
sudo docker-compose --profile gpu up -d
```

Or in case you have to use the CPU:

```
sudo docker-compose --profile cpu up -d
```

You can specify the used model with an env variable at the start in case of some tests or just for playing around:

```
WHISPER_MODEL=tiny docker-compose --profile cpu up -d
```

Size	Parameters	English-only model	Multilingual model	Required VRAM	Relative speed
tiny	39 M	tiny.en	tiny	~1 GB	~10x
base	74 M	base.en	base	~1 GB	~7x
small	244 M	small.en	small	~2 GB	~4x
medium	769 M	medium.en	medium	~5 GB	~2x
large	1550 M	N/A	large	~10 GB	1x
turbo	809 M	N/A	turbo	~6 GB	~8x




3. Usage:

Now just connect a new networkdrive in Windows or connect via smb to the drive:

\\"Host IP of the Docker-Machine"\whisper (as example: \\\192.168.0.42\whisper )

Drop an .mp4, .mkv, .avi, .mp3, .wav File to that folder and watch the magic happens.
The Container checks frequently for a new compatible file, but the first translation will took a while cause
the model file have to be downloaded, but is stored permanent in a docker volume afterwards.
