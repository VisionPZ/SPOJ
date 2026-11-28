# DCEPCA08 — Saving BOB - 2 (SPOJ)
<https://www.spoj.com/problems/DCEPCA08/>

## Problem

Count the distinct prime sums that subsets of the generated array can produce. Only the set of sums matters, not how many subsets share one.

Input starts with the test count, then one array length per line. Output one integer per line: the number of different prime subset sums.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| length N | 1 to 100000 |
| array values | 1 to 52 |
| judge limit | 200 ms, 1536 MB |

The array starts at index one, with a zero at index one used only to seed the formula.

Sample input:

```
2
4
5
```

Sample output:

```
3
6
```

## Idea

The generated values cycle through every residue from one to fifty-two, like a clock with fifty-two positions. One full cycle can form every sum from zero up to its total, like having enough coins to pay any amount. For a long array, count primes up to the total instead of testing subsets. For a short array, test sums directly with a small table.

A sieve counts primes once for the largest input in the file.

## Why It Works

1. Writing a value as its excess over one turns the formula into multiplication by minus two modulo fifty-three.
2. The value at position i is therefore minus two to the power i, reduced modulo fifty-three.
3. Minus two has order fifty-two, so the first fifty-two values are one through fifty-two in some order.
4. Those values satisfy the coin condition, so every sum up to their total is reachable.
5. Adding more values keeps the reachable sums contiguous, and a sieve gives the prime count directly.

| term | meaning |
|---|---|
| `periodValues` | the fifty-two repeating array values |
| `periodSum` | total of one full cycle, equal to 1378 |
| `primeCounts` | number of primes up to each value |
| `reachable` | sums possible from a short prefix |

The sample prefix has values 51, 4, 45, and 16.

| subset | sum |
|---|---|
| 51 + 16 | 67 |
| 45 + 16 | 61 |
| 51 + 4 + 16 | 71 |

All three sums are prime, so the answer for length four is three.

Short prefixes use an exact sum table, and no rounding occurs anywhere.

## Code

**Input and scanner.** The reader loads all lines and parses each array length.

```nim
const flushBlockBytes = 1 shl 17
const residueModulus = 53
const periodLength = 52

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

**Output helper.** Buffered writes keep the output path cheap.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

**Cycle construction.** Repeated multiplication by minus two builds one full period.

```nim
var periodValues = newSeq[int](periodLength)
var prefixSums = newSeq[int](periodLength + 1)
var powerValue = 1
for position in 1 .. periodLength:
  powerValue = (powerValue * (residueModulus - 2)) mod residueModulus
  periodValues[position - 1] = powerValue
  prefixSums[position] = prefixSums[position - 1] + powerValue
let periodSum = prefixSums[periodLength]
```

Prefix sums give the total of any partial cycle in constant time.

**Length read.** All lengths are stored so the sieve covers the largest total.

```nim
let caseCount = nextInt(inputData, scanPos)
var lengths = newSeq[int](caseCount)
var largestLength = 0
for caseIndex in 0 .. caseCount - 1:
  lengths[caseIndex] = nextInt(inputData, scanPos)
  if lengths[caseIndex] > largestLength:
    largestLength = lengths[caseIndex]
let largestSum = (largestLength div periodLength) * periodSum + prefixSums[largestLength mod periodLength]
```

**Prime sieve.** A boolean table and a running count prepare every answer at once.

```nim
var primeFlags = newSeq[bool](largestSum + 1)
for value in 0 .. largestSum:
  primeFlags[value] = true
primeFlags[0] = false
primeFlags[1] = false
var divisor = 2
while divisor * divisor <= largestSum:
  if primeFlags[divisor]:
    var multiple = divisor * divisor
    while multiple <= largestSum:
      primeFlags[multiple] = false
      multiple += divisor
  divisor += 1
var primeCounts = newSeq[int](largestSum + 1)
for value in 1 .. largestSum:
  primeCounts[value] = primeCounts[value - 1]
  if primeFlags[value]:
    primeCounts[value] += 1
```

The sieve starts marking at each square, so each composite is crossed once.
The running count turns a primality query into one array lookup.

**Answer loop.** Long arrays use the prime count, and short arrays use a sum table.

```nim
for caseIndex in 0 .. caseCount - 1:
  let length = lengths[caseIndex]
  let cycles = length div periodLength
  let remainder = length mod periodLength
  let totalSum = cycles * periodSum + prefixSums[remainder]
  if length >= periodLength:
    appendOutput($primeCounts[totalSum])
  else:
    var reachable = newSeq[bool](totalSum + 1)
    reachable[0] = true
    for position in 0 .. length - 1:
      let value = periodValues[position]
      var score = totalSum
      while score >= value:
        if reachable[score - value]:
          reachable[score] = true
        score -= 1
    var primeSubsetCount = 0
    for score in 2 .. totalSum:
      if primeFlags[score] and reachable[score]:
        primeSubsetCount += 1
    appendOutput($primeSubsetCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A short array marks each reachable sum with one backward pass per value.
A long array needs only the count of primes up to its total.

## Complexity

The sieve is built once for the largest input length.

| phase | time | space |
|---|---|---|
| cycle construction | 52 steps | 53 counters |
| sieve and prefix | S log log S steps | S booleans and counters |
| short case | N times S steps | S booleans |
| long case | one lookup | unchanged |

| measure | Big O |
|---|---|
| sieve | O(S log log S), S about 2.7 million at maximum |
| short case | O(N S) with N under 52 |
| long case | O(1) per test |
| space | O(S) |

Checking every subset would take two to the power of N steps per test.

The cycle structure replaces that search with a sieve and a table.
