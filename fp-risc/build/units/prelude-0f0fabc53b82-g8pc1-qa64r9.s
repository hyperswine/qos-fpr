# target: qa64 (lowered from the rv64 emission; QOS Portable single-hart globals)
    .text
    .balign 4

# Actor (arity 0)
    .globl fpr_fn_Actor
fpr_fn_Actor:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel0
    bl fpr_fuel_exhausted
.Lfuel0:
    adrp x0, fpr_obj_Actor_x2erecv
    add x0, x0, :lo12:fpr_obj_Actor_x2erecv
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2erecvRes
    add x0, x0, :lo12:fpr_obj_Actor_x2erecvRes
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2eself
    add x0, x0, :lo12:fpr_obj_Actor_x2eself
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2esend
    add x0, x0, :lo12:fpr_obj_Actor_x2esend
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2espawn
    add x0, x0, :lo12:fpr_obj_Actor_x2espawn
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2espawnOn
    add x0, x0, :lo12:fpr_obj_Actor_x2espawnOn
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Actor_x2eyield
    add x0, x0, :lo12:fpr_obj_Actor_x2eyield
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #64
    bl fpr_alloc
    movz x9, #63263
    movk x9, #272, lsl #16
    stur w9, [x0, #0]
    mov x9, #7
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor segmax=53 exittail=53 ccalls=1
# Actor.recv (arity 1)
    .globl fpr_fn_Actor_x2erecv
fpr_fn_Actor_x2erecv:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel1
    bl fpr_fuel_exhausted
.Lfuel1:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_receive
    add x0, x0, :lo12:fpr_g_receive
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.recv segmax=18 exittail=18 ccalls=1
# Actor.recvRes (arity 1)
    .globl fpr_fn_Actor_x2erecvRes
fpr_fn_Actor_x2erecvRes:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel2
    bl fpr_fuel_exhausted
.Lfuel2:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_receiveRes
    add x0, x0, :lo12:fpr_g_receiveRes
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.recvRes segmax=18 exittail=18 ccalls=1
# Actor.self (arity 1)
    .globl fpr_fn_Actor_x2eself
fpr_fn_Actor_x2eself:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel3
    bl fpr_fuel_exhausted
.Lfuel3:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_myself
    add x0, x0, :lo12:fpr_g_myself
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.self segmax=18 exittail=18 ccalls=1
# Actor.send (arity 2)
    .globl fpr_fn_Actor_x2esend
fpr_fn_Actor_x2esend:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel4
    bl fpr_fuel_exhausted
.Lfuel4:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.send segmax=23 exittail=23 ccalls=1
# Actor.spawn (arity 1)
    .globl fpr_fn_Actor_x2espawn
fpr_fn_Actor_x2espawn:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel5
    bl fpr_fuel_exhausted
.Lfuel5:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_spawn
    add x0, x0, :lo12:fpr_g_spawn
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.spawn segmax=18 exittail=18 ccalls=1
# Actor.spawnOn (arity 2)
    .globl fpr_fn_Actor_x2espawnOn
fpr_fn_Actor_x2espawnOn:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel6
    bl fpr_fuel_exhausted
.Lfuel6:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_spawnOn
    add x0, x0, :lo12:fpr_g_spawnOn
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.spawnOn segmax=23 exittail=23 ccalls=1
# Actor.yield (arity 1)
    .globl fpr_fn_Actor_x2eyield
fpr_fn_Actor_x2eyield:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel7
    bl fpr_fuel_exhausted
.Lfuel7:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_yield
    add x0, x0, :lo12:fpr_g_yield
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Actor.yield segmax=18 exittail=18 ccalls=1
# Cons (arity 2)
fpr_fn_Cons:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel8
    bl fpr_fuel_exhausted
.Lfuel8:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #2
    stur w9, [x0, #0]
    mov x9, #1
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Cons segmax=23 exittail=23 ccalls=1
# Ent (arity 5)
fpr_fn_Ent:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel9
    bl fpr_fuel_exhausted
.Lfuel9:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #48
    bl fpr_alloc
    movz x9, #7588
    movk x9, #20162, lsl #16
    stur w9, [x0, #0]
    mov x9, #1
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Ent segmax=41 exittail=41 ccalls=1
# Err (arity 1)
fpr_fn_Err:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel10
    bl fpr_fuel_exhausted
.Lfuel10:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    mov x9, #3
    stur w9, [x0, #0]
    mov x9, #1
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Err segmax=17 exittail=17 ccalls=1
# False (arity 0)
fpr_fn_False:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel11
    bl fpr_fuel_exhausted
.Lfuel11:
    adrp x0, .Lnul_1_0
    add x0, x0, :lo12:.Lnul_1_0
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: False segmax=9 exittail=9 ccalls=0
# Frame (arity 3)
fpr_fn_Frame:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel12
    bl fpr_fuel_exhausted
.Lfuel12:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #32
    bl fpr_alloc
    movz x9, #40042
    movk x9, #14167, lsl #16
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Frame segmax=29 exittail=29 ccalls=1
# Handle (arity 1)
fpr_fn_Handle:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel13
    bl fpr_fuel_exhausted
.Lfuel13:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #16194
    movk x9, #22204, lsl #16
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Handle segmax=17 exittail=17 ccalls=1
# Int (arity 0)
    .globl fpr_fn_Int
fpr_fn_Int:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel14
    bl fpr_fuel_exhausted
.Lfuel14:
    adrp x0, fpr_obj_Int_x2e_x2a
    add x0, x0, :lo12:fpr_obj_Int_x2e_x2a
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x2b
    add x0, x0, :lo12:fpr_obj_Int_x2e_x2b
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x2d
    add x0, x0, :lo12:fpr_obj_Int_x2e_x2d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x2f
    add x0, x0, :lo12:fpr_obj_Int_x2e_x2f
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x3c
    add x0, x0, :lo12:fpr_obj_Int_x2e_x3c
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x3c_x3d
    add x0, x0, :lo12:fpr_obj_Int_x2e_x3c_x3d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2e_x3d_x3d
    add x0, x0, :lo12:fpr_obj_Int_x2e_x3d_x3d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2eabs
    add x0, x0, :lo12:fpr_obj_Int_x2eabs
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2emax
    add x0, x0, :lo12:fpr_obj_Int_x2emax
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2emin
    add x0, x0, :lo12:fpr_obj_Int_x2emin
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2emod
    add x0, x0, :lo12:fpr_obj_Int_x2emod
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Int_x2eneg
    add x0, x0, :lo12:fpr_obj_Int_x2eneg
    sub sp, sp, #16
    stur x0, [sp, #0]
    bl fpr_fn_Int_x2ezero
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #112
    bl fpr_alloc
    movz x9, #41433
    movk x9, #3692, lsl #16
    stur w9, [x0, #0]
    mov x9, #13
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #104]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #96]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #88]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #80]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #72]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #64]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int segmax=52 exittail=52 ccalls=1
# Int.* (arity 2)
    .globl fpr_fn_Int_x2e_x2a
fpr_fn_Int_x2e_x2a:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel15
    bl fpr_fuel_exhausted
.Lfuel15:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2a
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.* segmax=20 exittail=20 ccalls=0
# Int.+ (arity 2)
    .globl fpr_fn_Int_x2e_x2b
fpr_fn_Int_x2e_x2b:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel16
    bl fpr_fuel_exhausted
.Lfuel16:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2b
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.+ segmax=20 exittail=20 ccalls=0
# Int.- (arity 2)
    .globl fpr_fn_Int_x2e_x2d
fpr_fn_Int_x2e_x2d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel17
    bl fpr_fuel_exhausted
.Lfuel17:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.- segmax=20 exittail=20 ccalls=0
# Int./ (arity 2)
    .globl fpr_fn_Int_x2e_x2f
fpr_fn_Int_x2e_x2f:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel18
    bl fpr_fuel_exhausted
.Lfuel18:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2f
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int./ segmax=20 exittail=20 ccalls=0
# Int.< (arity 2)
    .globl fpr_fn_Int_x2e_x3c
fpr_fn_Int_x2e_x3c:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel19
    bl fpr_fuel_exhausted
.Lfuel19:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x3c
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.< segmax=20 exittail=20 ccalls=0
# Int.<= (arity 2)
    .globl fpr_fn_Int_x2e_x3c_x3d
fpr_fn_Int_x2e_x3c_x3d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel20
    bl fpr_fuel_exhausted
.Lfuel20:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x3c_x3d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.<= segmax=20 exittail=20 ccalls=0
# Int.== (arity 2)
    .globl fpr_fn_Int_x2e_x3d_x3d
fpr_fn_Int_x2e_x3d_x3d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel21
    bl fpr_fuel_exhausted
.Lfuel21:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x3d_x3d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.== segmax=20 exittail=20 ccalls=0
# Int.abs (arity 1)
    .globl fpr_fn_Int_x2eabs
fpr_fn_Int_x2eabs:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel31
    bl fpr_fuel_exhausted
.Lfuel31:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    mov x0, #1
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x1, [x29, #-48]
    bl fpr_prim_fn__x3c
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf22
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf22
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf22
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd23
.Ltagf22:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd23:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse29
    mov x0, #1
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    ldur x1, [x29, #-56]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2d
    b .Lendif30
.Lelse29:
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf24
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf24
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf24
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd25
.Ltagf24:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd25:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse27
    ldur x0, [x29, #-32]
    b .Lendif28
.Lelse27:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif28:
.Lendif30:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.abs segmax=59 exittail=59 ccalls=2
# Int.max (arity 2)
    .globl fpr_fn_Int_x2emax
fpr_fn_Int_x2emax:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel40
    bl fpr_fuel_exhausted
.Lfuel40:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf32
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf32
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf32
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd33
.Ltagf32:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd33:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse38
    ldur x0, [x29, #-40]
    b .Lendif39
.Lelse38:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf34
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf34
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf34
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd35
.Ltagf34:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd35:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse36
    ldur x0, [x29, #-48]
    b .Lendif37
.Lelse36:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif37:
.Lendif39:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.max segmax=51 exittail=51 ccalls=2
# Int.min (arity 2)
    .globl fpr_fn_Int_x2emin
fpr_fn_Int_x2emin:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel49
    bl fpr_fuel_exhausted
.Lfuel49:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3c
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf41
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf41
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf41
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd42
.Ltagf41:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd42:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse47
    ldur x0, [x29, #-40]
    b .Lendif48
.Lelse47:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf43
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf43
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf43
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd44
.Ltagf43:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd44:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse45
    ldur x0, [x29, #-48]
    b .Lendif46
.Lelse45:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif46:
.Lendif48:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.min segmax=51 exittail=51 ccalls=2
# Int.mod (arity 2)
    .globl fpr_fn_Int_x2emod
fpr_fn_Int_x2emod:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel50
    bl fpr_fuel_exhausted
.Lfuel50:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_prim_fn__x2f
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_prim_fn__x2a
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.mod segmax=32 exittail=32 ccalls=2
# Int.neg (arity 1)
    .globl fpr_fn_Int_x2eneg
fpr_fn_Int_x2eneg:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel51
    bl fpr_fuel_exhausted
.Lfuel51:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #1
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x1, [x29, #-48]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.neg segmax=18 exittail=18 ccalls=0
# Int.zero (arity 0)
    .globl fpr_fn_Int_x2ezero
fpr_fn_Int_x2ezero:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel52
    bl fpr_fuel_exhausted
.Lfuel52:
    mov x0, #1
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Int.zero segmax=9 exittail=9 ccalls=0
# List (arity 0)
    .globl fpr_fn_List
fpr_fn_List:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel53
    bl fpr_fuel_exhausted
.Lfuel53:
    adrp x0, fpr_obj_List_x2e_x2b
    add x0, x0, :lo12:fpr_obj_List_x2e_x2b
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_List_x2e_x2d
    add x0, x0, :lo12:fpr_obj_List_x2e_x2d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_List_x2edrop
    add x0, x0, :lo12:fpr_obj_List_x2edrop
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_List_x2efold
    add x0, x0, :lo12:fpr_obj_List_x2efold
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_List_x2elen
    add x0, x0, :lo12:fpr_obj_List_x2elen
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_List_x2etake
    add x0, x0, :lo12:fpr_obj_List_x2etake
    sub sp, sp, #16
    stur x0, [sp, #0]
    bl fpr_fn_List_x2ezero
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #64
    bl fpr_alloc
    movz x9, #22893
    movk x9, #1481, lsl #16
    stur w9, [x0, #0]
    mov x9, #7
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List segmax=34 exittail=34 ccalls=1
# List.+ (arity 2)
    .globl fpr_fn_List_x2e_x2b
fpr_fn_List_x2e_x2b:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel54
    bl fpr_fuel_exhausted
.Lfuel54:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listAppend
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.+ segmax=14 exittail=14 ccalls=0
# List.- (arity 2)
    .globl fpr_fn_List_x2e_x2d
fpr_fn_List_x2e_x2d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel55
    bl fpr_fuel_exhausted
.Lfuel55:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listSub
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.- segmax=14 exittail=14 ccalls=0
# List.drop (arity 2)
    .globl fpr_fn_List_x2edrop
fpr_fn_List_x2edrop:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel56
    bl fpr_fuel_exhausted
.Lfuel56:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listDrop
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.drop segmax=14 exittail=14 ccalls=0
# List.fold (arity 3)
    .globl fpr_fn_List_x2efold
fpr_fn_List_x2efold:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel57
    bl fpr_fuel_exhausted
.Lfuel57:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    ldur x2, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listFold
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.fold segmax=19 exittail=19 ccalls=0
# List.len (arity 1)
    .globl fpr_fn_List_x2elen
fpr_fn_List_x2elen:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel58
    bl fpr_fuel_exhausted
.Lfuel58:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listLen
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.len segmax=10 exittail=10 ccalls=0
# List.take (arity 2)
    .globl fpr_fn_List_x2etake
fpr_fn_List_x2etake:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel59
    bl fpr_fuel_exhausted
.Lfuel59:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listTake
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.take segmax=14 exittail=14 ccalls=0
# List.zero (arity 0)
    .globl fpr_fn_List_x2ezero
fpr_fn_List_x2ezero:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel60
    bl fpr_fuel_exhausted
.Lfuel60:
    bl fpr_fn_Nil
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: List.zero segmax=9 exittail=9 ccalls=0
# Mmio (arity 0)
    .globl fpr_fn_Mmio
fpr_fn_Mmio:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel61
    bl fpr_fuel_exhausted
.Lfuel61:
    adrp x0, fpr_obj_Mmio_x2eread
    add x0, x0, :lo12:fpr_obj_Mmio_x2eread
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Mmio_x2ewrite
    add x0, x0, :lo12:fpr_obj_Mmio_x2ewrite
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    movz x9, #41598
    movk x9, #1042, lsl #16
    stur w9, [x0, #0]
    mov x9, #2
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Mmio segmax=23 exittail=23 ccalls=1
# Mmio.read (arity 1)
    .globl fpr_fn_Mmio_x2eread
fpr_fn_Mmio_x2eread:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel62
    bl fpr_fuel_exhausted
.Lfuel62:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_read
    add x0, x0, :lo12:fpr_g_read
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Mmio.read segmax=18 exittail=18 ccalls=1
# Mmio.write (arity 2)
    .globl fpr_fn_Mmio_x2ewrite
fpr_fn_Mmio_x2ewrite:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel63
    bl fpr_fuel_exhausted
.Lfuel63:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_write
    add x0, x0, :lo12:fpr_g_write
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Mmio.write segmax=23 exittail=23 ccalls=1
# Nil (arity 0)
fpr_fn_Nil:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel64
    bl fpr_fuel_exhausted
.Lfuel64:
    adrp x0, .Lnul_2_0
    add x0, x0, :lo12:.Lnul_2_0
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Nil segmax=9 exittail=9 ccalls=0
# Ok (arity 1)
fpr_fn_Ok:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel65
    bl fpr_fuel_exhausted
.Lfuel65:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    mov x9, #3
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Ok segmax=17 exittail=17 ccalls=1
# SStr (arity 0)
    .globl fpr_fn_SStr
fpr_fn_SStr:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel66
    bl fpr_fuel_exhausted
.Lfuel66:
    adrp x0, fpr_obj_SStr_x2eat
    add x0, x0, :lo12:fpr_obj_SStr_x2eat
    sub sp, sp, #16
    stur x0, [sp, #0]
    bl fpr_fn_SStr_x2ecap
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2eclear
    add x0, x0, :lo12:fpr_obj_SStr_x2eclear
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2efromStr
    add x0, x0, :lo12:fpr_obj_SStr_x2efromStr
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2elen
    add x0, x0, :lo12:fpr_obj_SStr_x2elen
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2enew
    add x0, x0, :lo12:fpr_obj_SStr_x2enew
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2epush
    add x0, x0, :lo12:fpr_obj_SStr_x2epush
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2eput
    add x0, x0, :lo12:fpr_obj_SStr_x2eput
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_SStr_x2etoStr
    add x0, x0, :lo12:fpr_obj_SStr_x2etoStr
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #80
    bl fpr_alloc
    movz x9, #19400
    movk x9, #1948, lsl #16
    stur w9, [x0, #0]
    mov x9, #9
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #72]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #64]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr segmax=61 exittail=61 ccalls=1
# SStr.at (arity 2)
    .globl fpr_fn_SStr_x2eat
fpr_fn_SStr_x2eat:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel67
    bl fpr_fuel_exhausted
.Lfuel67:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_sstrAt
    add x0, x0, :lo12:fpr_g_sstrAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.at segmax=23 exittail=23 ccalls=1
# SStr.cap (arity 0)
    .globl fpr_fn_SStr_x2ecap
fpr_fn_SStr_x2ecap:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel68
    bl fpr_fuel_exhausted
.Lfuel68:
    mov x0, #257
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.cap segmax=9 exittail=9 ccalls=0
# SStr.clear (arity 1)
    .globl fpr_fn_SStr_x2eclear
fpr_fn_SStr_x2eclear:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel69
    bl fpr_fuel_exhausted
.Lfuel69:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_sstrClear
    add x0, x0, :lo12:fpr_g_sstrClear
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.clear segmax=18 exittail=18 ccalls=1
# SStr.fromStr (arity 1)
    .globl fpr_fn_SStr_x2efromStr
fpr_fn_SStr_x2efromStr:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel70
    bl fpr_fuel_exhausted
.Lfuel70:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_sstrFromStr
    add x0, x0, :lo12:fpr_g_sstrFromStr
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.fromStr segmax=18 exittail=18 ccalls=1
# SStr.len (arity 1)
    .globl fpr_fn_SStr_x2elen
fpr_fn_SStr_x2elen:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel71
    bl fpr_fuel_exhausted
.Lfuel71:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_sstrLen
    add x0, x0, :lo12:fpr_g_sstrLen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.len segmax=18 exittail=18 ccalls=1
# SStr.new (arity 1)
    .globl fpr_fn_SStr_x2enew
fpr_fn_SStr_x2enew:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel72
    bl fpr_fuel_exhausted
.Lfuel72:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_sstrNew
    add x0, x0, :lo12:fpr_g_sstrNew
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.new segmax=18 exittail=18 ccalls=1
# SStr.push (arity 2)
    .globl fpr_fn_SStr_x2epush
fpr_fn_SStr_x2epush:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel73
    bl fpr_fuel_exhausted
.Lfuel73:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_sstrPush
    add x0, x0, :lo12:fpr_g_sstrPush
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.push segmax=23 exittail=23 ccalls=1
# SStr.put (arity 3)
    .globl fpr_fn_SStr_x2eput
fpr_fn_SStr_x2eput:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel74
    bl fpr_fuel_exhausted
.Lfuel74:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_sstrPut
    add x0, x0, :lo12:fpr_g_sstrPut
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #3
    ldur x0, [sp, #48]
    bl fpr_applyN
    add sp, sp, #64
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.put segmax=28 exittail=28 ccalls=1
# SStr.toStr (arity 1)
    .globl fpr_fn_SStr_x2etoStr
fpr_fn_SStr_x2etoStr:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel75
    bl fpr_fuel_exhausted
.Lfuel75:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_sstrToStr
    add x0, x0, :lo12:fpr_g_sstrToStr
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SStr.toStr segmax=18 exittail=18 ccalls=1
# SString (arity 1)
fpr_fn_SString:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel76
    bl fpr_fuel_exhausted
.Lfuel76:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #13120
    movk x9, #11118, lsl #16
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: SString segmax=17 exittail=17 ccalls=1
# Scene (arity 4)
fpr_fn_Scene:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel77
    bl fpr_fuel_exhausted
.Lfuel77:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #40
    bl fpr_alloc
    movz x9, #7588
    movk x9, #20162, lsl #16
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Scene segmax=35 exittail=35 ccalls=1
# Str (arity 0)
    .globl fpr_fn_Str
fpr_fn_Str:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel78
    bl fpr_fuel_exhausted
.Lfuel78:
    adrp x0, fpr_obj_Str_x2e_x2b
    add x0, x0, :lo12:fpr_obj_Str_x2e_x2b
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2e_x2d
    add x0, x0, :lo12:fpr_obj_Str_x2e_x2d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2e_x3d_x3d
    add x0, x0, :lo12:fpr_obj_Str_x2e_x3d_x3d
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2eat
    add x0, x0, :lo12:fpr_obj_Str_x2eat
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2efromCode
    add x0, x0, :lo12:fpr_obj_Str_x2efromCode
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2elen
    add x0, x0, :lo12:fpr_obj_Str_x2elen
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_Str_x2eparse
    add x0, x0, :lo12:fpr_obj_Str_x2eparse
    sub sp, sp, #16
    stur x0, [sp, #0]
    bl fpr_fn_Str_x2ezero
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #72
    bl fpr_alloc
    movz x9, #48459
    movk x9, #3660, lsl #16
    stur w9, [x0, #0]
    mov x9, #8
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #64]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str segmax=37 exittail=37 ccalls=1
# Str.+ (arity 2)
    .globl fpr_fn_Str_x2e_x2b
fpr_fn_Str_x2e_x2b:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel79
    bl fpr_fuel_exhausted
.Lfuel79:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn_strcat
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.+ segmax=20 exittail=20 ccalls=0
# Str.- (arity 2)
    .globl fpr_fn_Str_x2e_x2d
fpr_fn_Str_x2e_x2d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel80
    bl fpr_fuel_exhausted
.Lfuel80:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strSub
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.- segmax=14 exittail=14 ccalls=0
# Str.== (arity 2)
    .globl fpr_fn_Str_x2e_x3d_x3d
fpr_fn_Str_x2e_x3d_x3d:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel81
    bl fpr_fuel_exhausted
.Lfuel81:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x3d_x3d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.== segmax=20 exittail=20 ccalls=0
# Str.at (arity 2)
    .globl fpr_fn_Str_x2eat
fpr_fn_Str_x2eat:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel82
    bl fpr_fuel_exhausted
.Lfuel82:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_charAt
    add x0, x0, :lo12:fpr_g_charAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.at segmax=23 exittail=23 ccalls=1
# Str.fromCode (arity 1)
    .globl fpr_fn_Str_x2efromCode
fpr_fn_Str_x2efromCode:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel83
    bl fpr_fuel_exhausted
.Lfuel83:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_chr
    add x0, x0, :lo12:fpr_g_chr
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.fromCode segmax=18 exittail=18 ccalls=1
# Str.len (arity 1)
    .globl fpr_fn_Str_x2elen
fpr_fn_Str_x2elen:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel84
    bl fpr_fuel_exhausted
.Lfuel84:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_strlen
    add x0, x0, :lo12:fpr_g_strlen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.len segmax=18 exittail=18 ccalls=1
# Str.parse (arity 1)
    .globl fpr_fn_Str_x2eparse
fpr_fn_Str_x2eparse:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel85
    bl fpr_fuel_exhausted
.Lfuel85:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_parseInt
    add x0, x0, :lo12:fpr_g_parseInt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.parse segmax=18 exittail=18 ccalls=1
# Str.zero (arity 0)
    .globl fpr_fn_Str_x2ezero
fpr_fn_Str_x2ezero:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel87
    bl fpr_fuel_exhausted
.Lfuel87:
    adrp x0, .Lstr86
    add x0, x0, :lo12:.Lstr86
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Str.zero segmax=9 exittail=9 ccalls=0
# True (arity 0)
fpr_fn_True:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel88
    bl fpr_fuel_exhausted
.Lfuel88:
    adrp x0, .Lnul_1_1
    add x0, x0, :lo12:.Lnul_1_1
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: True segmax=9 exittail=9 ccalls=0
# Tup2 (arity 2)
fpr_fn_Tup2:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel89
    bl fpr_fuel_exhausted
.Lfuel89:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup2 segmax=23 exittail=23 ccalls=1
# Tup3 (arity 3)
fpr_fn_Tup3:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel90
    bl fpr_fuel_exhausted
.Lfuel90:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #32
    bl fpr_alloc
    mov x9, #5
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup3 segmax=29 exittail=29 ccalls=1
# Tup4 (arity 4)
fpr_fn_Tup4:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel91
    bl fpr_fuel_exhausted
.Lfuel91:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #40
    bl fpr_alloc
    mov x9, #10
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup4 segmax=35 exittail=35 ccalls=1
# Tup5 (arity 5)
fpr_fn_Tup5:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel92
    bl fpr_fuel_exhausted
.Lfuel92:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #48
    bl fpr_alloc
    mov x9, #11
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup5 segmax=41 exittail=41 ccalls=1
# Tup6 (arity 6)
fpr_fn_Tup6:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    stur x5, [x29, #-64]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel93
    bl fpr_fuel_exhausted
.Lfuel93:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #56
    bl fpr_alloc
    mov x9, #12
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup6 segmax=47 exittail=47 ccalls=1
# Tup7 (arity 7)
fpr_fn_Tup7:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    stur x5, [x29, #-64]
    stur x6, [x29, #-72]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel94
    bl fpr_fuel_exhausted
.Lfuel94:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #64
    bl fpr_alloc
    mov x9, #13
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup7 segmax=53 exittail=53 ccalls=1
# Tup8 (arity 8)
fpr_fn_Tup8:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    stur x5, [x29, #-64]
    stur x6, [x29, #-72]
    stur x7, [x29, #-80]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel95
    bl fpr_fuel_exhausted
.Lfuel95:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #72
    bl fpr_alloc
    mov x9, #14
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #64]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Tup8 segmax=59 exittail=59 ccalls=1
# Unit (arity 0)
fpr_fn_Unit:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel96
    bl fpr_fuel_exhausted
.Lfuel96:
    adrp x0, .Lnul_0_0
    add x0, x0, :lo12:.Lnul_0_0
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Unit segmax=9 exittail=9 ccalls=0
# VList (arity 0)
    .globl fpr_fn_VList
fpr_fn_VList:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel97
    bl fpr_fuel_exhausted
.Lfuel97:
    adrp x0, fpr_obj_VList_x2efilter
    add x0, x0, :lo12:fpr_obj_VList_x2efilter
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2efold
    add x0, x0, :lo12:fpr_obj_VList_x2efold
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2efree
    add x0, x0, :lo12:fpr_obj_VList_x2efree
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2efromList
    add x0, x0, :lo12:fpr_obj_VList_x2efromList
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2eget
    add x0, x0, :lo12:fpr_obj_VList_x2eget
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2elen
    add x0, x0, :lo12:fpr_obj_VList_x2elen
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2emap
    add x0, x0, :lo12:fpr_obj_VList_x2emap
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2enew
    add x0, x0, :lo12:fpr_obj_VList_x2enew
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2epush
    add x0, x0, :lo12:fpr_obj_VList_x2epush
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2eset
    add x0, x0, :lo12:fpr_obj_VList_x2eset
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2esplit
    add x0, x0, :lo12:fpr_obj_VList_x2esplit
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_VList_x2etoList
    add x0, x0, :lo12:fpr_obj_VList_x2etoList
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #104
    bl fpr_alloc
    movz x9, #56654
    movk x9, #1288, lsl #16
    stur w9, [x0, #0]
    mov x9, #12
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #96]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #88]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #80]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #72]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #64]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #56]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #48]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #40]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #32]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList segmax=83 exittail=83 ccalls=1
# VList.filter (arity 2)
    .globl fpr_fn_VList_x2efilter
fpr_fn_VList_x2efilter:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel98
    bl fpr_fuel_exhausted
.Lfuel98:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_Vec_x2efilter
    add x0, x0, :lo12:fpr_g_Vec_x2efilter
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.filter segmax=23 exittail=23 ccalls=1
# VList.fold (arity 3)
    .globl fpr_fn_VList_x2efold
fpr_fn_VList_x2efold:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel99
    bl fpr_fuel_exhausted
.Lfuel99:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_Vec_x2efold
    add x0, x0, :lo12:fpr_g_Vec_x2efold
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #3
    ldur x0, [sp, #48]
    bl fpr_applyN
    add sp, sp, #64
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_foldRes
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.fold segmax=29 exittail=29 ccalls=1
# VList.free (arity 1)
    .globl fpr_fn_VList_x2efree
fpr_fn_VList_x2efree:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel100
    bl fpr_fuel_exhausted
.Lfuel100:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_Vec_x2efree
    add x0, x0, :lo12:fpr_g_Vec_x2efree
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.free segmax=18 exittail=18 ccalls=1
# VList.fromList (arity 1)
    .globl fpr_fn_VList_x2efromList
fpr_fn_VList_x2efromList:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel101
    bl fpr_fuel_exhausted
.Lfuel101:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_Vec_x2efromList
    add x0, x0, :lo12:fpr_g_Vec_x2efromList
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.fromList segmax=18 exittail=18 ccalls=1
# VList.get (arity 2)
    .globl fpr_fn_VList_x2eget
fpr_fn_VList_x2eget:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel102
    bl fpr_fuel_exhausted
.Lfuel102:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_Vec_x2eget
    add x0, x0, :lo12:fpr_g_Vec_x2eget
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.get segmax=23 exittail=23 ccalls=1
# VList.len (arity 1)
    .globl fpr_fn_VList_x2elen
fpr_fn_VList_x2elen:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel103
    bl fpr_fuel_exhausted
.Lfuel103:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_Vec_x2elen
    add x0, x0, :lo12:fpr_g_Vec_x2elen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_lenRes
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.len segmax=19 exittail=19 ccalls=1
# VList.map (arity 2)
    .globl fpr_fn_VList_x2emap
fpr_fn_VList_x2emap:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel104
    bl fpr_fuel_exhausted
.Lfuel104:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_Vec_x2emap
    add x0, x0, :lo12:fpr_g_Vec_x2emap
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.map segmax=23 exittail=23 ccalls=1
# VList.new (arity 1)
    .globl fpr_fn_VList_x2enew
fpr_fn_VList_x2enew:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel105
    bl fpr_fuel_exhausted
.Lfuel105:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_Vec_x2enew
    add x0, x0, :lo12:fpr_g_Vec_x2enew
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.new segmax=18 exittail=18 ccalls=1
# VList.push (arity 2)
    .globl fpr_fn_VList_x2epush
fpr_fn_VList_x2epush:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel106
    bl fpr_fuel_exhausted
.Lfuel106:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_Vec_x2epush
    add x0, x0, :lo12:fpr_g_Vec_x2epush
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.push segmax=23 exittail=23 ccalls=1
# VList.set (arity 3)
    .globl fpr_fn_VList_x2eset
fpr_fn_VList_x2eset:
    sub sp, sp, #80
    stur x30, [sp, #72]
    stur x29, [sp, #64]
    add x29, sp, #80
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel107
    bl fpr_fuel_exhausted
.Lfuel107:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_Vec_x2eset
    add x0, x0, :lo12:fpr_g_Vec_x2eset
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #3
    ldur x0, [sp, #48]
    bl fpr_applyN
    add sp, sp, #64
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.set segmax=28 exittail=28 ccalls=1
# VList.split (arity 2)
    .globl fpr_fn_VList_x2esplit
fpr_fn_VList_x2esplit:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel108
    bl fpr_fuel_exhausted
.Lfuel108:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_Vec_x2esplit
    add x0, x0, :lo12:fpr_g_Vec_x2esplit
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.split segmax=23 exittail=23 ccalls=1
# VList.toList (arity 1)
    .globl fpr_fn_VList_x2etoList
fpr_fn_VList_x2etoList:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel109
    bl fpr_fuel_exhausted
.Lfuel109:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_Vec_x2etoList
    add x0, x0, :lo12:fpr_g_Vec_x2etoList
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: VList.toList segmax=18 exittail=18 ccalls=1
# Vector (arity 1)
fpr_fn_Vector:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel110
    bl fpr_fuel_exhausted
.Lfuel110:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #18555
    movk x9, #12455, lsl #16
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Vector segmax=17 exittail=17 ccalls=1
# ask (arity 3)
    .globl fpr_fn_ask
fpr_fn_ask:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel111
    bl fpr_fuel_exhausted
.Lfuel111:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-72]
    adrp x0, fpr_g_receiveFrom
    add x0, x0, :lo12:fpr_g_receiveFrom
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: ask segmax=57 exittail=57 ccalls=3
# closeHandle (arity 1)
    .globl fpr_fn_closeHandle
fpr_fn_closeHandle:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel117
    bl fpr_fuel_exhausted
.Lfuel117:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf112
    ldursw x9, [x0, #0]
    movz x10, #16194
    movk x10, #22204, lsl #16
    cmp x9, x10
    b.ne .Ltagf112
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf112
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd113
.Ltagf112:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd113:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse115
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    b .Lendif116
.Lelse115:
    adrp x0, .Lstr114
    add x0, x0, :lo12:.Lstr114
    bl fpr_panic
.Lendif116:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: closeHandle segmax=30 exittail=30 ccalls=1
# foldRes (arity 1)
    .globl fpr_fn_foldRes
fpr_fn_foldRes:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel123
    bl fpr_fuel_exhausted
.Lfuel123:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf118
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf118
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf118
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd119
.Ltagf118:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd119:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse121
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    b .Lendif122
.Lelse121:
    adrp x0, .Lstr120
    add x0, x0, :lo12:.Lstr120
    bl fpr_panic
.Lendif122:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: foldRes segmax=30 exittail=30 ccalls=1
# fromTo (arity 2)
    .globl fpr_fn_fromTo
fpr_fn_fromTo:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel132
    bl fpr_fuel_exhausted
.Lfuel132:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf124
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf124
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf124
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd125
.Ltagf124:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd125:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse130
    bl fpr_fn_Nil
    b .Lendif131
.Lelse130:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf126
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf126
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf126
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd127
.Ltagf126:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd127:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse128
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-88]
    mov x0, #3
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_fn_fromTo
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif129
.Lelse128:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif129:
.Lendif131:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: fromTo segmax=29 exittail=29 ccalls=3
# fstV (arity 1)
    .globl fpr_fn_fstV
fpr_fn_fstV:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel146
    bl fpr_fuel_exhausted
.Lfuel146:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf133
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf133
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf133
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd134
.Ltagf133:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd134:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse144
    bl fpr_fn_Nil
    b .Lendif145
.Lelse144:
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf135
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf135
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf135
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd136
.Ltagf135:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd136:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse142
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf137
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf137
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf137
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd138
.Ltagf137:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd138:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse140
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x0, [x0, #16]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    bl fpr_fn_fstV
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif141
.Lelse140:
    adrp x0, .Lstr139
    add x0, x0, :lo12:.Lstr139
    bl fpr_panic
.Lendif141:
    b .Lendif143
.Lelse142:
    adrp x0, .Lstr139
    add x0, x0, :lo12:.Lstr139
    bl fpr_panic
.Lendif143:
.Lendif145:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: fstV segmax=42 exittail=42 ccalls=2
# lenRes (arity 1)
    .globl fpr_fn_lenRes
fpr_fn_lenRes:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel151
    bl fpr_fuel_exhausted
.Lfuel151:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf147
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf147
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf147
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd148
.Ltagf147:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd148:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse149
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    b .Lendif150
.Lelse149:
    adrp x0, .Lstr120
    add x0, x0, :lo12:.Lstr120
    bl fpr_panic
.Lendif150:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: lenRes segmax=30 exittail=30 ccalls=1
# listAppend (arity 2)
    .globl fpr_fn_listAppend
fpr_fn_listAppend:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel161
    bl fpr_fuel_exhausted
.Lfuel161:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf152
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf152
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf152
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd153
.Ltagf152:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd153:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse159
    ldur x0, [x29, #-48]
    b .Lendif160
.Lelse159:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf154
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf154
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf154
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd155
.Ltagf154:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd155:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse157
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_fn_listAppend
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif158
.Lelse157:
    adrp x0, .Lstr156
    add x0, x0, :lo12:.Lstr156
    bl fpr_panic
.Lendif158:
.Lendif160:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listAppend segmax=50 exittail=50 ccalls=1
# listDrop (arity 2)
    .globl fpr_fn_listDrop
fpr_fn_listDrop:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel170
    bl fpr_fuel_exhausted
.Lfuel170:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    mov x0, #1
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3c_x3d
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf162
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf162
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf162
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd163
.Ltagf162:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd163:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse168
    ldur x0, [x29, #-40]
    b .Lendif169
.Lelse168:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf164
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf164
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf164
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd165
.Ltagf164:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd165:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse166
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listDropGo
    b .Lendif167
.Lelse166:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif167:
.Lendif169:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listDrop segmax=52 exittail=52 ccalls=2
# listDropGo (arity 2)
    .globl fpr_fn_listDropGo
fpr_fn_listDropGo:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel180
    bl fpr_fuel_exhausted
.Lfuel180:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf171
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf171
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf171
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd172
.Ltagf171:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd172:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse178
    bl fpr_fn_Nil
    b .Lendif179
.Lelse178:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf173
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf173
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf173
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd174
.Ltagf173:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd174:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse176
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    mov x0, #3
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listDrop
    b .Lendif177
.Lelse176:
    adrp x0, .Lstr175
    add x0, x0, :lo12:.Lstr175
    bl fpr_panic
.Lendif177:
.Lendif179:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listDropGo segmax=34 exittail=34 ccalls=2
# listFold (arity 3)
    .globl fpr_fn_listFold
fpr_fn_listFold:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel189
    bl fpr_fuel_exhausted
.Lfuel189:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf181
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf181
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf181
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd182
.Ltagf181:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd182:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse187
    ldur x0, [x29, #-56]
    b .Lendif188
.Lelse187:
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf183
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf183
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf183
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd184
.Ltagf183:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd184:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse185
    ldur x0, [x29, #-72]
    ldur x0, [x0, #8]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x0, [x0, #16]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listFold
    b .Lendif186
.Lelse185:
    adrp x0, .Lstr156
    add x0, x0, :lo12:.Lstr156
    bl fpr_panic
.Lendif186:
.Lendif188:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listFold segmax=70 exittail=70 ccalls=2
# listLen (arity 1)
    .globl fpr_fn_listLen
fpr_fn_listLen:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel198
    bl fpr_fuel_exhausted
.Lfuel198:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf190
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf190
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf190
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd191
.Ltagf190:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd191:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse196
    mov x0, #1
    b .Lendif197
.Lelse196:
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf192
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf192
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf192
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd193
.Ltagf192:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd193:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse194
    ldur x0, [x29, #-40]
    ldur x0, [x0, #16]
    stur x0, [x29, #-48]
    mov x0, #3
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    bl fpr_fn_listLen
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2b
    b .Lendif195
.Lelse194:
    adrp x0, .Lstr175
    add x0, x0, :lo12:.Lstr175
    bl fpr_panic
.Lendif195:
.Lendif197:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listLen segmax=42 exittail=42 ccalls=1
# listPrefEq (arity 2)
    .globl fpr_fn_listPrefEq
fpr_fn_listPrefEq:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel208
    bl fpr_fuel_exhausted
.Lfuel208:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf199
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf199
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf199
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd200
.Ltagf199:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd200:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse206
    bl fpr_fn_True
    b .Lendif207
.Lelse206:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf201
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf201
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf201
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd202
.Ltagf201:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd202:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse204
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listPrefEqAt
    b .Lendif205
.Lelse204:
    adrp x0, .Lstr203
    add x0, x0, :lo12:.Lstr203
    bl fpr_panic
.Lendif205:
.Lendif207:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listPrefEq segmax=34 exittail=34 ccalls=1
# listPrefEqAt (arity 3)
    .globl fpr_fn_listPrefEqAt
fpr_fn_listPrefEqAt:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel218
    bl fpr_fuel_exhausted
.Lfuel218:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf209
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf209
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf209
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd210
.Ltagf209:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd210:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse216
    bl fpr_fn_False
    b .Lendif217
.Lelse216:
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf211
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf211
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf211
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd212
.Ltagf211:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd212:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse214
    ldur x0, [x29, #-72]
    ldur x0, [x0, #8]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x0, [x0, #16]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x3, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listPrefEqCmp
    b .Lendif215
.Lelse214:
    adrp x0, .Lstr213
    add x0, x0, :lo12:.Lstr213
    bl fpr_panic
.Lendif215:
.Lendif217:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listPrefEqAt segmax=37 exittail=37 ccalls=1
# listPrefEqCmp (arity 4)
    .globl fpr_fn_listPrefEqCmp
fpr_fn_listPrefEqCmp:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel227
    bl fpr_fuel_exhausted
.Lfuel227:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3d_x3d
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf219
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf219
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf219
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd220
.Ltagf219:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd220:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse225
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listPrefEq
    b .Lendif226
.Lelse225:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf221
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf221
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf221
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd222
.Ltagf221:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd222:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse223
    bl fpr_fn_False
    b .Lendif224
.Lelse223:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif224:
.Lendif226:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listPrefEqCmp segmax=40 exittail=40 ccalls=2
# listSub (arity 2)
    .globl fpr_fn_listSub
fpr_fn_listSub:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel236
    bl fpr_fuel_exhausted
.Lfuel236:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    bl fpr_fn_listLen
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    bl fpr_fn_listLen
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf228
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf228
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf228
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd229
.Ltagf228:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd229:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse234
    ldur x0, [x29, #-40]
    b .Lendif235
.Lelse234:
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf230
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf230
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf230
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd231
.Ltagf230:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd231:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse232
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    ldur x3, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listSubGo
    b .Lendif233
.Lelse232:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif233:
.Lendif235:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listSub segmax=55 exittail=55 ccalls=2
# listSubGo (arity 4)
    .globl fpr_fn_listSubGo
fpr_fn_listSubGo:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel245
    bl fpr_fuel_exhausted
.Lfuel245:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_fn_listDrop
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_fn_listPrefEq
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf237
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf237
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf237
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd238
.Ltagf237:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd238:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse243
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listTake
    b .Lendif244
.Lelse243:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf239
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf239
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf239
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd240
.Ltagf239:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd240:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse241
    ldur x0, [x29, #-56]
    b .Lendif242
.Lelse241:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif242:
.Lendif244:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listSubGo segmax=31 exittail=31 ccalls=3
# listTake (arity 2)
    .globl fpr_fn_listTake
fpr_fn_listTake:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel254
    bl fpr_fuel_exhausted
.Lfuel254:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    mov x0, #1
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3c_x3d
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf246
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf246
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf246
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd247
.Ltagf246:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd247:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse252
    bl fpr_fn_Nil
    b .Lendif253
.Lelse252:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf248
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf248
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf248
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd249
.Ltagf248:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd249:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse250
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_listTakeGo
    b .Lendif251
.Lelse250:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif251:
.Lendif253:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listTake segmax=26 exittail=26 ccalls=2
# listTakeGo (arity 2)
    .globl fpr_fn_listTakeGo
fpr_fn_listTakeGo:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel263
    bl fpr_fuel_exhausted
.Lfuel263:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf255
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf255
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf255
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd256
.Ltagf255:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd256:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse261
    bl fpr_fn_Nil
    b .Lendif262
.Lelse261:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf257
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf257
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf257
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd258
.Ltagf257:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd258:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse259
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-112]
    mov x0, #3
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_fn_listTake
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif260
.Lelse259:
    adrp x0, .Lstr156
    add x0, x0, :lo12:.Lstr156
    bl fpr_panic
.Lendif260:
.Lendif262:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: listTakeGo segmax=35 exittail=35 ccalls=2
# mapFstV (arity 2)
    .globl fpr_fn_mapFstV
fpr_fn_mapFstV:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel277
    bl fpr_fuel_exhausted
.Lfuel277:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf264
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf264
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf264
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd265
.Ltagf264:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd265:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse275
    bl fpr_fn_Nil
    b .Lendif276
.Lelse275:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf266
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf266
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf266
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd267
.Ltagf266:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd267:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse273
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf268
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf268
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf268
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd269
.Ltagf268:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd269:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse271
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_fn_mapFstV
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif272
.Lelse271:
    adrp x0, .Lstr270
    add x0, x0, :lo12:.Lstr270
    bl fpr_panic
.Lendif272:
    b .Lendif274
.Lelse273:
    adrp x0, .Lstr270
    add x0, x0, :lo12:.Lstr270
    bl fpr_panic
.Lendif274:
.Lendif276:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: mapFstV segmax=76 exittail=76 ccalls=4
# mapSndV (arity 2)
    .globl fpr_fn_mapSndV
fpr_fn_mapSndV:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel290
    bl fpr_fuel_exhausted
.Lfuel290:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf278
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf278
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf278
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd279
.Ltagf278:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd279:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse288
    bl fpr_fn_Nil
    b .Lendif289
.Lelse288:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf280
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf280
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf280
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd281
.Ltagf280:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd281:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse286
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf282
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf282
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf282
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd283
.Ltagf282:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd283:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse284
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_fn_mapSndV
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif285
.Lelse284:
    adrp x0, .Lstr270
    add x0, x0, :lo12:.Lstr270
    bl fpr_panic
.Lendif285:
    b .Lendif287
.Lelse286:
    adrp x0, .Lstr270
    add x0, x0, :lo12:.Lstr270
    bl fpr_panic
.Lendif287:
.Lendif289:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: mapSndV segmax=76 exittail=76 ccalls=4
# mapV (arity 2)
    .globl fpr_fn_mapV
fpr_fn_mapV:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel300
    bl fpr_fuel_exhausted
.Lfuel300:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf291
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf291
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf291
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd292
.Ltagf291:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd292:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse298
    bl fpr_fn_Nil
    b .Lendif299
.Lelse298:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf293
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf293
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf293
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd294
.Ltagf293:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd294:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse296
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-80]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_fn_mapV
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif297
.Lelse296:
    adrp x0, .Lstr295
    add x0, x0, :lo12:.Lstr295
    bl fpr_panic
.Lendif297:
.Lendif299:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: mapV segmax=39 exittail=39 ccalls=2
# newHandle (arity 1)
    .globl fpr_fn_newHandle
fpr_fn_newHandle:
    sub sp, sp, #64
    stur x30, [sp, #56]
    stur x29, [sp, #48]
    add x29, sp, #64
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel301
    bl fpr_fuel_exhausted
.Lfuel301:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Handle
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: newHandle segmax=10 exittail=10 ccalls=0
# par2 (arity 5)
    .globl fpr_fn_par2
fpr_fn_par2:
    sub sp, sp, #160
    stur x30, [sp, #152]
    stur x29, [sp, #144]
    add x29, sp, #160
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    stur x4, [x29, #-56]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel307
    bl fpr_fuel_exhausted
.Lfuel307:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    adrp x0, fpr_g_myself
    add x0, x0, :lo12:fpr_g_myself
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-104]
    adrp x0, fpr_g_spawnOn
    add x0, x0, :lo12:fpr_g_spawnOn
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_parWorker
    add x0, x0, :lo12:fpr_obj_parWorker
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-112]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-112]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-104]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #32
    bl fpr_alloc
    mov x9, #5
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #24]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-120]
    ldur x0, [x29, #-88]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-96]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-128]
    adrp x0, fpr_g_receiveRes
    add x0, x0, :lo12:fpr_g_receiveRes
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-104]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-136]
    ldur x0, [x29, #-136]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf302
    ldursw x9, [x0, #0]
    mov x10, #3
    cmp x9, x10
    b.ne .Ltagf302
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf302
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd303
.Ltagf302:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd303:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse305
    ldur x0, [x29, #-136]
    ldur x0, [x0, #8]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-144]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-128]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    b .Lendif306
.Lelse305:
    adrp x0, .Lstr304
    add x0, x0, :lo12:.Lstr304
    bl fpr_panic
.Lendif306:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: par2 segmax=142 exittail=142 ccalls=8
# parWorker (arity 1)
    .globl fpr_fn_parWorker
fpr_fn_parWorker:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel313
    bl fpr_fuel_exhausted
.Lfuel313:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    adrp x0, fpr_g_receive
    add x0, x0, :lo12:fpr_g_receive
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-32]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf308
    ldursw x9, [x0, #0]
    mov x10, #5
    cmp x9, x10
    b.ne .Ltagf308
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf308
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd309
.Ltagf308:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd309:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse311
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x0, [x0, #16]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    ldur x0, [x0, #24]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    bl fpr_fn_Ok
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    b .Lendif312
.Lelse311:
    adrp x0, .Lstr310
    add x0, x0, :lo12:.Lstr310
    bl fpr_panic
.Lendif312:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: parWorker segmax=56 exittail=56 ccalls=4
# serve (arity 3)
    .globl fpr_fn_serve
fpr_fn_serve:
    sub sp, sp, #176
    stur x30, [sp, #168]
    stur x29, [sp, #160]
    add x29, sp, #176
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel322
    bl fpr_fuel_exhausted
.Lfuel322:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    adrp x0, fpr_g_receive
    add x0, x0, :lo12:fpr_g_receive
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf314
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf314
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf314
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd315
.Ltagf314:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd315:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse320
    ldur x0, [x29, #-80]
    ldur x0, [x0, #8]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x0, [x0, #16]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-96]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-104]
    ldur x0, [x29, #-104]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf316
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf316
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf316
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd317
.Ltagf316:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd317:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse318
    ldur x0, [x29, #-104]
    ldur x0, [x0, #8]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x0, [x0, #16]
    stur x0, [x29, #-120]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-88]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-120]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-128]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-136]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-152]
    ldur x0, [x29, #-112]
    stur x0, [x29, #-160]
    ldur x0, [x29, #-144]
    ldur x1, [x29, #-152]
    ldur x2, [x29, #-160]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_serve
    b .Lendif319
.Lelse318:
    adrp x0, .Lstr120
    add x0, x0, :lo12:.Lstr120
    bl fpr_panic
.Lendif319:
    b .Lendif321
.Lelse320:
    adrp x0, .Lstr120
    add x0, x0, :lo12:.Lstr120
    bl fpr_panic
.Lendif321:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: serve segmax=115 exittail=115 ccalls=6
# sndV (arity 1)
    .globl fpr_fn_sndV
fpr_fn_sndV:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel336
    bl fpr_fuel_exhausted
.Lfuel336:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf323
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf323
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf323
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd324
.Ltagf323:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd324:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse334
    bl fpr_fn_Nil
    b .Lendif335
.Lelse334:
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf325
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf325
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf325
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd326
.Ltagf325:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd326:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse332
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf327
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf327
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf327
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd328
.Ltagf327:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd328:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse330
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    ldur x0, [x0, #16]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x0, [x0, #16]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    bl fpr_fn_sndV
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif331
.Lelse330:
    adrp x0, .Lstr329
    add x0, x0, :lo12:.Lstr329
    bl fpr_panic
.Lendif331:
    b .Lendif333
.Lelse332:
    adrp x0, .Lstr329
    add x0, x0, :lo12:.Lstr329
    bl fpr_panic
.Lendif333:
.Lendif335:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: sndV segmax=42 exittail=42 ccalls=2
# strSub (arity 2)
    .globl fpr_fn_strSub
fpr_fn_strSub:
    sub sp, sp, #128
    stur x30, [sp, #120]
    stur x29, [sp, #112]
    add x29, sp, #128
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel345
    bl fpr_fuel_exhausted
.Lfuel345:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_strlen
    add x0, x0, :lo12:fpr_g_strlen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-56]
    adrp x0, fpr_g_strlen
    add x0, x0, :lo12:fpr_g_strlen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf337
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf337
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf337
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd338
.Ltagf337:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd338:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse343
    ldur x0, [x29, #-40]
    b .Lendif344
.Lelse343:
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf339
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf339
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf339
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd340
.Ltagf339:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd340:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse341
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    ldur x3, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strSubGo
    b .Lendif342
.Lelse341:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif342:
.Lendif344:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strSub segmax=82 exittail=82 ccalls=4
# strSubGo (arity 4)
    .globl fpr_fn_strSubGo
fpr_fn_strSubGo:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel354
    bl fpr_fuel_exhausted
.Lfuel354:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-104]
    mov x0, #3
    stur x0, [x29, #-112]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x2, [x29, #-104]
    ldur x3, [x29, #-112]
    bl fpr_fn_strSufEq
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf346
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf346
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf346
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd347
.Ltagf346:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd347:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse352
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strTake
    b .Lendif353
.Lelse352:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf348
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf348
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf348
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd349
.Ltagf348:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd349:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse350
    ldur x0, [x29, #-56]
    b .Lendif351
.Lelse350:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif351:
.Lendif353:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strSubGo segmax=31 exittail=31 ccalls=3
# strSufEq (arity 4)
    .globl fpr_fn_strSufEq
fpr_fn_strSufEq:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel363
    bl fpr_fuel_exhausted
.Lfuel363:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-88]
    adrp x0, fpr_g_strlen
    add x0, x0, :lo12:fpr_g_strlen
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf355
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf355
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf355
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd356
.Ltagf355:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd356:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse361
    bl fpr_fn_True
    b .Lendif362
.Lelse361:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf357
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf357
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf357
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd358
.Ltagf357:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd358:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse359
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x3, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strSufEqAt
    b .Lendif360
.Lelse359:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif360:
.Lendif362:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strSufEq segmax=40 exittail=40 ccalls=3
# strSufEqAt (arity 4)
    .globl fpr_fn_strSufEqAt
fpr_fn_strSufEqAt:
    sub sp, sp, #160
    stur x30, [sp, #152]
    stur x29, [sp, #144]
    add x29, sp, #160
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel372
    bl fpr_fuel_exhausted
.Lfuel372:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    adrp x0, fpr_g_charAt
    add x0, x0, :lo12:fpr_g_charAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x2b
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-88]
    adrp x0, fpr_g_charAt
    add x0, x0, :lo12:fpr_g_charAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3d_x3d
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf364
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf364
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf364
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd365
.Ltagf364:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd365:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse370
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-128]
    mov x0, #3
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x3, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strSufEq
    b .Lendif371
.Lelse370:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf366
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf366
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf366
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd367
.Ltagf366:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd367:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse368
    bl fpr_fn_False
    b .Lendif369
.Lelse368:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif369:
.Lendif371:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strSufEqAt segmax=84 exittail=84 ccalls=6
# strTake (arity 2)
    .globl fpr_fn_strTake
fpr_fn_strTake:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel373
    bl fpr_fuel_exhausted
.Lfuel373:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    mov x0, #3
    stur x0, [x29, #-72]
    adrp x0, .Lstr86
    add x0, x0, :lo12:.Lstr86
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x3, [x29, #-80]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strTakeGo
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strTake segmax=20 exittail=20 ccalls=0
# strTakeGo (arity 4)
    .globl fpr_fn_strTakeGo
fpr_fn_strTakeGo:
    sub sp, sp, #160
    stur x30, [sp, #152]
    stur x29, [sp, #144]
    add x29, sp, #160
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    stur x3, [x29, #-48]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel382
    bl fpr_fuel_exhausted
.Lfuel382:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf374
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf374
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf374
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd375
.Ltagf374:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd375:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse380
    ldur x0, [x29, #-80]
    b .Lendif381
.Lelse380:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf376
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf376
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf376
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd377
.Ltagf376:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd377:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse378
    ldur x0, [x29, #-56]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-120]
    mov x0, #3
    stur x0, [x29, #-128]
    ldur x0, [x29, #-120]
    ldur x1, [x29, #-128]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-128]
    adrp x0, fpr_g_chr
    add x0, x0, :lo12:fpr_g_chr
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_g_charAt
    add x0, x0, :lo12:fpr_g_charAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn_strcat
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x3, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_strTakeGo
    b .Lendif379
.Lelse378:
    adrp x0, .Lstr26
    add x0, x0, :lo12:.Lstr26
    bl fpr_panic
.Lendif379:
.Lendif381:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: strTakeGo segmax=97 exittail=97 ccalls=6
# sumV (arity 1)
    .globl fpr_fn_sumV
fpr_fn_sumV:
    sub sp, sp, #96
    stur x30, [sp, #88]
    stur x29, [sp, #80]
    add x29, sp, #96
    stur x0, [x29, #-24]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel391
    bl fpr_fuel_exhausted
.Lfuel391:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf383
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf383
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf383
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd384
.Ltagf383:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd384:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse389
    mov x0, #1
    b .Lendif390
.Lelse389:
    ldur x0, [x29, #-40]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf385
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf385
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf385
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd386
.Ltagf385:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd386:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse387
    ldur x0, [x29, #-40]
    ldur x0, [x0, #8]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x0, [x0, #16]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    bl fpr_fn_sumV
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2b
    b .Lendif388
.Lelse387:
    adrp x0, .Lstr295
    add x0, x0, :lo12:.Lstr295
    bl fpr_panic
.Lendif388:
.Lendif390:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: sumV segmax=45 exittail=45 ccalls=1
# zipV (arity 2)
    .globl fpr_fn_zipV
fpr_fn_zipV:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel404
    bl fpr_fuel_exhausted
.Lfuel404:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf392
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf392
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf392
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd393
.Ltagf392:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd393:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse402
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf394
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf394
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf394
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd395
.Ltagf394:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd395:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse400
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf396
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf396
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf396
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd397
.Ltagf396:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd397:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse398
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    ldur x0, [x0, #8]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    ldur x0, [x0, #16]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #24
    bl fpr_alloc
    mov x9, #4
    stur w9, [x0, #0]
    mov x9, #0
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #16]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_fn_zipV
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    b .Lendif399
.Lelse398:
    bl fpr_fn_Nil
.Lendif399:
    b .Lendif401
.Lelse400:
    bl fpr_fn_Nil
.Lendif401:
    b .Lendif403
.Lelse402:
    bl fpr_fn_Nil
.Lendif403:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
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
fpr_obj_Ent:
    .long 9001
    .long 0
    .quad fpr_fn_Ent
    .quad 5
    .quad 0

    .balign 8
fpr_obj_Err:
    .long 9001
    .long 0
    .quad fpr_fn_Err
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Frame:
    .long 9001
    .long 0
    .quad fpr_fn_Frame
    .quad 3
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
fpr_obj_Scene:
    .long 9001
    .long 0
    .quad fpr_fn_Scene
    .quad 4
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
.Lstr86:
    .long 9000
    .long 0
    .quad 0

    .balign 8
.Lstr114:
    .long 9000
    .long 0
    .quad 63
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 72, 97, 110, 100
    .byte 108, 101, 34, 32, 91, 80, 86, 97, 114, 32, 34, 118, 34, 93, 93

    .balign 8
.Lstr270:
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
.Lstr139:
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
.Lstr329:
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
.Lstr213:
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
.Lstr156:
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
.Lstr295:
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
.Lstr203:
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
.Lstr175:
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
.Lstr304:
    .long 9000
    .long 0
    .quad 60
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 79, 107, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 114, 97, 34, 93, 93

    .balign 8
.Lstr26:
    .long 9000
    .long 0
    .quad 69
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 84, 114, 117, 101
    .byte 34, 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 70, 97, 108, 115, 101
    .byte 34, 32, 91, 93, 93

    .balign 8
.Lstr310:
    .long 9000
    .long 0
    .quad 77
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 84, 117, 112, 32, 91, 80, 86, 97, 114
    .byte 32, 34, 112, 97, 114, 101, 110, 116, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 102, 34, 44, 80, 86, 97, 114, 32, 34, 97, 34, 93, 93

    .balign 8
.Lstr120:
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

