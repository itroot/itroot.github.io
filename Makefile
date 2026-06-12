SHELL := bash
export BASH_ENV := $(CURDIR)/.makerc
.SUFFIXES:
.PHONY: all build clean serve help
.DEFAULT_GOAL := all

# Verify dependencies
CMARK_GFM := $(shell command -v cmark-gfm 2>/dev/null)
$(if $(CMARK_GFM),,$(error "cmark-gfm required: sudo pacman -S cmark-gfm"))

# Source and output
SRC_DIR := src
OUT_DIR := docs
TPL_DIR := templates

# Discover articles: src/YYYY-MM-DD-slug.md
ARTICLES := $(wildcard $(SRC_DIR)/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md)
# Derive slugs: src/2025-06-12-lorem-ipsum.md → 2025-06-12-lorem-ipsum
SLUGS := $(ARTICLES:$(SRC_DIR)/%.md=%)
# Output files: docs/2025-06-12-lorem-ipsum/index.html
OUT_FILES := $(SLUGS:%=$(OUT_DIR)/%/index.html)

all: build

build: $(OUT_FILES) $(OUT_DIR)/index.html # Compile all articles and index

# Compile a single article: src/YYYY-MM-DD-slug.md → docs/YYYY-MM-DD-slug/index.html
$(OUT_DIR)/%/index.html: $(SRC_DIR)/%.md $(TPL_DIR)/header.html $(TPL_DIR)/footer.html
	@mkdir -p $(@D)
	TITLE=$$(extract_meta $< title) && \
	render $< > $(@D)/.body.html && \
	assemble "$$TITLE" $(TPL_DIR)/header.html $(@D)/.body.html $(TPL_DIR)/footer.html > $@ && \
	rm -f $(@D)/.body.html

# Generate the homepage index
$(OUT_DIR)/index.html: $(ARTICLES) $(TPL_DIR)/header.html $(TPL_DIR)/footer.html
	@mkdir -p $(@D)
	gen_index $(SRC_DIR) $(TPL_DIR)/header.html $(TPL_DIR)/footer.html > $@

serve: # Preview locally
	@cd $(OUT_DIR) && python3 -m http.server 8080

clean: # Remove build output
	rm -rf $(OUT_DIR)

install-git-hooks: # Install git hooks (symlink from scripts/)
	@mkdir -p .git/hooks && ln -sf $(CURDIR)/scripts/prepare-commit-msg .git/hooks/prepare-commit-msg && echo "Installed .git/hooks/prepare-commit-msg → scripts/"

help: # Show available targets
	@awk -F':+ |#' '/^[a-zA-Z._%-]+:.+#.+$$/ { printf "\033[1;32m%-20s\033[0m %s\n", $$1, $$3 }' $(MAKEFILE_LIST)
