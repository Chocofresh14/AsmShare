%include "include/syscalls.inc"

extern parse_request
extern send_file

global _start
global client_fd

section .data
reuse_value dd 1

sockaddr:
    dw AF_INET
    dw PORT_NETWORK
    dd 0
    dq 0
sockaddr_len equ $ - sockaddr

section .bss
server_fd       resq 1
client_fd       resq 1
request_buffer  resb REQUEST_SIZE

section .text

_start:
    call create_server_socket
    call set_reuse_address
    call bind_server
    call start_listening

accept_loop:
    call accept_client
    call read_request
    mov rdi, request_buffer
    call parse_request
    test rax, rax
    jnz skip_answer
    call send_file
skip_answer:
    call close_client
    jmp accept_loop

create_server_socket:
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    mov [server_fd], rax
    ret

set_reuse_address:
    mov rax, SYS_SETSOCKOPT
    mov rdi, [server_fd]
    mov rsi, SOL_SOCKET
    mov rdx, SO_REUSEADDR
    mov r10, reuse_value
    mov r8, 4
    syscall
    ret

bind_server:
    mov rax, SYS_BIND
    mov rdi, [server_fd]
    mov rsi, sockaddr
    mov rdx, sockaddr_len
    syscall
    ret

start_listening:
    mov rax, SYS_LISTEN
    mov rdi, [server_fd]
    mov rsi, BACKLOG
    syscall
    ret

accept_client:
    mov rax, SYS_ACCEPT
    mov rdi, [server_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [client_fd], rax
    ret

read_request:
    mov rax, SYS_READ
    mov rdi, [client_fd]
    mov rsi, request_buffer
    mov rdx, REQUEST_SIZE - 1
    syscall
    test rax, rax
    jg read_request_ok
    xor rax, rax
read_request_ok:
    mov byte [request_buffer + rax], 0
    ret

close_client:
    mov rax, SYS_CLOSE
    mov rdi, [client_fd]
    syscall
    ret
