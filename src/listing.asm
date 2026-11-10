%include "include/syscalls.inc"

extern strlen
extern memcpy
extern send_string
extern path_buffer

global send_listing

section .data
page_start:
    db "HTTP/1.0 200 OK", 13, 10
    db "Content-Type: text/html; charset=utf-8", 13, 10
    db "Connection: close", 13, 10
    db 13, 10
    db '<!DOCTYPE html>', 10
    db '<html><head><meta charset="utf-8"><title>AsmShare</title></head>', 10
    db '<body>', 10
    db '<h1>Index of ', 0
page_after_title:
    db '</h1>', 10
    db '<ul>', 10, 0
entry_start     db '<li><a href="', 0
entry_middle    db '">', 0
entry_end       db '</a></li>', 10, 0
page_end:
    db '</ul>', 10
    db '</body></html>', 10, 0

section .bss
dir_fd          resq 1
dirent_bytes    resq 1
dirent_offset   resq 1
entry_name      resq 1
link_prefix     resb LINK_PREFIX_SIZE
dirent_buffer   resb DIRENT_BUFFER_SIZE

section .text

send_listing:
    mov [dir_fd], rdi
    call build_link_prefix
    call send_page_start
    call send_entries
    call send_page_end
    ret

build_link_prefix:
    mov rdi, path_buffer
    call strlen
    lea rdx, [rax + 1]
    mov rdi, link_prefix
    mov rsi, path_buffer
    call memcpy
    mov rdi, link_prefix
    call strlen
    cmp byte [link_prefix + rax - 1], '/'
    je build_link_prefix_done
    mov byte [link_prefix + rax], '/'
    mov byte [link_prefix + rax + 1], 0
build_link_prefix_done:
    ret

send_page_start:
    mov rdi, page_start
    call send_string
    mov rdi, path_buffer
    call send_string
    mov rdi, page_after_title
    call send_string
    ret

send_page_end:
    mov rdi, page_end
    call send_string
    ret

send_entries:
    call read_directory
    test rax, rax
    jle send_entries_done
    mov [dirent_bytes], rax
    mov qword [dirent_offset], 0
    call send_buffer_entries
    jmp send_entries
send_entries_done:
    ret

read_directory:
    mov rax, SYS_GETDENTS64
    mov rdi, [dir_fd]
    mov rsi, dirent_buffer
    mov rdx, DIRENT_BUFFER_SIZE
    syscall
    ret

send_buffer_entries:
    mov rax, [dirent_offset]
    cmp rax, [dirent_bytes]
    jae send_buffer_entries_done
    lea rdi, [dirent_buffer + rax + DIRENT_NAME_OFFSET]
    call send_entry
    mov rax, [dirent_offset]
    movzx rcx, word [dirent_buffer + rax + DIRENT_RECLEN_OFFSET]
    add [dirent_offset], rcx
    jmp send_buffer_entries
send_buffer_entries_done:
    ret

send_entry:
    cmp byte [rdi], '.'
    je send_entry_done
    mov [entry_name], rdi
    mov rdi, entry_start
    call send_string
    mov rdi, link_prefix
    call send_string
    mov rdi, [entry_name]
    call send_string
    mov rdi, entry_middle
    call send_string
    mov rdi, [entry_name]
    call send_string
    mov rdi, entry_end
    call send_string
send_entry_done:
    ret
