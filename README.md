# WebRTC Streamer in Raspberry Pi OS

## Usage

```
usage: make <target>

services:
  [*] raspios-webrtc

targets:
  application:
    main              entrypoint
    alsa/init         initialize configuration for ALSA
    momo/init         download binary for WebRTC Native Client Momo
    momo/run          start streaming with Momo
  video4linux:
    v4l               set the value of the video controls
    v4l/help          display all video controls and their menus
  docker:
    build/[service]   build or rebuild a image
    run/[service]     run a one-off command on a container
    exec/[service]    run a command in a running container
    up                create and start containers, networks, and volumes
    up/[service]      create and start a container
    down              stop and remove containers, networks, images, and volumes
    down/[service]    stop and remove a container
    logs              view output from containers
    log/[service]     view output from a container
  other:
    help              list available targets and some
    clean             remove cache files from the working directory
```
