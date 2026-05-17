; ---------------------------------------------------------------------------
; COMMAND-LINE.ASM
; TinyDOS command shell and tiny RAM filesystem.
;
; The RAM filesystem is deliberately primitive:
;   - volatile; all files disappear on reboot
;   - fixed number of file slots
;   - fixed maximum text size per file
;   - no directories and no real floppy filesystem
; ---------------------------------------------------------------------------

COMMAND_MAX EQU 160
TOKEN_MAX   EQU 16
ASM_TOKEN_MAX EQU 32

FS_MAX_FILES   EQU 8
FS_NAME_MAX    EQU 12
FS_NAME_SIZE   EQU FS_NAME_MAX + 1
FS_DATA_MAX    EQU 768
FS_USED_OFF    EQU 0
FS_NAME_OFF    EQU 1
FS_SIZE_OFF    EQU FS_NAME_OFF + FS_NAME_SIZE
FS_DATA_OFF    EQU FS_SIZE_OFF + 2
FS_ENTRY_SIZE  EQU FS_DATA_OFF + FS_DATA_MAX
FS_TOTAL_BYTES EQU FS_MAX_FILES * FS_DATA_MAX

shell_start:
    mov si, shell_ready_message
    call print_string

shell_loop:
    mov si, prompt_text
    call print_string

    call read_command_line
    call execute_command
    jmp shell_loop

; Read one editable command line into command_buffer.
; ENTER finishes the line. BACKSPACE erases one character.
read_command_line:
    mov di, command_buffer
    xor cx, cx                    ; Current input length.

.wait_key:
    call read_key
    cmp al, 0
    je .wait_key                  ; Ignore extended keys.
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    cmp cx, COMMAND_MAX
    jae .wait_key                 ; Ignore extra text past the buffer limit.

    stosb
    inc cx
    call print_char
    jmp .wait_key

.backspace:
    cmp cx, 0
    je .wait_key
    dec di
    dec cx
    mov al, 8
    call print_char
    mov al, ' '
    call print_char
    mov al, 8
    call print_char
    jmp .wait_key

.enter:
    mov al, 0
    stosb
    call print_newline
    ret

; Parse the first word, compare it with the built-ins, and dispatch.
execute_command:
    mov si, command_buffer
    call command_skip_spaces
    cmp byte [si], 0
    je .done

    call copy_command_token       ; Leaves SI at the first byte after the token.
    call command_skip_spaces      ; SI now points to command arguments.

    mov [command_args], si

    mov si, command_token
    mov di, cmd_help
    call strings_equal
    cmp al, 1
    je .do_help

    mov si, command_token
    mov di, cmd_cls
    call strings_equal
    cmp al, 1
    je .do_cls

    mov si, command_token
    mov di, cmd_echo
    call strings_equal
    cmp al, 1
    je .do_echo

    mov si, command_token
    mov di, cmd_hex
    call strings_equal
    cmp al, 1
    je .do_hex

    mov si, command_token
    mov di, cmd_ver
    call strings_equal
    cmp al, 1
    je .do_ver

    mov si, command_token
    mov di, cmd_dir
    call strings_equal
    cmp al, 1
    je .do_dir

    mov si, command_token
    mov di, cmd_write
    call strings_equal
    cmp al, 1
    je .do_write

    mov si, command_token
    mov di, cmd_append
    call strings_equal
    cmp al, 1
    je .do_append

    mov si, command_token
    mov di, cmd_line
    call strings_equal
    cmp al, 1
    je .do_line

    mov si, command_token
    mov di, cmd_type
    call strings_equal
    cmp al, 1
    je .do_type

    mov si, command_token
    mov di, cmd_del
    call strings_equal
    cmp al, 1
    je .do_del

    mov si, command_token
    mov di, cmd_erase
    call strings_equal
    cmp al, 1
    je .do_del

    mov si, command_token
    mov di, cmd_ren
    call strings_equal
    cmp al, 1
    je .do_ren

    mov si, command_token
    mov di, cmd_copy
    call strings_equal
    cmp al, 1
    je .do_copy

    mov si, command_token
    mov di, cmd_mem
    call strings_equal
    cmp al, 1
    je .do_mem

    mov si, command_token
    mov di, cmd_format
    call strings_equal
    cmp al, 1
    je .do_format

    mov si, command_token
    mov di, cmd_fasm
    call strings_equal
    cmp al, 1
    je .do_fasm

    mov si, command_token
    mov di, cmd_time
    call strings_equal
    cmp al, 1
    je .do_time

    mov si, command_token
    mov di, cmd_date
    call strings_equal
    cmp al, 1
    je .do_date

    mov si, command_token
    mov di, cmd_pause
    call strings_equal
    cmp al, 1
    je .do_pause

    mov si, command_token
    mov di, cmd_beep
    call strings_equal
    cmp al, 1
    je .do_beep

    mov si, command_token
    mov di, cmd_reboot
    call strings_equal
    cmp al, 1
    je .do_reboot

    mov si, bad_command_message
    call print_string
    jmp .done

.do_help:
    mov si, help_message
    call print_string
    jmp .done

.do_cls:
    call clear_screen
    jmp .done

.do_echo:
    mov si, [command_args]
    call print_string
    call print_newline
    jmp .done

.do_hex:
    mov si, [command_args]
    call hex_command
    jmp .done

.do_ver:
    mov si, version_message
    call print_string
    jmp .done

.do_dir:
    call fs_cmd_dir
    jmp .done

.do_write:
    call fs_cmd_write
    jmp .done

.do_append:
    call fs_cmd_append
    jmp .done

.do_line:
    call fs_cmd_line
    jmp .done

.do_type:
    call fs_cmd_type
    jmp .done

.do_del:
    call fs_cmd_del
    jmp .done

.do_ren:
    call fs_cmd_ren
    jmp .done

.do_copy:
    call fs_cmd_copy
    jmp .done

.do_mem:
    call fs_cmd_mem
    jmp .done

.do_format:
    call fs_cmd_format
    jmp .done

