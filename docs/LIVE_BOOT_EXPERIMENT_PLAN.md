# Live Boot Experiment Plan

This document defines the approach for validating the Live Boot Strategy outlined in `docs/LIVE_BOOT_STRATEGY.md`. The goal is to build an experimental Live ISO from the existing Flavos OS rootfs without interfering with the stable build pipeline.

## 1. Experimental Constraints

- **Isolation:** The experiment must strictly output to `build/live/`.
- **Safety:** The script must not touch physical disks, invoke `dd`, or modify existing build scripts (`Makefile`, `02-create-image.sh`).
- **Opt-in:** The prototype script (`scripts/06-create-live-prototype.sh`) will not be added to the default `make all` target.

## 2. Dependencies

To build the prototype, the host environment requires:
- `squashfs-tools` (for `mksquashfs`)
- `xorriso` (for ISO generation)
- `grub-pc-bin` (for Legacy BIOS boot)
- `grub-efi-amd64-bin` (for UEFI 64-bit boot)

## 3. Prototype Script Workflow

The stub script (`06-create-live-prototype.sh`) will implement the following flow:

1. **Rootfs Preparation:**
   - Verify if `build/rootfs.tar.gz` (or the unpacked rootfs) exists.
   - Extract/copy the rootfs to a temporary staging area (`build/live/rootfs_stage`).
2. **Inject Live Dependencies:**
   - `chroot` into the staging area to install `live-boot`, `live-boot-initramfs-tools`, and update the initramfs.
3. **Squashfs Generation:**
   - Compress the staged rootfs using:
     `mksquashfs build/live/rootfs_stage build/live/iso/live/filesystem.squashfs -comp zstd -Xcompression-level 3 -b 256K`
4. **Bootloader Setup:**
   - Copy the kernel (`vmlinuz`) and `initrd.img` from the rootfs to `build/live/iso/live/`.
   - Generate `grub.cfg` with the three planned boot entries (Standard, Safe Graphics, Low RAM).
5. **ISO Packaging:**
   - Run `grub-mkrescue -o build/flavos-live-experiment.iso build/live/iso`.

## 4. Validation Steps

Once the prototype is successfully generated, it should be validated in a VM:

1. **Test Standard Boot (UEFI & BIOS)**
   - Boot VM with 2GB RAM using UEFI.
   - Boot VM with 2GB RAM using Legacy BIOS.
   - Verify that the desktop starts without kernel panics.

2. **Test Low RAM Boot**
   - Boot with the "Low RAM" grub entry (`overlay-size=384M`).
   - Run `df -h` and confirm the `/run/live/overlay` (or root `/`) tmpfs is capped at ~384M.

3. **Test Amnesia**
   - Create a file in `~gaua/Desktop/`.
   - Reboot the VM.
   - Confirm the file is gone.

## 5. Future Integration

If the experiment is deemed successful, the next stage will involve:
1. Formalizing the `06-create-live-prototype.sh` script into the main pipeline.
2. Optimizing the `chroot` step so that `live-boot` is automatically installed during `01-create-rootfs.sh` if a `BUILD_LIVE=true` flag is set.
3. Adding a `make live` target to the `Makefile`.
