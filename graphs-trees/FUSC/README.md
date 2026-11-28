# FUSC — Obfuscated Property (SPOJ)

<https://www.spoj.com/problems/FUSC/>

## Problem

The Fusc sequence starts with `f(0) = 0` and `f(1) = 1`, and splits by parity: `f(2n) = f(n)` and `f(2n+1) = f(n) + f(n+1)`. Given one number `n`, print the largest Fusc value at any index from 0 to `n`.

The input holds one integer up to 10^15. The output holds one integer. The range is far too large to visit every index.

| Item | Bound |
|---|---|
| Query `n` | 0 to 10^15 |
| Binary length of `n` | at most 50 |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
10
```

```
4
```

## Idea

Treat the binary digits of `n` as a path through a family tree, and keep the best branch you skip. Think of walking a staircase while noting the highest step on every landing you pass.

A full block of `2^r` indices has a peak value. That peak is a Fibonacci combination of `f(x)` and `f(x+1)`. The walk follows `n`'s digits and scores the skipped half whenever a digit is 1.

Each bit costs constant work. Visiting every index up to `n` would take exponential time in the bit length.

A Fibonacci table and one pass over the bits answer the query.

## Why It Works

1. Writing the pair `(f(x), f(x+1))` as `(a, b)`, the left child `2x` has pair `(a, a+b)` and the right child `2x+1` has pair `(a+b, b)`. A binary digit chooses one child.
2. The maximum over a full block of `r` remaining bits is `max(F[r+1]a + F[r]b, F[r]a + F[r+1]b)`, where `F[0]=0` and `F[1]=1`. Each extra bit adds two Fibonacci-weighted terms.
3. When the current digit is 1, the left child's whole block lies at or below `n`, so it can be scored and forgotten. When the digit is 0, that block lies beyond `n`, so the walk simply continues.

| Term | Meaning |
|---|---|
| `leftValue` | `f(x)` for the current prefix `x` |
| `rightValue` | `f(x+1)` for the current prefix `x` |
| `remainingBits` | how many digits are still unread |
| `fib` | Fibonacci numbers used by the block formula |

The pair and the bit count are the whole state of the walk.

A traced run of the sample `n = 10`:

```
n = 10, binary 1010, remaining bits after leading 1: 0 1 0
start: answer = F4 = 3        (full block below 8)
bit 0: pair (1,1) -> (1,2), no skipped block
bit 1: skipped block pair (1,3), r=1 -> max(1+3,1+3) = 4
       pair (1,2) -> (3,2)
bit 0: pair (3,2) -> (3,5), no skipped block
final: f(10) = 3
answer = max(3, 4, 3) = 4
```

The trace prints 4, which matches the sample output.

## Code

**Fibonacci table and block maximum.** Built once before the query.

```nim
var fib: array[64, int64]
fib[0] = 0
fib[1] = 1
for index in 2 .. 63:
  fib[index] = fib[index - 1] + fib[index - 2]

proc subtreeMax(leftValue, rightValue: int64, remaining: int): int64 =
  if remaining == 0: return leftValue
  let higher = fib[remaining + 1]
  let lower = fib[remaining]
  return max(higher * leftValue + lower * rightValue,
             lower * leftValue + higher * rightValue)
```

The table covers 50 binary digits with room to spare. The `remaining == 0` case returns the exact Fusc value at the prefix.

**Binary walk.** One iteration per bit of `n`.

```nim
  var remainingDigits = ""
  var temporary = limit
  while temporary > 1:
    remainingDigits.add char(firstDigitValue + int(temporary mod 2))
    temporary = temporary div 2

  var remainingBits = remainingDigits.len
  var answer = fib[remainingBits + 1]
  var leftValue = 1'i64
  var rightValue = 1'i64
```

`remainingDigits` is built least significant first and read back in reverse. The initial answer is the full block below the leading bit.

```nim
  var digitIndex = remainingDigits.len - 1
  while digitIndex >= 0:
    remainingBits -= 1
    if remainingDigits[digitIndex] == '1':
      answer = max(answer, subtreeMax(leftValue, leftValue + rightValue, remainingBits))
      leftValue = leftValue + rightValue
    else:
      let nextRight = leftValue + rightValue
      rightValue = nextRight
    digitIndex -= 1
```

A digit of 1 scores the left child before moving right. A digit of 0 only updates the pair. The loop ends after the last bit.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| Fibonacci table | 64 additions, once | 64 integers |
| Binary walk | one block evaluation per bit | constant |
| Output | one write of one line | one buffer |

The bit length of `n` drives the run.

| Measure | Big O |
|---|---|
| Time | O(log n) per query |
| Space | O(log n) for the Fibonacci table |

Visiting all indices up to 10^15 would take 10^15 steps. The binary walk finishes in about 50 steps.
