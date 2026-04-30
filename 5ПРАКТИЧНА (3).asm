; practice4.asm
; Вхід: одне число x (1..2_000_000_000)
; Вихід:
;   1) сума цифр числа
;   2) кількість цифр у числі
; Використовує тільки int 0x80

section .data
    input_buf   db  16 dup(0)      ; буфер для введення
    output_buf  db  16 dup(0)      ; буфер для виводу

section .text
global _start

_start:
    ; ====================== I/O ======================
    ; Читання числа з консолі
    mov eax, 3                     ; sys_read
    mov ebx, 0                     ; stdin
    mov ecx, input_buf
    mov edx, 15
    int 0x80

    ; ====================== parse ======================
    ; Перетворення рядка в число (результат у EAX)
    xor eax, eax                   ; число = 0
    mov esi, input_buf

.parse_loop:
    movzx edx, byte [esi]
    cmp dl, 10                     ; '\n'
    je .parse_done
    cmp dl, 13                     ; '\r'
    je .parse_done
    cmp dl, '0'
    jb .parse_done
    cmp dl, '9'
    ja .parse_done

    ; math: число = число * 10 + цифра
    mov ebx, 10
    mul ebx                        ; EAX *= 10
    sub dl, '0'
    add eax, edx

    inc esi
    jmp .parse_loop

.parse_done:
    ; EAX тепер містить число x (1..2_000_000_000)

    ; ====================== math + loops ======================
    ; Обчислення суми цифр і кількості цифр
    xor ebx, ebx                   ; EBX = сума цифр
    xor ecx, ecx                   ; ECX = кількість цифр

    mov edi, 10                    ; основа для ділення

.sum_loop:
    inc ecx                        ; збільшуємо кількість цифр

    xor edx, edx
    div edi                        ; EAX = EAX / 10, EDX = остача (цифра)

    add ebx, edx                   ; додаємо цифру до суми

    test eax, eax
    jnz .sum_loop

    ; Тепер:
    ; EBX = sumDigits(x)
    ; ECX = len(x)

    ; ====================== I/O ======================
    ; Вивід суми цифр
    call print_number              ; друкуємо EBX (sumDigits)
    call print_newline

    ; Вивід кількості цифр
    mov ebx, ecx
    call print_number              ; друкуємо ECX (len)
    call print_newline

    ; ====================== I/O ======================
    ; Завершення програми
    mov eax, 1
    xor ebx, ebx
    int 0x80

; ====================== I/O + math ======================
; Підпрограма: вивести число з EBX на екран
print_number:
    push eax
    push ecx
    push edx
    push esi

    mov esi, output_buf
    add esi, 15                    ; починаємо з кінця буфера
    mov byte [esi], 10             ; '\n'

    mov eax, ebx                   ; число для друку
    mov ecx, 10

    cmp eax, 0
    je .zero_case

.print_loop:
    xor edx, edx
    div ecx                        ; ділимо на 10

    add dl, '0'
    dec esi
    mov [esi], dl

    test eax, eax
    jnz .print_loop
    jmp .print_done

.zero_case:
    dec esi
    mov byte [esi], '0'

.print_done:
    ; Підрахунок довжини
    mov edx, output_buf
    add edx, 16
    sub edx, esi                   ; довжина рядка

    mov eax, 4                     ; sys_write
    mov ebx, 1                     ; stdout
    ; ecx = esi (початок числа)
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop eax
    ret

; ====================== I/O ======================
print_newline:
    mov eax, 4
    mov ebx, 1
    mov ecx, output_buf + 15       ; адреса '\n' у буфері
    mov edx, 1
    int 0x80
    ret