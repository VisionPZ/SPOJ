# LAI1819ESUMDIV — Somma e dividi (SPOJ)

<https://www.spoj.com/problems/LAI1819ESUMDIV/>

## Problem

Five integers arrive one per line. Add them up. If the sum is even, print the sum divided by 2. If the sum is odd, print the sum divided by 5. The answer must appear as a decimal number.

The judge can place several blocks of five in one file, so the program walks the whole token stream in groups.

| Item | Bound |
|---|---|
| Integers per case | exactly 5, one per line |
| Value range | none stated in the statement |
| Judge limit | 1000 ms, 1536 MB |
| Language | Python 3 only |

The sample case:

```
2
2
2
2
2
```

```
5.0
```

## Idea

Read every number, add up each block of five, then divide by 2 when the total is even and by 5 when it is odd. Python prints a float division with the decimal point already in place, so `str(total / 2)` gives the required decimal form for free.

## Why It Works

1. Python integers hold the sum exactly, so the parity test is exact.
2. An even total divided by 2 is a whole number; printing it as a float gives the ".0" tail the statement wants.
3. An odd total divided by 5 is a decimal; the float print shows it directly.
4. Sums stay far below 2^53, so the float division is exact and prints without rounding noise.
5. The loop stops cleanly when the file ends, so trailing whitespace never breaks a case.

| Term | Meaning |
|---|---|
| `tokens` | every input number as text |
| `scanPos` | index of the next unread token |
| `total` | sum of the current block of five |
| `answers` | finished decimal strings |

A script-traced example from `gen.py`:

```
2 2 2 2 2 -> total 10 -> even -> 10 / 2 -> 5.0
```

The trace matches the sample answer.

## Code

**Reading and grouping.** This block loads all tokens and walks them in blocks of five.

```python
import sys

tokens = sys.stdin.buffer.read().split()
answers = []
scanPos = 0
tokenCount = len(tokens)
while scanPos < tokenCount:
    groupEnd = scanPos + 5
    if groupEnd > tokenCount:
        groupEnd = tokenCount
    total = 0
    for idx in range(scanPos, groupEnd):
        total += int(tokens[idx])
    scanPos = groupEnd
```

One read call collects the whole file.
The group end is clamped so a short tail never raises an error.

**Answer formatting.** This block divides and stores the decimal text.

```python
    if total % 2 == 0:
        answers.append(str(total / 2))
    else:
        answers.append(str(total / 5))
if answers:
    sys.stdout.write("\n".join(answers) + "\n")
```

Float division already prints the decimal point.
One write emits every line at the end.

## Complexity

The cost splits into input, group sums, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Group sums | O(1) per group | constant |
| Output | one write per finished line | answer strings |

| Measure | Big O |
|---|---|
| Time | O(N) for N integers |
| Space | O(N) for the token list |

A line-by-line `input()` loop costs the same asymptotically but pays five interpreter calls per case.
