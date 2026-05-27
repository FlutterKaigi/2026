SRC := $(shell find ./lib ./web)
DART ?= fvm dart
JASPR_BUILD := $(DART) run jaspr_cli:jaspr build

build: $(SRC)
	$(JASPR_BUILD)

# CI invokes this for PR preview builds and supplies PR_NUMBER.
build-preview:
	@if [ -z "$(PR_NUMBER)" ]; then echo "PR_NUMBER is required"; exit 1; fi
	$(JASPR_BUILD) --dart-define=BASE_HREF=/pr-preview/pr-$(PR_NUMBER)/

.PHONY: build-preview
