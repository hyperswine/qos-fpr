# target: x64 (lowered from the rv64 emission -- the shared RISC IR)
    .text
    .balign 4

# Cons (arity 2)
fpr_fn_Cons:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Cons)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel0
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel0:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $24, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $2, %r10
    movl %r10d, (%rax)
    movq $1, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Cons segmax=23 exittail=23 ccalls=1
# Err (arity 1)
fpr_fn_Err:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Err)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel1
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel1:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $16, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $3, %r10
    movl %r10d, (%rax)
    movq $1, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Err segmax=17 exittail=17 ccalls=1
# False (arity 0)
fpr_fn_False:
    movq %rdi, %rax # arg0 fixup (fpr_fn_False)
    subq $32, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 24(%rsp)
    leaq 40(%rsp), %rbp
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel2
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel2:
    leaq .Lnul_1_0(%rip), %rax
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: False segmax=9 exittail=9 ccalls=0
# Handle (arity 1)
fpr_fn_Handle:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Handle)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel3
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel3:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $16, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $1455177538, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Handle segmax=17 exittail=17 ccalls=1
# Nil (arity 0)
fpr_fn_Nil:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Nil)
    subq $32, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 24(%rsp)
    leaq 40(%rsp), %rbp
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel4
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel4:
    leaq .Lnul_2_0(%rip), %rax
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Nil segmax=9 exittail=9 ccalls=0
# Ok (arity 1)
fpr_fn_Ok:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Ok)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel5
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel5:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $16, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $3, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Ok segmax=17 exittail=17 ccalls=1
# SString (arity 1)
fpr_fn_SString:
    movq %rdi, %rax # arg0 fixup (fpr_fn_SString)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel6
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel6:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $16, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $728642368, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: SString segmax=17 exittail=17 ccalls=1
# True (arity 0)
fpr_fn_True:
    movq %rdi, %rax # arg0 fixup (fpr_fn_True)
    subq $32, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 24(%rsp)
    leaq 40(%rsp), %rbp
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel7
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel7:
    leaq .Lnul_1_1(%rip), %rax
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: True segmax=9 exittail=9 ccalls=0
# Tup2 (arity 2)
fpr_fn_Tup2:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup2)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel8
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel8:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $24, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $4, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup2 segmax=23 exittail=23 ccalls=1
# Tup3 (arity 3)
fpr_fn_Tup3:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup3)
    subq $64, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 56(%rsp)
    leaq 72(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel9
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel9:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $32, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $5, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup3 segmax=29 exittail=29 ccalls=1
# Tup4 (arity 4)
fpr_fn_Tup4:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup4)
    subq $64, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 56(%rsp)
    leaq 72(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel10
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel10:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -48(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $40, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $10, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 32(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup4 segmax=35 exittail=35 ccalls=1
# Tup5 (arity 5)
fpr_fn_Tup5:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup5)
    subq $80, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 72(%rsp)
    leaq 88(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq %r8, -56(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel11
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel11:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -48(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -56(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $48, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $11, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 40(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 32(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup5 segmax=41 exittail=41 ccalls=1
# Tup6 (arity 6)
fpr_fn_Tup6:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup6)
    subq $80, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 72(%rsp)
    leaq 88(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq %r8, -56(%rbp)
    movq %r9, -64(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel12
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel12:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -48(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -56(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -64(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $56, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $12, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 48(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 40(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 32(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup6 segmax=47 exittail=47 ccalls=1
# Tup7 (arity 7)
fpr_fn_Tup7:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup7)
    subq $96, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 88(%rsp)
    leaq 104(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq %r8, -56(%rbp)
    movq %r9, -64(%rbp)
    movq fpr_g_tlsoff(%rip), %r11
    movq %fs:8(%r11), %r11
    movq %r11, -72(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel13
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel13:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -48(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -56(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -64(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -72(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $64, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $13, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 56(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 48(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 40(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 32(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup7 segmax=53 exittail=53 ccalls=1
# Tup8 (arity 8)
fpr_fn_Tup8:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Tup8)
    subq $96, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 88(%rsp)
    leaq 104(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq %rsi, -32(%rbp)
    movq %rdx, -40(%rbp)
    movq %rcx, -48(%rbp)
    movq %r8, -56(%rbp)
    movq %r9, -64(%rbp)
    movq fpr_g_tlsoff(%rip), %r11
    movq %fs:8(%r11), %r11
    movq %r11, -72(%rbp)
    movq fpr_g_tlsoff(%rip), %r11
    movq %fs:16(%r11), %r11
    movq %r11, -80(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel14
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel14:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -32(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -40(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -48(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -56(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -64(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -72(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq -80(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $72, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $14, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 64(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 56(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 48(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 40(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 32(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 24(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 16(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Tup8 segmax=59 exittail=59 ccalls=1
# Unit (arity 0)
fpr_fn_Unit:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Unit)
    subq $32, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 24(%rsp)
    leaq 40(%rsp), %rbp
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel15
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel15:
    leaq .Lnul_0_0(%rip), %rax
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Unit segmax=9 exittail=9 ccalls=0
# Vector (arity 1)
fpr_fn_Vector:
    movq %rdi, %rax # arg0 fixup (fpr_fn_Vector)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel16
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel16:
    movq -24(%rbp), %rax
    subq $16, %rsp
    movq %rax, 8(%rsp)
    movq $16, %rax
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_alloc
    addq $8, %rsp
    movq $816269435, %r10
    movl %r10d, (%rax)
    movq $0, %r10
    movl %r10d, 4(%rax)
    movq 8(%rsp), %r11
    addq $16, %rsp
    movq %r11, 8(%rax)
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: Vector segmax=17 exittail=17 ccalls=1
# mathName (arity 1)
    .globl fpr_fn_mathName
fpr_fn_mathName:
    movq %rdi, %rax # arg0 fixup (fpr_fn_mathName)
    subq $48, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 40(%rsp)
    leaq 56(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel18
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel18:
    movq -24(%rbp), %rax
    movq %rax, -32(%rbp)
    leaq .Lstr17(%rip), %rax
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: mathName segmax=10 exittail=10 ccalls=0
# mathOp (arity 1)
    .globl fpr_fn_mathOp
fpr_fn_mathOp:
    movq %rdi, %rax # arg0 fixup (fpr_fn_mathOp)
    subq $64, %rsp
    # (ra store: hardware call already placed it)
    movq %rbp, 56(%rsp)
    leaq 72(%rsp), %rbp
    movq %rax, -24(%rbp)
    movq fpr_g_tlsoff(%rip), %r10
    movq %fs:0(%r10), %r10
    movq (%r10), %r11
    addq $-1, %r11
    movq %r11, (%r10)
    cmpq $0, %r11
    jg .Lfuel19
    movq %rax, %rdi # arg0 fixup
    subq $8, %rsp # SysV call alignment
    call fpr_fuel_exhausted
    addq $8, %rsp
.Lfuel19:
    movq -24(%rbp), %rax
    movq %rax, -32(%rbp)
    movq -32(%rbp), %rax
    movq %rax, -40(%rbp)
    movq $5, %rax
    movq %rax, -48(%rbp)
    movq -40(%rbp), %rax
    movq -48(%rbp), %rsi
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    movq %rax, %rdi # arg0 fixup (tail)
    jmp fpr_prim_fn__x2a
    # (ra load: hardware ret will consume it)
    movq %rbp, %r10
    movq -16(%rbp), %rbp
    leaq -8(%r10), %rsp
    ret

# wcet: mathOp segmax=18 exittail=18 ccalls=0
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
    .globl fpr_obj_mathName
fpr_obj_mathName:
    .long 9001
    .long 0
    .quad fpr_fn_mathName
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_obj_mathOp
fpr_obj_mathOp:
    .long 9001
    .long 0
    .quad fpr_fn_mathOp
    .quad 1
    .quad 0

    .balign 8
    .globl fpr_modtab
fpr_modtab:
    .quad .Lstr20
    .quad .Lstr21
    .quad fpr_obj_mathOp
    .quad .Lstr20
    .quad .Lstr22
    .quad fpr_obj_mathName
    .quad 0

    .balign 8
.Lstr20:
    .long 9000
    .long 0
    .quad 16
    .byte 100, 53, 97, 51, 53, 54, 56, 97, 52, 101, 57, 49, 52, 55, 52, 57

    .balign 8
.Lstr17:
    .long 9000
    .long 0
    .quad 9
    .byte 100, 111, 117, 98, 108, 101, 46, 118, 49

    .balign 8
.Lstr22:
    .long 9000
    .long 0
    .quad 8
    .byte 109, 97, 116, 104, 78, 97, 109, 101

    .balign 8
.Lstr21:
    .long 9000
    .long 0
    .quad 6
    .byte 109, 97, 116, 104, 79, 112

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

