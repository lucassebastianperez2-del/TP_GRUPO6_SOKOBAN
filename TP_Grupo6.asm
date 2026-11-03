
.data
menu: .asciz "\nSOKOBAN\n1. Mapa 1\n2. Mapa 2\n3. Mapa 3\nSeleccione (1-3): "
badopt: .asciz "Opcion invalida.\n"
prompt: .asciz "\nMovimiento (W/A/S/D, R reinicia, Q sale): "
fail: .asciz "Movimiento invalido.\n"
movtxt: .asciz "Movimientos: "
nl: .asciz "\n"
cls: .ascii "\033[H\033[2J"
clslen = . - cls

mapa1:
.ascii "#######"
.ascii "#  .  #"
.ascii "#  $  #"
.ascii "#  @  #"
.ascii "#######"

mapa2:
.ascii "########"
.ascii "#  #   #"
.ascii "# $ .  #"
.ascii "# @ $  #"
.ascii "#    . #"
.ascii "########"

mapa3:
.ascii "##########"
.ascii "#   ..   #"
.ascii "# $$$$   #"
.ascii "#   @    #"
.ascii "#   ..   #"
.ascii "##########"

mapa_base: .space 60
mapa_ini: .space 60
mapa: .space 60
filas: .word 0
cols: .word 0
tam: .word 0
jugador: .word 0
sig: .word 0
dir: .word 0
movs: .word 0
opcion: .word 1
ch: .byte 0
movchar: .byte 0
digitos: .space 16

.text
.global _start

_start:
    BL elegir_mapa
    BL cargar_mapa

bucle:
    BL mostrar_mapa
    LDR r0, =prompt
    BL imprimir_cadena
    BL pedir_movimiento
    LDR r1, =movchar
    STRB r0, [r1]
    CMP r0, #'q'
    BEQ terminar
    CMP r0, #'r'
    BEQ reinicio
    BL obtener_posicion_siguiente
    BL verificar_y_mover
    B bucle

reinicio:
    BL reiniciar_nivel
    B bucle

terminar:
    MOV r0, #0
    MOV r7, #1
    SWI 0

elegir_mapa:
    PUSH {r4, lr}
em_menu:
    LDR r0, =menu
    BL imprimir_cadena
    BL leer_caracter
    MOV r4, r0
    LDR r0, =nl
    BL imprimir_cadena
    CMP r4, #'1'
    BLT em_bad
    CMP r4, #'3'
    BGT em_bad
    SUB r4, r4, #'0'
    LDR r0, =opcion
    STR r4, [r0]
    POP {r4, pc}
em_bad:
    LDR r0, =badopt
    BL imprimir_cadena
    B em_menu

cargar_mapa:
    PUSH {r4-r8, lr}
    LDR r0, =opcion
    LDR r4, [r0]
    CMP r4, #1
    BEQ cm1
    CMP r4, #2
    BEQ cm2
    LDR r5, =mapa3
    MOV r6, #6
    MOV r7, #10
    B cm_cfg
cm1:
    LDR r5, =mapa1
    MOV r6, #5
    MOV r7, #7
    B cm_cfg
cm2:
    LDR r5, =mapa2
    MOV r6, #6
    MOV r7, #8
cm_cfg:
    MUL r8, r6, r7
    LDR r0, =filas
    STR r6, [r0]
    LDR r0, =cols
    STR r7, [r0]
    LDR r0, =tam
    STR r8, [r0]
    LDR r0, =mapa_ini
    LDR r1, =mapa_base
    MOV r2, r8
cm_copy:
    CMP r2, #0
    BEQ cm_sanitize_start
    LDRB r3, [r5]
    STRB r3, [r0]
    STRB r3, [r1]
    ADD r5, r5, #1
    ADD r0, r0, #1
    ADD r1, r1, #1
    SUB r2, r2, #1
    B cm_copy
cm_sanitize_start:
    LDR r0, =mapa_base
    LDR r1, =tam
    LDR r1, [r1]
    MOV r2, #0
cm_sanitize:
    CMP r2, r1
    BGE cm_reset
    LDRB r3, [r0, r2]
    CMP r3, #'@'
    BEQ cm_san_floor
    CMP r3, #'$'
    BEQ cm_san_floor
    ADD r2, r2, #1
    B cm_sanitize
cm_san_floor:
    MOV r3, #' '
    STRB r3, [r0, r2]
    ADD r2, r2, #1
    B cm_sanitize
cm_reset:
    BL reiniciar_nivel
    POP {r4-r8, pc}