.do_fasm:
    call fasm_cmd
    jmp .done

.do_time:
    call cmd_print_time
    jmp .done

.do_date:
    call cmd_print_date
    jmp .done

.do_pause:
    mov si, pause_message
    call print_string
    call read_key
    call print_newline
    jmp .done

.do_beep:
    mov al, 7
    call print_char
    call print_newline
    jmp .done

.do_reboot:
    int 0x19                       ; BIOS bootstrap loader.

.done:
    ret

; Copy the first command word into command_token as uppercase ASCII.
; Input:
;   DS:SI points at the start of the command word.
; Output:
;   DS:SI points at the delimiter after the word.
copy_command_token:
    mov di, command_token
    mov cx, TOKEN_MAX - 1

.copy_loop:
    mov al, [si]
    cmp al, 0
    je .finish
    cmp al, ' '
    je .finish

    cmp cx, 0
    je .skip_extra
    call uppercase_char
    stosb
    dec cx

.skip_extra:
    inc si
    jmp .copy_loop

.finish:
    mov al, 0
    stosb
    ret

; Uppercase AL if it is a lowercase English letter.
uppercase_char:
    cmp al, 'a'
    jb .done
    cmp al, 'z'
    ja .done
    sub al, 32
.done:
    ret

command_skip_spaces:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp command_skip_spaces
.done:
    ret

; Compare two zero-terminated strings at DS:SI and DS:DI.
; Returns AL = 1 if equal, AL = 0 if different.
strings_equal:
    push si
    push di
    push bx

.compare:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .compare

.equal:
    mov al, 1
    jmp .exit

.not_equal:
    xor al, al

.exit:
    pop bx
    pop di
    pop si
    ret

; ---------------------------------------------------------------------------
; Small system commands
; ---------------------------------------------------------------------------

cmd_print_time:
    mov ah, 0x02                   ; BIOS RTC time.
    int 0x1A
    jc .bad
    mov al, ch
    call print_bcd_byte
    mov al, ':'
    call print_char
    mov al, cl
    call print_bcd_byte
    mov al, ':'
    call print_char
    mov al, dh
    call print_bcd_byte
    call print_newline
    ret
.bad:
    mov si, rtc_error_message
    call print_string
    ret

cmd_print_date:
    mov ah, 0x04                   ; BIOS RTC date.
    int 0x1A
    jc .bad
    mov al, ch
    call print_bcd_byte
    mov al, cl
    call print_bcd_byte
    mov al, '-'
    call print_char
    mov al, dh
    call print_bcd_byte
    mov al, '-'
    call print_char
    mov al, dl
    call print_bcd_byte
    call print_newline
    ret
.bad:
    mov si, rtc_error_message
    call print_string
    ret

; Print packed BCD in AL as two decimal characters.
print_bcd_byte:
    push ax
    mov ah, al
    shr al, 4
    and al, 0x0F
    add al, '0'
    call print_char
    mov al, ah
    and al, 0x0F
    add al, '0'
    call print_char
    pop ax
    ret

; ---------------------------------------------------------------------------
; RAM filesystem commands
; ---------------------------------------------------------------------------

ramfs_init:
    push ax
    push cx
    push di

    mov di, ramfs_table
    mov cx, FS_ENTRY_SIZE * FS_MAX_FILES
    xor al, al
.clear_loop:
    mov [di], al
    inc di
    loop .clear_loop

    pop di
    pop cx
    pop ax
    ret

fs_cmd_dir:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, dir_header_message
    call print_string
    mov bx, ramfs_table
    mov cx, FS_MAX_FILES
    xor dx, dx

.scan:
    cmp byte [bx + FS_USED_OFF], 0
    je .next

    inc dx
    lea si, [bx + FS_NAME_OFF]
    call print_string
    mov si, dir_gap_message
    call print_string
    mov ax, [bx + FS_SIZE_OFF]
    call print_decimal_word
    mov si, bytes_message
    call print_string

.next:
    add bx, FS_ENTRY_SIZE
    loop .scan

    cmp dx, 0
    jne .summary
    mov si, no_files_message
    call print_string

.summary:
    mov ax, dx
    call print_decimal_word
    mov si, files_message
    call print_string

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fs_cmd_write:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jnc .have_entry
    call find_free_file
    jc .full

.have_entry:
    mov si, fs_name_buffer
    call fs_set_entry_name
    mov si, [fs_saved_ptr]
    call command_skip_spaces
    call fs_write_text_to_entry
    mov si, file_written_message
    call print_string
    ret

.usage:
    mov si, write_usage_message
    call print_string
    ret
.full:
    mov si, ramdisk_full_message
    call print_string
    ret

fs_cmd_append:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jnc .have_entry
    call find_free_file
    jc .full
    mov si, fs_name_buffer
    call fs_set_entry_name
    mov word [bx + FS_SIZE_OFF], 0

.have_entry:
    mov si, [fs_saved_ptr]
    call command_skip_spaces
    call fs_append_text_to_entry
    jc .truncated
    mov si, file_appended_message
    call print_string
    ret

.truncated:
    mov si, append_truncated_message
    call print_string
    ret
.usage:
    mov si, append_usage_message
    call print_string
    ret
.full:
    mov si, ramdisk_full_message
    call print_string
    ret

fs_cmd_line:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jnc .have_entry
    call find_free_file
    jc .full
    mov si, fs_name_buffer
    call fs_set_entry_name
    mov word [bx + FS_SIZE_OFF], 0

.have_entry:
    mov si, [fs_saved_ptr]
    call command_skip_spaces
    call fs_append_line_to_entry
    jc .truncated
    mov si, line_added_message
    call print_string
    ret

.truncated:
    mov si, append_truncated_message
    call print_string
    ret
.usage:
    mov si, line_usage_message
    call print_string
    ret
.full:
    mov si, ramdisk_full_message
    call print_string
    ret

