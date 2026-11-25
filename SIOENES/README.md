# SIOENES — Eratosthenes Prime numbers (SPOJ)

<https://www.spoj.com/problems/SIOENES/>

## Problem

For each given number, report how many primes are at most that number.

The input starts with the test count. Every following line holds one upper bound. Print one count per line.

| item | bound |
|---|---|
| tests T | 1 to 10000 |
| upper bound N | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

Many tests share one small bound range, so the work should be paid once.

Sample input:

```
2
9
11
```

Sample output:

```
4
5
```

## Idea

Cross out composite numbers once, like removing names from a guest list before counting the invitees. Sieve every multiple of each prime, then keep a running count of the survivors. One pass up to the largest query builds all answers. Each test then reads one slot instead of testing numbers again.

## Why It Works

1. Every composite number has a prime factor no larger than its square root.
2. Starting the cross-out at the prime squared leaves that prime standing.
3. Uncrossed numbers up to a bound are exactly the primes up to that bound.
4. A running count turns any bound into a single table lookup.

| term | meaning |
|---|---|
| `isPrime` | cross-out table, true for surviving numbers |
| `primeCounts` | running number of primes up to each index |
| `limitNumber` | largest bound asked by any test |

The largest query fixes the one sieve size.

Script-generated trace for the small bounds:

```
bound | primes up to bound
1 | 0
2 | 1
3 | 2
5 | 3
7 | 4
9 | 4
11 | 5
```

The bound 9 gives 4 and the bound 11 gives 5, matching the sample.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

```nim
const flushBlockBytes = 1 shl 17

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

All queries are read before the sieve starts.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Sieve and answer table.** Multiples are crossed out, then counted once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[int](caseCount)
var limitNumber = 0
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex] = nextInt(inputData, scanPos)
  if queries[caseIndex] > limitNumber:
    limitNumber = queries[caseIndex]

var isPrime = newSeq[bool](limitNumber + 1)
for numberValue in 0 .. limitNumber:
  isPrime[numberValue] = true
if limitNumber >= 0:
  isPrime[0] = false
if limitNumber >= 1:
  isPrime[1] = false
var primeCandidate = 2
while primeCandidate * primeCandidate <= limitNumber:
  if isPrime[primeCandidate]:
    var multipleValue = primeCandidate * primeCandidate
    while multipleValue <= limitNumber:
      isPrime[multipleValue] = false
      multipleValue = multipleValue + primeCandidate
  primeCandidate += 1

var primeCounts = newSeq[int](limitNumber + 1)
for numberValue in 1 .. limitNumber:
  primeCounts[numberValue] = primeCounts[numberValue - 1]
  if isPrime[numberValue]:
    primeCounts[numberValue] += 1
for caseIndex in 0 .. caseCount - 1:
  appendOutput($primeCounts[queries[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The cross-out begins at each prime squared.
The count table fills in one ascending pass.
Each answer is one lookup and one buffered line.

## Complexity

One sieve pass serves all ten thousand tests.

| phase | time | space |
|---|---|---|
| input read | one pass over T bounds | one input string |
| sieve | one marking per composite multiple | table up to largest bound |
| output | one lookup per test | block buffer |

Tests never rebuild the sieve.

| measure | Big O |
|---|---|
| time | O(T + max N log log max N) |
| space | O(max N) |

Trial division for every test would cost O(T times max N) and repeat the same divisor work.
