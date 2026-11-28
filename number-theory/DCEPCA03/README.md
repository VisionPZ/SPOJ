# DCEPCA03 — Totient Extreme (SPOJ)

<https://www.spoj.com/problems/DCEPCA03/>

## Problem

For each queried N, add Euler's totient over 1..N and square the result. The nested loops in the statement add every pair of totient values, which equals the square of one sum.

Input starts with T, the number of queries. Each following line holds one integer N. Output one line per query with H for that N.

| item | bound |
|---|---|
| queries T | 1 to 500 |
| queried N | 1 to 10000 |
| totient sum | below 2^31 |
| judge limit | 1000 ms, 1536 MB |

The largest queried N sets the only precomputation work.

Sample input:

```
2
3
10
```

Sample output:

```
16
1024
```

## Idea

Squaring a sum is like pairing every card in a pile with every card in the same pile. One pass builds all totients with a sieve, and a prefix array gives each sum at once.

The algorithm is an Euler totient sieve followed by prefix sums. The sieve costs O(N log log N) once, and each query costs O(1). The written double loop costs O(N^2) per query, so it cannot handle 500 queries.

Takeaway: precompute once, then answer each query with a single lookup.

## Why It Works

1. The loops add totient(i) times totient(j) over all ordered pairs.
2. That double sum factors into (sum of totient) squared.
3. A sieve sets totient(p) = p for primes and multiplies by (p-1)/p for each prime factor.
4. The prefix array holds the sum of totients from 1 up to each index.
5. Squaring the prefix entry gives H in 64-bit arithmetic.

| term | meaning |
|---|---|
| `totients` | Euler's totient for each number up to the largest query |
| `prefixTotients` | running sum of totients from 1 to that index |
| `totientSum` | prefix value for one query |
| `largestQuery` | highest N present in the input |

Each table entry feeds the next one, so the sieve finishes before any answer is written.

A script-generated trace for N from 1 to 4:

```
N    phi(N)   prefix   H
1       1        1      1
2       1        2      4
3       2        4     16
4       2        6     36
```

The third row gives H(3) = 16, matching the first sample answer.

## Code

**Input and scanning.** The hand reader loads the query count and every queried N.

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

let caseCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](caseCount)
var largestQuery = 0
for caseIndex in 0 .. caseCount - 1:
  queryValues[caseIndex] = nextInt(inputData, scanPos)
  if queryValues[caseIndex] > largestQuery:
    largestQuery = queryValues[caseIndex]
```

The scan skips separators and keeps only digit runs.
Tracking `largestQuery` avoids work beyond the input range.
Reading once keeps input handling to a single pass.

**Totient sieve and prefix sums.** Each prime updates its multiples, then a running sum is built.

```nim
var totients = newSeq[int](largestQuery + 1)
for numberValue in 0 .. largestQuery:
  totients[numberValue] = numberValue
for primeCandidate in 2 .. largestQuery:
  if totients[primeCandidate] == primeCandidate:
    var multiple = primeCandidate
    while multiple <= largestQuery:
      totients[multiple] = totients[multiple] div primeCandidate * (primeCandidate - 1)
      multiple += primeCandidate

var prefixTotients = newSeq[int64](largestQuery + 1)
for numberValue in 1 .. largestQuery:
  prefixTotients[numberValue] = prefixTotients[numberValue - 1] + int64(totients[numberValue])
```

A value that still equals its index is prime.
Division comes before multiplication to keep intermediates small.
The prefix array uses 64-bit entries for safe sums.

**Buffered output.** Each answer is squared once and flushed in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let totientSum = prefixTotients[queryValues[caseIndex]]
  appendOutput($(totientSum * totientSum))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The square stays in 64-bit range for the given bounds.
One newline follows each answer.
The final write clears any remaining buffered text.

## Complexity

Precomputation runs once, and queries are lookups.

| phase | time | space |
|---|---|---|
| input read | one pass over query tokens | query array |
| totient sieve | O(N log log N) | N integers |
| prefix sums | O(N) | N 64-bit entries |
| output | one line per query | block buffer |

The sieve dominates the build, while queries add almost nothing.

| measure | Big O |
|---|---|
| time | O(N log log N + T) |
| space | O(N) |

A direct double loop costs O(N^2) per query and cannot finish 500 cases.

Takeaway: move the repeated work into one sieve and answer with a lookup.
