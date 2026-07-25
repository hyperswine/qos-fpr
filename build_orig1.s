# target: rv64
    .text
    .balign 4

# Cons (arity 2)
fpr_fn_Cons:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel0
    call fpr_fuel_exhausted
.Lfuel0:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 24
    call fpr_alloc
    li t0, 2
    sw t0, 0(a0)
    li t0, 1
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 16(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Err (arity 1)
fpr_fn_Err:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel1
    call fpr_fuel_exhausted
.Lfuel1:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 3
    sw t0, 0(a0)
    li t0, 1
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# False (arity 0)
fpr_fn_False:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel2
    call fpr_fuel_exhausted
.Lfuel2:
    la a0, .Lnul_1_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Handle (arity 1)
fpr_fn_Handle:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel3
    call fpr_fuel_exhausted
.Lfuel3:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 1311748180
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Nil (arity 0)
fpr_fn_Nil:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel4
    call fpr_fuel_exhausted
.Lfuel4:
    la a0, .Lnul_2_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Ok (arity 1)
fpr_fn_Ok:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel5
    call fpr_fuel_exhausted
.Lfuel5:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 3
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SString (arity 1)
fpr_fn_SString:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel6
    call fpr_fuel_exhausted
.Lfuel6:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 1893715646
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# True (arity 0)
fpr_fn_True:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel7
    call fpr_fuel_exhausted
.Lfuel7:
    la a0, .Lnul_1_1
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Tup2 (arity 2)
fpr_fn_Tup2:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel8
    call fpr_fuel_exhausted
.Lfuel8:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 24
    call fpr_alloc
    li t0, 4
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 16(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Tup3 (arity 3)
fpr_fn_Tup3:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel9
    call fpr_fuel_exhausted
.Lfuel9:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 32
    call fpr_alloc
    li t0, 5
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 24(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 16(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Unit (arity 0)
fpr_fn_Unit:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel10
    call fpr_fuel_exhausted
.Lfuel10:
    la a0, .Lnul_0_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Vector (arity 1)
fpr_fn_Vector:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel11
    call fpr_fuel_exhausted
.Lfuel11:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 1461553473
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# getx (arity 1)
    .globl fpr_fn_getx
fpr_fn_getx:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel12
    call fpr_fuel_exhausted
.Lfuel12:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    ld a0, 8(a0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# lifted_2 (arity 1)
fpr_fn_lifted_x5f2:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel13
    call fpr_fuel_exhausted
.Lfuel13:
    ld a0, -24(s0)
    sd a0, -32(s0)
    li a0, 5
    sd a0, -40(s0)
    ld a0, -32(s0)
    ld a1, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2a
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# lifted_3 (arity 1)
fpr_fn_lifted_x5f3:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel14
    call fpr_fuel_exhausted
.Lfuel14:
    ld a0, -24(s0)
    sd a0, -32(s0)
    li a0, 3
    sd a0, -40(s0)
    ld a0, -32(s0)
    ld a1, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2b
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# lifted_4 (arity 1)
fpr_fn_lifted_x5f4:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel15
    call fpr_fuel_exhausted
.Lfuel15:
    ld a0, -24(s0)
    sd a0, -32(s0)
    li a0, 7
    sd a0, -40(s0)
    ld a0, -32(s0)
    ld a1, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2a
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# main (arity 0)
    .globl fpr_fn_main
fpr_fn_main:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel25
    call fpr_fuel_exhausted
.Lfuel25:
    li a0, 21
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 41
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 24
    call fpr_alloc
    li t0, 60143704
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 16(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    sd a0, -24(s0)
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    call fpr_fn_getx
    sd a0, -32(s0)
    ld a0, -32(s0)
    call fpr_fn_newHandle
    sd a0, -32(s0)
    li a0, 3
    sd a0, -40(s0)
    ld a0, -24(s0)
    ld a0, 16(a0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a1, -48(s0)
    call fpr_fn_fromTo
    sd a0, -40(s0)
    la a0, fpr_obj_lifted_x5f2
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    ld a1, -56(s0)
    call fpr_fn_mapV
    sd a0, -48(s0)
    la a0, fpr_obj_lifted_x5f3
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_fn_mapV
    sd a0, -56(s0)
    la a0, fpr_obj_lifted_x5f4
    sd a0, -64(s0)
    ld a0, -56(s0)
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    call fpr_fn_mapV
    sd a0, -64(s0)
    ld a0, -64(s0)
    sd a0, -72(s0)
    ld a0, -72(s0)
    call fpr_fn_sumV
    sd a0, -72(s0)
    ld a0, -72(s0)
    sd a0, -80(s0)
    li a0, 3
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    call fpr_prim_fn__x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 1
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 24
    call fpr_alloc
    li t0, 60143704
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 16(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 8(a0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    sd a0, -88(s0)
    li a0, 201
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x3c_x3d
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf16
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf16
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf16
    la a0, fpr_true
    j .Ltagd17
.Ltagf16:
    la a0, fpr_false
.Ltagd17:
    lw t0, 4(a0)
    beqz t0, .Lelse23
    ld a0, -24(s0)
    sd a0, -96(s0)
    ld a0, -96(s0)
    call fpr_fn_getx
    j .Lendif24
.Lelse23:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf18
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf18
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf18
    la a0, fpr_true
    j .Ltagd19
.Ltagf18:
    la a0, fpr_false
.Ltagd19:
    lw t0, 4(a0)
    beqz t0, .Lelse21
    ld a0, -24(s0)
    sd a0, -104(s0)
    ld a0, -104(s0)
    call fpr_fn_getx
    sd a0, -96(s0)
    ld a0, -80(s0)
    ld a0, 8(a0)
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_prim_fn__x2b
    j .Lendif22
.Lelse21:
    la a0, .Lstr20
    call fpr_panic
.Lendif22:
.Lendif24:
    sd a0, -88(s0)
    ld a0, -88(s0)
    sd a0, -96(s0)
    ld a0, -32(s0)
    sd a0, -112(s0)
    ld a0, -112(s0)
    call fpr_fn_closeHandle
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2b
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

    .section .rodata

    .balign 8
fpr_obj_Cons:
    .long 9001
    .long 0
    .quad fpr_fn_Cons
    .quad 2
    .quad 0

    .balign 8
fpr_obj_Err:
    .long 9001
    .long 0
    .quad fpr_fn_Err
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Handle:
    .long 9001
    .long 0
    .quad fpr_fn_Handle
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Ok:
    .long 9001
    .long 0
    .quad fpr_fn_Ok
    .quad 1
    .quad 0

    .balign 8
fpr_obj_SString:
    .long 9001
    .long 0
    .quad fpr_fn_SString
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Tup2:
    .long 9001
    .long 0
    .quad fpr_fn_Tup2
    .quad 2
    .quad 0

    .balign 8
fpr_obj_Tup3:
    .long 9001
    .long 0
    .quad fpr_fn_Tup3
    .quad 3
    .quad 0

    .balign 8
fpr_obj_Vector:
    .long 9001
    .long 0
    .quad fpr_fn_Vector
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_getx
fpr_obj_getx:
    .long 9001
    .long 0
    .quad fpr_fn_getx
    .quad 1
    .quad 0

    .balign 8
fpr_obj_lifted_x5f2:
    .long 9001
    .long 0
    .quad fpr_fn_lifted_x5f2
    .quad 1
    .quad 0

    .balign 8
fpr_obj_lifted_x5f3:
    .long 9001
    .long 0
    .quad fpr_fn_lifted_x5f3
    .quad 1
    .quad 0

    .balign 8
fpr_obj_lifted_x5f4:
    .long 9001
    .long 0
    .quad fpr_fn_lifted_x5f4
    .quad 1
    .quad 0

    .balign 8
.Lstr20:
    .long 9000
    .long 0
    .quad 69
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 84, 114, 117, 101
    .byte 34, 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 70, 97, 108, 115, 101
    .byte 34, 32, 91, 93, 93

    .balign 8
.Lnul_0_0:
    .long 0
    .long 0

    .balign 8
.Lnul_1_0:
    .long 1
    .long 0

    .balign 8
.Lnul_1_1:
    .long 1
    .long 1

    .balign 8
.Lnul_2_0:
    .long 2
    .long 0

