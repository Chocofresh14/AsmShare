SYS_READ        equ 0
SYS_WRITE       equ 1
SYS_OPEN        equ 2
SYS_CLOSE       equ 3
SYS_FSTAT       equ 5
SYS_RT_SIGACTION equ 13
SYS_SENDFILE    equ 40
SYS_SOCKET      equ 41
SYS_ACCEPT      equ 43
SYS_BIND        equ 49
SYS_LISTEN      equ 50
SYS_SETSOCKOPT  equ 54
SYS_FORK        equ 57
SYS_EXIT        equ 60
SYS_CHROOT      equ 161
SYS_GETDENTS64  equ 217
STDOUT		equ 1

AF_INET         equ 2
SOCK_STREAM     equ 1
SOL_SOCKET      equ 1
SO_REUSEADDR    equ 2

PORT_NETWORK    equ 0x901F
BACKLOG         equ 16
REQUEST_SIZE    equ 4096
PATH_SIZE       equ 1024
