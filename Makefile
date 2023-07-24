include .env
export

.DEFAULT_GOAL:=help

.PHONY: dependencies
dependencies:
	docker-compose run --rm --no-deps php sh -lc './composer install --no-interaction --no-suggest --no-scripts --ansi'

.PHONY: test
test:
	docker-compose run --rm --no-deps php sh -lc './vendor/bin/phpunit --testdox --exclude-group=none --colors=always'

.PHONY: qa
qa: php-cs-fixer-ci phpstan

.PHONY: php-cs-fixer
php-cs-fixer:
	docker-compose run --rm --no-deps php sh -lc './vendor/bin/php-cs-fixer fix --no-interaction --allow-risky=yes --diff --verbose'

.PHONY: php-cs-fixer-ci
php-cs-fixer-ci:
	docker-compose run --rm --no-deps php sh -lc './vendor/bin/php-cs-fixer fix --dry-run --no-interaction --allow-risky=yes --diff --verbose --stop-on-violation'

PHONY: phpstan
phpstan:
	vdocker-compose run --rm --no-deps php sh -lc './endor/bin/phpstan analyse --level=5 src/'

.PHONY: changelog
changelog:
	git log $$(git describe --abbrev=0 --tags)...HEAD --no-merges --pretty=format:"* [%h](http://github.com/${TRAVIS_REPO_SLUG}/commit/%H) %s (%cN)"

.PHONY: license
license:
	docker-compose run --rm --no-deps php sh -lc './vendor/bin/docheader check --no-interaction --ansi -vvv {src,test,examples}'

# Based on https://suva.sh/posts/well-documented-makefiles/
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

sources = bin/console config src
version = $(shell git describe --tags --dirty --always)
build_name = application-$(version)
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
#$(eval $(RUN_ARGS):;@:)

.PHONY: fix-permission
fix-permission: ## fix permission for docker env
	sudo chown -R $(shell whoami):$(shell whoami) *
	sudo chown -R $(shell whoami):$(shell whoami) .docker/*

.PHONY: build
build: ## build environment and initialize composer and project dependencies
	docker build --build-arg CI_SERVICE_NAME=$(CI_SERVICE_NAME) .docker/php8.0-dev/ -t gitlab.micro-moduletech.net:5001/micro-module/dev/shared/modules/package-$(CI_SERVICE_NAME)/php8.0-dev:$(CI_COMMIT_REF_SLUG)
	docker-compose build
	docker-compose run --rm --no-deps php sh -lc 'composer install'

.PHONY: logs
logs: ## look for service logs
	docker-compose logs -f $(RUN_ARGS)

.PHONY: composer-install
composer-install: ## Install project dependencies
	docker-compose run --rm --no-deps php sh -lc 'composer install'

.PHONY: composer-update
composer-update: ## Update project dependencies
	docker-compose run --rm --no-deps php sh -lc 'composer update'

.PHONY: composer-outdated
composer-outdated: ## Show outdated project dependencies
	docker-compose run --rm --no-deps php sh -lc 'composer outdated'

.PHONY: composer-validate
composer-validate: ## Validate composer config
	    docker-compose run --rm --no-deps php sh -lc 'composer validate --no-check-publish'

.PHONY: composer
composer: ## Execute composer command
	docker-compose run --rm --no-deps php sh -lc "composer $(RUN_ARGS)"

.PHONY: phpunit
phpunit: ## execute project unit tests
	docker-compose run --rm php sh -lc  "./vendor/bin/phpunit $(conf)"

