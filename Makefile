# Define docker compose command unless it is redefined 
# You can redefine it by setting legacy dockerCompose := docker-compose in parent Makefile
dockerCompose ?= docker compose

up:
	$(dockerCompose) up -d

down:
	$(dockerCompose) down

restart: down up

start:
	$(dockerCompose) start

stop:
	$(dockerCompose) stop

logs:
	$(dockerCompose) logs --follow --tail 100

build:
	$(dockerCompose) build

pull:
	$(dockerCompose) pull

ps:
	$(dockerCompose) ps
