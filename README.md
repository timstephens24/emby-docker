# Emby Docker

This supports hardware transcoding with Intel and NVIDIA. If you don't need the Intel support remove the line the says `--device /dev/dri:/dev/dri \` (or the last two lines in the docker-compose). If you don't need NVIDIA support you can remove the environment variable for `NVIDIA_VISIBLE_DEVICES` but there's no harm in leaving it.

It's also set to expose port 8096 (tcp) and 8290 (tcp), so it should be able to run with just exposing those ports, but I run it in host mode. Let me know if there's any issues here.

For Unraid I also have templates at: https://github.com/timstephens24/docker-templates. I have Emby's configuration located at `/mnt/user/appdata/emby` and my Media folder is `/mnt/user/data/Media`. Change those as appropriate

## Usage
### docker-compose (recommended)
```yaml
version: "3.8"
services:
  emby:
    restart: always
    container_name: emby
    hostname: emby
    image: timstephens24/emby
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - UMASK_SET=<022> #optional
      - NVIDIA_VISIBLE_DEVICES=all #optional
    volumes:
      - /path/to/config:/config
      - /path/to/tvshows:/data/tvshows
      - /path/to/movies:/data/movies
      - /path/for/transcoding:/transcode #optional
    ports:
      - 8096:8096
      - 8920:8920 #optional
    devices:
      - /dev/dri:/dev/dri #optional
```
### docker cli
```
docker run -d \
  --net=host \
  --hostname=emby \
  --restart=always \
  --name=emby \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/New_York \
  -e UMASK_SET=<022> `#optional` \
  -e NVIDIA_VISIBLE_DEVICES=all `#optional` \
  -p 8096:8096 \
  -p 8920:8920 `#optional` \
  -v /path/to/config:/config \
  -v /path/to/tvshows:/data/tvshows \
  -v /path/to/movies:/data/movies \
  -v /path/for/transcoding:/transcode `#optional` \
  --device /dev/dri:/dev/dri `#optional` \
  timstephens24/emby
```

## Architecture Tags
Current support is for x86-64 only, but hopefully arm64 and armhf soon as well.

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | latest |

## Version Tags

This image provides various versions that are available via tags. `latest` tag usually provides the latest stable version. Others are considered under development and caution must be exercised when using them.

| Tag | Description |
| :----: | --- |
| latest | Stable Emby release |
