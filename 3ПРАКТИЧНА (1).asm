; practice3.asm - Читання рядка → конвертація в число (AX) → вивід числа
; Використовує лише int 0x80 (sys_read, sys_write, sys_exit)
; Компіляція: nasm -f elf32 practice3.asm -o practice3.o
; Лінкування: ld -m elf_i386 practice3.o -o practice3

section .data
    input_buffer  db  20 dup(0)     ; буфер для введення (достатньо для 999999 + '\n')
    output_buffer db  10 dup(0)     ; буфер для виводу числа
    newline       db  10

section .text
global _start

_start:
    ; ====================== I/O ======================
    ; Читання рядка з консолі (sys_read)
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, input_buffer
    mov edx, 20                 ; максимальна кількість байт
    int 0x80

    ; EDX тепер містить кількість прочитаних байтів
    mov esi, eax                ; зберігаємо довжину введення в ESI

    ; ====================== parse ======================
    ; Конвертація ASCII рядка в число (результат у AX)
    xor eax, eax                ; число = 0
    mov ecx, input_buffer       ; вказівник на початок введення
    xor ebx, ebx                ; лічильник/тимчасовий регістр

.parse_loop:
    cmp byte [ecx], 10          ; перевірка на '\n'
    je .parsing_done
    cmp byte [ecx], 13          ; перевірка на '\r' (на всяк випадок)
    je .parsing_done
    cmp byte [ecx], ' '         ; пробіл — теж кінець
    je .parsing_done

    ; Перевірка, чи символ є цифрою
    mov bl, [ecx]
    cmp bl, '0'
    jb .parsing_done            ; символ < '0' — кінець
    cmp bl, '9'
    ja .parsing_done            ; символ > '9' — кінець

    ; math: число = число * 10 + (цифра)
    mov edx, 10
    mul edx                     ; EAX = EAX * 10

    sub bl, '0'                 ; перетворюємо ASCII в число
    add eax, ebx                ; додаємо нову цифру

    inc ecx                     ; переходимо до наступного символу
    jmp .parse_loop

.parsing_done:
    ; AX тепер містить число (0..999999)
    ; Обмежуємо результат до 16-біт (якщо переповнення — беремо тільки нижні 16 біт)
    mov ax, ax                  ; явно беремо тільки AX

    ; ====================== memory ======================
    ; Використовуємо output_buffer для перетворення числа в рядок
    mov ecx, output_buffer
    add ecx, 9                  ; починаємо з кінця буфера
    mov byte [ecx], 10          ; додаємо '\n'

    cmp ax, 0
    je .print_zero

    mov ebx, 10                 ; основа системи числення

.convert_loop:
    xor edx, edx
    div ebx                     ; EAX / 10 → EAX = частка, EDX = остача

    add dl, '0'
    dec ecx
    mov [ecx], dl

    test eax, eax
    jnz .convert_loop

    jmp .prepare_output

.print_zero:
    mov ecx, output_buffer
    mov byte [ecx], '0'
    mov byte [ecx+1], 10

.prepare_output:
    ; ====================== I/O ======================
    ; Підрахунок довжини рядка для виводу
    mov edx, output_buffer
    add edx, 10                 ; кінець буфера
    sub edx, ecx                ; довжина = кінець - початок

    ; sys_write
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    ; ecx вже вказує на першу цифру
    int 0x80

    ; ====================== I/O ======================
    ; Завершення програми
    mov eax, 1                  ; sys_exit
    xor ebx, ebx
    int 0x80