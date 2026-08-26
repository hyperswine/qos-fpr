# target: rv64
    .option arch, +v
    .text
    .balign 4

    .globl fpr_rvv_enable
fpr_rvv_enable:
    li t0, 0x600
    csrs mstatus, t0
    ret

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
    li t0, 7
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

# wcet: Actor segmax=53 exittail=53 ccalls=1
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

# wcet: Actor.recv segmax=18 exittail=18 ccalls=1
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

# wcet: Actor.recvRes segmax=18 exittail=18 ccalls=1
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

# wcet: Actor.self segmax=18 exittail=18 ccalls=1
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

# wcet: Actor.send segmax=23 exittail=23 ccalls=1
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

# wcet: Actor.spawn segmax=18 exittail=18 ccalls=1
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

# wcet: Actor.spawnOn segmax=23 exittail=23 ccalls=1
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

# wcet: Actor.yield segmax=18 exittail=18 ccalls=1
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

# wcet: Cons segmax=23 exittail=23 ccalls=1
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

# wcet: Err segmax=17 exittail=17 ccalls=1
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

# wcet: False segmax=9 exittail=9 ccalls=0
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
    li t0, 1455177538
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

# wcet: Handle segmax=17 exittail=17 ccalls=1
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
    li t0, 13
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

# wcet: Int segmax=52 exittail=52 ccalls=1
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

# wcet: Int.* segmax=20 exittail=20 ccalls=0
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

# wcet: Int.+ segmax=20 exittail=20 ccalls=0
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

# wcet: Int.- segmax=20 exittail=20 ccalls=0
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

# wcet: Int./ segmax=20 exittail=20 ccalls=0
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

# wcet: Int.< segmax=20 exittail=20 ccalls=0
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

# wcet: Int.<= segmax=20 exittail=20 ccalls=0
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

# wcet: Int.== segmax=20 exittail=20 ccalls=0
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

# wcet: Int.abs segmax=59 exittail=59 ccalls=2
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

# wcet: Int.max segmax=51 exittail=51 ccalls=2
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

# wcet: Int.min segmax=51 exittail=51 ccalls=2
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

# wcet: Int.mod segmax=32 exittail=32 ccalls=2
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

# wcet: Int.neg segmax=18 exittail=18 ccalls=0
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

# wcet: Int.zero segmax=9 exittail=9 ccalls=0
# List (arity 0)
    .globl fpr_fn_List
fpr_fn_List:
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
    la a0, fpr_obj_List_x2e_x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_List_x2e_x2d
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_List_x2edrop
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_List_x2efold
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_List_x2elen
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_List_x2etake
    addi sp, sp, -16
    sd a0, 0(sp)
    call fpr_fn_List_x2ezero
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 64
    call fpr_alloc
    li t0, 97081709
    sw t0, 0(a0)
    li t0, 7
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

# wcet: List segmax=34 exittail=34 ccalls=1
# List.+ (arity 2)
    .globl fpr_fn_List_x2e_x2b
fpr_fn_List_x2e_x2b:
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
    bgtz t1, .Lfuel52
    call fpr_fuel_exhausted
.Lfuel52:
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
    j fpr_fn_listAppend
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.+ segmax=14 exittail=14 ccalls=0
# List.- (arity 2)
    .globl fpr_fn_List_x2e_x2d
fpr_fn_List_x2e_x2d:
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
    bgtz t1, .Lfuel53
    call fpr_fuel_exhausted
.Lfuel53:
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
    j fpr_fn_listSub
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.- segmax=14 exittail=14 ccalls=0
# List.drop (arity 2)
    .globl fpr_fn_List_x2edrop
fpr_fn_List_x2edrop:
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
    bgtz t1, .Lfuel54
    call fpr_fuel_exhausted
.Lfuel54:
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
    j fpr_fn_listDrop
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.drop segmax=14 exittail=14 ccalls=0
# List.fold (arity 3)
    .globl fpr_fn_List_x2efold
fpr_fn_List_x2efold:
    addi sp, sp, -112
    sd ra, 104(sp)
    sd s0, 96(sp)
    addi s0, sp, 112
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel55
    call fpr_fuel_exhausted
