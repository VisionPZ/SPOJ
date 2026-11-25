# MPRIME1 — Sum of Primes (SPOJ)

<https://www.spoj.com/problems/MPRIME1/>

## Problem

Count how many ways a number can be written as a sum of one or more consecutive primes. The order of the primes is fixed by the number line, so only the start and end of the run can change.

Input contract: one positive integer per line, ending with the sentinel 0. Output contract: print one count per query line, omitting the sentinel.

The bounds from the statement:

| item | bound |
|---|---|
| query value | 2 to 11000 |
| query count | as many lines as the file holds |
| judge limit | 1000 ms, 1536 MB |

A single prime counts as a run of length one.

Sample input:

```
2
3
17
41
20
666
12
53
0
```

Sample output:

```
1
1
2
3
0
0
1
2
```

## Idea

Build a lookup table of counts once, like indexing every recipe before taking orders. The algorithm sieves the primes, then slides a window over them and tallies each sum it reaches. Every window costs constant work because the sum only grows as the end moves. Recomputing every start and end for each query would repeat the same table many times. One table answers all queries immediately.

## Why It Works

1. A representation is exactly a contiguous slice of the ordered prime list.
2. The sum of a slice grows when the end moves right and shrinks when the start moves right.
3. Extending a start until the sum passes the limit visits every slice once.
4. Each valid sum adds one to its count.
5. The sentinel produces no output.

The terms used in the precomputation:

| term | meaning |
|---|---|
| `primeNumbers` | all primes up to the query limit |
| `runningTotal` | sum of the current prime window |
| `representationCounts` | tally for every reachable sum |
| `queryValue` | one number read from input |

The sieve marks composites, so every unmarked value is prime.

A traced set of windows for query 41:

```
2 + 3 + 5 + 7 + 11 + 13 = 41
11 + 13 + 17 = 41
41 = 41
count = 3
```

The three windows match the sample answer for 41.

## Code

**Sieve.** The prime list is built once up to the largest legal query.

```nim
const flushBlockBytes = 1 shl 17
const maxQueryValue = 11000

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

var isComposite = newSeq[bool](maxQueryValue + 1)
var baseValue = 2
while baseValue * baseValue <= maxQueryValue:
  if not isComposite[baseValue]:
    var multipleValue = baseValue * baseValue
    while multipleValue <= maxQueryValue:
      isComposite[multipleValue] = true
      multipleValue += baseValue
  baseValue += 1

var primeNumbers = newSeq[int](0)
for candidateValue in 2 .. maxQueryValue:
  if not isComposite[candidateValue]:
    primeNumbers.add candidateValue
```

Marking starts at the square of each base prime.
The square test stops the sieve at the root of the limit.
The prime list is dense enough for a sliding window.

**Window tally and queries.** Each start extends until the sum exceeds the limit.

```nim
var representationCounts = newSeq[int](maxQueryValue + 1)
for startIndex in 0 .. primeNumbers.len - 1:
  var runningTotal = 0
  for endIndex in startIndex .. primeNumbers.len - 1:
    runningTotal += primeNumbers[endIndex]
    if runningTotal > maxQueryValue:
      break
    representationCounts[runningTotal] += 1

while true:
  let queryValue = nextInt(inputData, scanPos)
  if queryValue == 0:
    break
  appendOutput($(representationCounts[queryValue]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The break bounds every window by the query limit.
A zero count is still a valid answer and prints 0.
The shared buffer flushes once after the last query.

## Complexity

The sieve and the tally happen before any query is read.

| phase | time | space |
|---|---|---|
| sieve | one pass over multiples of each prime | composite flags |
| window tally | one visit per valid prime slice | count table |
| queries | one lookup per input line | block buffer |

The prime count is small because the limit is 11000.

| measure | Big O |
|---|---|
| time | O(L log log L plus queries), L = 11000 |
| space | O(L) |

Searching every start and end again per query would multiply the work by the query count.
The single count table keeps each answer constant time.
