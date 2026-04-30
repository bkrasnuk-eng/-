; practice9.asm - Генерація псевдовипадкових чисел + гістограма частот
; i386, NASM, Debian Linux, тільки int 0x80

section .data
    newline   db 10
    colon     db ': '
    space     db ' '
    hash      db '#'

section .bss
    n         resd 1          ; кількість чисел (100..1000)
    seed      resd 1          ; поточне значення LCG
    freq      resd 10         ; частоти для цифр 0-9

    input_buf times 32 db 0
    num_str   times 16 db 0

section .text
global _start

_start:
    ; ==================== I/O + parse: читання n ====================
    call read_int
    mov [n], eax

    ; ==================== memory: ініціалізація масиву частот ====================
    mov ecx, 10
    mov ebx, freq
init_freq:
    mov dword [ebx], 0
    add ebx, 4
    dec ecx
    jnz init_freq

    ; ==================== math: ініціалізація LCG ====================
    mov dword [seed], 123456789   ; початкове значення seed

    ; ==================== loops: генерація n чисел та підрахунок частот ====================
    mov ecx, [n]                  ; лічильник циклу
generate_loop:
    cmp ecx, 0
    jle print_histogram

    ; LCG: x = (a * x + c) mod 2^31
    mov eax, [seed]
    mov ebx, 1103515245
    mul ebx                       ; edx:eax = 1103515245 * seed
    add eax, 12345
    ; mod 2^31 = очистити старший біт (edx ігноруємо)
    and eax, 0x7FFFFFFF
    mov [seed], eax

    ; Отримуємо цифру 0-9: x % 10
    mov ebx, 10
    xor edx, edx
    div ebx                       ; eax = quotient, edx = remainder (0-9)

    ; Інкремент freq[digit]
    shl edx, 2                    ; edx *= 4 (розмір dword)
    inc dword [freq + edx]

    dec ecx
    jmp generate_loop

print_histogram:
    ; ==================== I/O + loops: вивід гістограми ====================
    mov ecx, 0                    ; цифра від 0 до 9
print_loop:
    cmp ecx, 10
    jge exit_program

    ; Друк цифри
    mov eax, ecx
    call print_digit

    ; Друк ": "
    mov eax, 4
    mov ebx, 1
    mov edx, 2
    mov ecx, colon
    int 0x80

    ; Друк # пропорційно частоті (1 # = 1 елемент)
    mov eax, [freq + ecx*4]
    call print_hashes

    ; Друк кількості в дужках
    push ecx
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    mov eax, '('
    call print_char
    mov eax, [freq + ecx*4]       ; відновлюємо частоту
    call print_int
    mov eax, ')'
    call print_char
    pop ecx

    call print_newline

    inc ecx
    jmp print_loop

exit_program:
    mov eax, 1                    ; sys_exit
    mov ebx, 0
    int 0x80

; ================================================================
; read_int - читання цілого числа
; ================================================================
read_int:
    push ebx
    push ecx
    push edx
    push esi

    mov eax, 3                    ; sys_read
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 31
    int 0x80

    test eax, eax
    jz .error

    mov esi, input_buf
    xor eax, eax
    xor ebx, ebx

.parse:
    movzx edx, byte [esi]
    cmp edx, 10                   ; \n
    je .done
    cmp edx, '0'
    jl .done
    cmp edx, '9'
    jg .done

    imul eax, 10
    sub edx, '0'
    add eax, edx
    inc esi
    jmp .parse

.done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

.error:
    xor eax, eax
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ================================================================
; print_digit - друк однієї цифри (0-9)
; ================================================================
print_digit:
    push eax
    push ebx
    push ecx
    push edx

    add al, '0'
    mov [num_str], al

    mov eax, 4
    mov ebx, 1
    mov ecx, num_str
    mov edx, 1
    int 0x80

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; ================================================================
; print_hashes - друк count символів '#'
; ================================================================
print_hashes:
    push ebx
    push ecx
    push edx

    mov ecx, eax                  ; кількість #
    test ecx, ecx
    jz .done

.hash_loop:
    mov eax, 4
    mov ebx, 1
    mov edx, 1
    mov esi, hash
    xchg ecx, esi                 ; тимчасово
    int 0x80
    xchg ecx, esi

    dec ecx
    jnz .hash_loop

.done:
    pop edx
    pop ecx
    pop ebx
    ret

; ================================================================
; print_int - вивід цілого числа (негативні не потрібні)
; ================================================================
print_int:
    push ebx
    push ecx
    push edx
    push esi

    mov esi, num_str + 15
    mov byte [esi], 0
    dec esi

    test eax, eax
    jnz .digits

    mov byte [esi], '0'
    dec esi
    jmp .output

.digits:
    mov ebx, 10
.digit_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    mov [esi], dl
    dec esi
    test eax, eax
    jnz .digit_loop

.output:
    inc esi
    mov ecx, esi
    mov edx, num_str + 15
    sub edx, ecx
    inc edx

    mov eax, 4
    mov ebx, 1
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ================================================================
; print_char - вивід одного символу
; ================================================================
print_char:
    push ebx
    push ecx
    push edx

    mov [num_str], al

    mov eax, 4
    mov ebx, 1
    mov ecx, num_str
    mov edx, 1
    int 0x80

    pop edx
    pop ecx
    pop ebx
    ret

; ================================================================
; print_newline
; ================================================================
print_newline:
    push eax
    push ebx
    push ecx
    push edx

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret