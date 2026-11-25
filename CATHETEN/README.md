# CATHETEN — Shared cathetus (easy) (SPOJ)

<https://www.spoj.com/problems/CATHETEN/>

## Problem

Count the right triangles that use a given integer as one leg. Print that count for every test value.

Input starts with T, then T lines holding one integer n. Print one count per line.

| item | bound |
|---|---|
| test count T | 1 to 99999 |
| leg length n | 1 to 999999999 |
| judge limit | 1899 ms, 1536 MB |

The leg size sets the trial-division bound, and the test count sets the need for a prime sieve.

Sample input:

```
3
5
10
15
```

Sample output:

```
1
1
4
```

## Idea

Fixing one leg turns the triangle count into a divisor count, like pairing page numbers whose product is fixed. Write the missing leg as half the difference of two divisors of n squared. Each valid pair of divisors gives one triangle, so a factorization of n squared gives the answer without searching triangles.

## Why It Works

1. Let u = c - b and v = c + b for leg a = n.
2. Then u times v equals n squared, and v is larger than u.
3. Both u and v must have the same parity for b and c to be integers.
4. When n is odd, all divisors of n squared are odd, so every pair u < v works.
5. When n is even, halving n makes the same count reappear, because both divisors carry one factor of two.
6. A square has one unpaired divisor at its root, which produces a degenerate triangle and is removed.

| term | meaning |
|---|---|
| `core` | n when n is odd, otherwise n divided by two |
| `divisorCount` | number of divisors of core squared |
| `exponent` | power of one prime inside core |
| `triangleCount` | divisor pairs that form real triangles |

The count equals one less than the divisor count, halved.

```
n = 15, core = 15, core squared = 225
divisors of 225: 1 3 5 9 15 25 45 75 225
pairs below the root: four
F(15) = (9 - 1) / 2 = 4
```

The four pairs match the four triangles in the sample.

## Code

**Input, sieve, and output buffer.** The scanner reads positive values, and primes are sieved once.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const sieveLimit = 31623

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Reading all input once avoids token-by-token system calls.
The sieve limit covers the square root of the largest leg.
One buffer holds the answer lines.

**Prime factorization.** Each core value yields the divisor count of its square.

```nim
var composite = newSeq[bool](sieveLimit + 1)
var primeList: seq[int] = @[]
var sieveIndex = 2
while sieveIndex <= sieveLimit:
  if not composite[sieveIndex]:
    primeList.add sieveIndex
    var multipleIndex = sieveIndex * sieveIndex
    while multipleIndex <= sieveLimit:
      composite[multipleIndex] = true
      multipleIndex += sieveIndex
  sieveIndex += 1

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let legLength = nextInt(inputData, scanPos)
  var core = legLength
  if (core mod 2) == 0:
    core = core div 2
  var divisorCount: int64 = 1
  var remaining = core
  var primeIndex = 0
  while primeIndex < primeList.len:
    let primeValue = primeList[primeIndex]
    if primeValue * primeValue > remaining:
      break
    if (remaining mod primeValue) == 0:
      var exponent = 0
      while (remaining mod primeValue) == 0:
        exponent += 1
        remaining = remaining div primeValue
      divisorCount = divisorCount * int64(2 * exponent + 1)
    primeIndex += 1
  if remaining > 1:
    divisorCount = divisorCount * 3
  let triangleCount = (divisorCount - 1) div 2
  appendOutput($triangleCount)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

An odd leg keeps its full value, and an even leg is halved first.
Each prime exponent e contributes 2e+1 divisors to the square.
A leftover prime has exponent one and contributes three divisors.

## Complexity

The sieve is shared, and factorization is the only per-case work.

| phase | time | space |
|---|---|---|
| input read | one pass over T values | one input string |
| sieve | one pass up to 31623 | one boolean array |
| each case | trial division up to the square root of core | constant |
| output | one block flush | block buffer |

Most cases stop early once the remaining value drops below the next prime square.

| measure | Big O |
|---|---|
| time | O(sieve limit + T times sqrt n) |
| space | O(sieve limit) |

Enumerating triangle sides for each n would need work proportional to n, while counting divisors needs only its prime powers.
