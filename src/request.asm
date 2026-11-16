%include "include/syscalls.inc"

extern strlen

global parse_request
global has_parent_reference
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
    test rax, rax
    jnz parse_request_bad
    mov rsi, rdi
    mov rdi, path_buffer
    call strlen
    lea rdi, [rsi + rax + 1]
    call check_http_version
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

check_http_version:
    cmp dword [rdi], 'HTTP'
    jne check_http_version_bad
    cmp word [rdi + 4], '/1'
    jne check_http_version_bad
    cmp byte [rdi + 6], '.'
    jne check_http_version_bad
    cmp byte [rdi + 7], '0'
    je check_http_version_ok
    cmp byte [rdi + 7], '1'
    jne check_http_version_bad
check_http_version_ok:
    xor rax, rax
    ret
check_http_version_bad:
    mov rax, 1
    ret

has_parent_reference:
    xor rcx, rcx
has_parent_reference_loop:
    mov al, [rdi + rcx]
    test al, al
    je has_parent_reference_no
    cmp al, '.'
    jne has_parent_reference_next
    cmp byte [rdi + rcx + 1], '.'
    je has_parent_reference_yes
has_parent_reference_next:
    inc rcx
    jmp has_parent_reference_loop
has_parent_reference_no:
    xor rax, rax
    ret
has_parent_reference_yes:
    mov rax, 1
    ret