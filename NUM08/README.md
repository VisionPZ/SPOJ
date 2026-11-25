# NUM08 — Sum Of Divisiors (SPOJ)

<https://www.spoj.com/problems/NUM08/>

## Problem

Factor each even number into prime powers and print every prime with its exponent. Then print the sum of all positive divisors of that number. Results for consecutive test cases are separated by a blank line.

Input starts with the test count `t`. Each following line holds one even integer `n` with `n <= 10^14`.

Output for each case lists lines of `prime exponent`, ordered from the smallest prime upward. A final line reads `Sum Of Divisiors: X`, where `X` is the divisor sum.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| number n | even, at most 10^14 |
| divisor sum | fits in a signed 64-bit integer |
| judge limit | 1000 ms, 1536 MB |

The largest n sets the trial-division limit at 10^7.

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

List the primes first, like a singer warming up a scale before a song. Then divide the number by each prime and count the repeats. The divisor sum follows from the prime powers with a short geometric-series formula.

A sieve builds the prime list once, so each test case skips composite trial divisors. Trial division costs about pi(sqrt(n)) steps per case instead of sqrt(n) steps. Taking the geometric sum avoids listing every divisor.

Sieve once, factor by primes, then sum geometric series per prime power.

## Why It Works

1. A sieve marks composite numbers up to the square root of the largest input.
2. Dividing by primes in order yields each distinct prime with its exact exponent.
3. A leftover value above one is itself a prime with exponent one.
4. Divisors of a prime power are its powers from zero up to the exponent.
5. The divisor-sum function is multiplicative across coprime prime powers.

| term | meaning |
|---|---|
| `primeList` | primes up to 10^7 used as trial divisors |
| `factorBases` | distinct prime factors of the current number |
| `factorPowers` | exponent paired with each prime factor |
| `geometricSum` | sum of powers of one prime factor |
| `divisorSum` | product of the geometric sums |

Each prime power contributes exactly one geometric series to the answer.

A worked trace for `n = 56` gives factors `2 3` and `7 1`. The first series is `1+2+4+8 = 15`. The second series is `1+7 = 8`. Their product is `120`, matching the sample.

Print a blank line between cases and stop after the last case.

## Code

**Input and prime sieve.** The reader loads all tokens, then the sieve builds the trial-division list.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

The sieve stops at the square root of ten million.
The prime list is reused for every test case.
The parser skips whitespace and reads one integer at a time.

**Factorization and divisor sum.** Each case records prime powers and multiplies their geometric sums.

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
  for factorIndex in 0 .. factorBases.len - 1:
    appendOutput($factorBases[factorIndex] & " " & $factorPowers[factorIndex] & "\n")
  appendOutput("Sum Of Divisiors: " & $divisorSum & "\n")
  if caseIndex < caseCount - 1:
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Trial division stops once the square of the prime exceeds the remainder.
A leftover prime is appended with exponent one.
All output passes through one buffered string.

## Complexity

Sieve work dominates the setup, and each case tests primes up to its own square root.

| phase | time | space |
|---|---|---|
| prime sieve | one pass up to 10^7 | boolean array of 10^7 entries |
| factorization | up to pi(sqrt(n)) divisions per case | list of prime powers |
| divisor sum | one series per distinct prime | two small arrays |
| output | one buffered stream | block buffer |

The sieve runs once for all cases.

| measure | Big O |
|---|---|
| time | O(L log log L + t pi(sqrt(n))) with L = 10^7 |
| space | O(L) |

A plain trial division over every integer would need about sqrt(n) tests per case.

Sieve first, divide by primes, and finish each case with a multiplicative divisor sum.
