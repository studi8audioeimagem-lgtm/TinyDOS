# TinyDOS

TinyDOS is a tiny hobby DOS-like operating system written entirely in x86 Assembly.

It is designed to:
- fit inside a single 1.44MB floppy disk image
- boot in real hardware or emulators
- stay simple and educational
- provide a minimal command-line environment
- experiment with low-level operating system development

TinyDOS currently runs in 16-bit real mode and uses BIOS interrupts for hardware access.

---

# Features

## Bootloader
- Custom boot sector
- Loads kernel directly from floppy sectors
- Boots on x86 PCs and emulators

## Kernel
- Real mode x86 Assembly kernel
- VGA text mode interface
- Keyboard input handling
- Basic memory management

## Command Line
Commands currently implemented include:

| Command | Description |
|---|---|
| HELP | Show commands |
| CLS | Clear screen |
| VER | Show version |
| ECHO | Print text |
| DIR | List RAM files |
| WRITE | Create/write file |
| APPEND | Append to file |
| TYPE | View file |
| DEL | Delete file |
| REN | Rename file |
| COPY | Copy file |
| MEM | Memory info |
| FORMAT | Clear RAM disk |
| FASM | Tiny assembler experiment |

## RAM File System
TinyDOS includes an in-memory filesystem that stores files while the OS is running.

Current limitations:
- data is not persistent
- files disappear after reboot
- no FAT12/FAT16 support yet

---

# Project Structure

```text
BOOT-OS.ASM        -> Bootloader
MAIN_SYSTEM.ASM    -> Main kernel
COMMAND-LINE.ASM   -> Shell and commands
DRIVERS.ASM        -> Drivers and hardware routines
HEX.ASM            -> Hex utilities
Makefile           -> Build system