fs_cmd_type:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov si, fs_name_buffer
    call find_file_by_name
    jc .not_found

    lea si, [bx + FS_DATA_OFF]
    mov cx, [bx + FS_SIZE_OFF]
    call print_buffer
    call print_newline
    ret

.usage:
    mov si, type_usage_message
    call print_string
    ret
.not_found:
    mov si, file_not_found_message
    call print_string
    ret

fs_cmd_del:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov si, fs_name_buffer
    call find_file_by_name
    jc .not_found
    mov byte [bx + FS_USED_OFF], 0
    mov si, file_deleted_message
    call print_string
    ret

.usage:
    mov si, del_usage_message
    call print_string
    ret
.not_found:
    mov si, file_not_found_message
    call print_string
    ret

fs_cmd_ren:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jc .not_found
    mov [fs_source_entry], bx

    mov si, [fs_saved_ptr]
    call fs_parse_name
    jc .usage
    mov si, fs_name_buffer
    call find_file_by_name
    jnc .exists

    mov bx, [fs_source_entry]
    mov si, fs_name_buffer
    call fs_set_entry_name
    mov si, file_renamed_message
    call print_string
    ret

.usage:
    mov si, ren_usage_message
    call print_string
    ret
.not_found:
    mov si, file_not_found_message
    call print_string
    ret
.exists:
    mov si, file_exists_message
    call print_string
    ret

fs_cmd_copy:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jc .not_found
    mov [fs_source_entry], bx

    mov si, [fs_saved_ptr]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jnc .have_destination
    call find_free_file
    jc .full

.have_destination:
    mov si, fs_name_buffer
    call fs_set_entry_name
    call fs_copy_file_data
    mov si, file_copied_message
    call print_string
    ret

.usage:
    mov si, copy_usage_message
    call print_string
    ret
.not_found:
    mov si, file_not_found_message
    call print_string
    ret
.full:
    mov si, ramdisk_full_message
    call print_string
    ret

fs_cmd_mem:
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, ramfs_table
    mov cx, FS_MAX_FILES
    xor ax, ax
    xor dx, dx

.scan:
    cmp byte [bx + FS_USED_OFF], 0
    je .next
    inc dx
    add ax, [bx + FS_SIZE_OFF]
.next:
    add bx, FS_ENTRY_SIZE
    loop .scan

    mov [fs_used_bytes], ax
    mov [fs_used_slots], dx

    mov si, mem_slots_message
    call print_string
    mov ax, [fs_used_slots]
    call print_decimal_word
    mov si, slash_message
    call print_string
    mov ax, FS_MAX_FILES
    call print_decimal_word
    call print_newline

    mov si, mem_used_message
    call print_string
    mov ax, [fs_used_bytes]
    call print_decimal_word
    mov si, bytes_message
    call print_string

    mov si, mem_free_message
    call print_string
    mov ax, FS_TOTAL_BYTES
    sub ax, [fs_used_bytes]
    call print_decimal_word
    mov si, bytes_message
    call print_string

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fs_cmd_format:
    call ramfs_init
    mov si, format_done_message
    call print_string
    ret

; Parse one space-delimited filename into fs_name_buffer.
; Input:
;   DS:SI points to arguments.
; Output:
;   DS:SI points to the delimiter after the filename.
;   Carry set if no valid filename or if the name is too long.
fs_parse_name:
    push ax
    push cx
    push di

    call command_skip_spaces
    cmp byte [si], 0
    je .fail

    mov di, fs_name_buffer
    mov cx, FS_NAME_MAX

.copy:
    mov al, [si]
    cmp al, 0
    je .finish
    cmp al, ' '
    je .finish
    cmp cx, 0
    je .fail
    call uppercase_char
    stosb
    dec cx
    inc si
    jmp .copy

.finish:
    mov al, 0
    stosb
    clc
    jmp .exit

.fail:
    stc

.exit:
    pop di
    pop cx
    pop ax
    ret

find_file_by_name:
    push ax
    push cx
    push dx
    push si
    push di

    mov dx, si
    mov di, ramfs_table
    mov cx, FS_MAX_FILES

.scan:
    cmp byte [di + FS_USED_OFF], 0
    je .next

    push cx
    push di
    mov si, dx
    lea di, [di + FS_NAME_OFF]
    call strings_equal
    cmp al, 1
    pop di
    pop cx
    je .found

.next:
    add di, FS_ENTRY_SIZE
    loop .scan
    stc
    jmp .exit

.found:
    mov bx, di
    clc

.exit:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

find_free_file:
    push ax
    push cx
    push di

    mov di, ramfs_table
    mov cx, FS_MAX_FILES

.scan:
    cmp byte [di + FS_USED_OFF], 0
    je .found
    add di, FS_ENTRY_SIZE
    loop .scan
    stc
    jmp .exit

.found:
    mov bx, di
    clc

.exit:
    pop di
    pop cx
    pop ax
    ret

fs_set_entry_name:
    push ax
    push cx
    push di

    mov byte [bx + FS_USED_OFF], 1
    lea di, [bx + FS_NAME_OFF]
    mov cx, FS_NAME_SIZE

.clear_name:
    mov byte [di], 0
    inc di
    loop .clear_name

    lea di, [bx + FS_NAME_OFF]

.copy_name:
    lodsb
    mov [di], al
    inc di
    cmp al, 0
    jne .copy_name

    pop di
    pop cx
    pop ax
    ret

fs_write_text_to_entry:
    push ax
    push cx
    push dx
    push di

    lea di, [bx + FS_DATA_OFF]
    xor dx, dx
    mov cx, FS_DATA_MAX

.copy:
    cmp cx, 0
    je .done
    lodsb
    cmp al, 0
    je .done
    mov [di], al
    inc di
    inc dx
    dec cx
    jmp .copy

.done:
    mov [bx + FS_SIZE_OFF], dx
    cmp dx, FS_DATA_MAX
    jae .no_zero
    mov byte [di], 0
.no_zero:
    pop di
    pop dx
    pop cx
    pop ax
    ret

