.ONESHELL:

include .env .env.local

DOCKER_COMPOSE := docker-compose -f deployments/$(ENVIRONMENT)/docker-compose.yml --env-file .env.local

# ==================================================
# .TARGET: application
# ==================================================
.PHONY: main alsa/init momo/init momo/run

main: alsa/init momo/init # entrypoint
	$(MAKE) momo/run

alsa/init: # initialize configuration for ALSA
	arecord -L | \
	awk -F',' '
		/^plughw:/ {
			gsub(/^.+=/, "", $$1);
			gsub(/^.+=/, "", $$2);
			printf("pcm.!default {\n  type plug\n  slave {\n    pcm \"hw:CARD=%s,DEV=%s\"\n  }\n}\n\nctl.!default {\n    type hw\n    card %s\n}", $$1, $$2, $$1);
		}
	' | \
	tee ~/.asoundrc
momo/init: # download binary for WebRTC Native Client Momo
	if [ ! -e bin ]; then
		curl -fsSLO https://github.com/shiguredo/momo/releases/download/2022.4.1/momo-2022.4.1_raspberry-pi-os_armv8.tar.gz
		tar xzf momo-2022.4.1_raspberry-pi-os_armv8.tar.gz
		mv momo-2022.4.1_raspberry-pi-os_armv8 bin
	fi
momo/run: # start streaming with Momo
	cd bin && ./momo test

# ==================================================
# .TARGET: video4linux
# ==================================================
.PHONY: v4l v4l/help

v4l: # set the value of the video controls
	ctrls=$$($(DOCKER_COMPOSE) exec $(SERVICE) v4l2-ctl -C brightness,contrast,saturation)
	printf "$$ctrls" | nl
	n=$$(.prompt 'control' 'number')
	ctrl=$$(printf "$$ctrls" | sed -n $${n}p | cut -d':' -f1)
	before=$$(printf "$$ctrls" | sed -n $${n}p | cut -d' ' -f2)
	after=$$(.prompt "value" "$$before" "$$before")
	yn=$$(.prompt "change '$$ctrl' from '$$before' to '$$after'" 'y/N')
	if [ "$$yn" = 'y' ]; then
		$(DOCKER_COMPOSE) exec $(SERVICE) v4l2-ctl -c $$ctrl=$$after
	fi
v4l/help: # display all video controls and their menus
	$(DOCKER_COMPOSE) exec $(SERVICE) v4l2-ctl -L

# ==================================================
# .TARGET: docker
# ==================================================
.PHONY: build build/% run run/% up up/% exec exec/% down down/% logs log log/%

build: build/$(SERVICE)
build/%: # build or rebuild a image
	$(DOCKER_COMPOSE) build $*

run: run/$(SERVICE)
run/%: # run a one-off command on a container
	$(DOCKER_COMPOSE) run --rm $* sh -c 'bash || sh'

exec: exec/$(SERVICE)
exec/%: # run a command in a running container
	$(DOCKER_COMPOSE) exec $* sh -c 'bash || sh'

up: # create and start containers, networks, and volumes
	$(DOCKER_COMPOSE) up -d
up/%: # create and start a container
	$(DOCKER_COMPOSE) up -d $*

down: # stop and remove containers, networks, images, and volumes
	$(DOCKER_COMPOSE) down
down/%: # stop and remove a container
	$(DOCKER_COMPOSE) rm -fsv $*

logs: # view output from containers
	$(DOCKER_COMPOSE) logs -f

log: log/$(SERVICE)
log/%: # view output from a container
	$(DOCKER_COMPOSE) logs -f $*

# ==================================================
# .TARGET: other
# ==================================================
.PHONY: help clean

help: # list available targets and some
	@len=$$(awk -F':' 'BEGIN {m = 0;} /^[^\s]+:/ {gsub(/%/, "<service>", $$1); l = length($$1); if(l > m) m = l;} END {print m;}' $(MAKEFILE_LIST)) && \
	printf \
		"%s%s\n\n%s\n%s\n\n%s\n%s\n" \
		"usage:" \
		"$$(printf " make <\033[1mtarget\033[0m>")" \
		"services:" \
		"$$($(DOCKER_COMPOSE) config --services | awk '{ $$1 == "$(SERVICE)" ? x = "*" : x = " "; } { printf("  \033[1m[%s] %s\033[0m\n", x, $$1); }')" \
		"targets:" \
		"$$(awk -F':' '
			function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s; } function rtrim(s) { sub(/[ \t\r\n]+$$/, "", s); return s; } function trim(s)  { return rtrim(ltrim(s)); }
			$$1 ~ /^#+[ \t]+\.TARGET$$/ { target = trim($$2); printf("  \033[2;37m%s:\033[m\n", target); } /^[^ \t]+:/ {gsub(/%/, target == "docker" ? "[service]" : "**", $$1); gsub(/^[^#]+/, "", $$2); gsub(/^[# \t]+/, "", $$2); if ($$2) printf "    \033[1m%-'$$len's\033[0m  %s\n", $$1, $$2;}' $(MAKEFILE_LIST)
		)"

clean: # remove cache files from the working directory
	rm bin momo-*.tar.gz
