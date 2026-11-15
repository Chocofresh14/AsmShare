%include "include/syscalls.inc"

global parse_request
global path_buffer

section .bss
path_buffer resb PATH_SIZE

section .text

parse_request:
    cmp dword [rdi], 'GET '
    jne parse_request_bad
    add rdi, 4
    cmp byte [rdi], '/'
    jne parse_request_bad
    call extract_path
    ret
parse_request_bad:
    mov rax, 1
    ret

extract_path:
    xor rcx, rcx
extract_path_loop:
    mov al, [rdi + rcx]
    cmp al, ' '
    je extract_path_done
    jb extract_path_bad
    cmp rcx, PATH_SIZE - 1
    jae extract_path_bad
    mov [path_buffer + rcx], al
    inc rcx
    jmp extract_path_loop
extract_path_done:
    mov byte [path_buffer + rcx], 0
    xor rax, rax
    ret
extract_path_bad:
    mov rax, 1
    ret