fs_append_text_to_entry:
    push ax
    push cx
    push dx
    push di

    mov dx, [bx + FS_SIZE_OFF]
    lea di, [bx + FS_DATA_OFF]
    add di, dx
    mov cx, FS_DATA_MAX
    sub cx, dx

.copy:
    cmp byte [si], 0
    je .ok
    cmp cx, 0
    je .full
    lodsb
    mov [di], al
    inc di
    inc dx
    dec cx
    jmp .copy

.ok:
    mov [bx + FS_SIZE_OFF], dx
    cmp dx, FS_DATA_MAX
    jae .ok_no_zero
    mov byte [di], 0
.ok_no_zero:
    clc
    jmp .exit

.full:
    mov [bx + FS_SIZE_OFF], dx
    stc

.exit:
    pop di
    pop dx
    pop cx
    pop ax
    ret

fs_append_line_to_entry:
    call fs_append_text_to_entry
    jc .exit
    mov si, crlf_text
    call fs_append_text_to_entry
.exit:
    ret

fs_copy_file_data:
    push ax
    push cx
    push si
    push di

    mov si, [fs_source_entry]
    mov ax, [si + FS_SIZE_OFF]
    mov [bx + FS_SIZE_OFF], ax
    mov cx, ax
    lea si, [si + FS_DATA_OFF]
    lea di, [bx + FS_DATA_OFF]

.copy:
    cmp cx, 0
    je .done
    mov al, [si]
    mov [di], al
    inc si
    inc di
    dec cx
    jmp .copy

.done:
    pop di
    pop si
    pop cx
    pop ax
    ret

print_buffer:
    push ax
    push cx
    push si

.print:
    cmp cx, 0
    je .done
    lodsb
    call print_char
    dec cx
    jmp .print

.done:
    pop si
    pop cx
    pop ax
    ret

; ---------------------------------------------------------------------------
; TinyFASM command
;
; This is not the full upstream FASM language. It is a tiny, educational,
; FASM-like boot-sector assembler that emits a 512-byte bootable .BIN in RAM.
; It supports enough syntax for simple boot sectors:
;   ORG, BITS, DB, DW, TIMES, INT, MOV, XOR, JMP $, HLT, CLI, STI, NOP, RET,
;   IRET, PUSH, POP, and BOOT.
;
; Optimizations:
;   MOV r16,0 is emitted as XOR r16,r16.
;   JMP $ is emitted as EB FE.
; ---------------------------------------------------------------------------

fasm_cmd:
    mov si, [command_args]
    call fs_parse_name
    jc .usage
    mov [fs_saved_ptr], si

    mov si, fs_name_buffer
    call find_file_by_name
    jc .not_found
    mov [asm_source_entry], bx

    mov si, [fs_saved_ptr]
    call command_skip_spaces
    cmp byte [si], 0
    jne .parse_output

    call fasm_make_default_output_name
    jc .usage
    jmp .have_output

.parse_output:
    call fs_parse_name
    jc .usage

.have_output:
    mov si, fs_name_buffer
    call find_file_by_name
    jnc .have_entry
    call find_free_file
    jc .full

.have_entry:
    mov [asm_dest_entry], bx
    mov si, fs_name_buffer
    call fs_set_entry_name
    mov word [bx + FS_SIZE_OFF], 0

    call fasm_assemble_entry
    ret

.usage:
    mov si, fasm_usage_message
    call print_string
    ret
.not_found:
    mov si, file_not_found_message
    call print_string
    ret
.full:
    mov si, ramdisk_full_message
    call print_string
    ret

fasm_make_default_output_name:
    push ax
    push cx
    push si
    push di

    mov si, fs_name_buffer
    mov di, fs_name_buffer2
    mov cx, FS_NAME_MAX - 4

.copy_base:
    mov al, [si]
    cmp al, 0
    je .add_ext
    cmp al, '.'
    je .add_ext
    cmp cx, 0
    je .fail
    mov [di], al
    inc si
    inc di
    dec cx
    jmp .copy_base

.add_ext:
    mov byte [di], '.'
    inc di
    mov byte [di], 'B'
    inc di
    mov byte [di], 'I'
    inc di
    mov byte [di], 'N'
    inc di
    mov byte [di], 0

    mov si, fs_name_buffer2
    mov di, fs_name_buffer
.copy_back:
    lodsb
    stosb
    cmp al, 0
    jne .copy_back
    clc
    jmp .exit

.fail:
    stc

.exit:
    pop di
    pop si
    pop cx
    pop ax
    ret

fasm_assemble_entry:
    mov bx, [asm_dest_entry]
    lea di, [bx + FS_DATA_OFF]
    mov [asm_out_ptr], di
    mov word [asm_out_size], 0

    mov bx, [asm_source_entry]
    lea si, [bx + FS_DATA_OFF]
    mov [asm_src_ptr], si

.next:
    call asm_get_token
    jc .finish
    call asm_dispatch_token
    jc .error
    jmp .next

.finish:
    call asm_finalize_boot_bin
    jc .error

    mov bx, [asm_dest_entry]
    mov si, fasm_ok_message
    call print_string
    lea si, [bx + FS_NAME_OFF]
    call print_string
    mov si, fasm_size_message
    call print_string
    ret

.error:
    mov bx, [asm_dest_entry]
    mov word [bx + FS_SIZE_OFF], 0
    mov si, fasm_error_message
    call print_string
    mov si, asm_token
    call print_string
    call print_newline
    ret