reiniciar_nivel:
    PUSH {r4-r6, lr}
    LDR r0, =mapa
    LDR r1, =mapa_ini
    LDR r2, =tam
    LDR r2, [r2]
    MOV r4, #0
rn_copy:
    CMP r2, #0
    BEQ rn_scan_start
    LDRB r3, [r1]
    STRB r3, [r0]
    ADD r1, r1, #1
    ADD r0, r0, #1
    SUB r2, r2, #1
    B rn_copy
rn_scan_start:
    LDR r0, =movs
    STR r4, [r0]
    LDR r5, =mapa
    LDR r6, =tam
    LDR r6, [r6]
rn_scan:
    CMP r4, r6
    BGE rn_done
    LDRB r3, [r5, r4]
    CMP r3, #'@'
    BEQ rn_found
    ADD r4, r4, #1
    B rn_scan
rn_found:
    LDR r0, =jugador
    STR r4, [r0]
rn_done:
    POP {r4-r6, pc}

mostrar_mapa:
    PUSH {r4-r8, lr}
    MOV r0, #1
    LDR r1, =cls
    LDR r2, =clslen
    MOV r7, #4
    SWI 0
    LDR r4, =mapa
    LDR r5, =filas
    LDR r5, [r5]
    LDR r6, =cols
    LDR r6, [r6]
    MOV r8, #0
mm_row:
    CMP r8, r5
    BGE mm_count
    MOV r3, #0
mm_col:
    CMP r3, r6
    BGE mm_nl
    MUL r0, r8, r6
    ADD r0, r0, r3
    LDRB r1, [r4, r0]
    LDR r2, =ch
    STRB r1, [r2]
    MOV r0, #1
    MOV r1, r2
    MOV r2, #1
    PUSH {r3, r8}
    MOV r7, #4
    SWI 0
    POP {r3, r8}
    ADD r3, r3, #1
    B mm_col
mm_nl:
    MOV r0, #1
    LDR r1, =nl
    MOV r2, #1
    PUSH {r8}
    MOV r7, #4
    SWI 0
    POP {r8}
    ADD r8, r8, #1
    B mm_row
mm_count:
    LDR r0, =movtxt
    BL imprimir_cadena
    LDR r0, =movs
    LDR r0, [r0]
    BL numero_ascii
    LDR r0, =nl
    BL imprimir_cadena
    POP {r4-r8, pc}

pedir_movimiento:
    PUSH {r4, lr}
pm_read:
    BL leer_caracter
    MOV r4, r0
    CMP r4, #10
    BEQ pm_read
    CMP r4, #13
    BEQ pm_read
    CMP r4, #'A'
    BLT pm_valid
    CMP r4, #'Z'
    BGT pm_valid
    ADD r4, r4, #32
pm_valid:
    CMP r4, #'w'
    BEQ pm_done
    CMP r4, #'a'
    BEQ pm_done
    CMP r4, #'s'
    BEQ pm_done
    CMP r4, #'d'
    BEQ pm_done
    CMP r4, #'r'
    BEQ pm_done
    CMP r4, #'q'
    BEQ pm_done
    LDR r0, =fail
    BL imprimir_cadena
    B pm_read
pm_done:
    MOV r0, r4
    POP {r4, pc}

obtener_posicion_siguiente:
    PUSH {r4-r6, lr}
    LDR r0, =movchar
    LDRB r4, [r0]
    LDR r0, =jugador
    LDR r5, [r0]
    CMP r4, #'w'
    BEQ ops_up
    CMP r4, #'a'
    BEQ ops_left
    CMP r4, #'s'
    BEQ ops_down
    ADD r5, r5, #1
    MOV r6, #3
    B ops_save
ops_up:
    LDR r0, =cols
    LDR r0, [r0]
    SUB r5, r5, r0
    MOV r6, #0
    B ops_save
ops_left:
    SUB r5, r5, #1
    MOV r6, #1
    B ops_save
ops_down:
    LDR r0, =cols
    LDR r0, [r0]
    ADD r5, r5, r0
    MOV r6, #2
ops_save:
    LDR r0, =dir
    STR r6, [r0]
    LDR r0, =sig
    STR r5, [r0]
    POP {r4-r6, pc}

verificar_y_mover:
    PUSH {r4-r11, lr}
    LDR r0, =sig
    LDR r4, [r0]
    LDR r0, =tam
    LDR r0, [r0]
    CMP r4, #0
    BLT vm_fail
    CMP r4, r0
    BGE vm_fail
    LDR r5, =mapa
    LDRB r6, [r5, r4]
    CMP r6, #'#'
    BEQ vm_fail
    CMP r6, #' '
    BEQ vm_walk
    CMP r6, #'.'
    BEQ vm_walk
    CMP r6, #'$'
    BEQ vm_box
    B vm_fail
vm_box:
    LDR r0, =dir
    LDR r7, [r0]
    LDR r0, =cols
    LDR r8, [r0]
    CMP r7, #0
    BEQ vm_up
    CMP r7, #1
    BEQ vm_left
    CMP r7, #2
    BEQ vm_down
    ADD r9, r4, #1
    B vm_check_box
vm_up:
    SUB r9, r4, r8
    B vm_check_box
vm_left:
    SUB r9, r4, #1
    B vm_check_box
vm_down:
    ADD r9, r4, r8
vm_check_box:
    LDR r0, =tam
    LDR r0, [r0]
    CMP r9, #0
    BLT vm_fail
    CMP r9, r0
    BGE vm_fail
    LDRB r10, [r5, r9]
    CMP r10, #' '
    BEQ vm_push
    CMP r10, #'.'
    BEQ vm_push
    B vm_fail
vm_push:
    LDR r0, =mapa_base
    LDRB r11, [r0, r9]
    CMP r11, #'.'
    BEQ vm_box_goal
    MOV r10, #'$'
    B vm_box_store
vm_box_goal:
    MOV r10, #'*'
vm_box_store:
    STRB r10, [r5, r9]
    LDR r0, =mapa_base
    LDRB r10, [r0, r4]
    CMP r10, #'.'
    BEQ vm_player_goal
    MOV r10, #'@'
    B vm_player_store
vm_player_goal:
    MOV r10, #'+'
vm_player_store:
    STRB r10, [r5, r4]
    B vm_update
vm_walk:
    LDR r0, =jugador
    LDR r6, [r0]
    LDR r0, =mapa_base
    LDRB r7, [r0, r6]
    STRB r7, [r5, r6]
    LDR r0, =mapa_base
    LDRB r7, [r0, r4]
    CMP r7, #'.'
    BEQ vm_walk_goal
    MOV r7, #'@'
    B vm_walk_store
vm_walk_goal:
    MOV r7, #'+'
vm_walk_store:
    STRB r7, [r5, r4]
vm_update:
    LDR r0, =jugador
    STR r4, [r0]
    LDR r0, =movs
    LDR r1, [r0]
    ADD r1, r1, #1
    STR r1, [r0]
    POP {r4-r11, pc}
vm_fail:
    LDR r0, =fail
    BL imprimir_cadena
    POP {r4-r11, pc}

numero_ascii:
    PUSH {r4-r8, lr}
    MOV r4, r0
    CMP r4, #0
    BNE na_loop
    MOV r0, #'0'
    BL imprimir_caracter
    POP {r4-r8, pc}
na_loop:
    MOV r5, #0
na_div:
    CMP r4, #0
    BEQ na_print
    MOV r0, r4
    MOV r1, #10
    BL division10
    MOV r4, r0
    ADD r1, r1, #'0'
    LDR r2, =digitos
    STRB r1, [r2, r5]
    ADD r5, r5, #1
    B na_div
na_print:
    SUB r5, r5, #1
na_print_loop:
    LDR r2, =digitos
    LDRB r0, [r2, r5]
    BL imprimir_caracter
    SUB r5, r5, #1
    CMP r5, #0
    BGE na_print_loop
    POP {r4-r8, pc}

division10:
    MOV r2, #0
d10_loop:
    CMP r0, r1
    BLT d10_end
    SUB r0, r0, r1
    ADD r2, r2, #1
    B d10_loop
d10_end:
    MOV r1, r0
    MOV r0, r2
    BX lr

leer_caracter:
    PUSH {r1-r3, r7, lr}
    MOV r0, #0
    LDR r1, =ch
    MOV r2, #1
    MOV r7, #3
    SWI 0
    LDR r1, =ch
    LDRB r0, [r1]
    POP {r1-r3, r7, pc}

imprimir_cadena:
    PUSH {r1-r3, r7, lr}
    MOV r1, r0
    MOV r2, #0
ic_len:
    LDRB r3, [r1, r2]
    CMP r3, #0
    BEQ ic_write
    ADD r2, r2, #1
    B ic_len
ic_write:
    MOV r0, #1
    MOV r7, #4
    SWI 0
    POP {r1-r3, r7, pc}

imprimir_caracter:
    PUSH {r1-r3, r7, lr}
    LDR r1, =ch
    STRB r0, [r1]
    MOV r0, #1
    MOV r2, #1
    MOV r7, #4
    SWI 0
    POP {r1-r3, r7, pc}
