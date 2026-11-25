# BUET19A — Mod (SPOJ)

<https://www.spoj.com/problems/BUET19A/>

## Problem

Gon and Killua play rock-paper-scissors by shouting numbers. A number means ROCK when n % 3 == 0, PAPER when n % 3 == 1, and SCISSORS when n % 3 == 2. The usual rules decide the winner; equal gestures draw. Print GON, KILLUA, or DRAW for each case.

| Item | Bound |
|---|---|
| Test cases | 1 ≤ T ≤ 100000 |
| X, Y | stated 1..100000; the sample also uses 0 |
| Judge limit | 1000 ms, 1536 MB |
| Language | C++ (g++ 4.3.2) |

The sample case:

```
3
0 1
1 0
3 3
```

```
KILLUA
GON
DRAW
```

## Idea

Reduce both numbers modulo 3, then compare the residues. In the cycle ROCK(0) → PAPER(1) → SCISSORS(2) → ROCK(0), each gesture is beaten by the residue that follows it. So Gon wins exactly when (rx - ry) mod 3 == 1.

## Why It Works

1. The remainder mod 3 is the gesture, by the statement's own mapping.
2. Equal remainders mean equal gestures, which is a DRAW.
3. PAPER(1) beats ROCK(0): 1 - 0 = 1. SCISSORS(2) beats PAPER(1): 2 - 1 = 1. ROCK(0) beats SCISSORS(2): 0 - 2 = -2 ≡ 1 (mod 3). So a residue difference of 1 always means Gon's gesture wins.
4. Adding 3 before the final % 3 keeps the difference non-negative, so C's remainder sign is never a problem.
5. Every other case is Killua's win.

| Term | Meaning |
|---|---|
| `gonSign` | Gon's gesture as 0, 1, or 2 |
| `killuaSign` | Killua's gesture as 0, 1, or 2 |
| `(gonSign - killuaSign + 3) % 3 == 1` | Gon's gesture beats Killua's |

A script-traced example from `gen.py`:

```
X = 0, Y = 1
rx = 0 (ROCK), ry = 1 (PAPER)
(0 - 1 + 3) % 3 = 2, not 1
KILLUA wins, matching the sample
```

The trace matches the first sample answer.

## Code

**Case loop.** This block reads each pair of numbers.

```cpp
#include <cstdio>

int main() {
    int caseCount = 0;
    if (scanf("%d", &caseCount) != 1) return 0;
    while (caseCount--) {
        long long gonNumber = 0;
        long long killuaNumber = 0;
        scanf("%lld %lld", &gonNumber, &killuaNumber);
```

`long long` leaves room for any input size beyond the stated bound.
The loop runs exactly T times.

**Gesture decision.** This block maps residues to an outcome.

```cpp
        int gonSign = (int)(gonNumber % 3);
        int killuaSign = (int)(killuaNumber % 3);
        if (gonSign == killuaSign) {
            puts("DRAW");
        } else if ((gonSign - killuaSign + 3) % 3 == 1) {
            puts("GON");
        } else {
            puts("KILLUA");
        }
    }
    return 0;
}
```

Three comparisons decide each case.
The +3 shift keeps the modulo argument positive.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | two `scanf` per case | constant |
| Decision | O(1) per case | constant |
| Output | one line per case | constant |

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(1) |

A gesture-name table would cost the same; the residue arithmetic skips the strings entirely.
