# Flavos OS — Makefile
# Orquestrador principal do build.
# Uso: make [target]
#   make deps     — Verifica dependências do host
#   make rootfs   — Gera rootfs via debootstrap
#   make image    — Cria imagem .img particionada
#   make install  — Copia rootfs para imagem, instala bootloader
#   make test     — Executa smoke test offline
#   make boot     — Inicia QEMU com a imagem
#   make all      — Pipeline completo (rootfs → image → install → test)
#   make clean    — Remove build/

SHELL := /bin/bash
.DEFAULT_GOAL := help

PROJECT_ROOT := $(shell pwd)
BUILD_DIR    := $(PROJECT_ROOT)/build
ROOTFS_DIR   := $(BUILD_DIR)/rootfs
IMAGE        := $(BUILD_DIR)/flavos.img
SCRIPTS      := $(PROJECT_ROOT)/scripts

.PHONY: help deps rootfs image install test manifest boot write-disk all clean

help:
	@echo ""
	@echo "  Flavos OS — Build System"
	@echo ""
	@echo "  Targets:"
	@echo "    make deps      Verifica dependências do host"
	@echo "    make rootfs    Gera root filesystem (requer sudo)"
	@echo "    make image     Cria imagem de disco (requer sudo)"
	@echo "    make install   Instala sistema na imagem (requer sudo)"
	@echo "    make test      Executa smoke test offline"
	@echo "    make manifest  Gera metadados .json do build final"
	@echo "    make boot      Inicia VM via QEMU"
	@echo "    make boot-gui  Inicia VM via QEMU (modo gráfico)"
	@echo "    make write-disk DISK=/dev/sdX  Grava imagem em disco real (CUIDADO)"
	@echo "    make all       Pipeline completo (requer sudo)"
	@echo "    make clean     Remove artefatos de build"
	@echo ""

deps:
	@bash $(SCRIPTS)/00-check-deps.sh

rootfs:
	@sudo bash $(SCRIPTS)/01-create-rootfs.sh

image:
	@sudo bash $(SCRIPTS)/02-create-image.sh

install:
	@sudo bash $(SCRIPTS)/03-install-system.sh

test:
	@bash $(PROJECT_ROOT)/tests/smoke-test.sh

manifest:
	@bash $(SCRIPTS)/99-generate-manifest.sh

boot:
	@bash $(SCRIPTS)/04-boot-vm.sh --serial

boot-gui:
	@bash $(SCRIPTS)/04-boot-vm.sh --gui

write-disk:
	@if [ -z "$(DISK)" ]; then \
		echo ""; \
		echo "ERRO: Especifique o disco alvo: make write-disk DISK=/dev/sdX"; \
		echo ""; \
		exit 1; \
	fi
	@sudo bash $(SCRIPTS)/05-write-to-disk.sh --disk $(DISK)

all: rootfs image install test manifest
	@echo ""
	@echo "=== Build completo. Execute 'make boot' para iniciar a VM. ==="

clean:
	@echo "Removendo artefatos de build..."
	@if mountpoint -q "$(BUILD_DIR)/mnt_root" 2>/dev/null; then sudo umount -lf "$(BUILD_DIR)/mnt_root"; fi
	@if mountpoint -q "$(BUILD_DIR)/mnt_esp" 2>/dev/null; then sudo umount -lf "$(BUILD_DIR)/mnt_esp"; fi
	@# Desmontar qualquer coisa dentro do rootfs (dev, proc, sys, run)
	@for mp in $(ROOTFS_DIR)/run $(ROOTFS_DIR)/sys $(ROOTFS_DIR)/proc $(ROOTFS_DIR)/dev/pts $(ROOTFS_DIR)/dev; do \
		if mountpoint -q "$$mp" 2>/dev/null; then sudo umount -lf "$$mp"; fi; \
	done
	@# Desanexar loop devices associados à imagem
	@for loop in $$(losetup -j "$(IMAGE)" 2>/dev/null | cut -d: -f1); do \
		sudo losetup -d "$$loop" 2>/dev/null || true; \
	done
	@sudo rm -rf $(BUILD_DIR)
	@echo "Limpo."
