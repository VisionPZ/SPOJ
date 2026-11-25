# G10183 — Divide Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10183/>

Judge status: submissions return "Missing testcases", so the problem has no
test data and cannot be accepted. The solution below reproduces the statement
sample byte for byte in the local harness.

## Problem

Each input line holds a positive integer of up to 50 digits; a line with `0` ends the input. For every number, print it, then repeatedly delete its last digit and subtract that deleted digit from what remains, printing each result, while the result has more than two digits. Finally print whether the original number is divisible by 11, in Spanish, and leave a blank line after each case.

| Item | Bound |
|---|---|
| Number length | ≤ 50 digits |
| Input | one number per line, ends at 0 |
| Judge limit | 1000 ms, 1536 MB |

The sample case (first number only):

```
12345678901234567900
```

```
12345678901234567900
1234567890123456790
123456789012345679
12345678901234558
1234567890123447
123456789012337
12345678901226
1234567890116
123456789005
12345678895
1234567884
123456784
12345674
1234563
123453
12342
1232
121
11
El numero 12345678901234567900 es divisible por 11.
```

## Idea

The statement hands you the algorithm: chop the last digit, subtract it, repeat. Run it with Python big integers, where chopping is `divmod` by 10 and the step is one subtraction. Think of peeling layers off an onion: each peel is one digit shorter. A number shrinks by at least one digit per step, so at most about 48 steps run per case. Checking divisibility only at the end avoids testing every intermediate value.

## Why It Works

1. `divmod(n, 10)` splits n into the number without its last digit and the last digit.
2. The step `truncated - lastDigit` never goes negative for numbers with three or more digits, because the truncated part is at least 10.
3. The statement guarantees the original number is divisible by 11 exactly when the final two-digit-or-smaller result is.
4. `len(str(n)) > 2` is the loop guard, so `11` prints and then stops.

| Term | Meaning |
|---|---|
| `remainingValue` | the number as the peeling process shrinks it |
| `originalText` | the input number as text, used in the verdict |
| `stepLines` | the printed sequence, starting with the original |
| `truncatedValue` | the number minus its last digit |
| `lastDigit` | the digit just deleted |

The verdict line quotes the original number, not the shrunken one.

A script-traced example from `gen.py`:

```
start 121
peel: 12 - 1 = 11
stop: 11 has two digits
11 % 11 == 0, so the verdict is divisible
```

The trace matches the sample's ending.

## Code

**Line loop.** This block reads each number and peels its digits.

```python
    remainingValue = int(numberText)
    originalText = str(remainingValue)
    stepLines = [originalText]
    while len(str(remainingValue)) > 2:
        truncatedValue, lastDigit = divmod(remainingValue, 10)
        remainingValue = truncatedValue - lastDigit
        stepLines.append(str(remainingValue))
```

`int()` handles 50-digit values natively.
The guard stops as soon as two digits remain.
Each peel costs one divmod and one subtraction.

**Verdict and blank line.** This block builds the message and the case block.

```python
    if remainingValue % divisorValue == 0:
        verdictText = "El numero " + originalText + " es divisible por 11."
    else:
        verdictText = "El numero " + originalText + " no es divisible por 11."
    caseBlocks.append("\n".join(stepLines) + "\n" + verdictText + "\n")
```

The modulo test runs on the small final value.
Each block ends with a newline, so joining blocks with `\n` leaves the required blank line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Peeling | ≤ 48 steps per number | step strings |
| Output | one write | case blocks |

| Measure | Big O |
|---|---|
| Time | O(lines × digits) |
| Space | O(N) for the input buffer |

A per-step divisibility test would add work the statement never asks for.
