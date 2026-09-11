MAKEFILE_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

PDK_ROOT ?= $(MAKEFILE_DIR)/gf180mcu
PDK ?= gf180mcuD
PDK_COMMIT ?= f6eeac7dad085ffcc829ccfd721f7b4ce39edcf7
SCL ?= gf180mcu_fd_sc_mcu7t5v0

VENV ?= $(MAKEFILE_DIR)/.venv
VENV_PYTHON = $(VENV)/bin/python3
VENV_STAMP = $(VENV)/.requirements-installed

# Native only if both librelane and yosys are on PATH. Pip librelane without
# Yosys is not enough; then Dockerize.
ifeq ($(shell command -v librelane >/dev/null 2>&1 && command -v yosys >/dev/null 2>&1 && echo yes),yes)
LIBRELANE_BIN = librelane
else
LIBRELANE_BIN = $(VENV_PYTHON) -m librelane --docker-no-tty --dockerized
endif

CIEL_BIN = $(VENV_PYTHON) -m ciel

CORE_OPTS = --pdk ${PDK} --pdk-root ${PDK_ROOT} --manual-pdk --scl ${SCL}

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Generic core (no pads): make synth | make core'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
.PHONY: help

all: synth ## Generic core synthesis
.PHONY: all

fetch-rtl: ## Re-vendor fx68k RTL at the pinned commit
	./scripts/fetch-rtl.sh
.PHONY: fetch-rtl

sv2v: ## Patch fx68k SV, convert to Verilog, emit ROM modules from .mem
	./scripts/run-sv2v.sh
.PHONY: sv2v

roms: ## Generate uRom.v / nanoRom.v from microrom.mem / nanorom.mem
	./scripts/mem-to-verilog.py
.PHONY: roms

fetch-um: ## Refresh the MC68000UM text extract
	./scripts/fetch-mc68000um.sh
.PHONY: fetch-um

$(VENV_STAMP): requirements.txt
	python3 -m venv $(VENV)
	$(VENV_PYTHON) -m pip install -U pip
	$(VENV_PYTHON) -m pip install -r $(MAKEFILE_DIR)/requirements.txt
	touch $(VENV_STAMP)

venv: $(VENV_STAMP) ## Create .venv and install ciel + librelane
.PHONY: venv

$(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK): $(VENV_STAMP)
	$(CIEL_BIN) enable $(PDK_COMMIT) --pdk-root $(PDK_ROOT) --pdk-family $(PDK) --include-libraries all

clone-pdk: $(PDK_ROOT)/ciel/gf180mcu/versions/$(PDK_COMMIT)/$(PDK) ## Clone the gf180mcu PDK
.PHONY: clone-pdk

synth: venv clone-pdk sv2v ## Generic core: synthesis + pre-PnR STA (no pads)
	$(LIBRELANE_BIN) ${CORE_OPTS} --overwrite --run-tag synth core/liberty.yaml core/synth.yaml
.PHONY: synth

core: venv clone-pdk sv2v ## Generic core: Classic flow through GDS (no pads)
	$(LIBRELANE_BIN) ${CORE_OPTS} --overwrite --run-tag core --save-views-to $(MAKEFILE_DIR)/core/final core/liberty.yaml core/config.yaml
.PHONY: core