.Lfuel55:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -48(s0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -64(s0)
    sd a0, -88(s0)
    ld a0, -72(s0)
    ld a1, -80(s0)
    ld a2, -88(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listFold
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.fold segmax=19 exittail=19 ccalls=0
# List.len (arity 1)
    .globl fpr_fn_List_x2elen
fpr_fn_List_x2elen:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel56
    call fpr_fuel_exhausted
.Lfuel56:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listLen
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.len segmax=10 exittail=10 ccalls=0
# List.take (arity 2)
    .globl fpr_fn_List_x2etake
fpr_fn_List_x2etake:
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
    bgtz t1, .Lfuel57
    call fpr_fuel_exhausted
.Lfuel57:
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
    j fpr_fn_listTake
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.take segmax=14 exittail=14 ccalls=0
# List.zero (arity 0)
    .globl fpr_fn_List_x2ezero
fpr_fn_List_x2ezero:
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
    call fpr_fn_Nil
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: List.zero segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel59
    call fpr_fuel_exhausted
.Lfuel59:
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
    li t0, 2
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

# wcet: Mmio segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel60
    call fpr_fuel_exhausted
.Lfuel60:
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

# wcet: Mmio.read segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel61
    call fpr_fuel_exhausted
.Lfuel61:
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

# wcet: Mmio.write segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel62
    call fpr_fuel_exhausted
.Lfuel62:
    la a0, .Lnul_2_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: Nil segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel63
    call fpr_fuel_exhausted
.Lfuel63:
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

# wcet: Ok segmax=17 exittail=17 ccalls=1
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
    bgtz t1, .Lfuel64
    call fpr_fuel_exhausted
.Lfuel64:
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
    li t0, 9
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

# wcet: SStr segmax=61 exittail=61 ccalls=1
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
    bgtz t1, .Lfuel65
    call fpr_fuel_exhausted
.Lfuel65:
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

# wcet: SStr.at segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel66
    call fpr_fuel_exhausted
.Lfuel66:
    li a0, 257
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: SStr.cap segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel67
    call fpr_fuel_exhausted
.Lfuel67:
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

# wcet: SStr.clear segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel68
    call fpr_fuel_exhausted
.Lfuel68:
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

# wcet: SStr.fromStr segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel69
    call fpr_fuel_exhausted
.Lfuel69:
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

# wcet: SStr.len segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel70
    call fpr_fuel_exhausted
.Lfuel70:
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

# wcet: SStr.new segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel71
    call fpr_fuel_exhausted
.Lfuel71:
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

# wcet: SStr.push segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel72
    call fpr_fuel_exhausted
.Lfuel72:
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

# wcet: SStr.put segmax=28 exittail=28 ccalls=1
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
    bgtz t1, .Lfuel73
    call fpr_fuel_exhausted
.Lfuel73:
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

# wcet: SStr.toStr segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel74
    call fpr_fuel_exhausted
.Lfuel74:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 728642368
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

# wcet: SString segmax=17 exittail=17 ccalls=1
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
    bgtz t1, .Lfuel75
    call fpr_fuel_exhausted
.Lfuel75:
    la a0, fpr_obj_Str_x2e_x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_obj_Str_x2e_x2d
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
    li a0, 72
    call fpr_alloc
    li t0, 239910219
    sw t0, 0(a0)
    li t0, 8
    sw t0, 4(a0)
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

# wcet: Str segmax=37 exittail=37 ccalls=1
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
    bgtz t1, .Lfuel76
    call fpr_fuel_exhausted
.Lfuel76:
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

# wcet: Str.+ segmax=20 exittail=20 ccalls=0
# Str.- (arity 2)
    .globl fpr_fn_Str_x2e_x2d
fpr_fn_Str_x2e_x2d:
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
    bgtz t1, .Lfuel77
    call fpr_fuel_exhausted
.Lfuel77:
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
    j fpr_fn_strSub
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: Str.- segmax=14 exittail=14 ccalls=0
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
    bgtz t1, .Lfuel78
    call fpr_fuel_exhausted
.Lfuel78:
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

# wcet: Str.== segmax=20 exittail=20 ccalls=0
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
    bgtz t1, .Lfuel79
    call fpr_fuel_exhausted
.Lfuel79:
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

# wcet: Str.at segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel80
    call fpr_fuel_exhausted
.Lfuel80:
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

# wcet: Str.fromCode segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel81
    call fpr_fuel_exhausted
.Lfuel81:
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

# wcet: Str.len segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel82
    call fpr_fuel_exhausted
.Lfuel82:
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

# wcet: Str.parse segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel84
    call fpr_fuel_exhausted
.Lfuel84:
    la a0, .Lstr83
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: Str.zero segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel85
    call fpr_fuel_exhausted
.Lfuel85:
    la a0, .Lnul_1_1
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: True segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel86
    call fpr_fuel_exhausted
.Lfuel86:
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

# wcet: Tup2 segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel87
    call fpr_fuel_exhausted
.Lfuel87:
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

# wcet: Tup3 segmax=29 exittail=29 ccalls=1
# Tup4 (arity 4)
fpr_fn_Tup4:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    addi s0, sp, 64
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel88
    call fpr_fuel_exhausted
.Lfuel88:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 40
    call fpr_alloc
    li t0, 10
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
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

# wcet: Tup4 segmax=35 exittail=35 ccalls=1
# Tup5 (arity 5)
fpr_fn_Tup5:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    sd a4, -56(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel89
    call fpr_fuel_exhausted
.Lfuel89:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 48
    call fpr_alloc
    li t0, 11
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
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

# wcet: Tup5 segmax=41 exittail=41 ccalls=1
# Tup6 (arity 6)
fpr_fn_Tup6:
    addi sp, sp, -80
    sd ra, 72(sp)
    sd s0, 64(sp)
    addi s0, sp, 80
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    sd a4, -56(s0)
    sd a5, -64(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel90
    call fpr_fuel_exhausted
.Lfuel90:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
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
    li a0, 56
    call fpr_alloc
    li t0, 12
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
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

# wcet: Tup6 segmax=47 exittail=47 ccalls=1
# Tup7 (arity 7)
fpr_fn_Tup7:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    sd a4, -56(s0)
    sd a5, -64(s0)
    sd a6, -72(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel91
    call fpr_fuel_exhausted
.Lfuel91:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
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
    ld a0, -72(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 64
    call fpr_alloc
    li t0, 13
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

# wcet: Tup7 segmax=53 exittail=53 ccalls=1
# Tup8 (arity 8)
fpr_fn_Tup8:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    sd a4, -56(s0)
    sd a5, -64(s0)
    sd a6, -72(s0)
    sd a7, -80(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel92
    call fpr_fuel_exhausted
.Lfuel92:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -32(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
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
    ld a0, -72(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -80(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 72
    call fpr_alloc
    li t0, 14
    sw t0, 0(a0)
    li t0, 0
    sw t0, 4(a0)
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

# wcet: Tup8 segmax=59 exittail=59 ccalls=1
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
    bgtz t1, .Lfuel93
    call fpr_fuel_exhausted
.Lfuel93:
    la a0, .Lnul_0_0
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: Unit segmax=9 exittail=9 ccalls=0
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
    bgtz t1, .Lfuel94
    call fpr_fuel_exhausted
.Lfuel94:
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
    li t0, 12
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

# wcet: VList segmax=83 exittail=83 ccalls=1
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
    bgtz t1, .Lfuel95
    call fpr_fuel_exhausted
.Lfuel95:
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

# wcet: VList.filter segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel96
    call fpr_fuel_exhausted
.Lfuel96:
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

# wcet: VList.fold segmax=29 exittail=29 ccalls=1
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
    bgtz t1, .Lfuel97
    call fpr_fuel_exhausted
.Lfuel97:
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

# wcet: VList.free segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel98
    call fpr_fuel_exhausted
.Lfuel98:
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

# wcet: VList.fromList segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel99
    call fpr_fuel_exhausted
.Lfuel99:
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

# wcet: VList.get segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel100
    call fpr_fuel_exhausted
.Lfuel100:
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

# wcet: VList.len segmax=19 exittail=19 ccalls=1
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
    bgtz t1, .Lfuel101
    call fpr_fuel_exhausted
.Lfuel101:
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

# wcet: VList.map segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel102
    call fpr_fuel_exhausted
.Lfuel102:
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

# wcet: VList.new segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel103
    call fpr_fuel_exhausted
.Lfuel103:
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

# wcet: VList.push segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel104
    call fpr_fuel_exhausted
.Lfuel104:
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

# wcet: VList.set segmax=28 exittail=28 ccalls=1
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
    bgtz t1, .Lfuel105
    call fpr_fuel_exhausted
.Lfuel105:
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

# wcet: VList.split segmax=23 exittail=23 ccalls=1
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
    bgtz t1, .Lfuel106
    call fpr_fuel_exhausted
.Lfuel106:
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

# wcet: VList.toList segmax=18 exittail=18 ccalls=1
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
    bgtz t1, .Lfuel107
    call fpr_fuel_exhausted
.Lfuel107:
    ld a0, -24(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    li a0, 16
    call fpr_alloc
    li t0, 816269435
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

# wcet: Vector segmax=17 exittail=17 ccalls=1
# ask (arity 3)
    .globl fpr_fn_ask
fpr_fn_ask:
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
    bgtz t1, .Lfuel108
    call fpr_fuel_exhausted
.Lfuel108:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    la a0, fpr_g_send
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
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
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -72(s0)
    la a0, fpr_g_receiveFrom
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
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

# wcet: ask segmax=57 exittail=57 ccalls=3
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
    bgtz t1, .Lfuel114
    call fpr_fuel_exhausted
.Lfuel114:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf109
    lw t0, 0(a0)
    li t1, 1455177538
    bne t0, t1, .Ltagf109
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf109
    la a0, fpr_true
    j .Ltagd110
.Ltagf109:
    la a0, fpr_false
.Ltagd110:
    lw t0, 4(a0)
    beqz t0, .Lelse112
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif113
.Lelse112:
    la a0, .Lstr111
    call fpr_panic
.Lendif113:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: closeHandle segmax=30 exittail=30 ccalls=1
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
    bgtz t1, .Lfuel120
    call fpr_fuel_exhausted
.Lfuel120:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf115
    lw t0, 0(a0)
    li t1, 4
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
    beqz t0, .Lelse118
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif119
.Lelse118:
    la a0, .Lstr117
    call fpr_panic
.Lendif119:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: foldRes segmax=30 exittail=30 ccalls=1
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
    bgtz t1, .Lfuel129
    call fpr_fuel_exhausted
.Lfuel129:
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
    bnez t0, .Ltagf121
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf121
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf121
    la a0, fpr_true
    j .Ltagd122
.Ltagf121:
    la a0, fpr_false
.Ltagd122:
    lw t0, 4(a0)
    beqz t0, .Lelse127
    call fpr_fn_Nil
    j .Lendif128
.Lelse127:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf123
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf123
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf123
    la a0, fpr_true
    j .Ltagd124
.Ltagf123:
    la a0, fpr_false
.Ltagd124:
    lw t0, 4(a0)
    beqz t0, .Lelse125
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
    j .Lendif126
.Lelse125:
    la a0, .Lstr24
    call fpr_panic
.Lendif126:
.Lendif128:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: fromTo segmax=29 exittail=29 ccalls=3
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
    bgtz t1, .Lfuel143
    call fpr_fuel_exhausted
.Lfuel143:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf130
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf130
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf130
    la a0, fpr_true
    j .Ltagd131
.Ltagf130:
    la a0, fpr_false
.Ltagd131:
    lw t0, 4(a0)
    beqz t0, .Lelse141
    call fpr_fn_Nil
    j .Lendif142
.Lelse141:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf132
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf132
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf132
    la a0, fpr_true
    j .Ltagd133
.Ltagf132:
    la a0, fpr_false
.Ltagd133:
    lw t0, 4(a0)
    beqz t0, .Lelse139
    ld a0, -40(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf134
    lw t0, 0(a0)
    li t1, 4
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
    beqz t0, .Lelse137
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
    j .Lendif138
.Lelse137:
    la a0, .Lstr136
    call fpr_panic
.Lendif138:
    j .Lendif140
.Lelse139:
    la a0, .Lstr136
    call fpr_panic
.Lendif140:
.Lendif142:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: fstV segmax=42 exittail=42 ccalls=2
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
    bgtz t1, .Lfuel148
    call fpr_fuel_exhausted
.Lfuel148:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf144
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf144
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf144
    la a0, fpr_true
    j .Ltagd145
.Ltagf144:
    la a0, fpr_false
.Ltagd145:
    lw t0, 4(a0)
    beqz t0, .Lelse146
    ld a0, -40(s0)
    ld a0, 8(a0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    j .Lendif147
.Lelse146:
    la a0, .Lstr117
    call fpr_panic
.Lendif147:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: lenRes segmax=30 exittail=30 ccalls=1
# listAppend (arity 2)
    .globl fpr_fn_listAppend
fpr_fn_listAppend:
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
    bgtz t1, .Lfuel158
    call fpr_fuel_exhausted
.Lfuel158:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf149
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf149
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf149
    la a0, fpr_true
    j .Ltagd150
.Ltagf149:
    la a0, fpr_false
.Ltagd150:
    lw t0, 4(a0)
    beqz t0, .Lelse156
    ld a0, -48(s0)
    j .Lendif157
.Lelse156:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf151
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf151
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf151
    la a0, fpr_true
    j .Ltagd152
.Ltagf151:
    la a0, fpr_false
.Ltagd152:
    lw t0, 4(a0)
    beqz t0, .Lelse154
    ld a0, -56(s0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -64(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    sd a0, -96(s0)
    ld a0, -48(s0)
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_fn_listAppend
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif155
.Lelse154:
    la a0, .Lstr153
    call fpr_panic
.Lendif155:
.Lendif157:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listAppend segmax=50 exittail=50 ccalls=1
# listDrop (arity 2)
    .globl fpr_fn_listDrop
fpr_fn_listDrop:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel167
    call fpr_fuel_exhausted
.Lfuel167:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    li a0, 1
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_prim_fn__x3c_x3d
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf159
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf159
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf159
    la a0, fpr_true
    j .Ltagd160
.Ltagf159:
    la a0, fpr_false
.Ltagd160:
    lw t0, 4(a0)
    beqz t0, .Lelse165
    ld a0, -40(s0)
    j .Lendif166
.Lelse165:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf161
    lw t0, 0(a0)
    li t1, 1
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
    beqz t0, .Lelse163
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -48(s0)
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listDropGo
    j .Lendif164
.Lelse163:
    la a0, .Lstr24
    call fpr_panic
.Lendif164:
.Lendif166:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listDrop segmax=52 exittail=52 ccalls=2
# listDropGo (arity 2)
    .globl fpr_fn_listDropGo
fpr_fn_listDropGo:
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
    bgtz t1, .Lfuel177
    call fpr_fuel_exhausted
.Lfuel177:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf168
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf168
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf168
    la a0, fpr_true
    j .Ltagd169
.Ltagf168:
    la a0, fpr_false
.Ltagd169:
    lw t0, 4(a0)
    beqz t0, .Lelse175
    call fpr_fn_Nil
    j .Lendif176
.Lelse175:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf170
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf170
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf170
    la a0, fpr_true
    j .Ltagd171
.Ltagf170:
    la a0, fpr_false
.Ltagd171:
    lw t0, 4(a0)
    beqz t0, .Lelse173
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -64(s0)
    ld a0, -64(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    li a0, 3
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x2d
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a1, -80(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listDrop
    j .Lendif174
.Lelse173:
    la a0, .Lstr172
    call fpr_panic
.Lendif174:
.Lendif176:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listDropGo segmax=34 exittail=34 ccalls=2
# listFold (arity 3)
    .globl fpr_fn_listFold
fpr_fn_listFold:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel186
    call fpr_fuel_exhausted
.Lfuel186:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -64(s0)
    sd a0, -72(s0)
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf178
    lw t0, 0(a0)
    li t1, 2
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
    beqz t0, .Lelse184
    ld a0, -56(s0)
    j .Lendif185
.Lelse184:
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf180
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf180
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf180
    la a0, fpr_true
    j .Ltagd181
.Ltagf180:
    la a0, fpr_false
.Ltagd181:
    lw t0, 4(a0)
    beqz t0, .Lelse182
    ld a0, -72(s0)
    ld a0, 8(a0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a0, 16(a0)
    sd a0, -88(s0)
    ld a0, -48(s0)
    sd a0, -96(s0)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -80(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -104(s0)
    ld a0, -88(s0)
    sd a0, -112(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld a2, -112(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listFold
    j .Lendif183
.Lelse182:
    la a0, .Lstr153
    call fpr_panic
.Lendif183:
.Lendif185:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listFold segmax=70 exittail=70 ccalls=2
# listLen (arity 1)
    .globl fpr_fn_listLen
fpr_fn_listLen:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel195
    call fpr_fuel_exhausted
.Lfuel195:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf187
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf187
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf187
    la a0, fpr_true
    j .Ltagd188
.Ltagf187:
    la a0, fpr_false
.Ltagd188:
    lw t0, 4(a0)
    beqz t0, .Lelse193
    li a0, 1
    j .Lendif194
.Lelse193:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf189
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf189
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf189
    la a0, fpr_true
    j .Ltagd190
.Ltagf189:
    la a0, fpr_false
.Ltagd190:
    lw t0, 4(a0)
    beqz t0, .Lelse191
    ld a0, -40(s0)
    ld a0, 16(a0)
    sd a0, -48(s0)
    li a0, 3
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -72(s0)
    ld a0, -72(s0)
    call fpr_fn_listLen
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_prim_fn__x2b
    j .Lendif192
.Lelse191:
    la a0, .Lstr172
    call fpr_panic
.Lendif192:
.Lendif194:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listLen segmax=42 exittail=42 ccalls=1
# listPrefEq (arity 2)
    .globl fpr_fn_listPrefEq
fpr_fn_listPrefEq:
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
    bgtz t1, .Lfuel205
    call fpr_fuel_exhausted
.Lfuel205:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf196
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf196
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf196
    la a0, fpr_true
    j .Ltagd197
.Ltagf196:
    la a0, fpr_false
.Ltagd197:
    lw t0, 4(a0)
    beqz t0, .Lelse203
    call fpr_fn_True
    j .Lendif204
.Lelse203:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf198
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf198
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf198
    la a0, fpr_true
    j .Ltagd199
.Ltagf198:
    la a0, fpr_false
.Ltagd199:
    lw t0, 4(a0)
    beqz t0, .Lelse201
    ld a0, -56(s0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -40(s0)
    sd a0, -80(s0)
    ld a0, -64(s0)
    sd a0, -88(s0)
    ld a0, -72(s0)
    sd a0, -96(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld a2, -96(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listPrefEqAt
    j .Lendif202
.Lelse201:
    la a0, .Lstr200
    call fpr_panic
.Lendif202:
.Lendif204:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listPrefEq segmax=34 exittail=34 ccalls=1
# listPrefEqAt (arity 3)
    .globl fpr_fn_listPrefEqAt
fpr_fn_listPrefEqAt:
    addi sp, sp, -144
    sd ra, 136(sp)
    sd s0, 128(sp)
    addi s0, sp, 144
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel215
    call fpr_fuel_exhausted
.Lfuel215:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -48(s0)
    sd a0, -72(s0)
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf206
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf206
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf206
    la a0, fpr_true
    j .Ltagd207
.Ltagf206:
    la a0, fpr_false
.Ltagd207:
    lw t0, 4(a0)
    beqz t0, .Lelse213
    call fpr_fn_False
    j .Lendif214
.Lelse213:
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf208
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf208
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf208
    la a0, fpr_true
    j .Ltagd209
.Ltagf208:
    la a0, fpr_false
.Ltagd209:
    lw t0, 4(a0)
    beqz t0, .Lelse211
    ld a0, -72(s0)
    ld a0, 8(a0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a0, 16(a0)
    sd a0, -88(s0)
    ld a0, -80(s0)
    sd a0, -96(s0)
    ld a0, -56(s0)
    sd a0, -104(s0)
    ld a0, -88(s0)
    sd a0, -112(s0)
    ld a0, -64(s0)
    sd a0, -120(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld a2, -112(s0)
    ld a3, -120(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listPrefEqCmp
    j .Lendif212
.Lelse211:
    la a0, .Lstr210
    call fpr_panic
.Lendif212:
.Lendif214:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listPrefEqAt segmax=37 exittail=37 ccalls=1
# listPrefEqCmp (arity 4)
    .globl fpr_fn_listPrefEqCmp
fpr_fn_listPrefEqCmp:
    addi sp, sp, -128
    sd ra, 120(sp)
    sd s0, 112(sp)
    addi s0, sp, 128
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel224
    call fpr_fuel_exhausted
.Lfuel224:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -56(s0)
    sd a0, -88(s0)
    ld a0, -64(s0)
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x3d_x3d
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf216
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf216
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf216
    la a0, fpr_true
    j .Ltagd217
.Ltagf216:
    la a0, fpr_false
.Ltagd217:
    lw t0, 4(a0)
    beqz t0, .Lelse222
    ld a0, -72(s0)
    sd a0, -96(s0)
    ld a0, -80(s0)
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listPrefEq
    j .Lendif223
.Lelse222:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf218
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf218
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf218
    la a0, fpr_true
    j .Ltagd219
.Ltagf218:
    la a0, fpr_false
.Ltagd219:
    lw t0, 4(a0)
    beqz t0, .Lelse220
    call fpr_fn_False
    j .Lendif221
.Lelse220:
    la a0, .Lstr24
    call fpr_panic
.Lendif221:
.Lendif223:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listPrefEqCmp segmax=40 exittail=40 ccalls=2
# listSub (arity 2)
    .globl fpr_fn_listSub
fpr_fn_listSub:
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
    bgtz t1, .Lfuel233
    call fpr_fuel_exhausted
.Lfuel233:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    call fpr_fn_listLen
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    ld a0, -64(s0)
    call fpr_fn_listLen
    sd a0, -64(s0)
    ld a0, -64(s0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a1, -80(s0)
    call fpr_prim_fn__x3e
    sd a0, -72(s0)
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf225
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf225
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf225
    la a0, fpr_true
    j .Ltagd226
.Ltagf225:
    la a0, fpr_false
.Ltagd226:
    lw t0, 4(a0)
    beqz t0, .Lelse231
    ld a0, -40(s0)
    j .Lendif232
.Lelse231:
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf227
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf227
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf227
    la a0, fpr_true
    j .Ltagd228
.Ltagf227:
    la a0, fpr_false
.Ltagd228:
    lw t0, 4(a0)
    beqz t0, .Lelse229
    ld a0, -40(s0)
    sd a0, -80(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -64(s0)
    sd a0, -104(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld a2, -96(s0)
    ld a3, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listSubGo
    j .Lendif230
.Lelse229:
    la a0, .Lstr24
    call fpr_panic
.Lendif230:
.Lendif232:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listSub segmax=55 exittail=55 ccalls=2
# listSubGo (arity 4)
    .globl fpr_fn_listSubGo
fpr_fn_listSubGo:
    addi sp, sp, -144
    sd ra, 136(sp)
    sd s0, 128(sp)
    addi s0, sp, 144
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel242
    call fpr_fuel_exhausted
.Lfuel242:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_prim_fn__x2d
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_fn_listDrop
    sd a0, -88(s0)
    ld a0, -64(s0)
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_fn_listPrefEq
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf234
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf234
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf234
    la a0, fpr_true
    j .Ltagd235
.Ltagf234:
    la a0, fpr_false
.Ltagd235:
    lw t0, 4(a0)
    beqz t0, .Lelse240
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_prim_fn__x2d
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listTake
    j .Lendif241
.Lelse240:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf236
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf236
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf236
    la a0, fpr_true
    j .Ltagd237
.Ltagf236:
    la a0, fpr_false
.Ltagd237:
    lw t0, 4(a0)
    beqz t0, .Lelse238
    ld a0, -56(s0)
    j .Lendif239
.Lelse238:
    la a0, .Lstr24
    call fpr_panic
.Lendif239:
.Lendif241:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listSubGo segmax=31 exittail=31 ccalls=3
# listTake (arity 2)
    .globl fpr_fn_listTake
fpr_fn_listTake:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel251
    call fpr_fuel_exhausted
.Lfuel251:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    li a0, 1
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    call fpr_prim_fn__x3c_x3d
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf243
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf243
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf243
    la a0, fpr_true
    j .Ltagd244
.Ltagf243:
    la a0, fpr_false
.Ltagd244:
    lw t0, 4(a0)
    beqz t0, .Lelse249
    call fpr_fn_Nil
    j .Lendif250
.Lelse249:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf245
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf245
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf245
    la a0, fpr_true
    j .Ltagd246
.Ltagf245:
    la a0, fpr_false
.Ltagd246:
    lw t0, 4(a0)
    beqz t0, .Lelse247
    ld a0, -40(s0)
    sd a0, -64(s0)
    ld a0, -48(s0)
    sd a0, -72(s0)
    ld a0, -64(s0)
    ld a1, -72(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_listTakeGo
    j .Lendif248
.Lelse247:
    la a0, .Lstr24
    call fpr_panic
.Lendif248:
.Lendif250:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listTake segmax=26 exittail=26 ccalls=2
# listTakeGo (arity 2)
    .globl fpr_fn_listTakeGo
fpr_fn_listTakeGo:
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
    bgtz t1, .Lfuel260
    call fpr_fuel_exhausted
.Lfuel260:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf252
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf252
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf252
    la a0, fpr_true
    j .Ltagd253
.Ltagf252:
    la a0, fpr_false
.Ltagd253:
    lw t0, 4(a0)
    beqz t0, .Lelse258
    call fpr_fn_Nil
    j .Lendif259
.Lelse258:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf254
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf254
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf254
    la a0, fpr_true
    j .Ltagd255
.Ltagf254:
    la a0, fpr_false
.Ltagd255:
    lw t0, 4(a0)
    beqz t0, .Lelse256
    ld a0, -56(s0)
    ld a0, 8(a0)
    sd a0, -64(s0)
    ld a0, -56(s0)
    ld a0, 16(a0)
    sd a0, -72(s0)
    ld a0, -64(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    sd a0, -96(s0)
    ld a0, -48(s0)
    sd a0, -112(s0)
    li a0, 3
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_prim_fn__x2d
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_fn_listTake
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_Cons
    j .Lendif257
.Lelse256:
    la a0, .Lstr153
    call fpr_panic
.Lendif257:
.Lendif259:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: listTakeGo segmax=35 exittail=35 ccalls=2
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
    bgtz t1, .Lfuel274
    call fpr_fuel_exhausted
.Lfuel274:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf261
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf261
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf261
    la a0, fpr_true
    j .Ltagd262
.Ltagf261:
    la a0, fpr_false
.Ltagd262:
    lw t0, 4(a0)
    beqz t0, .Lelse272
    call fpr_fn_Nil
    j .Lendif273
.Lelse272:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf263
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf263
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf263
    la a0, fpr_true
    j .Ltagd264
.Ltagf263:
    la a0, fpr_false
.Ltagd264:
    lw t0, 4(a0)
    beqz t0, .Lelse270
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf265
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf265
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf265
    la a0, fpr_true
    j .Ltagd266
.Ltagf265:
    la a0, fpr_false
.Ltagd266:
    lw t0, 4(a0)
    beqz t0, .Lelse268
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
    j .Lendif269
.Lelse268:
    la a0, .Lstr267
    call fpr_panic
.Lendif269:
    j .Lendif271
.Lelse270:
    la a0, .Lstr267
    call fpr_panic
.Lendif271:
.Lendif273:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: mapFstV segmax=76 exittail=76 ccalls=4
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
    bgtz t1, .Lfuel287
    call fpr_fuel_exhausted
.Lfuel287:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf275
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf275
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf275
    la a0, fpr_true
    j .Ltagd276
.Ltagf275:
    la a0, fpr_false
.Ltagd276:
    lw t0, 4(a0)
    beqz t0, .Lelse285
    call fpr_fn_Nil
    j .Lendif286
.Lelse285:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf277
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf277
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf277
    la a0, fpr_true
    j .Ltagd278
.Ltagf277:
    la a0, fpr_false
.Ltagd278:
    lw t0, 4(a0)
    beqz t0, .Lelse283
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf279
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf279
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf279
    la a0, fpr_true
    j .Ltagd280
.Ltagf279:
    la a0, fpr_false
.Ltagd280:
    lw t0, 4(a0)
    beqz t0, .Lelse281
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
    j .Lendif282
.Lelse281:
    la a0, .Lstr267
    call fpr_panic
.Lendif282:
    j .Lendif284
.Lelse283:
    la a0, .Lstr267
    call fpr_panic
.Lendif284:
.Lendif286:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: mapSndV segmax=76 exittail=76 ccalls=4
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
    bgtz t1, .Lfuel297
    call fpr_fuel_exhausted
.Lfuel297:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -48(s0)
    sd a0, -56(s0)
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf288
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf288
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf288
    la a0, fpr_true
    j .Ltagd289
.Ltagf288:
    la a0, fpr_false
.Ltagd289:
    lw t0, 4(a0)
    beqz t0, .Lelse295
    call fpr_fn_Nil
    j .Lendif296
.Lelse295:
    ld a0, -56(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf290
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf290
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf290
    la a0, fpr_true
    j .Ltagd291
.Ltagf290:
    la a0, fpr_false
.Ltagd291:
    lw t0, 4(a0)
    beqz t0, .Lelse293
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
    j .Lendif294
.Lelse293:
    la a0, .Lstr292
    call fpr_panic
.Lendif294:
.Lendif296:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: mapV segmax=39 exittail=39 ccalls=2
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
    bgtz t1, .Lfuel298
    call fpr_fuel_exhausted
.Lfuel298:
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

# wcet: newHandle segmax=10 exittail=10 ccalls=0
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
    bgtz t1, .Lfuel304
    call fpr_fuel_exhausted
.Lfuel304:
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
    bnez t0, .Ltagf299
    lw t0, 0(a0)
    li t1, 3
    bne t0, t1, .Ltagf299
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf299
    la a0, fpr_true
    j .Ltagd300
.Ltagf299:
    la a0, fpr_false
.Ltagd300:
    lw t0, 4(a0)
    beqz t0, .Lelse302
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
    j .Lendif303
.Lelse302:
    la a0, .Lstr301
    call fpr_panic
.Lendif303:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: par2 segmax=142 exittail=142 ccalls=8
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
    bgtz t1, .Lfuel310
    call fpr_fuel_exhausted
.Lfuel310:
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
    bnez t0, .Ltagf305
    lw t0, 0(a0)
    li t1, 5
    bne t0, t1, .Ltagf305
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf305
    la a0, fpr_true
    j .Ltagd306
.Ltagf305:
    la a0, fpr_false
.Ltagd306:
    lw t0, 4(a0)
    beqz t0, .Lelse308
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
    j .Lendif309
.Lelse308:
    la a0, .Lstr307
    call fpr_panic
.Lendif309:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: parWorker segmax=56 exittail=56 ccalls=4
# serve (arity 3)
    .globl fpr_fn_serve
fpr_fn_serve:
    addi sp, sp, -176
    sd ra, 168(sp)
    sd s0, 160(sp)
    addi s0, sp, 176
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel319
    call fpr_fuel_exhausted
.Lfuel319:
    ld a0, -24(s0)
    sd a0, -48(s0)
    ld a0, -32(s0)
    sd a0, -56(s0)
    ld a0, -40(s0)
    sd a0, -64(s0)
    la a0, fpr_g_receive
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -72(s0)
    ld a0, -72(s0)
    sd a0, -80(s0)
    ld a0, -80(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf311
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf311
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf311
    la a0, fpr_true
    j .Ltagd312
.Ltagf311:
    la a0, fpr_false
.Ltagd312:
    lw t0, 4(a0)
    beqz t0, .Lelse317
    ld a0, -80(s0)
    ld a0, 8(a0)
    sd a0, -88(s0)
    ld a0, -80(s0)
    ld a0, 16(a0)
    sd a0, -96(s0)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -96(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -104(s0)
    ld a0, -104(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf313
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf313
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf313
    la a0, fpr_true
    j .Ltagd314
.Ltagf313:
    la a0, fpr_false
.Ltagd314:
    lw t0, 4(a0)
    beqz t0, .Lelse315
    ld a0, -104(s0)
    ld a0, 8(a0)
    sd a0, -112(s0)
    ld a0, -104(s0)
    ld a0, 16(a0)
    sd a0, -120(s0)
    la a0, fpr_g_send
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -88(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -120(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -128(s0)
    la a0, fpr_g_drop
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
    sd a0, -136(s0)
    ld a0, -48(s0)
    sd a0, -144(s0)
    ld a0, -56(s0)
    sd a0, -152(s0)
    ld a0, -112(s0)
    sd a0, -160(s0)
    ld a0, -144(s0)
    ld a1, -152(s0)
    ld a2, -160(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_serve
    j .Lendif316
.Lelse315:
    la a0, .Lstr117
    call fpr_panic
.Lendif316:
    j .Lendif318
.Lelse317:
    la a0, .Lstr117
    call fpr_panic
.Lendif318:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: serve segmax=115 exittail=115 ccalls=6
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
    bgtz t1, .Lfuel333
    call fpr_fuel_exhausted
.Lfuel333:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf320
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf320
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf320
    la a0, fpr_true
    j .Ltagd321
.Ltagf320:
    la a0, fpr_false
.Ltagd321:
    lw t0, 4(a0)
    beqz t0, .Lelse331
    call fpr_fn_Nil
    j .Lendif332
.Lelse331:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf322
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf322
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf322
    la a0, fpr_true
    j .Ltagd323
.Ltagf322:
    la a0, fpr_false
.Ltagd323:
    lw t0, 4(a0)
    beqz t0, .Lelse329
    ld a0, -40(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf324
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf324
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf324
    la a0, fpr_true
    j .Ltagd325
.Ltagf324:
    la a0, fpr_false
.Ltagd325:
    lw t0, 4(a0)
    beqz t0, .Lelse327
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
    j .Lendif328
.Lelse327:
    la a0, .Lstr326
    call fpr_panic
.Lendif328:
    j .Lendif330
.Lelse329:
    la a0, .Lstr326
    call fpr_panic
.Lendif330:
.Lendif332:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: sndV segmax=42 exittail=42 ccalls=2
# strSub (arity 2)
    .globl fpr_fn_strSub
fpr_fn_strSub:
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
    bgtz t1, .Lfuel342
    call fpr_fuel_exhausted
.Lfuel342:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    la a0, fpr_g_strlen
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -40(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -56(s0)
    la a0, fpr_g_strlen
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -48(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -64(s0)
    ld a0, -64(s0)
    sd a0, -72(s0)
    ld a0, -56(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    ld a1, -80(s0)
    call fpr_prim_fn__x3e
    sd a0, -72(s0)
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf334
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf334
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf334
    la a0, fpr_true
    j .Ltagd335
.Ltagf334:
    la a0, fpr_false
.Ltagd335:
    lw t0, 4(a0)
    beqz t0, .Lelse340
    ld a0, -40(s0)
    j .Lendif341
.Lelse340:
    ld a0, -72(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf336
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf336
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf336
    la a0, fpr_true
    j .Ltagd337
.Ltagf336:
    la a0, fpr_false
.Ltagd337:
    lw t0, 4(a0)
    beqz t0, .Lelse338
    ld a0, -40(s0)
    sd a0, -80(s0)
    ld a0, -48(s0)
    sd a0, -88(s0)
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -64(s0)
    sd a0, -104(s0)
    ld a0, -80(s0)
    ld a1, -88(s0)
    ld a2, -96(s0)
    ld a3, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strSubGo
    j .Lendif339
.Lelse338:
    la a0, .Lstr24
    call fpr_panic
.Lendif339:
.Lendif341:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strSub segmax=82 exittail=82 ccalls=4
# strSubGo (arity 4)
    .globl fpr_fn_strSubGo
fpr_fn_strSubGo:
    addi sp, sp, -144
    sd ra, 136(sp)
    sd s0, 128(sp)
    addi s0, sp, 144
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel351
    call fpr_fuel_exhausted
.Lfuel351:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -56(s0)
    sd a0, -88(s0)
    ld a0, -64(s0)
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_prim_fn__x2d
    sd a0, -104(s0)
    li a0, 3
    sd a0, -112(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    ld a2, -104(s0)
    ld a3, -112(s0)
    call fpr_fn_strSufEq
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf343
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf343
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf343
    la a0, fpr_true
    j .Ltagd344
.Ltagf343:
    la a0, fpr_false
.Ltagd344:
    lw t0, 4(a0)
    beqz t0, .Lelse349
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -120(s0)
    ld a0, -112(s0)
    ld a1, -120(s0)
    call fpr_prim_fn__x2d
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strTake
    j .Lendif350
.Lelse349:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf345
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf345
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf345
    la a0, fpr_true
    j .Ltagd346
.Ltagf345:
    la a0, fpr_false
.Ltagd346:
    lw t0, 4(a0)
    beqz t0, .Lelse347
    ld a0, -56(s0)
    j .Lendif348
.Lelse347:
    la a0, .Lstr24
    call fpr_panic
.Lendif348:
.Lendif350:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strSubGo segmax=31 exittail=31 ccalls=3
# strSufEq (arity 4)
    .globl fpr_fn_strSufEq
fpr_fn_strSufEq:
    addi sp, sp, -144
    sd ra, 136(sp)
    sd s0, 128(sp)
    addi s0, sp, 144
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel360
    call fpr_fuel_exhausted
.Lfuel360:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -80(s0)
    sd a0, -88(s0)
    la a0, fpr_g_strlen
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
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x3e
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf352
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf352
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf352
    la a0, fpr_true
    j .Ltagd353
.Ltagf352:
    la a0, fpr_false
.Ltagd353:
    lw t0, 4(a0)
    beqz t0, .Lelse358
    call fpr_fn_True
    j .Lendif359
.Lelse358:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf354
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf354
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf354
    la a0, fpr_true
    j .Ltagd355
.Ltagf354:
    la a0, fpr_false
.Ltagd355:
    lw t0, 4(a0)
    beqz t0, .Lelse356
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -64(s0)
    sd a0, -104(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -120(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld a2, -112(s0)
    ld a3, -120(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strSufEqAt
    j .Lendif357
.Lelse356:
    la a0, .Lstr24
    call fpr_panic
.Lendif357:
.Lendif359:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strSufEq segmax=40 exittail=40 ccalls=3
# strSufEqAt (arity 4)
    .globl fpr_fn_strSufEqAt
fpr_fn_strSufEqAt:
    addi sp, sp, -160
    sd ra, 152(sp)
    sd s0, 144(sp)
    addi s0, sp, 160
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel369
    call fpr_fuel_exhausted
.Lfuel369:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    la a0, fpr_g_charAt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -72(s0)
    sd a0, -96(s0)
    ld a0, -80(s0)
    sd a0, -104(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    call fpr_prim_fn__x2b
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -88(s0)
    la a0, fpr_g_charAt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -64(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -80(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x3d_x3d
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf361
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf361
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf361
    la a0, fpr_true
    j .Ltagd362
.Ltagf361:
    la a0, fpr_false
.Ltagd362:
    lw t0, 4(a0)
    beqz t0, .Lelse367
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -64(s0)
    sd a0, -104(s0)
    ld a0, -72(s0)
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -128(s0)
    li a0, 3
    sd a0, -136(s0)
    ld a0, -128(s0)
    ld a1, -136(s0)
    call fpr_prim_fn__x2b
    sd a0, -120(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld a2, -112(s0)
    ld a3, -120(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strSufEq
    j .Lendif368
.Lelse367:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf363
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf363
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf363
    la a0, fpr_true
    j .Ltagd364
.Ltagf363:
    la a0, fpr_false
.Ltagd364:
    lw t0, 4(a0)
    beqz t0, .Lelse365
    call fpr_fn_False
    j .Lendif366
.Lelse365:
    la a0, .Lstr24
    call fpr_panic
.Lendif366:
.Lendif368:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strSufEqAt segmax=84 exittail=84 ccalls=6
# strTake (arity 2)
    .globl fpr_fn_strTake
fpr_fn_strTake:
    addi sp, sp, -96
    sd ra, 88(sp)
    sd s0, 80(sp)
    addi s0, sp, 96
    sd a0, -24(s0)
    sd a1, -32(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel370
    call fpr_fuel_exhausted
.Lfuel370:
    ld a0, -24(s0)
    sd a0, -40(s0)
    ld a0, -32(s0)
    sd a0, -48(s0)
    ld a0, -40(s0)
    sd a0, -56(s0)
    ld a0, -48(s0)
    sd a0, -64(s0)
    li a0, 3
    sd a0, -72(s0)
    la a0, .Lstr83
    sd a0, -80(s0)
    ld a0, -56(s0)
    ld a1, -64(s0)
    ld a2, -72(s0)
    ld a3, -80(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strTakeGo
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strTake segmax=20 exittail=20 ccalls=0
# strTakeGo (arity 4)
    .globl fpr_fn_strTakeGo
fpr_fn_strTakeGo:
    addi sp, sp, -160
    sd ra, 152(sp)
    sd s0, 144(sp)
    addi s0, sp, 160
    sd a0, -24(s0)
    sd a1, -32(s0)
    sd a2, -40(s0)
    sd a3, -48(s0)
    mv t0, tp
    ld t1, 0(t0)
    addi t1, t1, -1
    sd t1, 0(t0)
    bgtz t1, .Lfuel379
    call fpr_fuel_exhausted
.Lfuel379:
    ld a0, -24(s0)
    sd a0, -56(s0)
    ld a0, -32(s0)
    sd a0, -64(s0)
    ld a0, -40(s0)
    sd a0, -72(s0)
    ld a0, -48(s0)
    sd a0, -80(s0)
    ld a0, -72(s0)
    sd a0, -88(s0)
    ld a0, -64(s0)
    sd a0, -96(s0)
    ld a0, -88(s0)
    ld a1, -96(s0)
    call fpr_prim_fn__x3e
    sd a0, -88(s0)
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf371
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf371
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf371
    la a0, fpr_true
    j .Ltagd372
.Ltagf371:
    la a0, fpr_false
.Ltagd372:
    lw t0, 4(a0)
    beqz t0, .Lelse377
    ld a0, -80(s0)
    j .Lendif378
.Lelse377:
    ld a0, -88(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf373
    lw t0, 0(a0)
    li t1, 1
    bne t0, t1, .Ltagf373
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf373
    la a0, fpr_true
    j .Ltagd374
.Ltagf373:
    la a0, fpr_false
.Ltagd374:
    lw t0, 4(a0)
    beqz t0, .Lelse375
    ld a0, -56(s0)
    sd a0, -96(s0)
    ld a0, -64(s0)
    sd a0, -104(s0)
    ld a0, -72(s0)
    sd a0, -120(s0)
    li a0, 3
    sd a0, -128(s0)
    ld a0, -120(s0)
    ld a1, -128(s0)
    call fpr_prim_fn__x2b
    sd a0, -112(s0)
    ld a0, -80(s0)
    sd a0, -128(s0)
    la a0, fpr_g_chr
    addi sp, sp, -16
    sd a0, 0(sp)
    la a0, fpr_g_charAt
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -56(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    ld a0, -72(s0)
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 2
    ld a0, 32(sp)
    call fpr_applyN
    addi sp, sp, 48
    addi sp, sp, -16
    sd a0, 0(sp)
    mv a2, sp
    li a1, 1
    ld a0, 16(sp)
    call fpr_applyN
    addi sp, sp, 32
    sd a0, -136(s0)
    ld a0, -128(s0)
    ld a1, -136(s0)
    call fpr_prim_fn_strcat
    sd a0, -120(s0)
    ld a0, -96(s0)
    ld a1, -104(s0)
    ld a2, -112(s0)
    ld a3, -120(s0)
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    j fpr_fn_strTakeGo
    j .Lendif376
.Lelse375:
    la a0, .Lstr24
    call fpr_panic
.Lendif376:
.Lendif378:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: strTakeGo segmax=97 exittail=97 ccalls=6
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
    bgtz t1, .Lfuel388
    call fpr_fuel_exhausted
.Lfuel388:
    ld a0, -24(s0)
    sd a0, -32(s0)
    ld a0, -32(s0)
    sd a0, -40(s0)
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf380
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf380
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf380
    la a0, fpr_true
    j .Ltagd381
.Ltagf380:
    la a0, fpr_false
.Ltagd381:
    lw t0, 4(a0)
    beqz t0, .Lelse386
    li a0, 1
    j .Lendif387
.Lelse386:
    ld a0, -40(s0)
    andi t0, a0, 1
    bnez t0, .Ltagf382
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf382
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf382
    la a0, fpr_true
    j .Ltagd383
.Ltagf382:
    la a0, fpr_false
.Ltagd383:
    lw t0, 4(a0)
    beqz t0, .Lelse384
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
    j .Lendif385
.Lelse384:
    la a0, .Lstr292
    call fpr_panic
.Lendif385:
.Lendif387:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: sumV segmax=45 exittail=45 ccalls=1
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
    bgtz t1, .Lfuel401
    call fpr_fuel_exhausted
.Lfuel401:
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
    bnez t0, .Ltagf389
    lw t0, 0(a0)
    li t1, 4
    bne t0, t1, .Ltagf389
    lw t0, 4(a0)
    li t1, 0
    bne t0, t1, .Ltagf389
    la a0, fpr_true
    j .Ltagd390
.Ltagf389:
    la a0, fpr_false
.Ltagd390:
    lw t0, 4(a0)
    beqz t0, .Lelse399
    ld a0, -56(s0)
    ld a0, 8(a0)
    andi t0, a0, 1
    bnez t0, .Ltagf391
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf391
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf391
    la a0, fpr_true
    j .Ltagd392
.Ltagf391:
    la a0, fpr_false
.Ltagd392:
    lw t0, 4(a0)
    beqz t0, .Lelse397
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
    bnez t0, .Ltagf393
    lw t0, 0(a0)
    li t1, 2
    bne t0, t1, .Ltagf393
    lw t0, 4(a0)
    li t1, 1
    bne t0, t1, .Ltagf393
    la a0, fpr_true
    j .Ltagd394
.Ltagf393:
    la a0, fpr_false
.Ltagd394:
    lw t0, 4(a0)
    beqz t0, .Lelse395
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
    j .Lendif396
.Lelse395:
    call fpr_fn_Nil
.Lendif396:
    j .Lendif398
.Lelse397:
    call fpr_fn_Nil
.Lendif398:
    j .Lendif400
.Lelse399:
    call fpr_fn_Nil
.Lendif400:
    ld ra, -8(s0)
    mv t0, s0
    ld s0, -16(s0)
    mv sp, t0
    ret

# wcet: zipV segmax=108 exittail=108 ccalls=2
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
    .globl fpr_obj_List_x2e_x2b
fpr_obj_List_x2e_x2b:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2e_x2b
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_List_x2e_x2d
fpr_obj_List_x2e_x2d:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2e_x2d
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_List_x2edrop
fpr_obj_List_x2edrop:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2edrop
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_List_x2efold
fpr_obj_List_x2efold:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2efold
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_List_x2elen
fpr_obj_List_x2elen:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2elen
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_List_x2etake
fpr_obj_List_x2etake:
    .long 9001
    .long 0
    .quad fpr_fn_List_x2etake
    .quad 2
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
    .globl fpr_obj_Str_x2e_x2d
fpr_obj_Str_x2e_x2d:
    .long 9001
    .long 0
    .quad fpr_fn_Str_x2e_x2d
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
fpr_obj_Tup4:
    .long 9001
    .long 0
    .quad fpr_fn_Tup4
    .quad 4
    .quad 0

    .balign 8
fpr_obj_Tup5:
    .long 9001
    .long 0
    .quad fpr_fn_Tup5
    .quad 5
    .quad 0

    .balign 8
fpr_obj_Tup6:
    .long 9001
    .long 0
    .quad fpr_fn_Tup6
    .quad 6
    .quad 0

    .balign 8
fpr_obj_Tup7:
    .long 9001
    .long 0
    .quad fpr_fn_Tup7
    .quad 7
    .quad 0

    .balign 8
fpr_obj_Tup8:
    .long 9001
    .long 0
    .quad fpr_fn_Tup8
    .quad 8
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
    .globl fpr_obj_ask
fpr_obj_ask:
    .long 9001
    .long 0
    .quad fpr_fn_ask
    .quad 3
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
    .globl fpr_obj_listAppend
fpr_obj_listAppend:
    .long 9001
    .long 0
    .quad fpr_fn_listAppend
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listDrop
fpr_obj_listDrop:
    .long 9001
    .long 0
    .quad fpr_fn_listDrop
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listDropGo
fpr_obj_listDropGo:
    .long 9001
    .long 0
    .quad fpr_fn_listDropGo
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listFold
fpr_obj_listFold:
    .long 9001
    .long 0
    .quad fpr_fn_listFold
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_listLen
fpr_obj_listLen:
    .long 9001
    .long 0
    .quad fpr_fn_listLen
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_listPrefEq
fpr_obj_listPrefEq:
    .long 9001
    .long 0
    .quad fpr_fn_listPrefEq
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listPrefEqAt
fpr_obj_listPrefEqAt:
    .long 9001
    .long 0
    .quad fpr_fn_listPrefEqAt
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_listPrefEqCmp
fpr_obj_listPrefEqCmp:
    .long 9001
    .long 0
    .quad fpr_fn_listPrefEqCmp
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_listSub
fpr_obj_listSub:
    .long 9001
    .long 0
    .quad fpr_fn_listSub
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listSubGo
fpr_obj_listSubGo:
    .long 9001
    .long 0
    .quad fpr_fn_listSubGo
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_listTake
fpr_obj_listTake:
    .long 9001
    .long 0
    .quad fpr_fn_listTake
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_listTakeGo
fpr_obj_listTakeGo:
    .long 9001
    .long 0
    .quad fpr_fn_listTakeGo
    .quad 2
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
    .globl fpr_obj_serve
fpr_obj_serve:
    .long 9001
    .long 0
    .quad fpr_fn_serve
    .quad 3
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
    .globl fpr_obj_strSub
fpr_obj_strSub:
    .long 9001
    .long 0
    .quad fpr_fn_strSub
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_strSubGo
fpr_obj_strSubGo:
    .long 9001
    .long 0
    .quad fpr_fn_strSubGo
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_strSufEq
fpr_obj_strSufEq:
    .long 9001
    .long 0
    .quad fpr_fn_strSufEq
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_strSufEqAt
fpr_obj_strSufEqAt:
    .long 9001
    .long 0
    .quad fpr_fn_strSufEqAt
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_strTake
fpr_obj_strTake:
    .long 9001
    .long 0
    .quad fpr_fn_strTake
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_strTakeGo
fpr_obj_strTakeGo:
    .long 9001
    .long 0
    .quad fpr_fn_strTakeGo
    .quad 4
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
.Lstr83:
    .long 9000
    .long 0
    .quad 0

    .balign 8
.Lstr111:
    .long 9000
    .long 0
    .quad 63
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 72, 97, 110, 100
    .byte 108, 101, 34, 32, 91, 80, 86, 97, 114, 32, 34, 118, 34, 93, 93

    .balign 8
.Lstr267:
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
.Lstr136:
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
.Lstr326:
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
.Lstr210:
    .long 9000
    .long 0
    .quad 85
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 120, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 97, 114, 34, 93, 93

    .balign 8
.Lstr153:
    .long 9000
    .long 0
    .quad 84
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 120, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 114, 34, 93, 93

    .balign 8
.Lstr292:
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
.Lstr200:
    .long 9000
    .long 0
    .quad 85
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 121, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 98, 114, 34, 93, 93

    .balign 8
.Lstr172:
    .long 9000
    .long 0
    .quad 81
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 87, 105, 108, 100, 44, 80, 86, 97, 114, 32, 34, 114, 34, 93
    .byte 93

    .balign 8
.Lstr301:
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
.Lstr307:
    .long 9000
    .long 0
    .quad 77
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 84, 117, 112, 32, 91, 80, 86, 97, 114
    .byte 32, 34, 112, 97, 114, 101, 110, 116, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 102, 34, 44, 80, 86, 97, 114, 32, 34, 97, 34, 93, 93

    .balign 8
.Lstr117:
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

