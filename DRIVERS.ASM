; ---------------------------------------------------------------------------
; DRIVERS.ASM
; Tiny BIOS-only routines used by the kernel and shell.
;
; These routines keep TinyDOS in 16-bit real mode and call only the PC BIOS.
; ---------------------------------------------------------------------------

; Set classic 80x25 color text mode.
set_text_mode:
    push ax
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    pop ax
    ret

; Print AL at the current cursor position.
print_char:
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07                  ; Light gray on black.
    int 0x10
    pop bx
    pop ax
    ret

; Print a zero-terminated string pointed to by DS:SI.
print_string:
    push ax
.next:
    lodsb
    test al, al
    jz .done
    call print_char
    jmp .next
.done:
    pop ax
    ret

; Move to the next line using DOS-style CR/LF.
print_newline:
    push ax
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    pop ax
    ret

; Clear the full 80x25 screen and reset the cursor to the top-left corner.
clear_screen:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x06                  ; Scroll window up.
    mov al, 0x00                  ; Clear entire window.
    mov bh, 0x07                  ; Light gray on black.
    mov cx, 0x0000                ; Upper-left row/column.
    mov dx, 0x184F                ; Lower-right row/column.
    int 0x10
    call cursor_home
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Place the cursor at row 0, column 0.
cursor_home:
    push ax
    push bx
    push dx
    mov ah, 0x02
    mov bh, 0x00
    xor dx, dx
    int 0x10
    pop dx
    pop bx
    pop ax
    ret

; Wait for one keypress.
; Returns:
;   AL = ASCII character, or 0 for extended keys
;   AH = BIOS scan code
read_key:
    mov ah, 0x00
    int 0x16
    ret

; Read sectors with BIOS INT 13h.
; Inputs:
;   AH ignored, AL = sector count
;   CH = cylinder, CL = sector, DH = head, DL = drive
;   ES:BX = destination buffer
; Output:
;   Carry clear on success, set on BIOS error
disk_read_sectors:
    mov ah, 0x02
    int 0x13
    ret
