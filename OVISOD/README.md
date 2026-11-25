# OVISOD — Sum of Something (SPOJ)

<https://www.spoj.com/problems/OVISOD/>

## Problem

Each test case gives a list of integers. The task is to add all numbers that divide every integer in that list.

Input starts with a test count. Each case then holds the list length and the integers themselves. Output holds one sum per case on its own line.

| Item | Bound |
|---|---|
| Test count | 1 ≤ t ≤ 10 |
| List length | 1 ≤ n ≤ 10⁵ |
| List value | 1 ≤ aᵢ ≤ 10⁹ |
| Judge limit | 1000 ms, 1536 MB |

The value bound keeps factorization cheap once the list shrinks to one number.

The sample case:

```
3
3
4 6 8
2
15 13
1
5
```

```
3
1
6
```

## Idea

Replace the list with its greatest common divisor, then sum that number's divisors. Think of shrinking a group to the largest shared building block. The program factors the gcd by trial division and uses the prime-power sum formula. Testing every candidate up to the gcd costs far more. One factorization and one product give the answer.

## Why It Works

1. The gcd of a list is the largest integer that divides every element.
2. A number divides every element exactly when it divides the gcd.
3. For g = p₁ᵉ¹ · p₂ᵉ² · …, the divisor sum is a product of geometric sums.
4. Trial division extracts each prime once and builds its geometric sum.
5. Any factor left after division is prime and contributes 1 + that factor.
6. int64 holds the largest sum allowed by the value bound.

| Term | Meaning |
|---|---|
| `gcdValues` | Euclidean gcd of two integers |
| `divisorSum` | sum of all divisors of one value |
| `commonDivisor` | gcd accumulated over the current list |
| `remaining` | unfactored part of the gcd |
| `term` | geometric sum for one prime power |

The gcd reduces a whole list to one factorable number.

A script-traced example from `gen.py`:

```
numbers 4 6 8
gcd 2
divisors 1 2
sum 3
```

The trace matches the first sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
The scanner walks by index and skips line breaks.
Scanning costs one pass over the input integers.

**Gcd helper.** This block applies Euclid's algorithm to two values.

```nim
proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

An initial zero acts as the identity for the first element.
Each step replaces a pair with a smaller pair.
The loop costs O(log value) steps.

**Divisor sum.** This block factors the gcd and multiplies geometric sums.

```nim
proc divisorSum(value: int64): int64 =
  var remaining = value
  var total = 1.int64
  var factor = 2.int64
  while factor * factor <= remaining:
    if remaining mod factor == 0:
      var power = 1.int64
      var term = 1.int64
      while remaining mod factor == 0:
        remaining = remaining div factor
        power = power * factor
        term += power
      total *= term
    factor += 1
  if remaining > 1:
    total *= 1 + remaining
  return total
```

The loop ends when the factor exceeds the square root.
The last factor is prime, so it adds one geometric term.
Factoring costs O(√g) steps for a gcd of g.

**Buffered output and main loop.** This block emits one sum per case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let numberCount = nextInt(inputData, scanPos)
  var commonDivisor = 0.int64
  for numberIndex in 0..<numberCount:
    let currentValue = int64(nextInt(inputData, scanPos))
    commonDivisor = gcdValues(commonDivisor, currentValue)
  appendOutput($(divisorSum(commonDivisor)) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop runs exactly n times per case.
Each element folds into one running gcd.
The buffer flushes at 128 KiB and once at the end.

## Complexity

The cost splits into input, gcd folding, one factorization per case, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Gcd fold | O(log value) per element | constant |
| Divisor sum | O(√g) per case | constant |
| Output | one write per 128 KiB block | block buffer |

Factorization runs once per case, after the list collapses.

| Measure | Big O |
|---|---|
| Time | O(n log V + √V) per case |
| Space | O(N) for the input buffer |

Testing every integer up to the gcd costs O(g), which is far larger.
