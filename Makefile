# Copyright Splunk Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO               = go
TIMEOUT          = 15
PKGS             = ./...
TOOLS_MODULE_DIR = ./internal/tools
TEST_RESULTS     = $(CURDIR)/test-results

# Verbose output
V = 0
Q = $(if $(filter 1,$V),,@)

# ALL_MODULES includes ./* dirs (excludes . and ./internal/tools dir).
ALL_MODULES := $(shell find . -type f -name "go.mod" -exec dirname {} \; | sort )
# All directories with go.mod files related to opentelemetry library. Used for building, testing and linting.
ALL_GO_MOD_DIRS := $(filter-out $(TOOLS_MODULE_DIR), $(ALL_MODULES))
# All directories sub-modules. Used for tagging and generating dependabot config.
SUBMODULES = $(filter-out ., $(ALL_GO_MOD_DIRS))

.DEFAULT_GOAL := all

.PHONY: all
all: mod-tidy build lint license-check test-race

.PHONY: ci
ci: mod-tidy build lint license-check diff

.PHONY: build
build: # build whole codebase
	${call for-all-modules,$(GO) build $(PKGS)}
# Compile all test code.
	${call for-all-modules,$(GO) test -vet=off -run xxxxxMatchNothingxxxxx $(PKGS) >/dev/null}

# Tools

TOOLS = $(CURDIR)/.tools

$(TOOLS):
	@mkdir -p $@
$(TOOLS)/%: | $(TOOLS)
	$Q cd $(TOOLS_MODULE_DIR) \
		&& $(GO) build -o $@ $(PACKAGE)

GOLANGCI_LINT = $(TOOLS)/golangci-lint
$(TOOLS)/golangci-lint: PACKAGE=github.com/golangci/golangci-lint/cmd/golangci-lint

# Tests

TEST_TARGETS := test-bench test-short test-verbose test-race
.PHONY: $(TEST_TARGETS) test tests
test-bench:   ARGS=-run=xxxxxMatchNothingxxxxx -test.benchtime=1ms -bench=.
test-short:   ARGS=-short
test-verbose: ARGS=-v
test-race:    ARGS=-race
$(TEST_TARGETS): test
test tests:
	${call for-all-modules,$(GO) test -timeout $(TIMEOUT)s $(ARGS) $(PKGS)}

COVERAGE_MODE    = atomic
COVERAGE_PROFILE = $(COVERAGE_DIR)/profile.out
.PHONY: test-coverage
test-coverage: COVERAGE_DIR := $(TEST_RESULTS)/coverage_$(shell date -u +"%s")
test-coverage:
	$Q mkdir -p $(COVERAGE_DIR)
	${call for-all-modules,$(GO) test -coverpkg=$(PKGS) -covermode=$(COVERAGE_MODE) -coverprofile="$(COVERAGE_PROFILE)" $(PKGS)}

.PHONY: lint
lint: | $(GOLANGCI_LINT)
# Run once to fix and run again to verify resolution.
	${call for-all-modules,$(GOLANGCI_LINT) run --fix && $(GOLANGCI_LINT) run}

# Pre-release targets

.PHONY: add-tag
add-tag: # example usage: make add-tag tag=v1.100.1
	$Q [ "$(tag)" ] || ( echo ">> 'tag' is not set"; exit 1 )
	@echo "Adding tag $(tag)"
	$Q git tag -a $(tag) -m "Version $(tag)"
	$Q set -e; for dir in $(SUBMODULES); do \
	  (echo Adding tag "$${dir:2}/$(tag)" && \
	 	git tag -a "$${dir:2}/$(tag)" -m "Version ${dir:2}/$(tag)" ); \
	done

.PHONY: delete-tag
delete-tag: # example usage: make delete-tag tag=v1.100.1
	$Q [ "$(tag)" ] || ( echo ">> 'tag' is not set"; exit 1 )
	@echo "Deleting tag $(tag)"
	$Q git tag -d $(tag)
	$Q set -e; for dir in $(SUBMODULES); do \
	  (echo Deleting tag "$${dir:2}/$(tag)" && \
	 	git tag -d "$${dir:2}/$(tag)" ); \
	done

.PHONY: push-tag
push-tag: # example usage: make push-tag tag=v1.100.1 remote=origin
	$Q [ "$(tag)" ] || ( echo ">> 'tag' is not set"; exit 1 )
	$Q [ "$(remote)" ] || ( echo ">> 'remote' is not set"; exit 1 )
	@echo "Pushing tag $(tag) to $(remote)"
	$Q git push $(remote) $(tag)
	$Q set -e; for dir in $(SUBMODULES); do \
	  (echo Pushing tag "$${dir:2}/$(tag) to $(remote)" && \
	 	git push $(remote) "$${dir:2}/$(tag)"); \
	done

DEPENDABOT_PATH=./.github/dependabot.yml
.PHONY: gendependabot
gendependabot: # generate dependabot.yml
	@echo "Recreate dependabot.yml file"
	@printf "# File generated by \"make gendependabot\"; DO NOT EDIT.\n\n" > ${DEPENDABOT_PATH}
	@printf "version: 2\n" >> ${DEPENDABOT_PATH}
	@printf "updates:\n" >> ${DEPENDABOT_PATH}
	@printf "  - package-ecosystem: \"github-actions\"\n    directory: \"/\"\n    schedule:\n      interval: \"daily\"\n" >> ${DEPENDABOT_PATH}
	@echo "Add entry for \"/\""
	@printf "  - package-ecosystem: \"gomod\"\n    directory: \"/\"\n    schedule:\n      interval: \"daily\"\n" >> ${DEPENDABOT_PATH}
	@set -e; for dir in $(SUBMODULES); do \
		(echo "Add entry for \"$${dir:1}\"" && \
		  printf "  - package-ecosystem: \"gomod\"\n    directory: \"$${dir:1}\"\n    schedule:\n      interval: \"daily\"\n" >> ${DEPENDABOT_PATH} ); \
	done

.PHONY: license-check
license-check: # check if license is applied to relevant files
	$Q licRes=$$(for f in $$(find . -type f \( -iname '*.go' -o -iname '*.sh' -o -iname '*.yml' \)) ; do \
	           awk '/Copyright Splunk Inc.|generated|GENERATED/ && NR<=3 { found=1; next } END { if (!found) print FILENAME }' $$f; \
	   done); \
	   if [ -n "$${licRes}" ]; then \
	           echo "license header checking failed:"; echo "$${licRes}"; \
	           exit 1; \
	   fi

.PHONY: mod-tidy
mod-tidy: # go mod tidy for all modules
	${call for-all-modules,$(GO) mod tidy}
	@echo "$(GO) mod tidy in $(TOOLS_MODULE_DIR)"
	$Q (cd $(TOOLS_MODULE_DIR) && $(GO) mod tidy)

.PHONY: diff
diff:
	$Q git diff --exit-code
	$Q RES=$$(git status --porcelain) ; if [ -n "$$RES" ]; then echo $$RES && exit 1 ; fi

.PHONY: for-all
for-all: # run a command in all modules, example: make for-all cmd="go mod tidy"
	$Q [ "$(cmd)" ] || ( echo ">> 'cmd' is not set"; exit 1 )
	${call for-all-modules, $(cmd)}

define for-all-modules # run provided command for each module
   $Q EXIT=0 ;\
	for dir in $(ALL_GO_MOD_DIRS); do \
	  echo "${1} in $${dir}"; \
	  (cd "$${dir}" && ${1}) || EXIT=$$?; \
	done ;\
	exit $$EXIT
endef
