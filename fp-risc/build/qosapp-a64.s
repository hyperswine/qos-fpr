# target: qa64 (lowered from the rv64 emission; QOS Portable single-hart globals)
    .text
    .balign 4

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
    b.gt .Lfuel0
    bl fpr_fuel_exhausted
.Lfuel0:
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
    b.gt .Lfuel1
    bl fpr_fuel_exhausted
.Lfuel1:
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
    movz x9, #63187
    movk x9, #28287, lsl #16
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
    b.gt .Lfuel2
    bl fpr_fuel_exhausted
.Lfuel2:
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
    b.gt .Lfuel3
    bl fpr_fuel_exhausted
.Lfuel3:
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
    b.gt .Lfuel4
    bl fpr_fuel_exhausted
.Lfuel4:
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
    movz x9, #12845
    movk x9, #27038, lsl #16
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
    b.gt .Lfuel5
    bl fpr_fuel_exhausted
.Lfuel5:
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
    b.gt .Lfuel6
    bl fpr_fuel_exhausted
.Lfuel6:
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
    b.gt .Lfuel7
    bl fpr_fuel_exhausted
.Lfuel7:
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
    b.gt .Lfuel8
    bl fpr_fuel_exhausted
.Lfuel8:
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
    mov x0, #40
    bl fpr_alloc
    movz x9, #63187
    movk x9, #28287, lsl #16
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
    b.gt .Lfuel10
    bl fpr_fuel_exhausted
.Lfuel10:
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
    b.gt .Lfuel11
    bl fpr_fuel_exhausted
.Lfuel11:
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
    b.gt .Lfuel13
    bl fpr_fuel_exhausted
.Lfuel13:
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
    b.gt .Lfuel14
    bl fpr_fuel_exhausted
.Lfuel14:
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
    b.gt .Lfuel15
    bl fpr_fuel_exhausted
.Lfuel15:
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
    b.gt .Lfuel16
    bl fpr_fuel_exhausted
.Lfuel16:
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
    b.gt .Lfuel17
    bl fpr_fuel_exhausted
.Lfuel17:
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
    b.gt .Lfuel18
    bl fpr_fuel_exhausted
.Lfuel18:
    adrp x0, .Lnul_0_0
    add x0, x0, :lo12:.Lnul_0_0
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: Unit segmax=9 exittail=9 ccalls=0
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
    b.gt .Lfuel19
    bl fpr_fuel_exhausted
.Lfuel19:
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
# applyKey (arity 3)
    .globl fpr_fn_applyKey
fpr_fn_applyKey:
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
    b.gt .Lfuel24
    bl fpr_fuel_exhausted
.Lfuel24:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    mov x0, #33
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse22
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    mov x0, #3
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse20
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    bl fpr_fn_keyQuit
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_keyDown
    b .Lendif21
.Lelse20:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_applyKey_x5ffb_x5f11
.Lendif21:
    b .Lendif23
.Lelse22:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_applyKey_x5ffb_x5f11
.Lendif23:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: applyKey segmax=22 exittail=22 ccalls=2
# applyKey_fb_10 (arity 3)
fpr_fn_applyKey_x5ffb_x5f10:
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
    b.gt .Lfuel29
    bl fpr_fuel_exhausted
.Lfuel29:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    mov x0, #3
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse27
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    bl fpr_fn_keyBit
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_keyDown
    b .Lendif28
