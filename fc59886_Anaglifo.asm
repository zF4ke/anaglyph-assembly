; fc59886

section .data
    red_mult: dd 0.299
    green_mult: dd 0.587
    blue_mult: dd 0.114

section .bss
    mode: resq 1

    left_filename: resq 1
    right_filename: resq 1
    anaglyph_filename: resq 1   

    image_right: resb 1048576
    image_right_size: resq 1
    image_right_offset: resq 1

    image_left: resb 1048576
    image_left_size: resq 1
    image_left_offset: resq 1

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

    ; create anaglyph image
    xor rax, rax 
    mov rbx, [image_left_offset]
    mov rcx, [image_left_size]
_C_for:
    cmp rbx, rcx
    jb _C_cycle
    jmp _C_for_end
_C_cycle:
    ; move left R to right R
    mov al, [image_left+rbx+2]
    mov [image_right+rbx+2], al

    add rbx, 4
    jmp _C_for
_C_for_end:    
    mov rdi, [anaglyph_filename]
    mov rsi, image_right
    mov rcx, [image_left_size]
    call writeImageFile

    jmp _end

_M:
    ; get images
    call getImages

    ; create anaglyph image
    xor rax, rax
    mov rbx, [image_left_offset]
    mov rcx, [image_left_size]
_M_for:
    cmp rbx, rcx
    jb _M_cycle
    jmp _M_for_end
_M_cycle:
    ; clear rax, rsi, xmm0, xmm1, xmm2, xmm3, xmm4, xmm5
    xor rax, rax
    xor rsi, rsi
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    xorps xmm4, xmm4
    xorps xmm5, xmm5

    ; move left R to al
    mov al, [image_left+rbx+2]
    ; convert to float and multiply by red_mult
    cvtsi2ss xmm0, eax
    mov rsi, red_mult
    movss xmm1, [rsi]
    mulss xmm0, xmm1
    
    ; move left G to al
    mov al, [image_left+rbx+1]
    ; convert to float and multiply by green_mult
    cvtsi2ss xmm2, eax
    mov rsi, green_mult
    movss xmm3, [rsi]
    mulss xmm2, xmm3
    ; add to xmm0
    addss xmm0, xmm2

    ; move left B to al
    mov al, [image_left+rbx]
    ; convert to float and multiply by blue_mult
    cvtsi2ss xmm4, eax
    mov rsi, blue_mult
    movss xmm5, [rsi]
    mulss xmm4, xmm5
    ; add to xmm0
    addss xmm0, xmm4

    ; convert to int and move to right R
    cvttss2si rax, xmm0
    mov [image_right+rbx+2], al

    ; clear xmm0, xmm1, xmm2, xmm3, xmm4, xmm5
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    xorps xmm4, xmm4
    xorps xmm5, xmm5

    ; move right R to al
    mov al, [image_right+rbx+2]
    ; convert to float and multiply by red_mult
    cvtsi2ss xmm0, eax
    mov rsi, red_mult
    movss xmm1, [rsi]
    mulss xmm0, xmm1

    ; move right G to al
    mov al, [image_right+rbx+1]
    ; convert to float and multiply by green_mult
    cvtsi2ss xmm2, eax
    mov rsi, green_mult
    movss xmm3, [rsi]
    mulss xmm2, xmm3
    ; add to xmm0
    addss xmm0, xmm2

    ; move right B to al
    mov al, [image_right+rbx]
    ; convert to float and multiply by blue_mult
    cvtsi2ss xmm4, eax
    mov rsi, blue_mult
    movss xmm5, [rsi]
    mulss xmm4, xmm5
    ; add to xmm0
    addss xmm0, xmm4

    ; convert to int and move to right G
    cvttss2si rax, xmm0
    mov [image_right+rbx+1], al
    ; move to right B
    mov [image_right+rbx], al

    add rbx, 4
    jmp _M_for
_M_for_end:
    mov rdi, [anaglyph_filename]
    mov rsi, image_right
    mov rcx, [image_left_size]
    call writeImageFile

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

getImages:
    ; get left image
    mov rdi, [left_filename]
    mov rsi, image_left
    call readImageFile

    ; get left image size
    mov rdi, image_left
    call getImageSize
    mov qword [image_left_size], rax

    ; get left image offset
    mov rdi, image_left
    call getImageOffset
    mov qword [image_left_offset], rax

    ; get right image
    mov rdi, [right_filename]
    mov rsi, image_right
    call readImageFile

    ; get right image size
    mov rdi, image_right
    call getImageSize
    mov qword [image_right_size], rax

    ; get right image offset
    mov rdi, image_right
    call getImageOffset
    mov qword [image_right_offset], rax

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