; practice10.asm - Двійкове представлення числа, popcount та бітові операції
; i386, NASM, Debian Linux, тільки int 0x80

section .data
    newline   db 10
    space     db ' '
    separator db " | "
    msg_pop   db "popcount: "
    len_pop   equ $ - msg_pop
    msg_after db "after set/clear: "
    len_after equ $ - msg_after

section .bss
    x         resd 1          ; введене число
    input_buf times 32 db 0
    num_str   times 16 db 0

section .text
global _start

_start:
    ; ==================== I/O + parse: читання числа x ====================
    call read_int
    mov [x], eax

    ; ==================== I/O: вивід двійкового представлення ====================
    ; 32 біти, групи по 4 з пробілом
    mov eax, [x]
    mov ecx, 32               ; лічильник бітів (зверху вниз)

bin_loop:
    cmp ecx, 0
    jle bin_done

    ; Виводимо групу по 4 біти
    push ecx
    mov ebx, 4                ; 4 біти в групі

group_loop:
    cmp ebx, 0
    jle group_done

    shl eax, 1                ; зсуваємо вліво, старший біт потрапляє у CF
    jc print_one
    mov al, '0'
    jmp print_bit
print_one:
    mov al, '1'
print_bit:
    call print_char

    dec ebx
    jmp group_loop

group_done:
    pop ecx

    ; Після кожної групи (крім останньої) друкуємо пробіл
    cmp ecx, 4
    jle no_space
    mov al, ' '
    call print_char
no_space:

    sub ecx, 4
    jmp bin_loop

bin_done:
    call print_newline

    ; ==================== math + loops: підрахунок popcount ====================
    mov eax, [x]
    mov ebx, 0                ; лічильник бітів = 0

popcount_loop:
    test eax, eax
    jz popcount_done

    mov edx, eax
    and edx, 1                ; беремо молодший біт
    add ebx, edx

    shr eax, 1                ; зсуваємо вправо
    jmp popcount_loop

popcount_done:
    ; Вивід "popcount: "
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_pop
    mov edx, len_pop
    int 0x80

    mov eax, ebx
    call print_int
    call print_newline

    ; ==================== logic: set бітів p=3, q=7 та clear біта r=15 ====================
    mov eax, [x]

    ; set bit 3 (1 << 3)
    or eax, (1 << 3)

    ; set bit 7 (1 << 7)
    or eax, (1 << 7)

    ; clear bit 15
    and eax, ~(1 << 15)

    ; ==================== I/O: вивід результату після операцій ====================
    mov ecx, eax              ; зберігаємо результат

    mov eax, 4
    mov ebx, 1
    mov edx, len_after
    mov esi, msg_after
    xchg ecx, esi
    int 0x80
    xchg ecx, esi

    mov eax, ecx
    call print_int
    call print_newline

    ; Завершення програми
    mov eax, 1                ; sys_exit
    mov ebx, 0
    int 0x80

; ================================================================
; read_int - читання 32-бітного цілого числа (підтримує від'ємні)
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
    xor ebx, ebx                  ; 0 = позитивне, 1 = негативне

    cmp byte [esi], '-'
    jne .parse_loop
    mov ebx, 1
    inc esi

.parse_loop:
    movzx edx, byte [esi]
    cmp edx, 10                   ; \n
    je .apply_sign
    cmp edx, '0'
    jl .apply_sign
    cmp edx, '9'
    jg .apply_sign

    imul eax, 10
    sub edx, '0'
    add eax, edx
    inc esi
    jmp .parse_loop

.apply_sign:
    test ebx, ebx
    jz .done
    neg eax

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
; print_int - друк цілого числа (підтримує від'ємні)
; ================================================================
print_int:
    push ebx
    push ecx
    push edx
    push esi

    mov esi, num_str + 15
    mov byte [esi], 0
    dec esi

    mov ebx, eax
    test eax, eax
    jns .positive

    neg eax
    mov byte [num_str], '-'
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, num_str
    mov edx, 1
    int 0x80
    pop eax

.positive:
    test eax, eax
    jnz .digits

    mov byte [esi], '0'
    dec esi
    jmp .output

.digits:
    mov ecx, 10
.digit_loop:
    xor edx, edx
    div ecx
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
; print_char - друк одного символу
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