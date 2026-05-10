# Flavos OS — Makefile
# Orquestrador principal do build.
# Uso: make [target]
#   make deps      — Verifica dependências do host
#   make rootfs    — Gera rootfs via debootstrap
#   make image     — Cria imagem .img particionada
#   make install   — Copia rootfs para imagem, instala bootloader
#   make test      — Executa smoke test offline
#   make boot      — Inicia QEMU com a imagem
#   make all       — Pipeline completo (rootfs → image → install → test)
#   make compress  — Comprime .img → .img.xz
#   make checksum  — Gera .img.xz.sha256
#   make release   — Pipeline de release (compress → checksum → manifest)
#   make clean     — Remove build/

SHELL := /bin/bash
.DEFAULT_GOAL := help

PROJECT_ROOT := $(shell pwd)
BUILD_DIR    := $(PROJECT_ROOT)/build
ROOTFS_DIR   := $(BUILD_DIR)/rootfs
IMAGE        := $(BUILD_DIR)/flavos.img
SCRIPTS      := $(PROJECT_ROOT)/scripts

# Release naming (sourced from config/flavos.conf via scripts)
RELEASE_BASENAME := $(shell bash -c 'source $(PROJECT_ROOT)/config/flavos.conf && echo $$RELEASE_IMAGE_BASENAME')
RELEASE_XZ       := $(BUILD_DIR)/$(RELEASE_BASENAME).img.xz
RELEASE_SHA      := $(RELEASE_XZ).sha256

.PHONY: help deps rootfs image install test manifest boot write-disk compress checksum release all clean

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
	@echo "    make compress  Comprime .img → .img.xz (xz -9)"
	@echo "    make checksum  Gera .img.xz.sha256"
	@echo "    make release   Pipeline de release (compress+checksum+manifest)"
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

# Opções de Validação em VM (Etapa 8A1)
DISK_BUS ?= virtio
NET_MODEL ?= virtio
DUMMY_DISK ?=
VM_ARGS = --disk-bus $(DISK_BUS) --net-model $(NET_MODEL)
ifneq ($(DUMMY_DISK),)
	VM_ARGS += --attach-dummy $(DUMMY_DISK)
endif

boot:
	@bash $(SCRIPTS)/04-boot-vm.sh --serial $(VM_ARGS)

boot-gui:
	@bash $(SCRIPTS)/04-boot-vm.sh --gui $(VM_ARGS)

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
	@echo "    Para gerar artefatos de release: make release"

compress:
	@echo "=== Comprimindo imagem para release ==="
	@if [ ! -f "$(BUILD_DIR)/flavos-0.1-basis-amd64.img" ]; then \
		echo "ERRO: Imagem .img não encontrada em $(BUILD_DIR)/. Execute 'make all' primeiro."; \
		exit 1; \
	fi
	@echo "  Fonte: $(BUILD_DIR)/flavos-0.1-basis-amd64.img"
	@echo "  Destino: $(RELEASE_XZ)"
	@echo "  Isso pode levar vários minutos..."
	@xz -9 -T0 --keep --force --stdout "$(BUILD_DIR)/flavos-0.1-basis-amd64.img" > "$(RELEASE_XZ)"
	@echo "  Comprimido: $$(du -h "$(RELEASE_XZ)" | awk '{print $$1}')"

checksum:
	@echo "=== Gerando checksum SHA256 ==="
	@if [ ! -f "$(RELEASE_XZ)" ]; then \
		echo "ERRO: $(RELEASE_XZ) não encontrado. Execute 'make compress' primeiro."; \
		exit 1; \
	fi
	@cd "$(BUILD_DIR)" && sha256sum "$(RELEASE_BASENAME).img.xz" > "$(RELEASE_BASENAME).img.xz.sha256"
	@echo "  SHA256: $$(cat "$(RELEASE_SHA)")"

release: compress checksum manifest
	@echo ""
	@echo "=== Release artifacts gerados ==="
	@echo "  Imagem:    $(RELEASE_XZ)"
	@echo "  Checksum:  $(RELEASE_SHA)"
	@echo "  Manifest:  $(BUILD_DIR)/flavos-$$(bash -c 'source $(PROJECT_ROOT)/config/flavos.conf && echo $$FLAVOS_VERSION')-manifest.json"
	@echo ""
	@echo "  Validar com: cd build && sha256sum -c $(RELEASE_BASENAME).img.xz.sha256"

clean:
	@echo "Sincronizando IO antes da limpeza..."
	@sync
	@echo "Removendo artefatos de build..."
	@if mountpoint -q "$(BUILD_DIR)/mnt_root" 2>/dev/null; then sudo umount "$(BUILD_DIR)/mnt_root" || sudo umount -l "$(BUILD_DIR)/mnt_root"; fi
	@if mountpoint -q "$(BUILD_DIR)/mnt_esp" 2>/dev/null; then sudo umount "$(BUILD_DIR)/mnt_esp" || sudo umount -l "$(BUILD_DIR)/mnt_esp"; fi
	@# Desmontar qualquer coisa dentro do rootfs (dev, proc, sys, run)
	@for mp in $(ROOTFS_DIR)/run $(ROOTFS_DIR)/sys $(ROOTFS_DIR)/proc $(ROOTFS_DIR)/dev/pts $(ROOTFS_DIR)/dev; do \
		if mountpoint -q "$$mp" 2>/dev/null; then sudo umount "$$mp" || sudo umount -l "$$mp"; fi; \
	done
	@# Desanexar loop devices associados à imagem
	@for loop in $$(losetup -j "$(IMAGE)" 2>/dev/null | cut -d: -f1); do \
		sudo losetup -d "$$loop" 2>/dev/null || true; \
	done
	@sudo rm -rf $(BUILD_DIR)
	@echo "Limpo."
