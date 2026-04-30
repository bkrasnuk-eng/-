; practice6.asm
; Заповнення масиву за формулою, пошук min та max з індексами
; Вхід: n (5..50)
; Формула: A[i] = i*i - 3*i + 7   (i від 0 до n-1)

section .bss
    array   resd  50        ; масив з 50 елементів (double word)

section .data
    input_buf   db  16 dup(0)
    space       db  ' '
    newline     db  10

section .text
global _start

_start:
    ; ====================== I/O ======================
    ; Читання n
    call read_number
    mov ecx, eax                ; ECX = n (5..50)

    ; ====================== memory ======================
    ; Заповнення масиву
    mov esi, array              ; база масиву
    xor edi, edi                ; i = 0

.fill_loop:
    ; math: A[i] = i*i - 3*i + 7
    mov eax, edi
    imul eax, edi               ; eax = i * i
    mov ebx, edi
    imul ebx, 3                 ; ebx = 3 * i
    sub eax, ebx                ; eax = i² - 3i
    add eax, 7                  ; eax = i² - 3i + 7

    mov [esi + edi*4], eax      ; array[i] = eax

    inc edi
    cmp edi, ecx
    jl .fill_loop

    ; ====================== I/O ======================
    ; Вивід масиву в один рядок
    mov esi, array
    xor edi, edi                ; індекс

.print_array:
    mov eax, [esi + edi*4]
    call print_number
    mov eax, 4
    mov ebx, 1
    mov ecx, space
    mov edx, 1
    int 0x80

    inc edi
    cmp edi, ecx
    jl .print_array

    call print_newline

    ; ====================== logic + loops ======================
    ; Пошук min та max з індексами
    mov esi, array
    xor edi, edi                ; i = 0

    mov eax, [esi]              ; min_val = array[0]
    mov ebx, [esi]              ; max_val = array[0]
    xor edx, edx                ; min_idx = 0
    xor ebp, ebp                ; max_idx = 0

.find_loop:
    mov eax, [esi + edi*4]      ; поточний елемент

    ; Порівняння для мінімуму (signed)
    cmp eax, [array + edx*4]
    jge .not_new_min
    mov edx, edi                ; новий min_idx
.not_new_min:

    ; Порівняння для максимуму (signed)
    cmp eax, [array + ebp*4]
    jle .not_new_max
    mov ebp, edi                ; новий max_idx
.not_new_max:

    inc edi
    cmp edi, ecx
    jl .find_loop

    ; ====================== I/O ======================
    ; Вивід min та його індексу
    mov eax, 4
    mov ebx, 1
    mov ecx, min_str
    mov edx, min_len
    int 0x80

    mov eax, [array + edx*4]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, idx_str
    mov edx, idx_len
    int 0x80

    mov eax, edx                ; індекс мінімуму
    call print_number
    call print_newline

    ; Вивід max та його індексу
    mov eax, 4
    mov ebx, 1
    mov ecx, max_str
    mov edx, max_len
    int 0x80

    mov eax, [array + ebp*4]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, idx_str
    mov edx, idx_len
    int 0x80

    mov eax, ebp                ; індекс максимуму
    call print_number
    call print_newline

    ; Завершення програми
    mov eax, 1
    xor ebx, ebx
    int 0x80

; =============================================================
; Підпрограми
; =============================================================

read_number:
    ; ====================== I/O ======================
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 15
    int 0x80

    ; ====================== parse ======================
    xor eax, eax
    mov esi, input_buf

.parse_loop:
    movzx ebx, byte [esi]
    cmp bl, 10
    je .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done

    imul eax, 10
    sub bl, '0'
    add eax, ebx
    inc esi
    jmp .parse_loop

.done:
    ret

print_number:
    ; ====================== I/O + math ======================
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, input_buf + 14
    mov byte [esi], 10

    test eax, eax
    jns .positive
    neg eax

.positive:
    mov ebx, 10
.loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec esi
    mov [esi], dl
    test eax, eax
    jnz .loop

    lea ecx, [esi]
    mov edx, input_buf + 15
    sub edx, esi

    mov eax, 4
    mov ebx, 1
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

section .data
    min_str db "min = "
    min_len equ $ - min_str

    max_str db "max = "
    max_len equ $ - max_str

    idx_str db ", index = "
    idx_len equ $ - idx_str