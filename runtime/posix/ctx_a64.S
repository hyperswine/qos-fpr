/* ctx_a64.S — fpr_ctx_switch for AArch64 AAPCS64 (untested sketch:
 * wired up when the a64 posix build grows actors).  x0=save x1=load.
 * Layout: 0 = resume pc, 1 = sp, 4..13 = x19..x28, 14 = x29, and the
 * callee-saved d8-d15 in 16 extra bytes? -- NO: ctx[] is 16 words, so
 * d8-d15 are deliberately NOT saved; the runtime's switch paths do no
 * FP, which matches virt ctx.S's integer-only contract. */
#ifdef __APPLE__
#define SYM(x) _##x
#else
#define SYM(x) x
#endif
    .text
    .balign 16
    .globl SYM(fpr_ctx_switch)
SYM(fpr_ctx_switch):
    mov x9, sp
    str x30, [x0, #0]          // resume pc: our return address
    str x9,  [x0, #8]
    stp x19, x20, [x0, #32]
    stp x21, x22, [x0, #48]
    stp x23, x24, [x0, #64]
    stp x25, x26, [x0, #80]
    stp x27, x28, [x0, #96]
    str x29, [x0, #112]

    ldr x9,  [x1, #8]
    mov sp, x9
    ldp x19, x20, [x1, #32]
    ldp x21, x22, [x1, #48]
    ldp x23, x24, [x1, #64]
    ldp x25, x26, [x1, #80]
    ldp x27, x28, [x1, #96]
    ldr x29, [x1, #112]
    ldr x30, [x1, #0]
    ret
