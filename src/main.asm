%include "include/syscalls.inc"

extern parse_request
extern has_parent_reference
extern send_file
extern send_error_400
extern send_error_403
extern send_error_404
extern path_buffer

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

sigaction_ignore:
    dq 1
    dq 0
    dq 0
    dq 0

section .bss
server_fd       resq 1
client_fd       resq 1
request_buffer  resb REQUEST_SIZE

section .text

_start:
    call ignore_sigchld
    call create_server_socket
    call set_reuse_address
    call bind_server
    call start_listening

accept_loop:
    call accept_client
    test rax, rax
    js accept_loop
    call fork_process
    test rax, rax
    je handle_client
    call close_client
    jmp accept_loop

handle_client:
    call close_server
    call read_request
    call handle_request
    call close_client
    call exit_process

handle_request:
    mov rdi, request_buffer
    call parse_request
    test rax, rax
    jnz handle_bad_request
    mov rdi, path_buffer
    call has_parent_reference
    test rax, rax
    jnz handle_forbidden
    call send_file
    test rax, rax
    jnz handle_not_found
    ret
handle_bad_request:
    call send_error_400
    ret
handle_forbidden:
    call send_error_403
    ret
handle_not_found:
    call send_error_404
    ret

ignore_sigchld:
    mov rax, SYS_RT_SIGACTION
    mov rdi, SIGCHLD
    mov rsi, sigaction_ignore
    xor rdx, rdx
    mov r10, SIGSET_SIZE
    syscall
    ret

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

fork_process:
    mov rax, SYS_FORK
    syscall
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

close_server:
    mov rax, SYS_CLOSE
    mov rdi, [server_fd]
    syscall
    ret

exit_process:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall