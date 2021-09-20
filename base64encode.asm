; File: base64encode.asm

SECTION .data           ; Section containing initialised data
    Base64Table: db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    padding: db "=" 

SECTION .bss            ; Section containing uninitialized data

    BUF_LEN_IN EQU 3    ; Input buffer length - so many chars we are reading in each turn
    BUF_LEN_OUT EQU 4   ; Output buffer length

    buf: resb BUF_LEN_IN+1 ; Input buffer: reserve 4 bytes, so we can easily move dword between memory and e*x registers
    buf_len: resd 1        ; holds length of the chars readen

    res: resb BUF_LEN_OUT ; Output buffer

SECTION .text           ; Section containing code

global _start           ; Linker needs this to find the entry point!

_start:
loop_read:

	; in each turn we try to read at most 3 bytes
	; fill with 0's  so no trash if read less then BUF_LEn
	mov byte [buf], 0       
	mov byte [buf+1], 0
	mov byte [buf+2], 0
	mov byte [buf+3], 0
	
	; reset buf_len from previous read cycle
	mov dword [buf_len], 0
	
	; reset output buffer from previous convert cycle
	mov byte [res],   0
	mov byte [res+1], 0
	mov byte [res+2], 0
	mov byte [res+3], 0
	
	      ; read system call
	mov rax, 3            
	mov rbx, 0  ; 0 = standard input handle        
	mov rcx, buf      
	mov rdx, BUF_LEN_IN
	int 80h      
	
	      ; if EOF - no more to read - exit
	cmp rax, 0  
	je finish  

        ; save number of read chars into buf_len
        mov dword [buf_len], eax

        ; reset rbx
        xor rbx, rbx

        ; we are putting readen chars into rbx
        ; put every byte into bl and then shift left
        mov bl, byte [buf]  ; 1. byte from the input buffer
        shl rbx, 8

        mov bl, byte [buf+1] ; 2. byte from the input buffer
        shl rbx, 8

        mov bl, byte [buf+2] ; 3. byte from the input buffer

        ; now we have 3 bytes into rbx
        ; save it into rcx becaue we're gonna need it later
        mov rcx, rbx     ; save 3 bytes
        
        ; now we are starting to build output
        ; convert 1. 6 bits
        shr rbx, 18
        and rbx, 0x3f
        mov al, [Base64Table + rbx]
        mov byte [res], al
        
        ; convert 2. 6 bits
        mov rbx, rcx
        shr rbx, 12
        and rbx, 0x3f
        mov al, [Base64Table + rbx]
        mov byte [res+1], al

        ; convert 3. 6 bits
        mov rbx, rcx
        shr rbx, 6
        and rbx, 0x3f
        mov al, [Base64Table + rbx]
        mov byte [res+2], al

        ; convert 4. 6 bits
        mov rbx, rcx
        and rbx, 0x3f
        mov al, [Base64Table + rbx]
        mov byte [res+3], al

check_padding:
        ; if read length != 3 then we have padding -> add '='
        mov eax, dword [buf_len]
        cmp eax, 1
        jne check_padding_2
        ;; by length 1 add 2 x '='
        ;; fill with 2 paddings
        mov byte [res+2], '='
        mov byte [res+3], '='
        jmp print

check_padding_2:
        cmp eax, 2
        ;  by length 2 add 1 x '='
        ;; fill with 1 padding
        jne print
        mov byte [res+3], '='
        jmp print

print:
        ; now print the output buffer
  mov rax, 4    
  mov rbx, 1  
  mov rdx, 4
  mov rcx, res
        int 80h  
        
        mov eax, dword [buf_len]
        ; if read length < 3 then we are finished
        ; otherwise try to read next 3 bytes
        cmp eax, 3
        je loop_read    
finish:
    ; exit
    mov rax, 60         ; Code for exit
    mov rdi, 0          ; Return a code of zero
    syscall             ; Make kernel call
