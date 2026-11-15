%include "include/syscalls.inc"

extern strlen
extern memcpy
extern strcmp
extern itoa

global _start

section .data
text_hello      db "Hello", 0
text_source     db "ABCDEF", 0
text_abc        db "abc", 0
text_abc_copy   db "abc", 0
text_abd        db "abd", 0
text_newline    db 10, 0

label_strlen    db "strlen(Hello) = ", 0
label_memcpy    db "memcpy(ABCDEF) = ", 0
label_cmp_same  db "strcmp(abc, abc) = ", 0
label_cmp_diff  db "strcmp(abd, abc) = ", 0
label_itoa_0    db "itoa(0) = ", 0
label_itoa_n    db "itoa(12345) = ", 0
label_itoa_big  db "itoa(4294967295) = ", 0
label_itoa_len  db "longueur itoa(12345) = ", 0

section .bss
copy_buffer     resb 16
number_buffer   resb 32

section .text

_start:
    call test_strlen
    call test_memcpy
    call test_strcmp
    call test_itoa
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

test_strlen:
    mov rdi, label_strlen
    call print_string
    mov rdi, text_hello
    call strlen
    mov rdi, rax
    call print_number
    call print_newline
    ret

test_memcpy:
    mov rdi, copy_buffer
    mov rsi, text_source
    mov rdx, 7
    call memcpy
    mov rdi, label_memcpy
    call print_string
    mov rdi, copy_buffer
    call print_string
    call print_newline
    ret

test_strcmp:
    mov rdi, label_cmp_same
    call print_string
    mov rdi, text_abc
    mov rsi, text_abc_copy
    call strcmp
    mov rdi, rax
    call print_number
    call print_newline
    mov rdi, label_cmp_diff
    call print_string
    mov rdi, text_abd
    mov rsi, text_abc
    call strcmp
    mov rdi, rax
    call print_number
    call print_newline
    ret

test_itoa:
    mov rdi, label_itoa_0
    call print_string
    mov rdi, 0
    call print_number
    call print_newline
    mov rdi, label_itoa_n
    call print_string
    mov rdi, 12345
    call print_number
    call print_newline
    mov rdi, label_itoa_big
    call print_string
    mov rdi, 4294967295
    call print_number
    call print_newline
    mov rdi, label_itoa_len
    call print_string
    mov rdi, 12345
    mov rsi, number_buffer
    call itoa
    mov rdi, rax
    call print_number
    call print_newline
    ret

print_string:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

print_number:
    mov rsi, number_buffer
    call itoa
    mov rdi, number_buffer
    call print_string
    ret

print_newline:
    mov rdi, text_newline
    call print_string
    ret
