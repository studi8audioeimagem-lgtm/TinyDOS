; ---------------------------------------------------------------------------
; HEX.ASM
; Tiny hexadecimal helper and command implementation.
;
; Command:
;   HEX 4660
; Output:
;   0x1234
; ---------------------------------------------------------------------------

; Convert a decimal command argument and print it as a 16-bit hexadecimal word.
; Input:
;   DS:SI points to the text after the HEX command.
hex_command:
    call hex_skip_spaces
    cmp byte [si], 0
    je .usage

    call parse_decimal_word
    jc .bad_number

    call print_hex_word
    call print_newline
    ret

.usage:
    mov si, hex_usage_message
    call print_string
    ret

.bad_number:
    mov si, hex_bad_number_message
    call print_string
    ret

; Print AX as 0x0000 through 0xFFFF.
print_hex_word:
    push ax
    push bx
    push cx
    push si

    mov bx, ax
    mov si, hex_prefix
    call print_string

    mov cx, 4
.digit_loop:
    rol bx, 4
    mov al, bl
    and al, 0x0F
    call print_hex_digit
    loop .digit_loop

    pop si
    pop cx
    pop bx
    pop ax
    ret

; Print AX as an unsigned decimal word.
print_decimal_word:
    push ax
    push bx
    push cx
    push dx

    cmp ax, 0
    jne .convert
    mov al, '0'
    call print_char
    jmp .done

.convert:
    mov bx, 10
    xor cx, cx

.divide:
    xor dx, dx
    div bx                         ; AX = quotient, DX = remainder.
    push dx
    inc cx
    cmp ax, 0
    jne .divide

.print_loop:
    pop dx
    mov al, dl
    add al, '0'
    call print_char
    loop .print_loop

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print the low nibble in AL as one uppercase hexadecimal digit.
print_hex_digit:
    push ax
    cmp al, 9
    jbe .decimal_digit
    add al, 'A' - 10
    jmp .emit
.decimal_digit:
    add al, '0'
.emit:
    call print_char
    pop ax
    ret

; Parse an unsigned decimal word from DS:SI into AX.
; Stops at a space or zero byte. Carry is set on invalid input or overflow.
parse_decimal_word:
    push bx
    push cx
    push dx

    xor ax, ax
    xor cx, cx                    ; Count parsed digits.

.next_digit:
    mov bl, [si]
    cmp bl, 0
    je .done
    cmp bl, ' '
    je .done
    cmp bl, '0'
    jb .fail
    cmp bl, '9'
    ja .fail

    sub bl, '0'
    xor bh, bh
    push bx                       ; Save this digit across MUL.
    mov bx, 10
    mul bx                        ; DX:AX = AX * 10.
    cmp dx, 0
    jne .overflow_after_digit_push
    pop bx
    add ax, bx
    jc .fail
    inc cx
    inc si
    jmp .next_digit

.overflow_after_digit_push:
    pop bx
.fail:
    stc
    jmp .exit

.done:
    cmp cx, 0
    je .fail
    clc

.exit:
    pop dx
    pop cx
    pop bx
    ret

hex_skip_spaces:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp hex_skip_spaces
.done:
    ret

hex_prefix             db '0x', 0
hex_usage_message      db 'Usage: HEX number', 13, 10
                       db 'Example: HEX 4660 prints 0x1234', 13, 10, 0
hex_bad_number_message db 'HEX expects a decimal number from 0 to 65535.', 13, 10, 0
