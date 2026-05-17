; ---------------------------------------------------------------------------
; BOOT-OS.ASM
; TinyDOS boot sector
;
; Assembled as a raw 512-byte boot sector and loaded by the BIOS at 0000:7C00.
; It prepares real-mode segments, reads the TinyDOS kernel from a 1.44MB
; floppy using BIOS INT 13h, and jumps to the loaded kernel.
; ---------------------------------------------------------------------------

BITS 16
ORG 0x7C00

KERNEL_SEG     EQU 0x1000          ; Kernel load segment: physical 0x10000.
KERNEL_OFF     EQU 0x0000
KERNEL_SECTORS EQU 64              ; Small kernel span, still on one floppy.

boot_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00                ; Small temporary stack below the boot code.
    sti

    mov [boot_drive], dl          ; BIOS passes the boot drive in DL.

    mov si, boot_message
    call boot_print_string

    ; Reset the floppy controller before reading.
    xor ax, ax
    mov dl, [boot_drive]
    int 0x13
    jc boot_disk_error

    ; Read the tiny kernel one sector at a time. This is slower than one large
    ; read, but it stays simple and works across track/head boundaries.
    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx                    ; ES:BX = 1000:0000.
    mov byte [read_sector], 2      ; Sector 1 is this boot sector.
    mov byte [read_head], 0
    mov byte [read_cylinder], 0
    mov byte [sectors_left], KERNEL_SECTORS

boot_read_loop:
    mov ah, 0x02                  ; BIOS disk read.
    mov al, 0x01                  ; Read one sector.
    mov ch, [read_cylinder]
    mov cl, [read_sector]
    mov dh, [read_head]
    mov dl, [boot_drive]
    int 0x13
    jc boot_disk_error

    add bx, 512
    inc byte [read_sector]
    cmp byte [read_sector], 19    ; 1.44MB floppy has sectors 1..18.
    jb boot_read_advance_done
    mov byte [read_sector], 1
    xor byte [read_head], 1
    cmp byte [read_head], 0
    jne boot_read_advance_done
    inc byte [read_cylinder]

boot_read_advance_done:
    dec byte [sectors_left]
    jnz boot_read_loop

    ; Enter the kernel. MAIN_SYSTEM.ASM is assembled with ORG 0.
    jmp KERNEL_SEG:KERNEL_OFF

boot_disk_error:
    mov si, disk_error_message
    call boot_print_string

boot_halt:
    hlt
    jmp boot_halt

; Print a zero-terminated string at DS:SI using BIOS teletype output.
boot_print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07                  ; Light gray on black.
    int 0x10
    jmp boot_print_string
.done:
    ret

boot_drive         db 0
read_sector        db 0
read_head          db 0
read_cylinder      db 0
sectors_left       db 0
boot_message       db 'TinyDOS booting...', 13, 10, 0
disk_error_message db 'Disk read error.', 13, 10, 0

; Pad to 512 bytes and finish with the PC boot signature.
times 510 - ($ - $$) db 0
dw 0xAA55
