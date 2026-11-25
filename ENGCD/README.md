# ENGCD — Greatest Common Divisor (SPOJ)
<https://www.spoj.com/problems/ENGCD/>

## Problem

Two nonzero integers are given. Print the largest positive integer dividing both.

The judge supplies one pair and expects one answer line.

| Item | Value |
|---|---|
| Input | two integers x and y, both nonzero |
| Output | one integer, the greatest common divisor |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Only one pair arrives, so one short loop settles the answer.

The statement sample follows below. Its page text loses the space between the two numbers.

```
812
```

```
4
```

## Idea

Imagine trimming a rope: keep the shorter piece and the leftover cut.
Euclid's algorithm does that with numbers, replacing a pair by its remainder pair.
Each step shrinks the larger value, so the loop runs only a few times.
Trial division tests every candidate down to one and costs far more.

The last nonzero remainder is the greatest common divisor.

## Why It Works

1. If d divides both x and y, then d also divides x mod y.
2. Therefore gcd(x, y) equals gcd(y, x mod y), and the pair shrinks each step.
3. A remainder is smaller than its divisor, so the loop cannot cycle.
4. When the remainder reaches zero, the other value is the divisor.
5. Absolute values keep the answer positive for negative inputs.

| Term | Meaning |
|---|---|
| divisor | an integer that divides another without a remainder |
| remainder | the integer left after division |
| gcd | the largest divisor shared by two integers |

These facts turn repeated division into a short, reliable loop.

A script trace of the sample uses the numbers 8 and 12.

```
gcd(8, 12)
  remainder step: (12, 8)
  remainder step: (8, 4)
  remainder step: (4, 0)
answer: 4
```

The final pair (4, 0) gives the sample answer 4.

## Code

**Euclid loop.**
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

Each pass replaces the pair by its divisor and remainder. Absolute values keep the result positive. The loop cost is logarithmic.

**Integer scanner.**
```nim
proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```

The scanner skips separators and folds digits into a 64-bit value. It walks one input buffer by index. No token objects are allocated.

**Output driver.**
```nim
let firstNumber = nextInt(inputData, scanPos)
let secondNumber = nextInt(inputData, scanPos)
appendOutput($(greatestCommonDivisor(firstNumber, secondNumber)))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The driver reads both numbers and writes one answer. The shared buffer flushes only at capacity. One newline closes the output.

## Complexity

The Euclid loop dominates the tiny input work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Euclid loop | O(log min(x, y)) steps | constant |
| Output | one buffered write | buffer block |

The step count is logarithmic in the smaller number.

| Measure | Big O |
|---|---|
| Time | O(input bytes + log min(x, y)) |
| Space | O(input bytes) |

Testing every divisor down to one would cost O(min(x, y)), so Euclid wins.
