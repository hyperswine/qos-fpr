/* SPIN model of one chan_t (actors.c): a single producer with a private
 * rt, a single consumer with a private rh, free-running 32-bit counters
 * (modelled modulo a small bound), publish = store rt after the slot
 * write (release), consume = load rt (acquire) then read ring[rh % CAP].
 * Properties: (1) the consumer never reads an unwritten slot, (2) FIFO:
 * received values are the sent sequence in order, (3) the producer's
 * full check (rt - rh == CAP) is never wrong, (4) every sent message is
 * eventually received (with a fair consumer). */
#define CAP 4
#define N 6           /* messages to send */
byte ring[CAP];
byte rt = 0;          /* published by the producer */
byte rh = 0;          /* published by the consumer */
byte sent = 0, recv = 0;
byte last = 0;        /* consumer's last received value */
bool full_seen = false;

active proctype producer() {
  byte v = 1;
  do
  :: sent < N ->
       atomic {                       /* the acquire-load of rh */
         if
         :: (rt - rh) == CAP -> full_seen = true; skip   /* would panic in C: model as retry */
         :: else -> ring[rt % CAP] = v; v++; sent++;
                    rt = rt + 1        /* release-store: publish after the slot write */
         fi
       }
  :: sent == N -> break
  od
}

active proctype consumer() {
  byte got;
  do
  :: recv < N ->
       atomic {
         if
         :: (rt - rh) > 0 ->
              got = ring[rh % CAP];
              assert(got != 0);              /* (1) slot was written */
              assert(got == last + 1);       /* (2) FIFO */
              last = got; ring[rh % CAP] = 0; recv++;
              rh = rh + 1                    /* release the slot */
         :: else -> skip
         fi
       }
  :: recv == N -> break
  od
}

ltl bounded { [] ((rt - rh) <= CAP) }          /* (3) never over-full */
ltl delivered { <> (recv == N) }                /* (4) with weak fairness */