asm_dispatch_token:
    mov si, asm_token
    mov di, asm_kw_org
    call strings_equal
    cmp al, 1
    je asm_ignore_one_operand

    mov si, asm_token
    mov di, asm_kw_bits
    call strings_equal
    cmp al, 1
    je asm_ignore_one_operand

    mov si, asm_token
    mov di, asm_kw_db
    call strings_equal
    cmp al, 1
    je asm_handle_db

    mov si, asm_token
    mov di, asm_kw_dw
    call strings_equal
    cmp al, 1
    je asm_handle_dw

    mov si, asm_token
    mov di, asm_kw_times
    call strings_equal
    cmp al, 1
    je asm_handle_times

    mov si, asm_token
    mov di, asm_kw_int
    call strings_equal
    cmp al, 1
    je asm_handle_int

    mov si, asm_token
    mov di, asm_kw_mov
    call strings_equal
    cmp al, 1
    je asm_handle_mov

    mov si, asm_token
    mov di, asm_kw_xor
    call strings_equal
    cmp al, 1
    je asm_handle_xor

    mov si, asm_token
    mov di, asm_kw_jmp
    call strings_equal
    cmp al, 1
    je asm_handle_jmp

    mov si, asm_token
    mov di, asm_kw_hlt
    call strings_equal
    cmp al, 1
    je asm_emit_hlt

    mov si, asm_token
    mov di, asm_kw_cli
    call strings_equal
    cmp al, 1
    je asm_emit_cli

    mov si, asm_token
    mov di, asm_kw_sti
    call strings_equal
    cmp al, 1
    je asm_emit_sti

    mov si, asm_token
    mov di, asm_kw_nop
    call strings_equal
    cmp al, 1
    je asm_emit_nop

    mov si, asm_token
    mov di, asm_kw_ret
    call strings_equal
    cmp al, 1
    je asm_emit_ret

    mov si, asm_token
    mov di, asm_kw_iret
    call strings_equal
    cmp al, 1
    je asm_emit_iret

    mov si, asm_token
    mov di, asm_kw_push
    call strings_equal
    cmp al, 1
    je asm_handle_push

    mov si, asm_token
    mov di, asm_kw_pop
    call strings_equal
    cmp al, 1
    je asm_handle_pop

    mov si, asm_token
    mov di, asm_kw_boot
    call strings_equal
    cmp al, 1
    je asm_finalize_boot_bin

    stc
    ret

asm_ignore_one_operand:
    call asm_get_token
    ret

asm_handle_db:
    call asm_get_token
    jc .fail
    cmp byte [asm_token], '"'
    je .string
    cmp byte [asm_token], 39
    je .string
    mov si, asm_token
    call asm_parse_number
    jc .fail
    call asm_emit_byte
    ret

.string:
    mov si, asm_token + 1
.string_loop:
    lodsb
    cmp al, 0
    je .ok
    call asm_emit_byte
    jc .fail
    jmp .string_loop
.ok:
    clc
    ret
.fail:
    stc
    ret

asm_handle_dw:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    call asm_emit_word
    ret
.fail:
    stc
    ret

asm_handle_times:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    mov [asm_repeat_count], ax

    call asm_get_token
    jc .fail

    mov si, asm_token
    mov di, asm_kw_db
    call strings_equal
    cmp al, 1
    je .times_db

    mov si, asm_token
    mov di, asm_kw_dw
    call strings_equal
    cmp al, 1
    je .times_dw

    mov si, asm_token
    mov di, asm_kw_nop
    call strings_equal
    cmp al, 1
    je .times_nop

    mov si, asm_token
    mov di, asm_kw_hlt
    call strings_equal
    cmp al, 1
    je .times_hlt

    jmp .fail

.times_db:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    mov [asm_repeat_value], ax
.db_loop:
    cmp word [asm_repeat_count], 0
    je .ok
    mov ax, [asm_repeat_value]
    call asm_emit_byte
    jc .fail
    dec word [asm_repeat_count]
    jmp .db_loop

.times_dw:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    mov [asm_repeat_value], ax
.dw_loop:
    cmp word [asm_repeat_count], 0
    je .ok
    mov ax, [asm_repeat_value]
    call asm_emit_word
    jc .fail
    dec word [asm_repeat_count]
    jmp .dw_loop

.times_nop:
    cmp word [asm_repeat_count], 0
    je .ok
    mov al, 0x90
    call asm_emit_byte
    jc .fail
    dec word [asm_repeat_count]
    jmp .times_nop

.times_hlt:
    cmp word [asm_repeat_count], 0
    je .ok
    mov al, 0xF4
    call asm_emit_byte
    jc .fail
    dec word [asm_repeat_count]
    jmp .times_hlt

.ok:
    clc
    ret
.fail:
    stc
    ret

asm_handle_int:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    mov bl, al
    mov al, 0xCD
    call asm_emit_byte
    jc .fail
    mov al, bl
    call asm_emit_byte
    ret
.fail:
    stc
    ret

asm_handle_jmp:
    call asm_get_token
    jc .fail
    mov si, asm_token
    mov di, asm_kw_short
    call strings_equal
    cmp al, 1
    jne .have_target
    call asm_get_token
    jc .fail

.have_target:
    mov si, asm_token
    mov di, asm_kw_dollar
    call strings_equal
    cmp al, 1
    jne .fail
    mov al, 0xEB
    call asm_emit_byte
    jc .fail
    mov al, 0xFE
    call asm_emit_byte
    ret
.fail:
    stc
    ret

asm_handle_mov:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jnc .dest_word
    mov si, asm_token
    call asm_byte_reg_code
    jnc .dest_byte
    mov si, asm_token
    call asm_seg_reg_code
    jnc .dest_seg
    jmp .fail

.dest_word:
    mov [asm_reg_code], al
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    cmp ax, 0
    je .mov_word_zero
    mov bl, al
    mov al, 0xB8
    add al, [asm_reg_code]
    call asm_emit_byte
    jc .fail
    mov al, bl
    mov ah, 0
    mov si, asm_token
    call asm_parse_number
    jc .fail
    call asm_emit_word
    ret

.mov_word_zero:
    mov al, [asm_reg_code]
    call asm_emit_xor_word_self
    ret

.dest_byte:
    mov [asm_reg_code], al
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_parse_number
    jc .fail
    mov bl, al
    mov al, 0xB0
    add al, [asm_reg_code]
    call asm_emit_byte
    jc .fail
    mov al, bl
    call asm_emit_byte
    ret

