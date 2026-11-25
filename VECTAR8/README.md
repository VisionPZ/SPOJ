# VECTAR8 — Primal Fear (SPOJ)

<https://www.spoj.com/problems/VECTAR8/>

## Problem

Count primes up to N that contain no digit zero and stay prime after removing any number of leading digits. Such a prime is called a scary prime in this solution.

The first line holds T test cases, followed by T values of N with 1 ≤ N < 1000000. Print one count per line.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 100000 |
| query value N | 1 to 999999 |
| judge limit | 300 ms, 1536 MB |

The large value of T makes precomputation necessary.

Sample input:

```
3
2
3
4
```

Sample output:

```
1
2
2
```

## Idea

Build scary primes by adding one digit at a time on the left, like growing a chain where every link must already be prime.

Start from the one-digit primes 2, 3, 5, and 7. Prepend each digit 1 through 9 and keep only results that are prime and below the limit. Repeat until no new number appears. A sieve answers each primality test, and a prefix array answers each query in constant time. Testing every number up to N instead repeats the same suffix checks millions of times. Each query then costs one table read.

## Why It Works

1. Removing leading digits from a constructed number reveals the earlier chain values.
2. Every prefix of the chain is prime by construction, so every suffix of the final number is prime.
3. Prepending digits from 1 to 9 never introduces a zero digit.
4. Each scary prime has a unique chain, so the generation visits it once.
5. The prefix count at N equals the number of scary primes at most N.

The main terms:

| term | meaning |
|---|---|
| `isPrimeValue` | sieve flag for primality up to the limit |
| `currentLevel` | scary primes with a given digit length |
| `placeValue` | power of ten matching the current digit length |
| `scaryCounts` | prefix count of scary primes by value |

Every query reads one entry of the prefix table.

A worked trace from the oracle, listing scary primes up to 100:

```
one digit   2 3 5 7
prepend 1   13 17
prepend 2   23 29
prepend 3   31 37
prepend 4   43 47
prepend 5   53 59
prepend 6   67
prepend 7   71 73 79
prepend 8   83 89
prepend 9   97
total up to 100 = 15
```

The sample counts 1, 2, and 2 agree with the single-digit chain.

## Code

**Sieve.** Eratosthenes marks every composite up to the limit.

```nim
const flushBlockBytes = 1 shl 17
const maxValue = 1000000

var isPrimeValue = newSeq[bool](maxValue + 1)
for value in 0 .. maxValue:
  isPrimeValue[value] = true
isPrimeValue[0] = false
isPrimeValue[1] = false
var primeCursor = 2
while primeCursor * primeCursor <= maxValue:
  if isPrimeValue[primeCursor]:
    var multiple = primeCursor * primeCursor
    while multiple <= maxValue:
      isPrimeValue[multiple] = false
      multiple = multiple + primeCursor
  primeCursor += 1
```

Multiples start at the square of the current prime.
Each composite is marked once by its smallest prime factor.
The sieve covers the whole query range in one pass.

**Digit growth.** Each round prepends one nonzero digit to the previous round.

```nim
var scaryFlags = newSeq[bool](maxValue + 1)
var seedNumbers = @[2, 3, 5, 7]
for seedValue in seedNumbers:
  scaryFlags[seedValue] = true
var currentLevel = seedNumbers
var placeValue = 10
while currentLevel.len > 0:
  var nextLevel = newSeq[int]()
  for baseValue in currentLevel:
    for leadingDigit in 1 .. 9:
      let candidate = leadingDigit * placeValue + baseValue
      if candidate > maxValue:
        continue
      if isPrimeValue[candidate]:
        scaryFlags[candidate] = true
        nextLevel.add candidate
  currentLevel = nextLevel
  placeValue = placeValue * 10
```

The place value tracks how many digits the current numbers have.
Candidates beyond the limit are skipped without a primality lookup.
The loop ends when no longer prime survives.

**Prefix table.** A running sum turns each query into one array read.

```nim
var scaryCounts = newSeq[int](maxValue + 1)
for value in 1 .. maxValue:
  scaryCounts[value] = scaryCounts[value - 1]
  if scaryFlags[value]:
    scaryCounts[value] = scaryCounts[value] + 1
```

Entry N holds every scary prime at most N.
Entry zero stays zero.
The table is reused for all test cases.

**Input and output.** The scanner reads all queries and block buffering writes all answers.

```nim
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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let upperBound = nextInt(inputData, scanPos)
  appendOutput($scaryCounts[upperBound])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Query values fit the precomputed table range.
The flush threshold is 131072 bytes.
One final flush emits the last partial block.

## Complexity

Precomputation runs once, and each query reads one prefix entry.

| phase | time | space |
|---|---|---|
| sieve | one pass over the limit | one boolean per value |
| digit growth | at most six rounds over generated numbers | two boolean and integer arrays |
| query loop | one read per test case | block buffer |

The arrays are sized to the query limit and not to T.

The asymptotic bounds:

| measure | Big O |
|---|---|
| preprocessing | O(MAX log log MAX) |
| time per query | O(1) |
| space | O(MAX) plus input |

Checking suffixes for every number up to N costs far more than generating the few valid chains once.
