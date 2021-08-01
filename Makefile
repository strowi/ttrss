SHELL:=/bin/bash -o pipefail

# detect OS
DETECTED_OS := $(shell uname)

# get all arguments after the target name
RUN_ARGS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))

# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)

# get target's first argument
TARGET_NAME := $(word 1, $(RUN_ARGS))
TARGET_ARG := $(word 2, $(RUN_ARGS))

# Computed from TARGET_NAME
UPPER_TARGET_NAME=$(shell echo ${TARGET_NAME} | tr '[:lower:]' '[:upper:]' | tr '-' '_')

# check prerequisites if not in the CI
ifndef GITLAB_CI
  export CI_REGISTRY_IMAGE := $(REGISTRY_IMAGE)
  export TAG := latest
else
  # running in Gitlab CI
  export TAG := $(CI_COMMIT_REF_SLUG)-$(CI_COMMIT_SHORT_SHA)
endif

EXECUTABLES := docker docker-compose

PREREQUISITES := $(foreach exec,$(EXECUTABLES),\
$(if $(shell which $(exec)), ,$(error "Error: $(exec) is not available in your PATH")))

export UID := $(shell id -u)
export GID := $(shell id -g)


build:
	docker-compose --project-directory ${TARGET_NAME} build

deploy:
	rsync -a --progress --exclude .git . hasnoname.de:$$(basename $${PWD})/
	ssh hasnoname.de "cd $$(basename $${PWD}) && docker-compose up --build -d"
