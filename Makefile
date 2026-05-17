NASM ?= nasm
QEMU ?= qemu-system-i386

IMG := tinydos.img
BOOT_BIN := boot.bin
KERNEL_BIN := kernel.bin
FLOPPY_SIZE := 1474560
KERNEL_MAX := 32768

.PHONY: all run clean

all: $(IMG)

$(BOOT_BIN): BOOT-OS.ASM
	$(NASM) -f bin -o $@ $<

$(KERNEL_BIN): MAIN_SYSTEM.ASM COMMAND-LINE.ASM DRIVERS.ASM HEX.ASM
	$(NASM) -f bin -o $@ MAIN_SYSTEM.ASM
	@size=$$(wc -c < $@); \
	if [ $$size -gt $(KERNEL_MAX) ]; then \
		echo "Kernel is $$size bytes, but boot sector loads only $(KERNEL_MAX) bytes."; \
		exit 1; \
	fi

$(IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@dd if=/dev/zero of=$@ bs=512 count=2880 status=none
	@dd if=$(BOOT_BIN) of=$@ conv=notrunc status=none
	@dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc status=none
	@echo "Built $(IMG) ($(FLOPPY_SIZE) bytes)"

run: all
	$(QEMU) -fda $(IMG) -boot a

clean:
	rm -f $(BOOT_BIN) $(KERNEL_BIN) $(IMG)
