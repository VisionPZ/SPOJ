# ENLCD — Lowest Common Denominator (SPOJ)
<https://www.spoj.com/problems/ENLCD/>

## Problem

Two nonzero integers are given. Print the smallest positive integer divisible by both.

The judge supplies one pair and expects one answer line.

| Item | Value |
|---|---|
| Input | two integers x and y, both nonzero |
| Output | one integer, the lowest common denominator |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

One pair means one compact computation.

The statement sample follows below. Its page text loses the space between the two numbers.

```
610
```

```
30
```

## Idea

Think of two bells ringing at fixed intervals; find the first instant they ring together.
That instant is the lowest common denominator.
Compute it by dividing the first number by its gcd with the second, then multiplying.
Dividing first avoids the overflow that a direct product can cause.

The divisor relationship keeps the answer exact.

## Why It Works

1. The gcd removes every factor shared by the two numbers.
2. The first factor after division is coprime to the second number.
3. Multiplying coprime factors gives the smallest shared multiple.
4. Dividing before multiplying keeps the intermediate value small.
5. Absolute values make the result positive for negative inputs.

| Term | Meaning |
|---|---|
| gcd | the largest divisor shared by two integers |
| coprime | having a gcd of one |
| lcd | the smallest positive multiple of both integers |

The table explains why division before multiplication is safe.

A script trace of the sample uses the numbers 6 and 10.

```
gcd(6, 10) = 2
(6 / 2) * 10 = 30
```

The product 30 matches the sample output.

## Code

**Divisor helper.**
```nim
proc greatestCommonDivisor(firstValue, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  if leftValue < 0: leftValue = -leftValue
  if rightValue < 0: rightValue = -rightValue
  while rightValue != 0'i64:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

The helper applies Euclid's remainder loop. Negative inputs are made positive first.

**Multiple computation.**
```nim
proc lowestCommonMultiple(firstValue, secondValue: int64): int64 =
  var leftValue = firstValue
  if leftValue < 0: leftValue = -leftValue
  var rightValue = secondValue
  if rightValue < 0: rightValue = -rightValue
  let divisor = greatestCommonDivisor(leftValue, rightValue)
  return (leftValue div divisor) * rightValue
```

The first number is divided by the gcd before the product. The order prevents overflow.

**Output driver.**
```nim
let firstNumber = nextInt(inputData, scanPos)
let secondNumber = nextInt(inputData, scanPos)
appendOutput($(lowestCommonMultiple(firstNumber, secondNumber)))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The driver reads the pair and writes one value. The buffer flushes at capacity. A newline closes the line.

## Complexity

The gcd loop dominates the small computation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Gcd and product | O(log min(x, y)) steps | constant |
| Output | one buffered write | buffer block |

The loop shrinks the pair on every pass.

| Measure | Big O |
|---|---|
| Time | O(input bytes + log min(x, y)) |
| Space | O(input bytes) |

Scanning every multiple up to the answer would cost O(lcd(x, y)), so the divisor shortcut wins.
