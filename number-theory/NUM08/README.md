# NUM08 — Sum Of Divisiors (SPOJ)

<https://www.spoj.com/problems/NUM08/>

## Problem

For each test case, take an even number n and factor it into primes. Print one prime per line as `p e` (for p^e) in increasing order. Then print the sum of all divisors of n on a line reading `Sum Of Divisiors: X`. A blank line separates the answers of consecutive cases.

The first line holds t with 1 ≤ t ≤ 100. Each case gives one even n with n ≤ 10^14.

| item | bound |
|---|---|
| test cases t | 1 ≤ t ≤ 100 |
| value n | even, n ≤ 10^14 |
| judge limit | 1000 ms, 1536 MB |

A prime table up to 10^7 covers every possible small factor of n.

Sample input:

```
3
8
32
56
```

Sample output:

```
2 3
Sum Of Divisiors: 15

2 5
Sum Of Divisiors: 63

2 3
7 1
Sum Of Divisiors: 120
```

## Idea

Factoring a number by trial division only needs primes up to its square root. Since n ≤ 10^14, that root is at most 10^7, so one sieve of Eratosthenes up to 10^7 supplies every prime a case could ever need.

Each case divides n by the primes in order, counting how many times each divides, until the square of the next prime exceeds what is left. Whatever remains above 1 is a single large prime. The divisor sum then comes from the factorization: for p^e the divisors contribute 1 + p + p^2 + ... + p^e, and the whole sum is the product of these pieces.

Takeaway: sieve once to the square root, then divide and multiply.

## Why It Works

1. Every composite factor of n has a prime factor at most sqrt(n) ≤ 10^7, which the sieve list contains.
2. Dividing out a prime completely leaves a cofactor with no smaller prime factors.
3. If the cofactor were composite, it would have a prime factor at most its own square root, which is at most sqrt(n) and already tried, so the cofactor is prime.
4. Every divisor of n is a product of the prime powers, so the divisor sum factors into the geometric sums (1 + p + ... + p^e) over the distinct primes.
5. For n ≤ 10^14 these sums stay below 10^15, which `int64` holds exactly.
6. Primes are tried in ascending order, so the printed pairs are already sorted.

For the sample, 8 = 2^3 gives the pairs `2 3` and the sum 1+2+4+8 = 15. For 56 = 2^3 · 7 the pairs are `2 3` and `7 1`, and the sum is 15 · 8 = 120.

The break test `p * p > remaining` uses the shrinking cofactor, which is the standard shortcut: once p^2 exceeds the cofactor, no further prime can divide it.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

```nim
const flushBlockBytes = 1 shl 17
const sieveLimit = 10000000

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner skips spaces and newlines.
On a 64-bit build `int` holds values up to 10^14.

**Buffered output.** One string collects all the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Prime table.** The sieve marks composites up to 10^7 and collects the survivors.

```nim
var isPrime = newSeq[bool](sieveLimit + 1)
var primeCursor = 2
while primeCursor <= sieveLimit:
  isPrime[primeCursor] = true
  primeCursor += 1
isPrime[0] = false
isPrime[1] = false
var sieveCursor = 2
while int64(sieveCursor) * int64(sieveCursor) <= int64(sieveLimit):
  if isPrime[sieveCursor]:
    var multipleCursor = sieveCursor * sieveCursor
    while multipleCursor <= sieveLimit:
      isPrime[multipleCursor] = false
      multipleCursor += sieveCursor
  sieveCursor += 1
var primeList = newSeq[int](0)
var collectCursor = 2
while collectCursor <= sieveLimit:
  if isPrime[collectCursor]:
    primeList.add collectCursor
  collectCursor += 1
```

Marking starts at the square of each prime because smaller multiples already have a smaller factor.

**Factoring and summing.** One case is factored, then printed with its divisor sum.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let targetNumber = nextInt(inputData, scanPos)
  var remainingValue = int64(targetNumber)
  var factorBases = newSeq[int64](0)
  var factorPowers = newSeq[int](0)
  for primeValue in primeList:
    if int64(primeValue) * int64(primeValue) > remainingValue:
      break
    if remainingValue mod int64(primeValue) == 0:
      var powerCount = 0
      while remainingValue mod int64(primeValue) == 0:
        remainingValue = remainingValue div int64(primeValue)
        powerCount += 1
      factorBases.add int64(primeValue)
      factorPowers.add powerCount
  if remainingValue > 1:
    factorBases.add remainingValue
    factorPowers.add 1
```

The loop stops as soon as p^2 passes the cofactor.
A leftover cofactor above 1 is one prime with exponent 1.

**Divisor sum.** Each factor multiplies in its geometric series.

```nim
  var divisorSum: int64 = 1
  for factorIndex in 0 .. factorBases.len - 1:
    var geometricSum: int64 = 1
    var currentPower: int64 = 1
    var exponentCursor = 0
    while exponentCursor < factorPowers[factorIndex]:
      currentPower = currentPower * factorBases[factorIndex]
      geometricSum = geometricSum + currentPower
      exponentCursor += 1
    divisorSum = divisorSum * geometricSum
```

Powers are built by repeated multiplication, no division or overflow guard needed.

**Answer lines.** Pairs first, then the sum, then the case separator.

```nim
  for factorIndex in 0 .. factorBases.len - 1:
    appendOutput($factorBases[factorIndex] & " " & $factorPowers[factorIndex] & "\n")
  appendOutput("Sum Of Divisiors: " & $divisorSum & "\n")
  if caseIndex < caseCount - 1:
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The blank line is written between cases, not after the last one.
The label spelling matches the statement.

## Complexity

The sieve runs once; each case walks primes only up to its cofactor's square root.

| phase | time | space |
|---|---|---|
| sieve | cross-out multiples to 10^7 | 10^7 flags |
| factor | primes up to sqrt(n) per case | factor lists |
| output | one line per factor | one block buffer |

| measure | Big O |
|---|---|
| time | O(S log log S + t · S / log S) with S = 10^7 |
| space | O(S) |

Trial division by every odd number up to 10^7 would cost about 5×10^6 steps per case instead of about 6.6×10^5.

Takeaway: one shared sieve makes 100 large factorizations cheap.
