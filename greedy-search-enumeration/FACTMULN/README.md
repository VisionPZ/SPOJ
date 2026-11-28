# FACTMULN — Product of factorials (easy) (SPOJ)

<https://www.spoj.com/problems/FACTMULN/>

## Problem

Find the smallest i such that n divides the product of factorials from 1! through i!. Factor n into prime powers and lift each prime requirement separately.

The input begins with T, the number of test cases. Each of the next T lines holds one integer n. Print the smallest valid index for each case on its own line.

| item | bound |
|---|---|
| test cases | between 1 and 9999 |
| n | between 1 and 999999999 |
| judge limit | 1659 ms, 1536 MB |

The largest n fits in a 32-bit integer, but valuation sums need 64-bit math.

The sample input:

```
3
4
5
6
```

The sample output:

```
3
5
3
```

## Idea

Give each prime in n its own small search, then take the largest result. That is like checking every locked door separately and leaving only when all doors open.

The algorithm factors n with a sieved list of primes. For each prime power it binary searches the smallest index i whose valuation of F(i) reaches the exponent. The answer is the maximum of those indices. A scan from i=1 would test up to a billion candidates per case, while the search tests about thirty.

One binary search per distinct prime factor solves each case.

## Why It Works

1. n divides F(i) exactly when every prime power in n divides F(i).
2. F(i) grows by whole factorials, so each prime valuation never decreases with i.
3. The exponent of prime p in F(i) is the sum over q = p, p^2, ... of the floor sums of k/q for k from 1 to i.
4. The floor sum of k/q up to i equals q*m*(m-1)/2 + m*(i-q*m+1), where m is i/q.
5. The smallest index that satisfies a prime power is found by binary search on that monotone valuation.

| term | meaning |
|---|---|
| `valuationAt` | exponent of a prime inside F at one index |
| `minimalIndex` | smallest index meeting one prime power |
| `isComposite` | sieve flags for trial division |
| `remaining` | unfactored part of the current n |

Each term maps to one table or one loop in the code.

A script trace for n = 4, which needs the prime power 2^2:

```
index    v2(F(index))   meets exponent 2?
1        0              no
2        1              no
3        2              yes
4        5              yes
```

The first yes appears at index 3, matching the sample answer.

## Code

**Input and sieve.** The reader loads all cases and builds the prime list once.

```nim
const flushBlockBytes = 1 shl 17
const sieveLimit = 31623
const largestNumber = 1000000000

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

proc valuationAt(prime: int64, limit: int64): int64 =
  var power = prime
  while power <= limit:
    let quotient = limit div power
    result = result + power * quotient * (quotient - 1) div 2
    result = result + quotient * (limit - power * quotient + 1)
    if power > limit div prime:
      break
    power = power * prime
  return result

proc minimalIndex(prime: int, exponent: int): int =
  var low = int64(prime)
  var high = int64(largestNumber - 1)
  while low < high:
    let middle = low + (high - low) div 2
    if valuationAt(int64(prime), middle) >= int64(exponent):
      high = middle
    else:
      low = middle + 1
  return int(low)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isComposite = newSeq[bool](sieveLimit + 1)
var primes = newSeq[int]()
for candidate in 2 .. sieveLimit:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= sieveLimit:
      var multiple = candidate * candidate
      while multiple <= sieveLimit:
        isComposite[multiple] = true
        multiple += candidate
```

`valuationAt` uses a closed floor sum, so one valuation costs a few powers of p.
`minimalIndex` searches from p up to the largest legal n.
The sieve stops at the square root of a billion, which bounds trial division.

**Per-case factor lift.** Trial division extracts prime powers and the maximum index wins.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = nextInt(inputData, scanPos)
  var answer = 1
  var remaining = numberValue
  for prime in primes:
    if int64(prime) * int64(prime) > int64(remaining):
      break
    if remaining mod prime == 0:
      var exponent = 0
      while remaining mod prime == 0:
        remaining = remaining div prime
        exponent += 1
      let needed = minimalIndex(prime, exponent)
      if needed > answer:
        answer = needed
  if remaining > 1:
    let needed = minimalIndex(remaining, 1)
    if needed > answer:
      answer = needed
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop handles n = 1 because `answer` starts at one.
A leftover factor above one is itself a prime with exponent one.
All answers leave through one buffered write at the end.

## Complexity

Sieve cost is fixed, and each case factors n once.

| phase | time | space |
|---|---|---|
| sieve | one pass up to the square root bound | flags and prime list |
| factoring | trial division by sieved primes | a few local integers |
| searches | one binary search per prime factor | constant per search |
| output | one write per block | block buffer |

Factoring and searching dominate, and both stay small for n below a billion.

| measure | Big O |
|---|---|
| time | O(sieveLimit log log sieveLimit + cases times factors times log n) |
| space | O(sieveLimit) |

A linear scan over candidate indices would test nearly a billion values per prime. The binary search cuts that to about thirty valuation calls.
