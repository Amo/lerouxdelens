APP_NAME := lerouxdelens
REMOTE_DOMAIN := lerouxdelens.com
LOCAL_DOMAIN := lerouxdelens.test
LOCAL_IMAGE := nginx:1.27-alpine
REMOTE_HOST := vps2
REMOTE_PORT := 22
REMOTE_DIR := /home/ops/apps/$(APP_NAME)
REMOTE_HTTP_PORT := 8094
CONTAINER_NAME := $(APP_NAME)-prod
LOCAL_CONTAINER_NAME := $(APP_NAME)-local
IMAGE_NAME := $(APP_NAME)
COMMIT_SHA := $(shell git rev-parse --short=12 HEAD)
ARCHIVE := /tmp/$(APP_NAME)-$(COMMIT_SHA).tar.gz
REMOTE_RELEASE_DIR := $(REMOTE_DIR)/releases/$(COMMIT_SHA)

.PHONY: build deploy check-clean local-setup local-up local-down local-logs

build:
	docker build -t $(IMAGE_NAME):local .

local-setup:
	bash ops/setup-local-host.sh "$(LOCAL_DOMAIN)"

local-up:
	@docker rm -f "$(LOCAL_CONTAINER_NAME)" >/dev/null 2>&1 || true
	docker run -d --restart unless-stopped --name "$(LOCAL_CONTAINER_NAME)" -p 127.0.0.1:80:80 -v "$(CURDIR):/usr/share/nginx/html:ro" $(LOCAL_IMAGE)
	@echo "Open http://$(LOCAL_DOMAIN) and refresh after edits"

local-down:
	@docker rm -f "$(LOCAL_CONTAINER_NAME)" >/dev/null 2>&1 || true

local-logs:
	docker logs -f "$(LOCAL_CONTAINER_NAME)"

check-clean:
	@test -z "$$(git status --porcelain)" || (echo "Refusing to deploy: working tree is not clean. Commit everything you want in production first."; exit 1)

deploy: check-clean
	@echo "Deploying $(APP_NAME) commit $(COMMIT_SHA) to $(REMOTE_HOST)"
	@git archive --format=tar.gz --output "$(ARCHIVE)" HEAD
	@ssh $(REMOTE_HOST) -p $(REMOTE_PORT) "mkdir -p '$(REMOTE_DIR)/releases'"
	@scp -P $(REMOTE_PORT) "$(ARCHIVE)" $(REMOTE_HOST):"$(REMOTE_RELEASE_DIR).tar.gz"
	@rm -f "$(ARCHIVE)"
	@ssh $(REMOTE_HOST) -p $(REMOTE_PORT) "set -eu; mkdir -p '$(REMOTE_RELEASE_DIR)'; tar -xzf '$(REMOTE_RELEASE_DIR).tar.gz' -C '$(REMOTE_RELEASE_DIR)'; rm -f '$(REMOTE_RELEASE_DIR).tar.gz'; sudo -n docker build -t '$(IMAGE_NAME):$(COMMIT_SHA)' '$(REMOTE_RELEASE_DIR)'; sudo -n docker rm -f '$(CONTAINER_NAME)' >/dev/null 2>&1 || true; sudo -n docker run -d --restart unless-stopped --name '$(CONTAINER_NAME)' -p 127.0.0.1:$(REMOTE_HTTP_PORT):80 '$(IMAGE_NAME):$(COMMIT_SHA)' >/dev/null; sudo -n nginx -t >/dev/null; sudo -n systemctl reload nginx; sudo -n docker image prune -f >/dev/null"
