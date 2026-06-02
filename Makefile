.PHONY: help validate up down restart logs deploy info

# Load .env if present (for PORTAINER_WEBHOOK)
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

HOST_IP ?= 10.0.0.10

help:           ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

validate:       ## Validate Caddyfile via Docker
	docker run --rm -v $(PWD)/Caddyfile:/etc/caddy/Caddyfile:ro caddy:2-alpine \
		caddy validate --config /etc/caddy/Caddyfile

up:             ## Start Caddy locally (testing)
	docker compose up -d

down:           ## Stop local Caddy
	docker compose down

restart:        ## Restart local Caddy
	docker compose restart

logs:           ## Tail local Caddy logs
	docker compose logs -f caddy

deploy:         ## Push to git + trigger Portainer redeploy
	@if [ -z "$$PORTAINER_WEBHOOK" ]; then \
		echo "ERROR: PORTAINER_WEBHOOK not set. Copy .env.example to .env and fill it in."; \
		exit 1; \
	fi
	git push origin main
	@echo ""
	@echo "Triggering Portainer redeploy..."
	@curl -k -sS -o /dev/null -w "HTTP %{http_code}\n" -X POST "$$PORTAINER_WEBHOOK"
	@echo "Deploy triggered. Check your Portainer instance to monitor."

info:           ## Show service map from Caddyfile
	@echo "DNS rewrite required: *.home.lan -> $(HOST_IP)"
	@echo ""
	@echo "Services:"
	@grep -E '^[a-z][a-z0-9-]*\.home\.lan' Caddyfile | awk '{print "  " $$1}'