.dest_seg:
    mov [asm_seg_code], al
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jc .fail
    mov [asm_reg_code], al
    mov al, 0x8E
    call asm_emit_byte
    jc .fail
    mov al, [asm_seg_code]
    shl al, 3
    add al, [asm_reg_code]
    add al, 0xC0
    call asm_emit_byte
    ret

.fail:
    stc
    ret

asm_handle_xor:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jnc .word_first
    mov si, asm_token
    call asm_byte_reg_code
    jnc .byte_first
    jmp .fail

.word_first:
    mov [asm_reg_code], al
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jc .fail
    mov bl, al
    mov al, 0x31
    call asm_emit_byte
    jc .fail
    mov al, bl
    shl al, 3
    add al, [asm_reg_code]
    add al, 0xC0
    call asm_emit_byte
    ret

.byte_first:
    mov [asm_reg_code], al
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_byte_reg_code
    jc .fail
    mov bl, al
    mov al, 0x30
    call asm_emit_byte
    jc .fail
    mov al, bl
    shl al, 3
    add al, [asm_reg_code]
    add al, 0xC0
    call asm_emit_byte
    ret

.fail:
    stc
    ret

asm_handle_push:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jc .fail
    add al, 0x50
    call asm_emit_byte
    ret
.fail:
    stc
    ret

asm_handle_pop:
    call asm_get_token
    jc .fail
    mov si, asm_token
    call asm_word_reg_code
    jc .fail
    add al, 0x58
    call asm_emit_byte
    ret
.fail:
    stc
    ret

asm_emit_hlt:
    mov al, 0xF4
    call asm_emit_byte
    ret

asm_emit_cli:
    mov al, 0xFA
    call asm_emit_byte
    ret

asm_emit_sti:
    mov al, 0xFB
    call asm_emit_byte
    ret

asm_emit_nop:
    mov al, 0x90
    call asm_emit_byte
    ret

asm_emit_ret:
    mov al, 0xC3
    call asm_emit_byte
    ret

asm_emit_iret:
    mov al, 0xCF
    call asm_emit_byte
    ret

asm_emit_xor_word_self:
    push ax
    mov bl, al
    mov al, 0x31
    call asm_emit_byte
    jc .fail
    mov al, bl
    mov ah, 9
    mul ah
    add al, 0xC0
    call asm_emit_byte
    pop ax
    ret
.fail:
    pop ax
    stc
    ret

asm_finalize_boot_bin:
    cmp word [asm_out_size], 512
    je .set_size
    cmp word [asm_out_size], 510
    ja .fail

.pad:
    cmp word [asm_out_size], 510
    jae .sig
    xor al, al
    call asm_emit_byte
    jc .fail
    jmp .pad

.sig:
    mov al, 0x55
    call asm_emit_byte
    jc .fail
    mov al, 0xAA
    call asm_emit_byte
    jc .fail

.set_size:
    mov bx, [asm_dest_entry]
    mov word [bx + FS_SIZE_OFF], 512
    clc
    ret

.fail:
    stc
    ret

asm_emit_byte:
    push bx
    push di

    mov bx, [asm_out_size]
    cmp bx, 512
    jae .fail
    mov di, [asm_out_ptr]
    mov [di], al
    inc di
    mov [asm_out_ptr], di
    inc bx
    mov [asm_out_size], bx
    clc
    jmp .exit

.fail:
    stc

.exit:
    pop di
    pop bx
    ret

asm_emit_word:
    push ax
    call asm_emit_byte
    jc .fail
    pop ax
    mov al, ah
    call asm_emit_byte
    ret
.fail:
    pop ax
    stc
    ret

asm_get_token:
    push ax
    push bx
    push cx
    push si
    push di

    mov si, [asm_src_ptr]

.skip:
    mov al, [si]
    cmp al, 0
    je .end
    cmp al, ' '
    je .skip_one
    cmp al, 9
    je .skip_one
    cmp al, 13
    je .skip_one
    cmp al, 10
    je .skip_one
    cmp al, ','
    je .skip_one
    cmp al, '|'
    je .skip_one
    cmp al, ';'
    je .skip_comment
    jmp .start

.skip_one:
    inc si
    jmp .skip

.skip_comment:
    inc si
.comment_loop:
    mov al, [si]
    cmp al, 0
    je .end
    cmp al, 13
    je .skip
    cmp al, 10
    je .skip
    inc si
    jmp .comment_loop

.start:
    mov di, asm_token
    mov cx, ASM_TOKEN_MAX - 1
    cmp al, '"'
    je .string
    cmp al, 39
    je .string

.regular:
    mov al, [si]
    cmp al, 0
    je .finish
    cmp al, ' '
    je .finish
    cmp al, 9
    je .finish
    cmp al, 13
    je .finish
    cmp al, 10
    je .finish
    cmp al, ','
    je .finish
    cmp al, '|'
    je .finish
    cmp al, ';'
    je .finish
    cmp cx, 0
    je .regular_skip_store
    call uppercase_char
    stosb
    dec cx
.regular_skip_store:
    inc si
    jmp .regular

.string:
    mov bl, al
    cmp cx, 0
    je .finish
    stosb
    dec cx
    inc si
.string_loop:
    mov al, [si]
    cmp al, 0
    je .finish
    cmp al, bl
    je .string_close
    cmp cx, 0
    je .string_skip_store
    stosb
    dec cx
.string_skip_store:
    inc si
    jmp .string_loop
.string_close:
    inc si

.finish:
    mov al, 0
    stosb
    mov [asm_src_ptr], si
    clc
    jmp .exit

.end:
    mov [asm_src_ptr], si
    stc

.exit:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

asm_parse_number:
    push bx
    push cx
    push dx
    push si
    push di

    mov di, asm_expr_bootpad
    call strings_equal
    cmp al, 1
    jne .check_current
    mov ax, 510
    sub ax, [asm_out_size]
    jc .fail
    jmp .ok

.check_current:
    cmp byte [si], '$'
    jne .check_hex_prefix
    cmp byte [si + 1], 0
    jne .fail
    mov ax, [asm_out_size]
    jmp .ok