.Lelse27:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    mov x0, #1
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse25
    ldur x0, [x29, #-64]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-96]
    bl fpr_fn_keyBit
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_keyUp
    b .Lendif26
.Lelse25:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
.Lendif26:
.Lendif28:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: applyKey_fb_10 segmax=19 exittail=19 ccalls=2
# applyKey_fb_11 (arity 3)
fpr_fn_applyKey_x5ffb_x5f11:
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
    b.gt .Lfuel34
    bl fpr_fuel_exhausted
.Lfuel34:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    mov x0, #3
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse32
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    mov x0, #3
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse30
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    bl fpr_fn_keyQuit
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_keyDown
    b .Lendif31
.Lelse30:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_applyKey_x5ffb_x5f10
.Lendif31:
    b .Lendif33
.Lelse32:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_applyKey_x5ffb_x5f10
.Lendif33:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: applyKey_fb_11 segmax=22 exittail=22 ccalls=2
# axis (arity 3)
    .globl fpr_fn_axis
fpr_fn_axis:
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
    b.gt .Lfuel35
    bl fpr_fuel_exhausted
.Lfuel35:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_fn_isDown
    stur x0, [x29, #-72]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_fn_isDown
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
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

# wcet: axis segmax=13 exittail=13 ccalls=0
# camera (arity 0)
    .globl fpr_fn_camera
fpr_fn_camera:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel36
    bl fpr_fuel_exhausted
.Lfuel36:
    mov x0, #14001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #18001
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
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
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
    mov x0, #1601
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

# wcet: camera segmax=75 exittail=75 ccalls=3
# clamp (arity 3)
    .globl fpr_fn_clamp
fpr_fn_clamp:
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
    b.gt .Lfuel41
    bl fpr_fuel_exhausted
.Lfuel41:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_prim_fn__x3c
    ldursw x9, [x0, #4]
    cbz x9, .Lelse39
    ldur x0, [x29, #-48]
    b .Lendif40
.Lelse39:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x3e
    ldursw x9, [x0, #4]
    cbz x9, .Lelse37
    ldur x0, [x29, #-80]
    b .Lendif38
.Lelse37:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-112]
.Lendif38:
.Lendif40:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: clamp segmax=46 exittail=46 ccalls=2
# frameWorker (arity 2)
    .globl fpr_fn_frameWorker
fpr_fn_frameWorker:
    sub sp, sp, #208
    stur x30, [sp, #200]
    stur x29, [sp, #192]
    add x29, sp, #208
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel51
    bl fpr_fuel_exhausted
.Lfuel51:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_receiveFrom
    add x0, x0, :lo12:fpr_g_receiveFrom
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-64]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf42
    ldursw x9, [x0, #0]
    movz x10, #12845
    movk x10, #27038, lsl #16
    cmp x9, x10
    b.ne .Ltagf42
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf42
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd43
.Ltagf42:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd43:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse49
    ldur x0, [x29, #-64]
    ldur x0, [x0, #8]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x0, [x0, #16]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    ldur x0, [x0, #24]
    stur x0, [x29, #-88]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-104]
    mov x0, #65
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_fn_pollKeys
    stur x0, [x29, #-104]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-104]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    ldur x2, [x29, #-128]
    bl fpr_fn_move
    stur x0, [x29, #-112]
    ldur x0, [x29, #-112]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf44
    ldursw x9, [x0, #0]
    mov x10, #4
    cmp x9, x10
    b.ne .Ltagf44
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf44
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd45
.Ltagf44:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd45:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse47
    ldur x0, [x29, #-112]
    ldur x0, [x0, #8]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x0, [x0, #16]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-120]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-136]
    ldur x1, [x29, #-144]
    bl fpr_fn_renderFrame
    stur x0, [x29, #-136]
    ldur x0, [x29, #-120]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-128]
    stur x0, [x29, #-152]
    ldur x0, [x29, #-104]
    stur x0, [x29, #-160]
    ldur x0, [x29, #-144]
    ldur x1, [x29, #-152]
    ldur x2, [x29, #-160]
    bl fpr_fn_Frame
    stur x0, [x29, #-144]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-144]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-152]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-144]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-160]
    adrp x0, fpr_g_Sys_x2epoolReset
    add x0, x0, :lo12:fpr_g_Sys_x2epoolReset
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
    stur x0, [x29, #-168]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-176]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-184]
    ldur x0, [x29, #-176]
    ldur x1, [x29, #-184]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_frameWorker
    b .Lendif48
.Lelse47:
    adrp x0, .Lstr46
    add x0, x0, :lo12:.Lstr46
    bl fpr_panic
.Lendif48:
    b .Lendif50
.Lelse49:
    adrp x0, .Lstr46
    add x0, x0, :lo12:.Lstr46
    bl fpr_panic
.Lendif50:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: frameWorker segmax=62 exittail=62 ccalls=7
# ground (arity 0)
    .globl fpr_fn_ground
fpr_fn_ground:
    sub sp, sp, #144
    stur x30, [sp, #136]
    stur x29, [sp, #128]
    add x29, sp, #144
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel54
    bl fpr_fuel_exhausted
.Lfuel54:
    adrp x0, .Lstr52
    add x0, x0, :lo12:.Lstr52
    stur x0, [x29, #-32]
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
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
    stur x0, [x29, #-40]
    mov x0, #1
    stur x0, [x29, #-48]
    mov x0, #16001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16001
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
    stur x0, [x29, #-56]
    mov x0, #361
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #481
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #441
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
    stur x0, [x29, #-64]
    ldur x0, [x29, #-32]
    ldur x1, [x29, #-40]
    ldur x2, [x29, #-48]
    ldur x3, [x29, #-56]
    ldur x4, [x29, #-64]
    bl fpr_fn_Ent
    stur x0, [x29, #-24]
    adrp x0, .Lstr53
    add x0, x0, :lo12:.Lstr53
    stur x0, [x29, #-48]
    mov x0, #1
    stur x0, [x29, #-64]
    mov x0, #6401
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    bl fpr_prim_fn__x2d
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #501
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    stur x0, [x29, #-64]
    mov x0, #6401
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    bl fpr_prim_fn__x2d
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
    stur x0, [x29, #-56]
    mov x0, #1
    stur x0, [x29, #-64]
    mov x0, #1001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1001
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
    stur x0, [x29, #-72]
    mov x0, #1801
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #801
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #441
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
    stur x0, [x29, #-80]
    ldur x0, [x29, #-48]
    ldur x1, [x29, #-56]
    ldur x2, [x29, #-64]
    ldur x3, [x29, #-72]
    ldur x4, [x29, #-80]
    bl fpr_fn_Ent
    stur x0, [x29, #-40]
    adrp x0, .Lstr53
    add x0, x0, :lo12:.Lstr53
    stur x0, [x29, #-64]
    mov x0, #6401
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #801
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    stur x0, [x29, #-80]
    mov x0, #6401
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_prim_fn__x2d
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
    stur x0, [x29, #-72]
    mov x0, #1
    stur x0, [x29, #-80]
    mov x0, #1201
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1601
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1201
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
    stur x0, [x29, #-88]
    mov x0, #1901
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1401
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #361
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
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x2, [x29, #-80]
    ldur x3, [x29, #-88]
    ldur x4, [x29, #-96]
    bl fpr_fn_Ent
    stur x0, [x29, #-56]
    adrp x0, .Lstr53
    add x0, x0, :lo12:.Lstr53
    stur x0, [x29, #-80]
    mov x0, #1
    stur x0, [x29, #-96]
    mov x0, #6401
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x2d
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1201
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #6401
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
    stur x0, [x29, #-88]
    mov x0, #1
    stur x0, [x29, #-96]
    mov x0, #1401
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2401
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1401
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
    stur x0, [x29, #-104]
    mov x0, #601
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1561
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #841
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
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    ldur x3, [x29, #-104]
    ldur x4, [x29, #-112]
    bl fpr_fn_Ent
    stur x0, [x29, #-72]
    adrp x0, .Lstr53
    add x0, x0, :lo12:.Lstr53
    stur x0, [x29, #-96]
    mov x0, #6401
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #601
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #6401
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
    stur x0, [x29, #-104]
    mov x0, #1
    stur x0, [x29, #-112]
    mov x0, #1801
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1201
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1801
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
    stur x0, [x29, #-120]
    mov x0, #1641
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #601
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #601
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
    stur x0, [x29, #-128]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    ldur x2, [x29, #-112]
    ldur x3, [x29, #-120]
    ldur x4, [x29, #-128]
    bl fpr_fn_Ent
    stur x0, [x29, #-88]
    bl fpr_fn_Nil
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_fn_Cons
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_fn_Cons
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_fn_Cons
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    ldur x1, [x29, #-48]
    bl fpr_fn_Cons
    stur x0, [x29, #-32]
    ldur x0, [x29, #-24]
    ldur x1, [x29, #-32]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: ground segmax=97 exittail=97 ccalls=19
# hasKey (arity 2)
    .globl fpr_fn_hasKey
fpr_fn_hasKey:
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
    adrp x0, fpr_g_band
    add x0, x0, :lo12:fpr_g_band
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
    stur x0, [x29, #-56]
    mov x0, #1
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x21_x3d
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: hasKey segmax=33 exittail=33 ccalls=1
# isDown (arity 2)
    .globl fpr_fn_isDown
fpr_fn_isDown:
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
    b.gt .Lfuel58
    bl fpr_fuel_exhausted
.Lfuel58:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_fn_hasKey
    ldursw x9, [x0, #4]
    cbz x9, .Lelse56
    mov x0, #3
    b .Lendif57
.Lelse56:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    mov x0, #1
.Lendif57:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: isDown segmax=14 exittail=14 ccalls=0
# keyA (arity 0)
    .globl fpr_fn_keyA
fpr_fn_keyA:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel59
    bl fpr_fuel_exhausted
.Lfuel59:
    mov x0, #5
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyA segmax=9 exittail=9 ccalls=0
# keyBit (arity 1)
    .globl fpr_fn_keyBit
fpr_fn_keyBit:
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
    b.gt .Lfuel68
    bl fpr_fuel_exhausted
.Lfuel68:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #35
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    ldur x1, [x29, #-40]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse66
    bl fpr_fn_keyW
    b .Lendif67
.Lelse66:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #61
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    ldur x1, [x29, #-40]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse64
    bl fpr_fn_keyA
    b .Lendif65
.Lelse64:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #63
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    ldur x1, [x29, #-40]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse62
    bl fpr_fn_keyS
    b .Lendif63
.Lelse62:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #65
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    ldur x1, [x29, #-40]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse60
    bl fpr_fn_keyD
    b .Lendif61
.Lelse60:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-32]
    mov x0, #1
.Lendif61:
.Lendif63:
.Lendif65:
.Lendif67:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyBit segmax=10 exittail=10 ccalls=4
# keyD (arity 0)
    .globl fpr_fn_keyD
fpr_fn_keyD:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel69
    bl fpr_fuel_exhausted
.Lfuel69:
    mov x0, #17
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyD segmax=9 exittail=9 ccalls=0
# keyDown (arity 2)
    .globl fpr_fn_keyDown
fpr_fn_keyDown:
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
    b.gt .Lfuel72
    bl fpr_fuel_exhausted
.Lfuel72:
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
    bl fpr_fn_hasKey
    ldursw x9, [x0, #4]
    cbz x9, .Lelse70
    ldur x0, [x29, #-40]
    b .Lendif71
.Lelse70:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2b
.Lendif71:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyDown segmax=19 exittail=19 ccalls=0
# keyQuit (arity 0)
    .globl fpr_fn_keyQuit
fpr_fn_keyQuit:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel73
    bl fpr_fuel_exhausted
.Lfuel73:
    mov x0, #33
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyQuit segmax=9 exittail=9 ccalls=0
# keyS (arity 0)
    .globl fpr_fn_keyS
fpr_fn_keyS:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel74
    bl fpr_fuel_exhausted
.Lfuel74:
    mov x0, #9
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyS segmax=9 exittail=9 ccalls=0
# keyUp (arity 2)
    .globl fpr_fn_keyUp
fpr_fn_keyUp:
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
    b.gt .Lfuel77
    bl fpr_fuel_exhausted
.Lfuel77:
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
    bl fpr_fn_hasKey
    ldursw x9, [x0, #4]
    cbz x9, .Lelse75
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
    b .Lendif76
.Lelse75:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
.Lendif76:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyUp segmax=24 exittail=24 ccalls=0
# keyW (arity 0)
    .globl fpr_fn_keyW
fpr_fn_keyW:
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
    mov x0, #3
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: keyW segmax=9 exittail=9 ccalls=0
# lights (arity 0)
    .globl fpr_fn_lights
fpr_fn_lights:
    sub sp, sp, #48
    stur x30, [sp, #40]
    stur x29, [sp, #32]
    add x29, sp, #48
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel79
    bl fpr_fuel_exhausted
.Lfuel79:
    mov x0, #9001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #18001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #10001
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
    mov x0, #2001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
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
    stur x0, [x29, #-24]
    bl fpr_fn_Nil
    stur x0, [x29, #-32]
    ldur x0, [x29, #-24]
    ldur x1, [x29, #-32]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: lights segmax=65 exittail=65 ccalls=3
# main (arity 0)
    .globl fpr_fn_main
fpr_fn_main:
    sub sp, sp, #112
    stur x30, [sp, #104]
    stur x29, [sp, #96]
    add x29, sp, #112
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel81
    bl fpr_fuel_exhausted
.Lfuel81:
    adrp x0, fpr_g_device
    add x0, x0, :lo12:fpr_g_device
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, .Lstr80
    add x0, x0, :lo12:.Lstr80
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-24]
    adrp x0, fpr_g_blkPages
    add x0, x0, :lo12:fpr_g_blkPages
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-32]
    adrp x0, fpr_g_glInit
    add x0, x0, :lo12:fpr_g_glInit
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1921
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1281
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-40]
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
    stur x0, [x29, #-48]
    adrp x0, fpr_g_spawn
    add x0, x0, :lo12:fpr_g_spawn
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, fpr_obj_frameWorker
    add x0, x0, :lo12:fpr_obj_frameWorker
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
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-72]
    mov x0, #1
    stur x0, [x29, #-80]
    mov x0, #1
    stur x0, [x29, #-88]
    mov x0, #1
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x2, [x29, #-80]
    ldur x3, [x29, #-88]
    ldur x4, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_run
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: main segmax=92 exittail=92 ccalls=6
# move (arity 3)
    .globl fpr_fn_move
fpr_fn_move:
    sub sp, sp, #160
    stur x30, [sp, #152]
    stur x29, [sp, #144]
    add x29, sp, #160
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel82
    bl fpr_fuel_exhausted
.Lfuel82:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    bl fpr_fn_keyD
    stur x0, [x29, #-72]
    bl fpr_fn_keyA
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    ldur x2, [x29, #-88]
    bl fpr_fn_axis
    stur x0, [x29, #-72]
    bl fpr_fn_keyS
    stur x0, [x29, #-80]
    bl fpr_fn_keyW
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    bl fpr_fn_axis
    stur x0, [x29, #-80]
    mov x0, #1
    stur x0, [x29, #-96]
    mov x0, #6001
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-88]
    mov x0, #6001
    stur x0, [x29, #-96]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-128]
    mov x0, #111
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn__x2a
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x2, [x29, #-104]
    bl fpr_fn_clamp
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    stur x0, [x29, #-96]
    mov x0, #6001
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-88]
    mov x0, #6001
    stur x0, [x29, #-96]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-128]
    mov x0, #111
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn__x2a
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x2, [x29, #-104]
    bl fpr_fn_clamp
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

# wcet: move segmax=29 exittail=29 ccalls=7
# nextFrame (arity 5)
    .globl fpr_fn_nextFrame
fpr_fn_nextFrame:
    sub sp, sp, #208
    stur x30, [sp, #200]
    stur x29, [sp, #192]
    add x29, sp, #208
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
    b.gt .Lfuel88
    bl fpr_fuel_exhausted
.Lfuel88:
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
    ldur x0, [x29, #-96]
    stur x0, [x29, #-104]
    bl fpr_fn_keyQuit
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_fn_hasKey
    ldursw x9, [x0, #4]
    cbz x9, .Lelse86
    adrp x0, .Lstr83
    add x0, x0, :lo12:.Lstr83
    stur x0, [x29, #-128]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-144]
    bl fpr_prim_fn_str
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn_strcat
    stur x0, [x29, #-120]
    adrp x0, .Lstr84
    add x0, x0, :lo12:.Lstr84
    stur x0, [x29, #-128]
    ldur x0, [x29, #-120]
    ldur x1, [x29, #-128]
    bl fpr_prim_fn_strcat
    stur x0, [x29, #-112]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-128]
    bl fpr_prim_fn_str
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    bl fpr_prim_fn_strcat
    stur x0, [x29, #-104]
    adrp x0, .Lstr85
    add x0, x0, :lo12:.Lstr85
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn_strcat
    b .Lendif87
.Lelse86:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-136]
    adrp x0, fpr_g_Sys_x2esleepUs
    add x0, x0, :lo12:fpr_g_Sys_x2esleepUs
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #32001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-144]
    adrp x0, fpr_g_Sys_x2epoolReset
    add x0, x0, :lo12:fpr_g_Sys_x2epoolReset
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
    stur x0, [x29, #-152]
    ldur x0, [x29, #-104]
    stur x0, [x29, #-160]
    ldur x0, [x29, #-112]
    stur x0, [x29, #-168]
    ldur x0, [x29, #-120]
    stur x0, [x29, #-176]
    ldur x0, [x29, #-128]
    stur x0, [x29, #-184]
    ldur x0, [x29, #-136]
    stur x0, [x29, #-192]
    ldur x0, [x29, #-160]
    ldur x1, [x29, #-168]
    ldur x2, [x29, #-176]
    ldur x3, [x29, #-184]
    ldur x4, [x29, #-192]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_run
.Lendif87:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: nextFrame segmax=91 exittail=91 ccalls=7
# player (arity 2)
    .globl fpr_fn_player
fpr_fn_player:
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
    b.gt .Lfuel90
    bl fpr_fuel_exhausted
.Lfuel90:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, .Lstr89
    add x0, x0, :lo12:.Lstr89
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1001
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
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
    stur x0, [x29, #-72]
    mov x0, #1
    stur x0, [x29, #-80]
    mov x0, #1701
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1701
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
    stur x0, [x29, #-88]
    mov x0, #321
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1241
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
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
    stur x0, [x29, #-96]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x2, [x29, #-80]
    ldur x3, [x29, #-88]
    ldur x4, [x29, #-96]
    bl fpr_fn_Ent
    stur x0, [x29, #-56]
    adrp x0, .Lstr89
    add x0, x0, :lo12:.Lstr89
    stur x0, [x29, #-80]
    ldur x0, [x29, #-40]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2101
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-48]
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
    stur x0, [x29, #-88]
    mov x0, #1
    stur x0, [x29, #-96]
    mov x0, #861
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #861
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #861
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
    stur x0, [x29, #-104]
    mov x0, #1701
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1881
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #2001
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
    stur x0, [x29, #-112]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x2, [x29, #-96]
    ldur x3, [x29, #-104]
    ldur x4, [x29, #-112]
    bl fpr_fn_Ent
    stur x0, [x29, #-72]
    bl fpr_fn_Nil
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_fn_Cons
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_Cons
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: player segmax=88 exittail=88 ccalls=6
# pollDecoded (arity 5)
    .globl fpr_fn_pollDecoded
fpr_fn_pollDecoded:
    sub sp, sp, #176
    stur x30, [sp, #168]
    stur x29, [sp, #160]
    add x29, sp, #176
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
    b.gt .Lfuel95
    bl fpr_fuel_exhausted
.Lfuel95:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-80]
    mov x0, #1
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse93
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-64]
    b .Lendif94
.Lelse93:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-96]
    mov x0, #9
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse91
    ldur x0, [x29, #-48]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-104]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-120]
    ldur x1, [x29, #-128]
    ldur x2, [x29, #-136]
    bl fpr_fn_applyKey
    stur x0, [x29, #-112]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-128]
    mov x0, #3
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_pollKeys
    b .Lendif92
.Lelse91:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-104]
    stur x0, [x29, #-152]
    mov x0, #3
    stur x0, [x29, #-160]
    ldur x0, [x29, #-152]
    ldur x1, [x29, #-160]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-144]
    ldur x0, [x29, #-136]
    ldur x1, [x29, #-144]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_pollKeys
.Lendif92:
.Lendif94:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: pollDecoded segmax=45 exittail=45 ccalls=4
# pollEvent (arity 3)
    .globl fpr_fn_pollEvent
fpr_fn_pollEvent:
    sub sp, sp, #160
    stur x30, [sp, #152]
    stur x29, [sp, #144]
    add x29, sp, #160
    stur x0, [x29, #-24]
    stur x1, [x29, #-32]
    stur x2, [x29, #-40]
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel100
    bl fpr_fuel_exhausted
.Lfuel100:
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
    cbnz x9, .Ltagf96
    ldursw x9, [x0, #0]
    mov x10, #5
    cmp x9, x10
    b.ne .Ltagf96
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf96
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd97
.Ltagf96:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd97:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse98
    ldur x0, [x29, #-72]
    ldur x0, [x0, #8]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x0, [x0, #16]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    ldur x0, [x0, #24]
    stur x0, [x29, #-96]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
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
    stur x0, [x29, #-104]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    ldur x2, [x29, #-128]
    ldur x3, [x29, #-136]
    ldur x4, [x29, #-144]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_pollDecoded
    b .Lendif99
.Lelse98:
    adrp x0, .Lstr46
    add x0, x0, :lo12:.Lstr46
    bl fpr_panic
.Lendif99:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: pollEvent segmax=62 exittail=62 ccalls=2
# pollKeys (arity 2)
    .globl fpr_fn_pollKeys
fpr_fn_pollKeys:
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
    b.gt .Lfuel103
    bl fpr_fuel_exhausted
.Lfuel103:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    mov x0, #1
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    ldur x1, [x29, #-56]
    bl fpr_prim_fn__x3d_x3d
    ldursw x9, [x0, #4]
    cbz x9, .Lelse101
    ldur x0, [x29, #-40]
    b .Lendif102
.Lelse101:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-72]
    adrp x0, fpr_g_inputPoll
    add x0, x0, :lo12:fpr_g_inputPoll
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
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x2, [x29, #-80]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_pollEvent
.Lendif102:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: pollKeys segmax=40 exittail=40 ccalls=2
# renderFrame (arity 2)
    .globl fpr_fn_renderFrame
fpr_fn_renderFrame:
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
    b.gt .Lfuel104
    bl fpr_fuel_exhausted
.Lfuel104:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    bl fpr_fn_ground
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_fn_player
    stur x0, [x29, #-64]
    bl fpr_fn_lights
    stur x0, [x29, #-72]
    bl fpr_fn_camera
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    ldur x2, [x29, #-72]
    ldur x3, [x29, #-80]
    bl fpr_fn_Scene
    stur x0, [x29, #-56]
    adrp x0, fpr_g_glRender
    add x0, x0, :lo12:fpr_g_glRender
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-64]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
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
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-56]
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

# wcet: renderFrame segmax=41 exittail=41 ccalls=3
# run (arity 5)
    .globl fpr_fn_run
fpr_fn_run:
    sub sp, sp, #224
    stur x30, [sp, #216]
    stur x29, [sp, #208]
    add x29, sp, #224
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
    b.gt .Lfuel109
    bl fpr_fuel_exhausted
.Lfuel109:
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
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    ldur x2, [x29, #-120]
    bl fpr_fn_Frame
    stur x0, [x29, #-104]
    adrp x0, fpr_g_send
    add x0, x0, :lo12:fpr_g_send
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-72]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-104]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-112]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
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
    stur x0, [x29, #-120]
    adrp x0, fpr_g_receiveFrom
    add x0, x0, :lo12:fpr_g_receiveFrom
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
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
    stur x0, [x29, #-128]
    ldur x0, [x29, #-128]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-136]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf105
    ldursw x9, [x0, #0]
    movz x10, #12845
    movk x10, #27038, lsl #16
    cmp x9, x10
    b.ne .Ltagf105
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf105
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd106
.Ltagf105:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd106:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse107
    ldur x0, [x29, #-136]
    ldur x0, [x0, #8]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-136]
    ldur x0, [x0, #16]
    stur x0, [x29, #-152]
    ldur x0, [x29, #-136]
    ldur x0, [x0, #24]
    stur x0, [x29, #-160]
    adrp x0, fpr_g_drop
    add x0, x0, :lo12:fpr_g_drop
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-128]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-168]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-176]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-184]
    ldur x0, [x29, #-144]
    stur x0, [x29, #-192]
    ldur x0, [x29, #-152]
    stur x0, [x29, #-200]
    ldur x0, [x29, #-160]
    stur x0, [x29, #-208]
    ldur x0, [x29, #-176]
    ldur x1, [x29, #-184]
    ldur x2, [x29, #-192]
    ldur x3, [x29, #-200]
    ldur x4, [x29, #-208]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_nextFrame
    b .Lendif108
.Lelse107:
    adrp x0, .Lstr46
    add x0, x0, :lo12:.Lstr46
    bl fpr_panic
.Lendif108:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: run segmax=99 exittail=99 ccalls=5
    .section .rodata

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
fpr_obj_Scene:
    .long 9001
    .long 0
    .quad fpr_fn_Scene
    .quad 4
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
fpr_obj_Vector:
    .long 9001
    .long 0
    .quad fpr_fn_Vector
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_applyKey
fpr_obj_applyKey:
    .long 9001
    .long 0
    .quad fpr_fn_applyKey
    .quad 3
    .quad 0

    .balign 8
fpr_obj_applyKey_x5ffb_x5f10:
    .long 9001
    .long 0
    .quad fpr_fn_applyKey_x5ffb_x5f10
    .quad 3
    .quad 0

    .balign 8
fpr_obj_applyKey_x5ffb_x5f11:
    .long 9001
    .long 0
    .quad fpr_fn_applyKey_x5ffb_x5f11
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_axis
fpr_obj_axis:
    .long 9001
    .long 0
    .quad fpr_fn_axis
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_clamp
fpr_obj_clamp:
    .long 9001
    .long 0
    .quad fpr_fn_clamp
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_frameWorker
fpr_obj_frameWorker:
    .long 9001
    .long 0
    .quad fpr_fn_frameWorker
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_hasKey
fpr_obj_hasKey:
    .long 9001
    .long 0
    .quad fpr_fn_hasKey
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_isDown
fpr_obj_isDown:
    .long 9001
    .long 0
    .quad fpr_fn_isDown
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_keyBit
fpr_obj_keyBit:
    .long 9001
    .long 0
    .quad fpr_fn_keyBit
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_keyDown
fpr_obj_keyDown:
    .long 9001
    .long 0
    .quad fpr_fn_keyDown
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_keyUp
fpr_obj_keyUp:
    .long 9001
    .long 0
    .quad fpr_fn_keyUp
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_move
fpr_obj_move:
    .long 9001
    .long 0
    .quad fpr_fn_move
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_nextFrame
fpr_obj_nextFrame:
    .long 9001
    .long 0
    .quad fpr_fn_nextFrame
    .quad 5
    .quad 0

    .balign 8
    .globl fpr_obj_player
fpr_obj_player:
    .long 9001
    .long 0
    .quad fpr_fn_player
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_pollDecoded
fpr_obj_pollDecoded:
    .long 9001
    .long 0
    .quad fpr_fn_pollDecoded
    .quad 5
    .quad 0

    .balign 8
    .globl fpr_obj_pollEvent
fpr_obj_pollEvent:
    .long 9001
    .long 0
    .quad fpr_fn_pollEvent
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_pollKeys
fpr_obj_pollKeys:
    .long 9001
    .long 0
    .quad fpr_fn_pollKeys
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_renderFrame
fpr_obj_renderFrame:
    .long 9001
    .long 0
    .quad fpr_fn_renderFrame
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_run
fpr_obj_run:
    .long 9001
    .long 0
    .quad fpr_fn_run
    .quad 5
    .quad 0

    .balign 8
.Lstr85:
    .long 9000
    .long 0
    .quad 1
    .byte 41

    .balign 8
.Lstr84:
    .long 9000
    .long 0
    .quad 2
    .byte 44, 32

    .balign 8
.Lstr80:
    .long 9000
    .long 0
    .quad 3
    .byte 98, 108, 107

    .balign 8
.Lstr53:
    .long 9000
    .long 0
    .quad 4
    .byte 99, 117, 98, 101

    .balign 8
.Lstr83:
    .long 9000
    .long 0
    .quad 36
    .byte 105, 110, 116, 101, 114, 97, 99, 116, 105, 118, 101, 95, 100, 101, 115, 107
    .byte 116, 111, 112, 95, 103, 108, 58, 32, 115, 116, 111, 112, 112, 101, 100, 32
    .byte 97, 116, 32, 40

    .balign 8
.Lstr46:
    .long 9000
    .long 0
    .quad 21
    .byte 108, 101, 116, 32, 112, 97, 116, 116, 101, 114, 110, 58, 32, 110, 111, 32
    .byte 109, 97, 116, 99, 104

    .balign 8
.Lstr52:
    .long 9000
    .long 0
    .quad 5
    .byte 112, 108, 97, 110, 101

    .balign 8
.Lstr89:
    .long 9000
    .long 0
    .quad 6
    .byte 115, 112, 104, 101, 114, 101

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

