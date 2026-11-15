global strlen
global memcpy
global strcmp
global itoa

section .text

strlen:
    xor rax, rax
strlen_loop:
    cmp byte [rdi + rax], 0
    je strlen_done
    inc rax
    jmp strlen_loop
strlen_done:
    ret

memcpy:
    xor rcx, rcx
memcpy_loop:
    cmp rcx, rdx
    jae memcpy_done
    mov al, [rsi + rcx]
    mov [rdi + rcx], al
    inc rcx
    jmp memcpy_loop
memcpy_done:
    ret

strcmp:
    mov al, [rdi]
    mov dl, [rsi]
    cmp al, dl
    jne strcmp_different
    test al, al
    je strcmp_equal
    inc rdi
    inc rsi
    jmp strcmp
strcmp_equal:
    xor rax, rax
    ret
strcmp_different:
    movzx rax, al
    movzx rdx, dl
    sub rax, rdx
    ret

itoa:
    mov rax, rdi
    mov r8, 10
    xor rcx, rcx
itoa_divide_loop:
    xor rdx, rdx
    div r8
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz itoa_divide_loop
    mov r9, rcx
itoa_write_loop:
    pop rdx
    mov [rsi], dl
    inc rsi
    dec rcx
    jnz itoa_write_loop
    mov byte [rsi], 0
    mov rax, r9
    ret