.check_hex_prefix:
    cmp byte [si], '0'
    jne .check_hex_suffix
    cmp byte [si + 1], 'X'
    jne .check_hex_suffix
    add si, 2
    jmp .parse_hex

.check_hex_suffix:
    mov di, si
.find_end:
    cmp byte [di], 0
    je .have_end
    inc di
    jmp .find_end
.have_end:
    cmp di, si
    je .fail
    dec di
    cmp byte [di], 'H'
    je .parse_hex

.parse_dec:
    xor ax, ax
    xor cx, cx
.dec_loop:
    mov bl, [si]
    cmp bl, 0
    je .dec_done
    cmp bl, '0'
    jb .fail
    cmp bl, '9'
    ja .fail
    sub bl, '0'
    xor bh, bh
    mov dx, ax
    shl ax, 1
    shl dx, 3
    add ax, dx
    add ax, bx
    inc cx
    inc si
    jmp .dec_loop
.dec_done:
    cmp cx, 0
    je .fail
    jmp .ok

.parse_hex:
    xor ax, ax
    xor cx, cx
.hex_loop:
    mov bl, [si]
    cmp bl, 0
    je .hex_done
    cmp bl, 'H'
    je .hex_done
    cmp bl, '0'
    jb .fail
    cmp bl, '9'
    jbe .hex_digit
    cmp bl, 'A'
    jb .fail
    cmp bl, 'F'
    ja .fail
    sub bl, 'A' - 10
    jmp .hex_add
.hex_digit:
    sub bl, '0'
.hex_add:
    xor bh, bh
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    add ax, bx
    inc cx
    inc si
    jmp .hex_loop
.hex_done:
    cmp cx, 0
    je .fail

.ok:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    clc
    ret

.fail:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    stc
    ret

asm_word_reg_code:
    mov di, reg_ax
    call strings_equal
    cmp al, 1
    je .ax
    mov di, reg_cx
    call strings_equal
    cmp al, 1
    je .cx
    mov di, reg_dx
    call strings_equal
    cmp al, 1
    je .dx
    mov di, reg_bx
    call strings_equal
    cmp al, 1
    je .bx
    mov di, reg_sp
    call strings_equal
    cmp al, 1
    je .sp
    mov di, reg_bp
    call strings_equal
    cmp al, 1
    je .bp
    mov di, reg_si
    call strings_equal
    cmp al, 1
    je .si
    mov di, reg_di
    call strings_equal
    cmp al, 1
    je .di
    stc
    ret
.ax:
    mov al, 0
    clc
    ret
.cx:
    mov al, 1
    clc
    ret
.dx:
    mov al, 2
    clc
    ret
.bx:
    mov al, 3
    clc
    ret
.sp:
    mov al, 4
    clc
    ret
.bp:
    mov al, 5
    clc
    ret
.si:
    mov al, 6
    clc
    ret
.di:
    mov al, 7
    clc
    ret

asm_byte_reg_code:
    mov di, reg_al
    call strings_equal
    cmp al, 1
    je .al
    mov di, reg_cl
    call strings_equal
    cmp al, 1
    je .cl
    mov di, reg_dl
    call strings_equal
    cmp al, 1
    je .dl
    mov di, reg_bl
    call strings_equal
    cmp al, 1
    je .bl
    mov di, reg_ah
    call strings_equal
    cmp al, 1
    je .ah
    mov di, reg_ch
    call strings_equal
    cmp al, 1
    je .ch
    mov di, reg_dh
    call strings_equal
    cmp al, 1
    je .dh
    mov di, reg_bh
    call strings_equal
    cmp al, 1
    je .bh
    stc
    ret
.al:
    mov al, 0
    clc
    ret
.cl:
    mov al, 1
    clc
    ret
.dl:
    mov al, 2
    clc
    ret
.bl:
    mov al, 3
    clc
    ret
.ah:
    mov al, 4
    clc
    ret
.ch:
    mov al, 5
    clc
    ret
.dh:
    mov al, 6
    clc
    ret
.bh:
    mov al, 7
    clc
    ret

asm_seg_reg_code:
    mov di, reg_es
    call strings_equal
    cmp al, 1
    je .es
    mov di, reg_ss
    call strings_equal
    cmp al, 1
    je .ss
    mov di, reg_ds
    call strings_equal
    cmp al, 1
    je .ds
    stc
    ret
.es:
    mov al, 0
    clc
    ret
.ss:
    mov al, 2
    clc
    ret
.ds:
    mov al, 3
    clc
    ret

; ---------------------------------------------------------------------------
; Shell text and RAM filesystem storage
; ---------------------------------------------------------------------------

prompt_text         db 'A:\> ', 0
shell_ready_message db 'Command shell ready. RAM disk active.', 13, 10, 0
bad_command_message db 'Bad command or file name.', 13, 10, 0
version_message     db 'TinyDOS 0.3 - BIOS real mode, RAM FS, TinyFASM', 13, 10, 0
pause_message       db 'Press any key to continue . . .', 0
rtc_error_message   db 'RTC not available.', 13, 10, 0
crlf_text           db 13, 10, 0

cmd_help   db 'HELP', 0
cmd_cls    db 'CLS', 0
cmd_echo   db 'ECHO', 0
cmd_hex    db 'HEX', 0
cmd_ver    db 'VER', 0
cmd_dir    db 'DIR', 0
cmd_write  db 'WRITE', 0
cmd_append db 'APPEND', 0
cmd_line   db 'LINE', 0
cmd_type   db 'TYPE', 0
cmd_del    db 'DEL', 0
cmd_erase  db 'ERASE', 0
cmd_ren    db 'REN', 0
cmd_copy   db 'COPY', 0
cmd_mem    db 'MEM', 0
cmd_format db 'FORMAT', 0
cmd_fasm   db 'FASM', 0
cmd_time   db 'TIME', 0
cmd_date   db 'DATE', 0
cmd_pause  db 'PAUSE', 0
cmd_beep   db 'BEEP', 0
cmd_reboot db 'REBOOT', 0

