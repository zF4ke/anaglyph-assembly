;********************************************************************
section .data
;********************************************************************
; definições úteis
LF                  equ 10
NULL                equ 0
EXIT_SUCCESS        equ 0
STDIN               equ 0
STDOUT              equ 1
STDERR              equ 2
SYS_read            equ 0
SYS_write           equ 1
SYS_open            equ 2
SYS_close           equ 3
SYS_exit            equ 60
SYS_creat           equ 85
O_RDONLY            equ 000000q
S_IRUSR             equ 00400q
S_IWUSR             equ 00200q
; tamanhos máximos esperados
MAX_FILENAME_SIZE   equ 255
MAX_IMG_SIZE        equ 1048576
; file descriptors
bmpFileDesc         dq  0
; mensagens de erro
errMsgOpenBmp       db "Erro ao abrir o BMP", LF, NULL
errMsgRead          db "Erro ao ler o BMP", LF, NULL
errMsgWrite         db "Error write", LF, NULL
newLine             db LF,NULL

;********************************************************************
section .text
;********************************************************************
;--------------------------------------------------------------------
; Listagem das funções disponíveis na biblioteca
;--------------------------------------------------------------------
global terminate
global printStr
global printStrLn
global readImageFile
global writeImageFile

;--------------------------------------------------------------------
; terminate
; Objetivo: Encerrar a execução do programa
; Entrada : Nenhuma
; Saida : Nenhuma
; Destrói: RAX e RDI
;--------------------------------------------------------------------
terminate:
    mov rax, SYS_exit
    mov rdi, EXIT_SUCCESS
    syscall

;--------------------------------------------------------------------
; printStr
; Objetivo: Imprime uma string (terminada em 0) no terminal de saída
; Entrada : 
;   RDI - Endereço de memória para string a ser impressa
; Saida : Nada
; Destrói: RDI, RSI e RAX
;--------------------------------------------------------------------
printStr:
    push rbp
    mov rbp, rsp
    push rbx
    ; 1) conta os caracteres da string
    mov rbx, rdi
    mov rdx, 0
strCountLoop:
    cmp byte [rbx], NULL
    je strCountDone
    inc rdx
    inc rbx
    jmp strCountLoop
strCountDone:
    cmp rdx, 0
    je prtDone
    ; 2) imprime a string na saída
    mov rax, SYS_write
    mov rsi, rdi
    mov rdi, STDOUT 
    syscall  
prtDone:
    pop rbx
    pop rbp
    ret

;--------------------------------------------------------------------
; printStrLn
; Objetivo: Imprime uma string (terminada em 0) e um '\n' no terminal de saída
; Entrada : 
;   RDI - Endereço de memória para string a ser impressa
; Saida : Nada
; Destrói: RDI, RSI e RAX
;--------------------------------------------------------------------
printStrLn:
    ; 1) imprime a string
    call printStr
    ; 2) imprime o newLine
    mov rdi, newLine
    call printStr
    ret

;--------------------------------------------------------------------
; readImageFile
; Objetivo: Ler um ficheiro de imagem (BMP) para um buffer (espaço) na memória
; Entrada : 
;   RDI - Endereço de memória para string com o nome do ficheiro (BMP) a ler
;   RSI - Endereço do buffer (espaço de memória) que guardará os bytes lidos
; Saida : 
;   RAX - quantidade de bytes lidos do ficheiro para o buffer na memória
; Destrói: RAX e RSI
;--------------------------------------------------------------------
readImageFile:
    push rsi ; salvaguarda o buffer para usar depois
    ; 1) abre o ficheiro
    mov rax, SYS_open
    ; RDI é passado como argumento para a função
    mov rsi, O_RDONLY
    syscall
    cmp rax,0
    jl errorOnOpenBmp 
    mov [bmpFileDesc], rax
    ; 2) lê o ficheiro
    mov rax, SYS_read
    mov rdi, qword [bmpFileDesc]
    pop rsi ; recupera o buffer que estava salvaguardado
    mov rdx, MAX_IMG_SIZE
    syscall
    cmp rax,0
    jl errorOnRead
    push rax ; salvaguarda o valor de rax, pois este contem a quantidade de bytes lidos da imagem original
    ; 3) fecha o ficheiro
    mov rax, SYS_close
    mov rdi, qword [bmpFileDesc]
    syscall 
    ; 4) retorna
    pop rax
    ret

;--------------------------------------------------------------------
; writeImageFile
; Objetivo: Escrever o conteúdo do buffer com a imagem modificada para um ficheiro BMP
; Entrada : 
;   RDI - Endereço de memória para a string com o nome do ficheiro a escrever
;   RSI - Endereço do buffer que contém os bytes da imagem modificada a serem escritos
;   RDX - Quantidade de bytes do buffer para escrever no ficheiro
; Saida : Nada
; Destrói: RDI, RSI, RAX e RDX
;--------------------------------------------------------------------
writeImageFile:
    push rsi
    push rdx
    ; 1) abre (ou cria) o ficheiro
    mov rax, SYS_creat
    ;mov rdi, [modifiedBmpFileName]; rdi already contains the address of the filename
    mov rsi, S_IRUSR | S_IWUSR
    syscall
    cmp rax,0
    jl errorOnOpenBmp
    mov [bmpFileDesc], rax
    ; 2) escreve o ficheiro
    mov rax, SYS_write
    mov rdi, qword [bmpFileDesc]
    pop rdx ; recupera o tamanho a escrever, que estava salvaguardado
    pop rsi ; recupera o buffer, que estava salvaguardado
    syscall
    cmp rax, 0
    jl errorOnWrite
    ; 3) fecha o ficheiro
    mov rax, SYS_close
    mov rdi, qword [bmpFileDesc]
    syscall 
    ; 4) retorna
    ret

;--------------------------------------------------------------------
; Rótulos auxiliares apenas para escrever mensagens de erro e terminar
;--------------------------------------------------------------------
errorOnOpenBmp:
    mov rdi, errMsgOpenBmp
    call printStrLn
    call terminate
    
errorOnRead:
    mov rdi, errMsgRead
    call printStrLn
    call terminate

errorOnWrite:
    mov rdi, errMsgWrite
    call printStrLn
    call terminate