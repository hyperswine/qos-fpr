# target: qa64 (lowered from the rv64 emission; QOS Portable single-hart globals)
    .text
    .balign 4

# Caps@a82bc70d8864e55d (arity 6)
fpr_fn_Caps_x40a82bc70d8864e55d:
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
    b.gt .Lfuel0
    bl fpr_fuel_exhausted
.Lfuel0:
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
    movz x9, #6720
    movk x9, #31190, lsl #16
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

# wcet: Caps@a82bc70d8864e55d segmax=47 exittail=47 ccalls=1
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
    b.gt .Lfuel1
    bl fpr_fuel_exhausted
.Lfuel1:
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
    b.gt .Lfuel4
    bl fpr_fuel_exhausted
.Lfuel4:
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
# IErr@a82bc70d8864e55d (arity 1)
fpr_fn_IErr_x40a82bc70d8864e55d:
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
    movz x9, #54751
    movk x9, #27504, lsl #16
    stur w9, [x0, #0]
    mov x9, #4
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: IErr@a82bc70d8864e55d segmax=17 exittail=17 ccalls=1
# IFn@a82bc70d8864e55d (arity 1)
fpr_fn_IFn_x40a82bc70d8864e55d:
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
    b.gt .Lfuel6
    bl fpr_fuel_exhausted
.Lfuel6:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #54751
    movk x9, #27504, lsl #16
    stur w9, [x0, #0]
    mov x9, #3
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: IFn@a82bc70d8864e55d segmax=17 exittail=17 ccalls=1
# IInt@a82bc70d8864e55d (arity 1)
fpr_fn_IInt_x40a82bc70d8864e55d:
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
    movz x9, #54751
    movk x9, #27504, lsl #16
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

# wcet: IInt@a82bc70d8864e55d segmax=17 exittail=17 ccalls=1
# IStr@a82bc70d8864e55d (arity 1)
fpr_fn_IStr_x40a82bc70d8864e55d:
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
    movz x9, #54751
    movk x9, #27504, lsl #16
    stur w9, [x0, #0]
    mov x9, #2
    stur w9, [x0, #4]
    ldur x10, [sp, #0]
    add sp, sp, #16
    stur x10, [x0, #8]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: IStr@a82bc70d8864e55d segmax=17 exittail=17 ccalls=1
# IUnit@a82bc70d8864e55d (arity 0)
fpr_fn_IUnit_x40a82bc70d8864e55d:
    sub sp, sp, #32
    stur x30, [sp, #24]
    stur x29, [sp, #16]
    add x29, sp, #32
    mov  x9, x28
    ldur x10, [x9, #0]
    sub x10, x10, #1
    stur x10, [x9, #0]
    cmp x10, #0
    b.gt .Lfuel9
    bl fpr_fuel_exhausted
.Lfuel9:
    adrp x0, .Lnul_1802556895_0
    add x0, x0, :lo12:.Lnul_1802556895_0
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: IUnit@a82bc70d8864e55d segmax=9 exittail=9 ccalls=0
# Io4 (arity 4)
fpr_fn_Io4:
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
    b.gt .Lfuel10
    bl fpr_fuel_exhausted
.Lfuel10:
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
    movz x9, #43456
    movk x9, #14858, lsl #16
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

# wcet: Io4 segmax=35 exittail=35 ccalls=1
# LFix@28388960a8f6aa26 (arity 1)
fpr_fn_LFix_x4028388960a8f6aa26:
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
    b.gt .Lfuel11
    bl fpr_fuel_exhausted
.Lfuel11:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #18702
    movk x9, #30951, lsl #16
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

# wcet: LFix@28388960a8f6aa26 segmax=17 exittail=17 ccalls=1
# LFlex@28388960a8f6aa26 (arity 1)
fpr_fn_LFlex_x4028388960a8f6aa26:
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
    b.gt .Lfuel12
    bl fpr_fuel_exhausted
.Lfuel12:
    ldur x0, [x29, #-24]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #16
    bl fpr_alloc
    movz x9, #18702
    movk x9, #30951, lsl #16
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

# wcet: LFlex@28388960a8f6aa26 segmax=17 exittail=17 ccalls=1
# Man (arity 5)
fpr_fn_Man:
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
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #48
    bl fpr_alloc
    movz x9, #63836
    movk x9, #27081, lsl #16
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

# wcet: Man segmax=41 exittail=41 ccalls=1
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
    b.gt .Lfuel14
    bl fpr_fuel_exhausted
.Lfuel14:
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
    b.gt .Lfuel15
    bl fpr_fuel_exhausted
.Lfuel15:
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
# Rec@7909d1a494a78ef2 (arity 4)
fpr_fn_Rec_x407909d1a494a78ef2:
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
    mov x0, #40
    bl fpr_alloc
    movz x9, #27065
    movk x9, #10986, lsl #16
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

# wcet: Rec@7909d1a494a78ef2 segmax=35 exittail=35 ccalls=1
# Rpc@a82bc70d8864e55d (arity 4)
fpr_fn_Rpc_x40a82bc70d8864e55d:
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
    mov x0, #40
    bl fpr_alloc
    movz x9, #63512
    movk x9, #9655, lsl #16
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

# wcet: Rpc@a82bc70d8864e55d segmax=35 exittail=35 ccalls=1
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
    b.gt .Lfuel18
    bl fpr_fuel_exhausted
.Lfuel18:
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
    b.gt .Lfuel19
    bl fpr_fuel_exhausted
.Lfuel19:
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
    b.gt .Lfuel20
    bl fpr_fuel_exhausted
.Lfuel20:
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
    b.gt .Lfuel21
    bl fpr_fuel_exhausted
.Lfuel21:
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
    b.gt .Lfuel22
    bl fpr_fuel_exhausted
.Lfuel22:
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
    b.gt .Lfuel23
    bl fpr_fuel_exhausted
.Lfuel23:
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
    b.gt .Lfuel24
    bl fpr_fuel_exhausted
.Lfuel24:
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
    b.gt .Lfuel25
    bl fpr_fuel_exhausted
.Lfuel25:
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
    b.gt .Lfuel26
    bl fpr_fuel_exhausted
.Lfuel26:
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
    b.gt .Lfuel27
    bl fpr_fuel_exhausted
.Lfuel27:
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
    b.gt .Lfuel28
    bl fpr_fuel_exhausted
.Lfuel28:
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
# eachM0@15b788aa3785ae48 (arity 2)
    .globl fpr_fn_eachM0_x4015b788aa3785ae48
fpr_fn_eachM0_x4015b788aa3785ae48:
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
    b.gt .Lfuel38
    bl fpr_fuel_exhausted
.Lfuel38:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf29
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf29
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf29
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd30
.Ltagf29:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd30:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse36
    bl fpr_fn_Unit
    b .Lendif37
.Lelse36:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf31
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf31
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf31
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd32
.Ltagf31:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd32:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse34
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
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-80]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_eachM0_x4015b788aa3785ae48
    b .Lendif35
.Lelse34:
    adrp x0, .Lstr33
    add x0, x0, :lo12:.Lstr33
    bl fpr_panic
.Lendif35:
.Lendif37:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: eachM0@15b788aa3785ae48 segmax=46 exittail=46 ccalls=2
# eachM@15b788aa3785ae48 (arity 3)
    .globl fpr_fn_eachM_x4015b788aa3785ae48
fpr_fn_eachM_x4015b788aa3785ae48:
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
    b.gt .Lfuel47
    bl fpr_fuel_exhausted
.Lfuel47:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf39
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf39
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf39
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd40
.Ltagf39:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd40:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse45
    bl fpr_fn_Unit
    b .Lendif46
.Lelse45:
    ldur x0, [x29, #-72]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf41
    ldursw x9, [x0, #0]
    mov x10, #2
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
    cbz x9, .Lelse43
    ldur x0, [x29, #-72]
    ldur x0, [x0, #8]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x0, [x0, #16]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-48]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-96]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    ldur x2, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_eachM_x4015b788aa3785ae48
    b .Lendif44
.Lelse43:
    adrp x0, .Lstr33
    add x0, x0, :lo12:.Lstr33
    bl fpr_panic
.Lendif44:
.Lendif46:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: eachM@15b788aa3785ae48 segmax=49 exittail=49 ccalls=2
# init@15b788aa3785ae48 (arity 3)
    .globl fpr_fn_init_x4015b788aa3785ae48
fpr_fn_init_x4015b788aa3785ae48:
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
    b.gt .Lfuel48
    bl fpr_fuel_exhausted
.Lfuel48:
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
    mov x0, #3
    stur x0, [x29, #-88]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    ldur x2, [x29, #-88]
    bl fpr_fn_eachM_x4015b788aa3785ae48
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_eachM0_x4015b788aa3785ae48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: init@15b788aa3785ae48 segmax=15 exittail=15 ccalls=0
# keyAt@15b788aa3785ae48 (arity 2)
    .globl fpr_fn_keyAt_x4015b788aa3785ae48
fpr_fn_keyAt_x4015b788aa3785ae48:
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
    b.gt .Lfuel50
    bl fpr_fuel_exhausted
.Lfuel50:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    adrp x0, fpr_g_charAt
    add x0, x0, :lo12:fpr_g_charAt
    sub sp, sp, #16
    stur x0, [sp, #0]
    adrp x0, .Lstr49
    add x0, x0, :lo12:.Lstr49
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    mov x0, #3
    stur x0, [x29, #-80]
    ldur x0, [x29, #-72]
    ldur x1, [x29, #-80]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-64]
    mov x0, #9
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    bl fpr_prim_fn__x2a
    stur x0, [x29, #-56]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x1, [x29, #-64]
    bl fpr_prim_fn__x2b
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

# wcet: keyAt@15b788aa3785ae48 segmax=41 exittail=41 ccalls=4
# nth1@15b788aa3785ae48 (arity 2)
    .globl fpr_fn_nth1_x4015b788aa3785ae48
fpr_fn_nth1_x4015b788aa3785ae48:
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
    b.gt .Lfuel69
    bl fpr_fuel_exhausted
.Lfuel69:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-40]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-48]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf51
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf51
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf51
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd52
.Ltagf51:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd52:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse67
    mov x0, #1
    stur x0, [x29, #-64]
    mov x0, #3
    stur x0, [x29, #-72]
    ldur x0, [x29, #-64]
    ldur x1, [x29, #-72]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_prim_fn__x2d
    b .Lendif68
.Lelse67:
    ldur x0, [x29, #-56]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf53
    ldursw x9, [x0, #0]
    mov x10, #2
    cmp x9, x10
    b.ne .Ltagf53
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf53
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd54
.Ltagf53:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd54:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse65
    ldur x0, [x29, #-56]
    ldur x0, [x0, #8]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-56]
    ldur x0, [x0, #16]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    mov x0, #3
    stur x0, [x29, #-88]
    ldur x0, [x29, #-80]
    ldur x1, [x29, #-88]
    bl fpr_prim_fn__x3d_x3d
    stur x0, [x29, #-80]
    ldur x0, [x29, #-80]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf55
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf55
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf55
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd56
.Ltagf55:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd56:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse62
    ldur x0, [x29, #-64]
    b .Lendif63
.Lelse62:
    ldur x0, [x29, #-80]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf57
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf57
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf57
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd58
.Ltagf57:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd58:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse60
    ldur x0, [x29, #-72]
    stur x0, [x29, #-88]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-104]
    mov x0, #3
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_prim_fn__x2d
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_nth1_x4015b788aa3785ae48
    b .Lendif61
.Lelse60:
    adrp x0, .Lstr59
    add x0, x0, :lo12:.Lstr59
    bl fpr_panic
.Lendif61:
.Lendif63:
    b .Lendif66
.Lelse65:
    adrp x0, .Lstr64
    add x0, x0, :lo12:.Lstr64
    bl fpr_panic
.Lendif66:
.Lendif68:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: nth1@15b788aa3785ae48 segmax=106 exittail=106 ccalls=4
# scCol@15b788aa3785ae48 (arity 4)
    .globl fpr_fn_scCol_x4015b788aa3785ae48
fpr_fn_scCol_x4015b788aa3785ae48:
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
    b.gt .Lfuel78
    bl fpr_fuel_exhausted
.Lfuel78:
    ldur x0, [x29, #-24]
    stur x0, [x29, #-56]
    ldur x0, [x29, #-32]
    stur x0, [x29, #-64]
    ldur x0, [x29, #-40]
    stur x0, [x29, #-72]
    ldur x0, [x29, #-48]
    stur x0, [x29, #-80]
    ldur x0, [x29, #-56]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-64]
    stur x0, [x29, #-96]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    ldur x1, [x29, #-104]
    bl fpr_fn_nth1_x4015b788aa3785ae48
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #1
    ldur x0, [sp, #16]
    bl fpr_applyN
    add sp, sp, #32
    stur x0, [x29, #-88]
    mov x0, #3
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3d_x3d
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf70
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf70
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf70
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd71
.Ltagf70:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd71:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse76
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
    b fpr_fn_keyAt_x4015b788aa3785ae48
    b .Lendif77
.Lelse76:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf72
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf72
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf72
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd73
.Ltagf72:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd73:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse74
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
    b fpr_fn_scCols_x4015b788aa3785ae48
    b .Lendif75
.Lelse74:
    adrp x0, .Lstr59
    add x0, x0, :lo12:.Lstr59
    bl fpr_panic
.Lendif75:
.Lendif77:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: scCol@15b788aa3785ae48 segmax=38 exittail=38 ccalls=4
# scCols@15b788aa3785ae48 (arity 4)
    .globl fpr_fn_scCols_x4015b788aa3785ae48
fpr_fn_scCols_x4015b788aa3785ae48:
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
    b.gt .Lfuel87
    bl fpr_fuel_exhausted
.Lfuel87:
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
    mov x0, #9
    stur x0, [x29, #-96]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-88]
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf79
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf79
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf79
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd80
.Ltagf79:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd80:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse85
    mov x0, #1
    b .Lendif86
.Lelse85:
    ldur x0, [x29, #-88]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf81
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf81
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf81
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd82
.Ltagf81:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd82:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse83
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
    b fpr_fn_scCol_x4015b788aa3785ae48
    b .Lendif84
.Lelse83:
    adrp x0, .Lstr59
    add x0, x0, :lo12:.Lstr59
    bl fpr_panic
.Lendif84:
.Lendif86:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: scCols@15b788aa3785ae48 segmax=62 exittail=62 ccalls=2
# scGo@15b788aa3785ae48 (arity 5)
    .globl fpr_fn_scGo_x4015b788aa3785ae48
fpr_fn_scGo_x4015b788aa3785ae48:
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
    b.gt .Lfuel96
    bl fpr_fuel_exhausted
.Lfuel96:
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
    mov x0, #9
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_prim_fn__x3e
    stur x0, [x29, #-104]
    ldur x0, [x29, #-104]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf88
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf88
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf88
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd89
.Ltagf88:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd89:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse94
    mov x0, #1
    b .Lendif95
.Lelse94:
    ldur x0, [x29, #-104]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf90
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf90
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf90
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd91
.Ltagf90:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd91:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse92
    ldur x0, [x29, #-64]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-72]
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
    b fpr_fn_scRow_x4015b788aa3785ae48
    b .Lendif93
.Lelse92:
    adrp x0, .Lstr59
    add x0, x0, :lo12:.Lstr59
    bl fpr_panic
.Lendif93:
.Lendif95:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: scGo@15b788aa3785ae48 segmax=67 exittail=67 ccalls=2
# scRow@15b788aa3785ae48 (arity 5)
    .globl fpr_fn_scRow_x4015b788aa3785ae48
fpr_fn_scRow_x4015b788aa3785ae48:
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
    b.gt .Lfuel105
    bl fpr_fuel_exhausted
.Lfuel105:
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
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-104]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-104]
    ldur x1, [x29, #-112]
    bl fpr_fn_nth1_x4015b788aa3785ae48
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #3
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-104]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-112]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-128]
    mov x0, #3
    stur x0, [x29, #-136]
    ldur x0, [x29, #-112]
    ldur x1, [x29, #-120]
    ldur x2, [x29, #-128]
    ldur x3, [x29, #-136]
    bl fpr_fn_scCols_x4015b788aa3785ae48
    stur x0, [x29, #-112]
    ldur x0, [x29, #-64]
    sub sp, sp, #16
    stur x0, [sp, #0]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-120]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-128]
    ldur x0, [x29, #-120]
    ldur x1, [x29, #-128]
    bl fpr_fn_nth1_x4015b788aa3785ae48
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x0, #1
    sub sp, sp, #16
    stur x0, [sp, #0]
    mov x2, sp
    mov x1, #2
    ldur x0, [sp, #32]
    bl fpr_applyN
    add sp, sp, #48
    stur x0, [x29, #-120]
    ldur x0, [x29, #-112]
    stur x0, [x29, #-128]
    mov x0, #1
    stur x0, [x29, #-136]
    ldur x0, [x29, #-128]
    ldur x1, [x29, #-136]
    bl fpr_prim_fn__x3d_x3d
    stur x0, [x29, #-128]
    ldur x0, [x29, #-128]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf97
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf97
    ldursw x9, [x0, #4]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf97
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd98
.Ltagf97:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd98:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse103
    ldur x0, [x29, #-64]
    stur x0, [x29, #-136]
    ldur x0, [x29, #-72]
    stur x0, [x29, #-144]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-152]
    ldur x0, [x29, #-88]
    stur x0, [x29, #-160]
    ldur x0, [x29, #-96]
    stur x0, [x29, #-176]
    mov x0, #3
    stur x0, [x29, #-184]
    ldur x0, [x29, #-176]
    ldur x1, [x29, #-184]
    bl fpr_prim_fn__x2b
    stur x0, [x29, #-168]
    ldur x0, [x29, #-136]
    ldur x1, [x29, #-144]
    ldur x2, [x29, #-152]
    ldur x3, [x29, #-160]
    ldur x4, [x29, #-168]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_scGo_x4015b788aa3785ae48
    b .Lendif104
.Lelse103:
    ldur x0, [x29, #-128]
    mov x16, #1
    and x9, x0, x16
    cbnz x9, .Ltagf99
    ldursw x9, [x0, #0]
    mov x10, #1
    cmp x9, x10
    b.ne .Ltagf99
    ldursw x9, [x0, #4]
    mov x10, #0
    cmp x9, x10
    b.ne .Ltagf99
    adrp x0, fpr_true
    add x0, x0, :lo12:fpr_true
    b .Ltagd100
.Ltagf99:
    adrp x0, fpr_false
    add x0, x0, :lo12:fpr_false
.Ltagd100:
    ldursw x9, [x0, #4]
    cbz x9, .Lelse101
    ldur x0, [x29, #-112]
    b .Lendif102
.Lelse101:
    adrp x0, .Lstr59
    add x0, x0, :lo12:.Lstr59
    bl fpr_panic
.Lendif102:
.Lendif104:
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: scRow@15b788aa3785ae48 segmax=58 exittail=58 ccalls=5
# scan@15b788aa3785ae48 (arity 4)
    .globl fpr_fn_scan_x4015b788aa3785ae48
fpr_fn_scan_x4015b788aa3785ae48:
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
    b.gt .Lfuel106
    bl fpr_fuel_exhausted
.Lfuel106:
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
    stur x0, [x29, #-104]
    ldur x0, [x29, #-80]
    stur x0, [x29, #-112]
    mov x0, #3
    stur x0, [x29, #-120]
    ldur x0, [x29, #-88]
    ldur x1, [x29, #-96]
    ldur x2, [x29, #-104]
    ldur x3, [x29, #-112]
    ldur x4, [x29, #-120]
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    b fpr_fn_scGo_x4015b788aa3785ae48
    ldur x30, [x29, #-8]
    mov x9, x29
    ldur x29, [x29, #-16]
    mov sp, x9
    ret

# wcet: scan@15b788aa3785ae48 segmax=27 exittail=27 ccalls=0
    .section .rodata

    .balign 8
fpr_obj_Caps_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_Caps_x40a82bc70d8864e55d
    .quad 6
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
fpr_obj_IErr_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_IErr_x40a82bc70d8864e55d
    .quad 1
    .quad 0

    .balign 8
fpr_obj_IFn_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_IFn_x40a82bc70d8864e55d
    .quad 1
    .quad 0

    .balign 8
fpr_obj_IInt_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_IInt_x40a82bc70d8864e55d
    .quad 1
    .quad 0

    .balign 8
fpr_obj_IStr_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_IStr_x40a82bc70d8864e55d
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Io4:
    .long 9001
    .long 0
    .quad fpr_fn_Io4
    .quad 4
    .quad 0

    .balign 8
fpr_obj_LFix_x4028388960a8f6aa26:
    .long 9001
    .long 0
    .quad fpr_fn_LFix_x4028388960a8f6aa26
    .quad 1
    .quad 0

    .balign 8
fpr_obj_LFlex_x4028388960a8f6aa26:
    .long 9001
    .long 0
    .quad fpr_fn_LFlex_x4028388960a8f6aa26
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Man:
    .long 9001
    .long 0
    .quad fpr_fn_Man
    .quad 5
    .quad 0

    .balign 8
fpr_obj_Ok:
    .long 9001
    .long 0
    .quad fpr_fn_Ok
    .quad 1
    .quad 0

    .balign 8
fpr_obj_Rec_x407909d1a494a78ef2:
    .long 9001
    .long 0
    .quad fpr_fn_Rec_x407909d1a494a78ef2
    .quad 4
    .quad 0

    .balign 8
fpr_obj_Rpc_x40a82bc70d8864e55d:
    .long 9001
    .long 0
    .quad fpr_fn_Rpc_x40a82bc70d8864e55d
    .quad 4
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
    .globl fpr_obj_eachM0_x4015b788aa3785ae48
fpr_obj_eachM0_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_eachM0_x4015b788aa3785ae48
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_eachM_x4015b788aa3785ae48
fpr_obj_eachM_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_eachM_x4015b788aa3785ae48
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_init_x4015b788aa3785ae48
fpr_obj_init_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_init_x4015b788aa3785ae48
    .quad 3
    .quad 0

    .balign 8
    .globl fpr_obj_keyAt_x4015b788aa3785ae48
fpr_obj_keyAt_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_keyAt_x4015b788aa3785ae48
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_nth1_x4015b788aa3785ae48
fpr_obj_nth1_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_nth1_x4015b788aa3785ae48
    .quad 2
    .quad 0

    .balign 8
    .globl fpr_obj_scCol_x4015b788aa3785ae48
fpr_obj_scCol_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_scCol_x4015b788aa3785ae48
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_scCols_x4015b788aa3785ae48
fpr_obj_scCols_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_scCols_x4015b788aa3785ae48
    .quad 4
    .quad 0

    .balign 8
    .globl fpr_obj_scGo_x4015b788aa3785ae48
fpr_obj_scGo_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_scGo_x4015b788aa3785ae48
    .quad 5
    .quad 0

    .balign 8
    .globl fpr_obj_scRow_x4015b788aa3785ae48
fpr_obj_scRow_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_scRow_x4015b788aa3785ae48
    .quad 5
    .quad 0

    .balign 8
    .globl fpr_obj_scan_x4015b788aa3785ae48
fpr_obj_scan_x4015b788aa3785ae48:
    .long 9001
    .long 0
    .quad fpr_fn_scan_x4015b788aa3785ae48
    .quad 4
    .quad 0

    .balign 8
.Lstr49:
    .long 9000
    .long 0
    .quad 16
    .byte 49, 50, 51, 65, 52, 53, 54, 66, 55, 56, 57, 67, 42, 48, 35, 68

    .balign 8
.Lstr33:
    .long 9000
    .long 0
    .quad 84
    .byte 99, 97, 115, 101, 58, 32, 110, 111, 32, 109, 97, 116, 99, 104, 105, 110
    .byte 103, 32, 112, 97, 116, 116, 101, 114, 110, 59, 32, 97, 114, 109, 115, 32
    .byte 119, 101, 114, 101, 32, 91, 80, 67, 111, 110, 32, 34, 78, 105, 108, 34
    .byte 32, 91, 93, 44, 80, 67, 111, 110, 32, 34, 67, 111, 110, 115, 34, 32
    .byte 91, 80, 86, 97, 114, 32, 34, 112, 34, 44, 80, 86, 97, 114, 32, 34
    .byte 114, 34, 93, 93

    .balign 8
.Lstr64:
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
.Lstr59:
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

    .balign 8
.Lnul_1802556895_0:
    .long 1802556895
    .long 0