help_message db 'TinyDOS internal commands:', 13, 10
             db '  HELP            Show this help', 13, 10
             db '  CLS             Clear the screen', 13, 10
             db '  VER             Show version', 13, 10
             db '  DATE / TIME     Show BIOS RTC date or time', 13, 10
             db '  ECHO text       Print text', 13, 10
             db '  HEX num         Print decimal num as hex', 13, 10
             db '  DIR             List RAM files', 13, 10
             db '  WRITE f text    Create or replace RAM file', 13, 10
             db '  APPEND f text   Add text to RAM file', 13, 10
             db '  LINE f text     Add source line plus CR/LF', 13, 10
             db '  TYPE f          Print RAM file', 13, 10
             db '  COPY s d        Copy RAM file', 13, 10
             db '  REN old new     Rename RAM file', 13, 10
             db '  DEL f / ERASE f Delete RAM file', 13, 10
             db '  MEM             RAM disk usage', 13, 10
             db '  FORMAT          Clear RAM disk', 13, 10
             db '  FASM s[ d]      Assemble RAM .ASM to boot .BIN', 13, 10
             db '  PAUSE           Wait for a key', 13, 10
             db '  BEEP            BIOS bell', 13, 10
             db '  REBOOT          BIOS reboot', 13, 10, 0

dir_header_message       db 'RAM disk directory', 13, 10, 0
dir_gap_message          db '  ', 0
bytes_message            db ' bytes', 13, 10, 0
files_message            db ' file(s).', 13, 10, 0
slash_message            db '/', 0
no_files_message         db 'No files.', 13, 10, 0
mem_slots_message        db 'File slots used: ', 0
mem_used_message         db 'Bytes used: ', 0
mem_free_message         db 'Bytes free: ', 0
file_written_message     db 'Written.', 13, 10, 0
file_appended_message    db 'Appended.', 13, 10, 0
line_added_message       db 'Line added.', 13, 10, 0
append_truncated_message db 'Appended; RAM file is full.', 13, 10, 0
file_deleted_message     db 'Deleted.', 13, 10, 0
file_renamed_message     db 'Renamed.', 13, 10, 0
file_copied_message      db 'Copied.', 13, 10, 0
format_done_message      db 'RAM disk formatted.', 13, 10, 0
file_not_found_message   db 'File not found.', 13, 10, 0
file_exists_message      db 'File already exists.', 13, 10, 0
ramdisk_full_message     db 'RAM disk full.', 13, 10, 0

write_usage_message  db 'Usage: WRITE name text', 13, 10, 0
append_usage_message db 'Usage: APPEND name text', 13, 10, 0
line_usage_message   db 'Usage: LINE name text', 13, 10, 0
type_usage_message   db 'Usage: TYPE name', 13, 10, 0
del_usage_message    db 'Usage: DEL name', 13, 10, 0
ren_usage_message    db 'Usage: REN oldname newname', 13, 10, 0
copy_usage_message   db 'Usage: COPY source dest', 13, 10, 0
fasm_usage_message   db 'Usage: FASM source.asm [dest.bin]', 13, 10
                     db 'Subset: ORG BITS DB DW TIMES INT MOV XOR JMP $ HLT CLI STI NOP RET IRET PUSH POP BOOT', 13, 10, 0
fasm_ok_message      db 'Assembled ', 0
fasm_size_message    db ' as 512-byte boot BIN.', 13, 10, 0
fasm_error_message   db 'TinyFASM error near: ', 0

asm_kw_org     db 'ORG', 0
asm_kw_bits    db 'BITS', 0
asm_kw_db      db 'DB', 0
asm_kw_dw      db 'DW', 0
asm_kw_times   db 'TIMES', 0
asm_kw_int     db 'INT', 0
asm_kw_mov     db 'MOV', 0
asm_kw_xor     db 'XOR', 0
asm_kw_jmp     db 'JMP', 0
asm_kw_short   db 'SHORT', 0
asm_kw_hlt     db 'HLT', 0
asm_kw_cli     db 'CLI', 0
asm_kw_sti     db 'STI', 0
asm_kw_nop     db 'NOP', 0
asm_kw_ret     db 'RET', 0
asm_kw_iret    db 'IRET', 0
asm_kw_push    db 'PUSH', 0
asm_kw_pop     db 'POP', 0
asm_kw_boot    db 'BOOT', 0
asm_kw_dollar  db '$', 0
asm_expr_bootpad db '510-($-$$)', 0

reg_ax db 'AX', 0
reg_cx db 'CX', 0
reg_dx db 'DX', 0
reg_bx db 'BX', 0
reg_sp db 'SP', 0
reg_bp db 'BP', 0
reg_si db 'SI', 0
reg_di db 'DI', 0
reg_al db 'AL', 0
reg_cl db 'CL', 0
reg_dl db 'DL', 0
reg_bl db 'BL', 0
reg_ah db 'AH', 0
reg_ch db 'CH', 0
reg_dh db 'DH', 0
reg_bh db 'BH', 0
reg_es db 'ES', 0
reg_ss db 'SS', 0
reg_ds db 'DS', 0

command_args   dw 0
fs_saved_ptr   dw 0
fs_source_entry dw 0
fs_used_bytes  dw 0
fs_used_slots  dw 0
asm_source_entry dw 0
asm_dest_entry   dw 0
asm_src_ptr      dw 0
asm_out_ptr      dw 0
asm_out_size     dw 0
asm_repeat_count dw 0
asm_repeat_value dw 0
asm_reg_code     db 0
asm_seg_code     db 0

command_token  times TOKEN_MAX db 0
command_buffer times COMMAND_MAX + 1 db 0
fs_name_buffer times FS_NAME_SIZE db 0
fs_name_buffer2 times FS_NAME_SIZE db 0
asm_token      times ASM_TOKEN_MAX db 0
ramfs_table    times FS_ENTRY_SIZE * FS_MAX_FILES db 0
