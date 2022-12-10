section .data

section .bss
    mode: resq 1
    left_filename: resq 1
    right_filename: resq 1
    anaglyph_filename: resq 1
    image: resb 1048576
    image_size: resb 3

section .rodata
    msg_error: db "Error: invalid arguments!", 10, "Help: C/M left.bmp right.mbp anaglyph.bmp", 0
    msg_debug_C: db "Executing C Mode", 0
    msg_debug_M: db "Executing M Mode", 0

section .text
global _start
extern printStrLn, terminate, readImageFile, writeImageFile

_start:
    ; get argc
    mov rcx, [rsp]
    ; check if there is at least four arguments
    cmp cl, 4
    jle _error

    ; get arguments
    ; get mode
    mov rsi, [rsp+2*8]
    mov [mode], rsi
    ; get left filename
    mov rsi, [rsp+3*8]
    mov [left_filename], rsi
    ; get right filename
    mov rsi, [rsp+4*8]
    mov [right_filename], rsi
    ; get anaglyph filename
    mov rsi, [rsp+5*8]
    mov [anaglyph_filename], rsi

    ; debug
    mov RDI, [mode]
    call printStrLn
    mov RDI, [left_filename]
    call printStrLn
    mov RDI, [right_filename]
    call printStrLn
    mov RDI, [anaglyph_filename]
    call printStrLn
    ; end debug

    ; check if arg is "C" or "M"
    ; if not, print error message and exit
    mov rsi, [mode]
    cmp byte [rsi], 'C'
    je _C
    cmp byte [rsi], 'M'
    je _M
    jmp _error

_C:
    ; debug
    mov RDI, msg_debug_C
    call printStrLn
    ; end debug

    mov rdi, [left_filename]
    call getImageFile

    mov rdi, [anaglyph_filename]
    call saveImageFile

    jmp _end
    
_M:
    call getImageFile

    jmp _end

_error:
    mov RDI, msg_error
    call printStrLn

_end:
    call terminate
    
getImageFile:
    ; open file
    mov rsi, image
    call readImageFile
    ; move rax to image_size
    mov [image_size], rax
    ret

saveImageFile:
    ; open file
    mov rsi, image
    mov rdx, [image_size]
    call writeImageFile
    ret
