# RG10 — Factores Primos Grado 10 (SPOJ)

<https://www.spoj.com/problems/RG10/>

## Problem

Read a composite natural number and write its prime factors.
List the factors from smallest to largest, with repetition.
Separate adjacent factors with a space, an x, and a space.

The statement shows two separate examples with one number each.

| Item | Bound |
|---|---|
| Input | one composite natural number |
| Output | ascending prime factors joined by " x " |
| Judge limit | 1000 ms |

Trial division only needs to reach the square root of the number.

Sample input:

```
100
```

Sample output:

```
2 x 2 x 5 x 5
```

## Idea

Imagine peeling layers off an onion until only a prime core remains.
Each layer is a divisor that leaves no remainder.
Peeling the smallest divisors first automatically sorts the factors.

Trial division tests two, then odd divisors only.
Every successful division shrinks the remaining value.
The leftover value, when greater than one, is the final prime factor.

## Why It Works

1. Any composite number has a prime divisor no larger than its square root.
2. Dividing by the smallest divisor first keeps the output sorted.
3. Repeated division extracts the full power of that divisor.
4. After all divisors up to the square root fail, the remainder is prime.

| Term | Meaning |
|---|---|
| `remaining` | the value not yet peeled into factors |
| `divisor` | the current trial divisor |
| `factorCount` | number of factors already written |

Script-generated example from `gen.py`:

```
49 -> 7 x 7
12 -> 2 x 2 x 3
```

Both examples peel the smallest divisor first.

## Code

**Input and buffered output.** This block scans every natural number in the input.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNatural(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = int64(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc hasMoreNatural(data: string, pos: int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  return probe < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner skips all non-digit bytes.
Every output write happens in 128 KiB blocks.
Multiple input numbers produce one line each.

**Factor peeling.** This block divides out factors in ascending order.

```nim
while hasMoreNatural(inputData, scanPos):
  let original = nextNatural(inputData, scanPos)
  var remaining = original
  var divisor = int64(2)
  var factorCount = 0
  while divisor <= remaining div divisor:
    while remaining mod divisor == 0:
      if factorCount > 0:
        appendOutput(" x ")
      appendOutput($(divisor))
      factorCount += 1
      remaining = remaining div divisor
    if divisor == 2:
      divisor = 3
    else:
      divisor += 2
  if remaining > 1:
    if factorCount > 0:
      appendOutput(" x ")
    appendOutput($(remaining))
    factorCount += 1
  if factorCount == 0:
    appendOutput($(original))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops once the divisor exceeds the square root.
Odd divisors skip all even candidates after two.
The separator is written only before later factors.

## Complexity

The divisor search dominates the runtime.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Factoring | O(sqrt(V)) divisions per number | constant |
| Output | one write per 128 KiB block | block buffer |

V is the value being factored.

| Measure | Big O |
|---|---|
| Time | O(sqrt(V)) per number |
| Space | O(I) for the input string |

Testing every divisor up to V would double the exponent in the bound.
Stopping at the square root halves the work at each step.
