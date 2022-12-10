section .data

section .bss
    mode: resq 1

    left_filename: resq 1
    right_filename: resq 1
    anaglyph_filename: resq 1

    image_right: resb 1048576
    image_right_size: resd 1
    image_right_offset: resd 1

    image_left: resb 1048576
    image_left_size: resd 1
    image_left_offset: resd 1

section .rodata
    msg_error_args: db "Error: invalid arguments!", 10, "Help: C/M left.bmp right.mbp anaglyph.bmp", 0
    msg_error_size: db "Error: images are not the same size!", 0

section .text
global _start
extern printStrLn, terminate, readImageFile, writeImageFile

_start:
    ; get argc
    mov rcx, [rsp]
    ; check if there is at least four arguments
    cmp cl, 4
    jle _error_args

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
    mov rdi, [mode]
    call printStrLn
    mov rdi, [left_filename]
    call printStrLn
    mov rdi, [right_filename]
    call printStrLn
    mov rdi, [anaglyph_filename]
    call printStrLn
    ; end debug

    ; check if arg is "C" or "M"
    ; if not, print error message and exit
    mov rsi, [mode]
    cmp byte [rsi], 'C'
    je _C
    cmp byte [rsi], 'M'
    je _M
    jmp _error_args

_C:
    ; get images
    call getImages

    ;mov rdi, [anaglyph_filename]
    ;call saveImageFile

    jmp _end
    
_M:
    ; get images
    call getImages

    jmp _end

_error_args:
    mov rdi, msg_error_args
    call printStrLn
    jmp _end

_error_size:
    mov rdi, msg_error_size
    call printStrLn
    jmp _end

_end:
    call terminate

    ;saveImageFile:
    ; open file
    ;mov rsi, image
    ;mov rdx, [image_size]
    ;call writeImageFile
    ;ret

getImages:
    ; get left image
    mov rdi, [left_filename]
    mov rsi, image_left
    call readImageFile

    ; get left image size
    mov rdi, image_left
    call getImageSize
    mov [image_left_size], eax

    ; get left image offset
    mov rdi, image_left
    call getImageOffset
    mov [image_left_offset], eax

    ; get right image
    mov rdi, [right_filename]
    mov rsi, image_right
    call readImageFile

    ; get right image size
    mov rdi, image_right
    call getImageSize
    mov [image_right_size], eax

    ; get right image offset
    mov rdi, image_right
    call getImageOffset
    mov [image_right_offset], eax

    ; check if images are the same size
    ; if not, print error message and exit
    mov rax, [image_left_size]
    cmp rax, [image_right_size]
    jne _error_size

    ret

getImageSize:
    ; save rbx
    push rbx
    ; get image size
    xor rax, rax
    xor rbx, rbx
    mov bl, [rdi+5]
    add rax, rbx
    mov bl, [rdi+4]
    shl rax, 8
    add rax, rbx
    mov bl, [rdi+3]
    shl rax, 8
    add rax, rbx
    mov bl, [rdi+2]
    shl rax, 8
    add rax, rbx
    ; restore rbx
    pop rbx
    ret

getImageOffset:
    ; save rbx
    push rbx
    ; get image offset
    xor rax, rax
    xor rbx, rbx
    mov bl, [rdi+13]
    add rax, rbx
    mov bl, [rdi+12]
    shl rax, 8
    add rax, rbx
    mov bl, [rdi+11]
    shl rax, 8
    add rax, rbx
    mov bl, [rdi+10]
    shl rax, 8
    add rax, rbx
    ; restore rbx
    pop rbx
    ret