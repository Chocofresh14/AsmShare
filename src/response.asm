%include "include/syscalls.inc"

extern strlen
extern memcpy
extern itoa
extern path_buffer
extern client_fd

global send_file
global send_string

section .data
www_prefix      db "www"
www_prefix_len  equ $ - www_prefix

header_start:
    db "HTTP/1.0 200 OK", 13, 10
    db "Content-Type: application/octet-stream", 13, 10
    db "Content-Length: ", 0
header_end:
    db 13, 10
    db "Connection: close", 13, 10
    db 13, 10, 0

section .bss
file_path_buffer    resb FILE_PATH_SIZE
stat_buffer         resb STAT_BUFFER_SIZE
size_buffer         resb 32
file_fd             resq 1
bytes_left          resq 1

section .text

send_file:
    call build_file_path
    call open_file
    test rax, rax
    js send_file_done
    mov [file_fd], rax
    call get_file_info
    test rax, rax
    jnz send_file_close
    call check_regular_file
    test rax, rax
    jnz send_file_close
    call send_headers
    call send_body
send_file_close:
    call close_file
send_file_done:
    ret

build_file_path:
    mov rdi, file_path_buffer
    mov rsi, www_prefix
    mov rdx, www_prefix_len
    call memcpy
    mov rdi, path_buffer
    call strlen
    lea rdx, [rax + 1]
    mov rdi, file_path_buffer + www_prefix_len
    mov rsi, path_buffer
    call memcpy
    ret

open_file:
    mov rax, SYS_OPEN
    mov rdi, file_path_buffer
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    ret

get_file_info:
    mov rax, SYS_FSTAT
    mov rdi, [file_fd]
    mov rsi, stat_buffer
    syscall
    ret

check_regular_file:
    mov eax, [stat_buffer + STAT_MODE_OFFSET]
    and eax, S_IFMT
    cmp eax, S_IFREG
    jne check_regular_file_bad
    xor rax, rax
    ret
check_regular_file_bad:
    mov rax, 1
    ret

send_headers:
    mov rdi, header_start
    call send_string
    mov rdi, [stat_buffer + STAT_SIZE_OFFSET]
    mov rsi, size_buffer
    call itoa
    mov rdi, size_buffer
    call send_string
    mov rdi, header_end
    call send_string
    ret

send_body:
    mov rax, [stat_buffer + STAT_SIZE_OFFSET]
    mov [bytes_left], rax
send_body_loop:
    cmp qword [bytes_left], 0
    je send_body_done
    mov rax, SYS_SENDFILE
    mov rdi, [client_fd]
    mov rsi, [file_fd]
    xor rdx, rdx
    mov r10, [bytes_left]
    syscall
    test rax, rax
    jle send_body_done
    sub [bytes_left], rax
    jmp send_body_loop
send_body_done:
    ret

close_file:
    mov rax, SYS_CLOSE
    mov rdi, [file_fd]
    syscall
    ret

send_string:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, [client_fd]
    syscall
    ret
