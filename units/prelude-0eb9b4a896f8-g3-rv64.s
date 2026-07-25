# target: rv64
    .text
    .balign 4

# Actor (arity 0)
    .globl fpr_fn_Actor
fpr_fn_Actor:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel0
    call fpr_fuel_exhausted
.Lfuel0:
    la a0, fpr_obj_Actor_x2erecv
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2erecvRes
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2eself
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2esend
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2espawn
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2espawnOn
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Actor_x2eyield
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 64
    call fpr_alloc
    li t0, 17889055
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 56(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 48(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 40(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 32(a0)
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

# Actor.recv (arity 1)
    .globl fpr_fn_Actor_x2erecv
fpr_fn_Actor_x2erecv:
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
    sd a0, -32(s0)
    la a0, fpr_g_receive
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.recvRes (arity 1)
    .globl fpr_fn_Actor_x2erecvRes
fpr_fn_Actor_x2erecvRes:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel2
    call fpr_fuel_exhausted
.Lfuel2:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_receiveRes
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.self (arity 1)
    .globl fpr_fn_Actor_x2eself
fpr_fn_Actor_x2eself:
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
    sd a0, -32(s0)
    la a0, fpr_g_myself
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.send (arity 2)
    .globl fpr_fn_Actor_x2esend
fpr_fn_Actor_x2esend:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel4
    call fpr_fuel_exhausted
.Lfuel4:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_send
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.spawn (arity 1)
    .globl fpr_fn_Actor_x2espawn
fpr_fn_Actor_x2espawn:
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
    sd a0, -32(s0)
    la a0, fpr_g_spawn
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.spawnOn (arity 2)
    .globl fpr_fn_Actor_x2espawnOn
fpr_fn_Actor_x2espawnOn:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel6
    call fpr_fuel_exhausted
.Lfuel6:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_spawnOn
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Actor.yield (arity 1)
    .globl fpr_fn_Actor_x2eyield
fpr_fn_Actor_x2eyield:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel7
    call fpr_fuel_exhausted
.Lfuel7:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_yield
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

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
    bgtz t1, .Lfuel9
    call fpr_fuel_exhausted
.Lfuel9:
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
    bgtz t1, .Lfuel10
    call fpr_fuel_exhausted
.Lfuel10:
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
    bgtz t1, .Lfuel11
    call fpr_fuel_exhausted
.Lfuel11:
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

# Int (arity 0)
    .globl fpr_fn_Int
fpr_fn_Int:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel12
    call fpr_fuel_exhausted
.Lfuel12:
    la a0, fpr_obj_Int_x2e_x2a
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x2d
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x2f
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x3c
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x3c_x3d
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2e_x3d_x3d
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2eabs
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2emax
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2emin
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2emod
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Int_x2eneg
    addi sp, sp, -16
    sd a0, 0(sp)
    call fpr_fn_Int_x2ezero
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 112
    call fpr_alloc
    li t0, 242000345
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 104(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 96(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 88(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 80(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 72(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 64(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 56(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 48(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 40(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 32(a0)
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

# Int.* (arity 2)
    .globl fpr_fn_Int_x2e_x2a
fpr_fn_Int_x2e_x2a:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel13
    call fpr_fuel_exhausted
.Lfuel13:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
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

# Int.+ (arity 2)
    .globl fpr_fn_Int_x2e_x2b
fpr_fn_Int_x2e_x2b:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel14
    call fpr_fuel_exhausted
.Lfuel14:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
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

# Int.- (arity 2)
    .globl fpr_fn_Int_x2e_x2d
fpr_fn_Int_x2e_x2d:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel15
    call fpr_fuel_exhausted
.Lfuel15:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int./ (arity 2)
    .globl fpr_fn_Int_x2e_x2f
fpr_fn_Int_x2e_x2f:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel16
    call fpr_fuel_exhausted
.Lfuel16:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2f
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.< (arity 2)
    .globl fpr_fn_Int_x2e_x3c
fpr_fn_Int_x2e_x3c:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel17
    call fpr_fuel_exhausted
.Lfuel17:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x3c
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.<= (arity 2)
    .globl fpr_fn_Int_x2e_x3c_x3d
fpr_fn_Int_x2e_x3c_x3d:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel18
    call fpr_fuel_exhausted
.Lfuel18:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x3c_x3d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.== (arity 2)
    .globl fpr_fn_Int_x2e_x3d_x3d
fpr_fn_Int_x2e_x3d_x3d:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel19
    call fpr_fuel_exhausted
.Lfuel19:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x3d_x3d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.abs (arity 1)
    .globl fpr_fn_Int_x2eabs
fpr_fn_Int_x2eabs:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel29
    call fpr_fuel_exhausted
.Lfuel29:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    li a0, 1
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a1, -48(s0)
    call fpr_prim_fn__x3c
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf20
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf20
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf20
    la a0, fpr_true
    j .Ltagd21
.Ltagf20:
    la a0, fpr_false
.Ltagd21:
    lw t0, 4(a0)
    beqz t0, .Lelse27
    li a0, 1
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    ld a1, -56(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2d
    j .Lendif28
.Lelse27:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf22
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf22
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf22
    la a0, fpr_true
    j .Ltagd23
.Ltagf22:
    la a0, fpr_false
.Ltagd23:
    lw t0, 4(a0)
    beqz t0, .Lelse25
    ld a0, -32(s0)
    j .Lendif26
.Lelse25:
    la a0, .Lstr24
    call fpr_panic
.Lendif26:
.Lendif28:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.max (arity 2)
    .globl fpr_fn_Int_x2emax
fpr_fn_Int_x2emax:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel38
    call fpr_fuel_exhausted
.Lfuel38:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_prim_fn__x3e
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf30
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf30
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf30
    la a0, fpr_true
    j .Ltagd31
.Ltagf30:
    la a0, fpr_false
.Ltagd31:
    lw t0, 4(a0)
    beqz t0, .Lelse36
    ld a0, -40(s0)
    j .Lendif37
.Lelse36:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf32
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf32
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf32
    la a0, fpr_true
    j .Ltagd33
.Ltagf32:
    la a0, fpr_false
.Ltagd33:
    lw t0, 4(a0)
    beqz t0, .Lelse34
    ld a0, -48(s0)
    j .Lendif35
.Lelse34:
    la a0, .Lstr24
    call fpr_panic
.Lendif35:
.Lendif37:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.min (arity 2)
    .globl fpr_fn_Int_x2emin
fpr_fn_Int_x2emin:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel47
    call fpr_fuel_exhausted
.Lfuel47:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_prim_fn__x3c
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf39
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf39
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf39
    la a0, fpr_true
    j .Ltagd40
.Ltagf39:
    la a0, fpr_false
.Ltagd40:
    lw t0, 4(a0)
    beqz t0, .Lelse45
    ld a0, -40(s0)
    j .Lendif46
.Lelse45:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf41
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf41
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf41
    la a0, fpr_true
    j .Ltagd42
.Ltagf41:
    la a0, fpr_false
.Ltagd42:
    lw t0, 4(a0)
    beqz t0, .Lelse43
    ld a0, -48(s0)
    j .Lendif44
.Lelse43:
    la a0, .Lstr24
    call fpr_panic
.Lendif44:
.Lendif46:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.mod (arity 2)
    .globl fpr_fn_Int_x2emod
fpr_fn_Int_x2emod:
    addi sp, sp, -112
    sd ra, 104(sp)
    sd s0, 96(sp)
    addi s0, sp, 112
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel48
    call fpr_fuel_exhausted
.Lfuel48:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -80(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    call fpr_prim_fn__x2f
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a1, -80(s0)
    call fpr_prim_fn__x2a
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.neg (arity 1)
    .globl fpr_fn_Int_x2eneg
fpr_fn_Int_x2eneg:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel49
    call fpr_fuel_exhausted
.Lfuel49:
    ld a0, -24(s0)
    sd a0, -32(s0)
    li a0, 1
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a1, -48(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Int.zero (arity 0)
    .globl fpr_fn_Int_x2ezero
fpr_fn_Int_x2ezero:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel50
    call fpr_fuel_exhausted
.Lfuel50:
    li a0, 1
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Mmio (arity 0)
    .globl fpr_fn_Mmio
fpr_fn_Mmio:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel51
    call fpr_fuel_exhausted
.Lfuel51:
    la a0, fpr_obj_Mmio_x2eread
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Mmio_x2ewrite
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 24
    call fpr_alloc
    li t0, 68330110
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

# Mmio.read (arity 1)
    .globl fpr_fn_Mmio_x2eread
fpr_fn_Mmio_x2eread:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel52
    call fpr_fuel_exhausted
.Lfuel52:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_read
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Mmio.write (arity 2)
    .globl fpr_fn_Mmio_x2ewrite
fpr_fn_Mmio_x2ewrite:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel53
    call fpr_fuel_exhausted
.Lfuel53:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_write
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
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
    bgtz t1, .Lfuel54
    call fpr_fuel_exhausted
.Lfuel54:
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
    bgtz t1, .Lfuel55
    call fpr_fuel_exhausted
.Lfuel55:
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

# SStr (arity 0)
    .globl fpr_fn_SStr
fpr_fn_SStr:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel56
    call fpr_fuel_exhausted
.Lfuel56:
    la a0, fpr_obj_SStr_x2eat
    addi sp, sp, -16
    sd a0, 0(sp)
    call fpr_fn_SStr_x2ecap
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2eclear
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2efromStr
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2elen
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2enew
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2epush
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2eput
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_SStr_x2etoStr
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 80
    call fpr_alloc
    li t0, 127683528
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 72(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 64(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 56(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 48(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 40(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 32(a0)
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

# SStr.at (arity 2)
    .globl fpr_fn_SStr_x2eat
fpr_fn_SStr_x2eat:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel57
    call fpr_fuel_exhausted
.Lfuel57:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_sstrAt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.cap (arity 0)
    .globl fpr_fn_SStr_x2ecap
fpr_fn_SStr_x2ecap:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel58
    call fpr_fuel_exhausted
.Lfuel58:
    li a0, 257
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.clear (arity 1)
    .globl fpr_fn_SStr_x2eclear
fpr_fn_SStr_x2eclear:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel59
    call fpr_fuel_exhausted
.Lfuel59:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_sstrClear
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.fromStr (arity 1)
    .globl fpr_fn_SStr_x2efromStr
fpr_fn_SStr_x2efromStr:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel60
    call fpr_fuel_exhausted
.Lfuel60:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_sstrFromStr
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.len (arity 1)
    .globl fpr_fn_SStr_x2elen
fpr_fn_SStr_x2elen:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel61
    call fpr_fuel_exhausted
.Lfuel61:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_sstrLen
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.new (arity 1)
    .globl fpr_fn_SStr_x2enew
fpr_fn_SStr_x2enew:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel62
    call fpr_fuel_exhausted
.Lfuel62:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_sstrNew
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.push (arity 2)
    .globl fpr_fn_SStr_x2epush
fpr_fn_SStr_x2epush:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel63
    call fpr_fuel_exhausted
.Lfuel63:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_sstrPush
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.put (arity 3)
    .globl fpr_fn_SStr_x2eput
fpr_fn_SStr_x2eput:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel64
    call fpr_fuel_exhausted
.Lfuel64:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    la a0, fpr_g_sstrPut
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 3
    ld a0, 48(sp)
    call fpr_applyN
    addi sp, sp, 64
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# SStr.toStr (arity 1)
    .globl fpr_fn_SStr_x2etoStr
fpr_fn_SStr_x2etoStr:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel65
    call fpr_fuel_exhausted
.Lfuel65:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_sstrToStr
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
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
    bgtz t1, .Lfuel66
    call fpr_fuel_exhausted
.Lfuel66:
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

# Str (arity 0)
    .globl fpr_fn_Str
fpr_fn_Str:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel67
    call fpr_fuel_exhausted
.Lfuel67:
    la a0, fpr_obj_Str_x2e_x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2e_x3d_x3d
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2eat
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2efromCode
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2elen
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2eparse
    addi sp, sp, -16
    sd a0, 0(sp)
    call fpr_fn_Str_x2ezero
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 64
    call fpr_alloc
    li t0, 127662496
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 56(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 48(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 40(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 32(a0)
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

# Str.+ (arity 2)
    .globl fpr_fn_Str_x2e_x2b
fpr_fn_Str_x2e_x2b:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel68
    call fpr_fuel_exhausted
.Lfuel68:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn_strcat
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.== (arity 2)
    .globl fpr_fn_Str_x2e_x3d_x3d
fpr_fn_Str_x2e_x3d_x3d:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel69
    call fpr_fuel_exhausted
.Lfuel69:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x3d_x3d
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.at (arity 2)
    .globl fpr_fn_Str_x2eat
fpr_fn_Str_x2eat:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel70
    call fpr_fuel_exhausted
.Lfuel70:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_charAt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.fromCode (arity 1)
    .globl fpr_fn_Str_x2efromCode
fpr_fn_Str_x2efromCode:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel71
    call fpr_fuel_exhausted
.Lfuel71:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_chr
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.len (arity 1)
    .globl fpr_fn_Str_x2elen
fpr_fn_Str_x2elen:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel72
    call fpr_fuel_exhausted
.Lfuel72:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_strlen
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.parse (arity 1)
    .globl fpr_fn_Str_x2eparse
fpr_fn_Str_x2eparse:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel73
    call fpr_fuel_exhausted
.Lfuel73:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_parseInt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# Str.zero (arity 0)
    .globl fpr_fn_Str_x2ezero
fpr_fn_Str_x2ezero:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel75
    call fpr_fuel_exhausted
.Lfuel75:
    la a0, .Lstr74
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
    bgtz t1, .Lfuel76
    call fpr_fuel_exhausted
.Lfuel76:
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
    bgtz t1, .Lfuel77
    call fpr_fuel_exhausted
.Lfuel77:
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
    bgtz t1, .Lfuel78
    call fpr_fuel_exhausted
.Lfuel78:
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
    bgtz t1, .Lfuel79
    call fpr_fuel_exhausted
.Lfuel79:
    la a0, .Lnul_0_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList (arity 0)
    .globl fpr_fn_VList
fpr_fn_VList:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel80
    call fpr_fuel_exhausted
.Lfuel80:
    la a0, fpr_obj_VList_x2efilter
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2efold
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2efree
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2efromList
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2eget
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2elen
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2emap
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2enew
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2epush
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2eset
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2esplit
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_VList_x2etoList
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 104
    call fpr_alloc
    li t0, 84467022
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 96(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 88(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 80(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 72(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 64(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 56(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 48(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 40(a0)
    ld t1, 0(sp)
    addi sp, sp, 16
    sd t1, 32(a0)
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

# VList.filter (arity 2)
    .globl fpr_fn_VList_x2efilter
fpr_fn_VList_x2efilter:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel81
    call fpr_fuel_exhausted
.Lfuel81:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_Vec_x2efilter
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.fold (arity 3)
    .globl fpr_fn_VList_x2efold
fpr_fn_VList_x2efold:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel82
    call fpr_fuel_exhausted
.Lfuel82:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    la a0, fpr_g_Vec_x2efold
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 3
    ld a0, 48(sp)
    call fpr_applyN
    addi sp, sp, 64
    sd a0, -72(s0)
    ld a0, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_foldRes
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.free (arity 1)
    .globl fpr_fn_VList_x2efree
fpr_fn_VList_x2efree:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel83
    call fpr_fuel_exhausted
.Lfuel83:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_Vec_x2efree
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.fromList (arity 1)
    .globl fpr_fn_VList_x2efromList
fpr_fn_VList_x2efromList:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel84
    call fpr_fuel_exhausted
.Lfuel84:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_Vec_x2efromList
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.get (arity 2)
    .globl fpr_fn_VList_x2eget
fpr_fn_VList_x2eget:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel85
    call fpr_fuel_exhausted
.Lfuel85:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_Vec_x2eget
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.len (arity 1)
    .globl fpr_fn_VList_x2elen
fpr_fn_VList_x2elen:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel86
    call fpr_fuel_exhausted
.Lfuel86:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_Vec_x2elen
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -40(s0)
    ld a0, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_lenRes
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.map (arity 2)
    .globl fpr_fn_VList_x2emap
fpr_fn_VList_x2emap:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel87
    call fpr_fuel_exhausted
.Lfuel87:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_Vec_x2emap
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.new (arity 1)
    .globl fpr_fn_VList_x2enew
fpr_fn_VList_x2enew:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel88
    call fpr_fuel_exhausted
.Lfuel88:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_Vec_x2enew
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.push (arity 2)
    .globl fpr_fn_VList_x2epush
fpr_fn_VList_x2epush:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel89
    call fpr_fuel_exhausted
.Lfuel89:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_Vec_x2epush
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.set (arity 3)
    .globl fpr_fn_VList_x2eset
fpr_fn_VList_x2eset:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel90
    call fpr_fuel_exhausted
.Lfuel90:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    la a0, fpr_g_Vec_x2eset
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 3
    ld a0, 48(sp)
    call fpr_applyN
    addi sp, sp, 64
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.split (arity 2)
    .globl fpr_fn_VList_x2esplit
fpr_fn_VList_x2esplit:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel91
    call fpr_fuel_exhausted
.Lfuel91:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_Vec_x2esplit
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# VList.toList (arity 1)
    .globl fpr_fn_VList_x2etoList
fpr_fn_VList_x2etoList:
    addi sp, sp, -48
    sd ra, 40(sp)
    sd s0, 32(sp)
    addi s0, sp, 48
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel92
    call fpr_fuel_exhausted
.Lfuel92:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_Vec_x2etoList
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
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
    bgtz t1, .Lfuel93
    call fpr_fuel_exhausted
.Lfuel93:
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

# closeHandle (arity 1)
    .globl fpr_fn_closeHandle
fpr_fn_closeHandle:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel99
    call fpr_fuel_exhausted
.Lfuel99:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf94
    lw t0, 0(a0)
    li t1, 1311748180
    bne t0, t1, .Ltagf94
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf94
    la a0, fpr_true
    j .Ltagd95
.Ltagf94:
    la a0, fpr_false
.Ltagd95:
    lw t0, 4(a0)
    beqz t0, .Lelse97
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif98
.Lelse97:
    la a0, .Lstr96
    call fpr_panic
.Lendif98:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# foldRes (arity 1)
    .globl fpr_fn_foldRes
fpr_fn_foldRes:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel105
    call fpr_fuel_exhausted
.Lfuel105:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf100
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf100
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf100
    la a0, fpr_true
    j .Ltagd101
.Ltagf100:
    la a0, fpr_false
.Ltagd101:
    lw t0, 4(a0)
    beqz t0, .Lelse103
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif104
.Lelse103:
    la a0, .Lstr102
    call fpr_panic
.Lendif104:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# fromTo (arity 2)
    .globl fpr_fn_fromTo
fpr_fn_fromTo:
    addi sp, sp, -112
    sd ra, 104(sp)
    sd s0, 96(sp)
    addi s0, sp, 112
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel114
    call fpr_fuel_exhausted
.Lfuel114:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_prim_fn__x3e
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf106
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf106
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf106
    la a0, fpr_true
    j .Ltagd107
.Ltagf106:
    la a0, fpr_false
.Ltagd107:
    lw t0, 4(a0)
    beqz t0, .Lelse112
    call fpr_fn_Nil
    j .Lendif113
.Lelse112:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf108
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf108
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf108
    la a0, fpr_true
    j .Ltagd109
.Ltagf108:
    la a0, fpr_false
.Ltagd109:
    lw t0, 4(a0)
    beqz t0, .Lelse110
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -88(s0)
    li a0, 3
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x2b
    sd a0, -80(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    call fpr_fn_fromTo
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif111
.Lelse110:
    la a0, .Lstr24
    call fpr_panic
.Lendif111:
.Lendif113:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# fstV (arity 1)
    .globl fpr_fn_fstV
fpr_fn_fstV:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel128
    call fpr_fuel_exhausted
.Lfuel128:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf115
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf115
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf115
    la a0, fpr_true
    j .Ltagd116
.Ltagf115:
    la a0, fpr_false
.Ltagd116:
    lw t0, 4(a0)
    beqz t0, .Lelse126
    call fpr_fn_Nil
    j .Lendif127
.Lelse126:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf117
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf117
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf117
    la a0, fpr_true
    j .Ltagd118
.Ltagf117:
    la a0, fpr_false
.Ltagd118:
    lw t0, 4(a0)
    beqz t0, .Lelse124
    ld a0, -40(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf119
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf119
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf119
    la a0, fpr_true
    j .Ltagd120
.Ltagf119:
    la a0, fpr_false
.Ltagd120:
    lw t0, 4(a0)
    beqz t0, .Lelse122
    ld a0, -40(s0)
    ld a0, 8(a0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a0, 16(a0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -80(s0)
    call fpr_fn_fstV
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif123
.Lelse122:
    la a0, .Lstr121
    call fpr_panic
.Lendif123:
    j .Lendif125
.Lelse124:
    la a0, .Lstr121
    call fpr_panic
.Lendif125:
.Lendif127:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# lenRes (arity 1)
    .globl fpr_fn_lenRes
fpr_fn_lenRes:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel133
    call fpr_fuel_exhausted
.Lfuel133:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf129
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf129
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf129
    la a0, fpr_true
    j .Ltagd130
.Ltagf129:
    la a0, fpr_false
.Ltagd130:
    lw t0, 4(a0)
    beqz t0, .Lelse131
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif132
.Lelse131:
    la a0, .Lstr102
    call fpr_panic
.Lendif132:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# mapFstV (arity 2)
    .globl fpr_fn_mapFstV
fpr_fn_mapFstV:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel147
    call fpr_fuel_exhausted
.Lfuel147:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf134
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf134
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf134
    la a0, fpr_true
    j .Ltagd135
.Ltagf134:
    la a0, fpr_false
.Ltagd135:
    lw t0, 4(a0)
    beqz t0, .Lelse145
    call fpr_fn_Nil
    j .Lendif146
.Lelse145:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf136
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf136
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf136
    la a0, fpr_true
    j .Ltagd137
.Ltagf136:
    la a0, fpr_false
.Ltagd137:
    lw t0, 4(a0)
    beqz t0, .Lelse143
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf138
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf138
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf138
    la a0, fpr_true
    j .Ltagd139
.Ltagf138:
    la a0, fpr_false
.Ltagd139:
    lw t0, 4(a0)
    beqz t0, .Lelse141
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -80(s0)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -72(s0)
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
    sd a0, -88(s0)
    ld a0, -40(s0)
    sd a0, -104(s0)
    ld a0, -80(s0)
    sd a0, -112(s0)
    ld a0, -104(s0)
    ld a1, -112(s0)
    call fpr_fn_mapFstV
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif142
.Lelse141:
    la a0, .Lstr140
    call fpr_panic
.Lendif142:
    j .Lendif144
.Lelse143:
    la a0, .Lstr140
    call fpr_panic
.Lendif144:
.Lendif146:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# mapSndV (arity 2)
    .globl fpr_fn_mapSndV
fpr_fn_mapSndV:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel160
    call fpr_fuel_exhausted
.Lfuel160:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf148
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf148
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf148
    la a0, fpr_true
    j .Ltagd149
.Ltagf148:
    la a0, fpr_false
.Ltagd149:
    lw t0, 4(a0)
    beqz t0, .Lelse158
    call fpr_fn_Nil
    j .Lendif159
.Lelse158:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf150
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf150
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf150
    la a0, fpr_true
    j .Ltagd151
.Ltagf150:
    la a0, fpr_false
.Ltagd151:
    lw t0, 4(a0)
    beqz t0, .Lelse156
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf152
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf152
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf152
    la a0, fpr_true
    j .Ltagd153
.Ltagf152:
    la a0, fpr_false
.Ltagd153:
    lw t0, 4(a0)
    beqz t0, .Lelse154
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -80(s0)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -72(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
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
    sd a0, -88(s0)
    ld a0, -40(s0)
    sd a0, -104(s0)
    ld a0, -80(s0)
    sd a0, -112(s0)
    ld a0, -104(s0)
    ld a1, -112(s0)
    call fpr_fn_mapSndV
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif155
.Lelse154:
    la a0, .Lstr140
    call fpr_panic
.Lendif155:
    j .Lendif157
.Lelse156:
    la a0, .Lstr140
    call fpr_panic
.Lendif157:
.Lendif159:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# mapV (arity 2)
    .globl fpr_fn_mapV
fpr_fn_mapV:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel170
    call fpr_fuel_exhausted
.Lfuel170:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf161
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf161
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf161
    la a0, fpr_true
    j .Ltagd162
.Ltagf161:
    la a0, fpr_false
.Ltagd162:
    lw t0, 4(a0)
    beqz t0, .Lelse168
    call fpr_fn_Nil
    j .Lendif169
.Lelse168:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf163
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf163
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf163
    la a0, fpr_true
    j .Ltagd164
.Ltagf163:
    la a0, fpr_false
.Ltagd164:
    lw t0, 4(a0)
    beqz t0, .Lelse166
    ld a0, -56(s0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -80(s0)
    ld a0, -40(s0)
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_fn_mapV
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif167
.Lelse166:
    la a0, .Lstr165
    call fpr_panic
.Lendif167:
.Lendif169:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# newHandle (arity 1)
    .globl fpr_fn_newHandle
fpr_fn_newHandle:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel171
    call fpr_fuel_exhausted
.Lfuel171:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Handle
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# par2 (arity 5)
    .globl fpr_fn_par2
fpr_fn_par2:
    addi sp, sp, -160
    sd ra, 152(sp)
    sd s0, 144(sp)
    addi s0, sp, 160
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    sd a4, -56(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel177
    call fpr_fuel_exhausted
.Lfuel177:
    ld a0, -24(s0)
    sd a0, -64(s0)
    ld a0, -32(s0)
    sd a0, -72(s0)
    ld a0, -40(s0)
    sd a0, -80(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    ld a0, -56(s0)
    sd a0, -96(s0)
    la a0, fpr_g_myself
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 1
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -104(s0)
    la a0, fpr_g_spawnOn
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_parWorker
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -112(s0)
    la a0, fpr_g_send
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -112(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -104(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -72(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -80(s0)
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
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -120(s0)
    ld a0, -88(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -96(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -128(s0)
    la a0, fpr_g_receiveRes
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -104(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -136(s0)
    ld a0, -136(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf172
    lw t0, 0(a0)
    li t1, 3
    bne t0, t1, .Ltagf172
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf172
    la a0, fpr_true
    j .Ltagd173
.Ltagf172:
    la a0, fpr_false
.Ltagd173:
    lw t0, 4(a0)
    beqz t0, .Lelse175
    ld a0, -136(s0)
    ld a0, 8(a0)
    sd a0, -144(s0)
    ld a0, -144(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -128(s0)
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
    j .Lendif176
.Lelse175:
    la a0, .Lstr174
    call fpr_panic
.Lendif176:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# parWorker (arity 1)
    .globl fpr_fn_parWorker
fpr_fn_parWorker:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel183
    call fpr_fuel_exhausted
.Lfuel183:
    ld a0, -24(s0)
    sd a0, -32(s0)
    la a0, fpr_g_receive
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf178
    lw t0, 0(a0)
    li t1, 5
    bne t0, t1, .Ltagf178
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf178
    la a0, fpr_true
    j .Ltagd179
.Ltagf178:
    la a0, fpr_false
.Ltagd179:
    lw t0, 4(a0)
    beqz t0, .Lelse181
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a0, 16(a0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    ld a0, 24(a0)
    sd a0, -64(s0)
    la a0, fpr_g_send
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -72(s0)
    ld a0, -72(s0)
    call fpr_fn_Ok
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    j .Lendif182
.Lelse181:
    la a0, .Lstr180
    call fpr_panic
.Lendif182:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# sndV (arity 1)
    .globl fpr_fn_sndV
fpr_fn_sndV:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel197
    call fpr_fuel_exhausted
.Lfuel197:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf184
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf184
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf184
    la a0, fpr_true
    j .Ltagd185
.Ltagf184:
    la a0, fpr_false
.Ltagd185:
    lw t0, 4(a0)
    beqz t0, .Lelse195
    call fpr_fn_Nil
    j .Lendif196
.Lelse195:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf186
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf186
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf186
    la a0, fpr_true
    j .Ltagd187
.Ltagf186:
    la a0, fpr_false
.Ltagd187:
    lw t0, 4(a0)
    beqz t0, .Lelse193
    ld a0, -40(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf188
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf188
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf188
    la a0, fpr_true
    j .Ltagd189
.Ltagf188:
    la a0, fpr_false
.Ltagd189:
    lw t0, 4(a0)
    beqz t0, .Lelse191
    ld a0, -40(s0)
    ld a0, 8(a0)
    ld a0, 16(a0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a0, 16(a0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -80(s0)
    call fpr_fn_sndV
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif192
.Lelse191:
    la a0, .Lstr190
    call fpr_panic
.Lendif192:
    j .Lendif194
.Lelse193:
    la a0, .Lstr190
    call fpr_panic
.Lendif194:
.Lendif196:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# sumV (arity 1)
    .globl fpr_fn_sumV
fpr_fn_sumV:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel206
    call fpr_fuel_exhausted
.Lfuel206:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf198
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf198
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf198
    la a0, fpr_true
    j .Ltagd199
.Ltagf198:
    la a0, fpr_false
.Ltagd199:
    lw t0, 4(a0)
    beqz t0, .Lelse204
    li a0, 1
    j .Lendif205
.Lelse204:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf200
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf200
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf200
    la a0, fpr_true
    j .Ltagd201
.Ltagf200:
    la a0, fpr_false
.Ltagd201:
    lw t0, 4(a0)
    beqz t0, .Lelse202
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    ld a0, 16(a0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -80(s0)
    call fpr_fn_sumV
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2b
    j .Lendif203
.Lelse202:
    la a0, .Lstr165
    call fpr_panic
.Lendif203:
.Lendif205:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# zipV (arity 2)
    .globl fpr_fn_zipV
fpr_fn_zipV:
    addi sp, sp, -144
    sd ra, 136(sp)
    sd s0, 128(sp)
    addi s0, sp, 144
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel219
    call fpr_fuel_exhausted
.Lfuel219:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
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
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf207
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf207
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf207
    la a0, fpr_true
    j .Ltagd208
.Ltagf207:
    la a0, fpr_false
.Ltagd208:
    lw t0, 4(a0)
    beqz t0, .Lelse217
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf209
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf209
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf209
    la a0, fpr_true
    j .Ltagd210
.Ltagf209:
    la a0, fpr_false
.Ltagd210:
    lw t0, 4(a0)
    beqz t0, .Lelse215
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 8(a0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf211
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf211
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf211
    la a0, fpr_true
    j .Ltagd212
.Ltagf211:
    la a0, fpr_false
.Ltagd212:
    lw t0, 4(a0)
    beqz t0, .Lelse213
    ld a0, -56(s0)
    ld a0, 16(a0)
    ld a0, 8(a0)
    sd a0, -80(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    ld a0, 16(a0)
    sd a0, -88(s0)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -80(s0)
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
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -88(s0)
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_fn_zipV
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif214
.Lelse213:
    call fpr_fn_Nil
.Lendif214:
    j .Lendif216
.Lelse215:
    call fpr_fn_Nil
.Lendif216:
    j .Lendif218
.Lelse217:
    call fpr_fn_Nil
.Lendif218:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

    .section .rodata

    .balign 8
    .globl fpr_obj_Actor_x2erecv
fpr_obj_Actor_x2erecv:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2erecv
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2erecvRes
fpr_obj_Actor_x2erecvRes:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2erecvRes
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2eself
fpr_obj_Actor_x2eself:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2eself
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2esend
fpr_obj_Actor_x2esend:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2esend
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2espawn
fpr_obj_Actor_x2espawn:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2espawn
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2espawnOn
fpr_obj_Actor_x2espawnOn:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2espawnOn
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Actor_x2eyield
fpr_obj_Actor_x2eyield:
    .long 9001
    .long 0
    .quad fpr_fn_Actor_x2eyield
    .quad 1
    .quad 0

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
    .globl fpr_obj_Int_x2e_x2a
fpr_obj_Int_x2e_x2a:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x2a
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x2b
fpr_obj_Int_x2e_x2b:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x2b
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x2d
fpr_obj_Int_x2e_x2d:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x2d
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x2f
fpr_obj_Int_x2e_x2f:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x2f
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x3c
fpr_obj_Int_x2e_x3c:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x3c
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x3c_x3d
fpr_obj_Int_x2e_x3c_x3d:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x3c_x3d
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2e_x3d_x3d
fpr_obj_Int_x2e_x3d_x3d:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2e_x3d_x3d
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2eabs
fpr_obj_Int_x2eabs:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2eabs
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2emax
fpr_obj_Int_x2emax:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2emax
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2emin
fpr_obj_Int_x2emin:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2emin
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2emod
fpr_obj_Int_x2emod:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2emod
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Int_x2eneg
fpr_obj_Int_x2eneg:
    .long 9001
    .long 0
    .quad fpr_fn_Int_x2eneg
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Mmio_x2eread
fpr_obj_Mmio_x2eread:
    .long 9001
    .long 0
    .quad fpr_fn_Mmio_x2eread
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Mmio_x2ewrite
fpr_obj_Mmio_x2ewrite:
    .long 9001
    .long 0
    .quad fpr_fn_Mmio_x2ewrite
    .quad 2
    .quad 0

    .balign 8
fpr_obj_Ok:
    .long 9001
    .long 0
    .quad fpr_fn_Ok
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2eat
fpr_obj_SStr_x2eat:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2eat
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2eclear
fpr_obj_SStr_x2eclear:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2eclear
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2efromStr
fpr_obj_SStr_x2efromStr:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2efromStr
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2elen
fpr_obj_SStr_x2elen:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2elen
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2enew
fpr_obj_SStr_x2enew:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2enew
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2epush
fpr_obj_SStr_x2epush:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2epush
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2eput
fpr_obj_SStr_x2eput:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2eput
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_SStr_x2etoStr
fpr_obj_SStr_x2etoStr:
    .long 9001
    .long 0
    .quad fpr_fn_SStr_x2etoStr
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
    .globl fpr_obj_Str_x2e_x2b
fpr_obj_Str_x2e_x2b:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2e_x2b
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Str_x2e_x3d_x3d
fpr_obj_Str_x2e_x3d_x3d:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2e_x3d_x3d
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Str_x2eat
fpr_obj_Str_x2eat:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2eat
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_Str_x2efromCode
fpr_obj_Str_x2efromCode:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2efromCode
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Str_x2elen
fpr_obj_Str_x2elen:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2elen
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_Str_x2eparse
fpr_obj_Str_x2eparse:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2eparse
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
    .globl fpr_obj_VList_x2efilter
fpr_obj_VList_x2efilter:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2efilter
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2efold
fpr_obj_VList_x2efold:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2efold
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2efree
fpr_obj_VList_x2efree:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2efree
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2efromList
fpr_obj_VList_x2efromList:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2efromList
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2eget
fpr_obj_VList_x2eget:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2eget
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2elen
fpr_obj_VList_x2elen:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2elen
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2emap
fpr_obj_VList_x2emap:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2emap
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2enew
fpr_obj_VList_x2enew:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2enew
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2epush
fpr_obj_VList_x2epush:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2epush
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2eset
fpr_obj_VList_x2eset:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2eset
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2esplit
fpr_obj_VList_x2esplit:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2esplit
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_VList_x2etoList
fpr_obj_VList_x2etoList:
    .long 9001
    .long 0
    .quad fpr_fn_VList_x2etoList
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Vector:
    .long 9001
    .long 0
    .quad fpr_fn_Vector
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_closeHandle
fpr_obj_closeHandle:
    .long 9001
    .long 0
    .quad fpr_fn_closeHandle
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_foldRes
fpr_obj_foldRes:
    .long 9001
    .long 0
    .quad fpr_fn_foldRes
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_fromTo
fpr_obj_fromTo:
    .long 9001
    .long 0
    .quad fpr_fn_fromTo
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_fstV
fpr_obj_fstV:
    .long 9001
    .long 0
    .quad fpr_fn_fstV
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_lenRes
fpr_obj_lenRes:
    .long 9001
    .long 0
    .quad fpr_fn_lenRes
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_mapFstV
fpr_obj_mapFstV:
    .long 9001
    .long 0
    .quad fpr_fn_mapFstV
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_mapSndV
fpr_obj_mapSndV:
    .long 9001
    .long 0
    .quad fpr_fn_mapSndV
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_mapV
fpr_obj_mapV:
    .long 9001
    .long 0
    .quad fpr_fn_mapV
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_newHandle
fpr_obj_newHandle:
    .long 9001
    .long 0
    .quad fpr_fn_newHandle
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_par2
fpr_obj_par2:
    .long 9001
    .long 0
    .quad fpr_fn_par2
    .quad 5
    .quad 0

    .balign 8
    .globl fpr_obj_parWorker
fpr_obj_parWorker:
    .long 9001
    .long 0
    .quad fpr_fn_parWorker
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_sndV
fpr_obj_sndV:
    .long 9001
    .long 0
    .quad fpr_fn_sndV
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_sumV
fpr_obj_sumV:
    .long 9001
    .long 0
    .quad fpr_fn_sumV
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_zipV
fpr_obj_zipV:
    .long 9001
    .long 0
    .quad fpr_fn_zipV
    .quad 2
    .quad 0

    .balign 8
.Lstr74:
    .long 9000
    .long 0
    .quad 0

    .balign 8
.Lstr96:
    .long 9000
    .long 0
    .quad 63
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 72, 97, 110, 100
    .byte 108, 101, 34, 32, 91, 80, 86, 97, 114, 32, 34, 118, 34, 93, 93

    .balign 8
.Lstr140:
    .long 9000
    .long 0
    .quad 103
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 84, 117, 112, 32, 91, 80, 86, 97, 114, 32, 34, 97, 34, 44
    .byte 80, 86, 97, 114, 32, 34, 98, 34, 93, 44, 80, 86, 97, 114, 32, 34
    .byte 114, 101, 115, 116, 34, 93, 93

    .balign 8
.Lstr121:
    .long 9000
    .long 0
    .quad 100
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 84, 117, 112, 32, 91, 80, 86, 97, 114, 32, 34, 97, 34, 44
    .byte 80, 87, 105, 108, 100, 93, 44, 80, 86, 97, 114, 32, 34, 114, 101, 115
    .byte 116, 34, 93, 93

    .balign 8
.Lstr190:
    .long 9000
    .long 0
    .quad 100
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 84, 117, 112, 32, 91, 80, 87, 105, 108, 100, 44, 80, 86, 97
    .byte 114, 32, 34, 98, 34, 93, 44, 80, 86, 97, 114, 32, 34, 114, 101, 115
    .byte 116, 34, 93, 93

    .balign 8
.Lstr165:
    .long 9000
    .long 0
    .quad 87
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 120, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 114, 101, 115, 116, 34, 93, 93

    .balign 8
.Lstr174:
    .long 9000
    .long 0
    .quad 60
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 79, 107, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 114, 97, 34, 93, 93

    .balign 8
.Lstr24:
    .long 9000
    .long 0
    .quad 69
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 84, 114, 117, 101
    .byte 34, 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 70, 97, 108, 115, 101
    .byte 34, 32, 91, 93, 93

    .balign 8
.Lstr180:
    .long 9000
    .long 0
    .quad 77
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 84, 117, 112, 32, 91, 80, 86, 97, 114
    .byte 32, 34, 112, 97, 114, 101, 110, 116, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 102, 34, 44, 80, 86, 97, 114, 32, 34, 97, 34, 93, 93

    .balign 8
.Lstr102:
    .long 9000
    .long 0
    .quad 21
    .byte 108, 101, 116, 32, 112, 97, 116, 116, 101, 114, 110, 58, 32, 110, 111, 32
    .byte 109, 97, 116, 99, 104

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

