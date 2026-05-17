; ---------------------------------------------------------------------------
; MAIN_SYSTEM.ASM
; TinyDOS 16-bit real-mode kernel core
;
; The boot sector loads this binary at 1000:0000 and far-jumps here.
; This file includes the tiny driver layer, HEX utility, and command shell.
; ---------------------------------------------------------------------------

BITS 16
ORG 0x0000

STACK_SEG EQU 0x7000
STACK_TOP EQU 0xFFFE

kernel_start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, STACK_SEG
    mov ss, ax
    mov sp, STACK_TOP
    sti

    call tiny_init
    call shell_start

; The shell normally never returns. If it ever does, keep the CPU parked.
tiny_main_loop:
    hlt
    jmp tiny_main_loop

tiny_init:
    call set_text_mode
    call clear_screen
    call ramfs_init
    mov si, tiny_banner
    call print_string
    call print_newline
    ret

; The old DOS style here is intentional: all modules become one small binary.
%include "DRIVERS.ASM"
%include "HEX.ASM"
%include "COMMAND-LINE.ASM"

tiny_banner db 'TinyDOS 0.3 - 16-bit real mode', 13, 10
            db 'Type HELP for commands.', 13, 10, 0
