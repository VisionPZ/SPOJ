# APS — Amazing Prime Sequence (SPOJ)

<https://www.spoj.com/problems/APS/>

## Problem

Build the sequence with a[0] = a[1] = 0 and a[n] = a[n - 1] plus the smallest prime factor of n. Answer each query N with the value a[N].

Input starts with T, the number of test cases. Each of the next T lines holds one integer N. Output one sequence value per line; values can exceed 32-bit range.

| item | bound |
|---|---|
| test cases T | up to 100 |
| query N | 1 < N < 10000000 |
| judge limit | 1000 ms, 1536 MB |

One sieve and one prefix pass serve all queries at once.

Sample input:

```
3
2
3
4
```

Sample output:

```
2
5
7
```

## Idea

The sequence is a running total, like a row of monthly bills where each new bill is the smallest prime factor of the current index. Find every smallest prime factor with one sieve, then accumulate them once in order.

A sieve marks each composite at its first prime divisor, so each entry is written a small number of times. Testing every number by trial division would cost about square root of N per entry and repeat work for all queries.

One precomputed array turns each query into a single lookup.

## Why It Works

1. a[n] equals the sum of the smallest prime factors from 2 through n.
2. A sieve visits each prime p starting at p squared.
3. The first prime that reaches a composite is its smallest prime factor.
4. Stored prefix values give a[n] from a[n - 1] plus one factor.
5. int64 holds the total, which grows faster than n.

| term | meaning |
|---|---|
| `smallestPrimeFactor` | smallest prime divisor stored for each index |
| `sequenceValues` | prefix sum of smallest prime factors |
| `largestValue` | largest query, used as the sieve bound |
| `requestedValues` | queries kept in input order |

A trace of the first few indices from the generator:

| index | smallest prime factor | sequence value |
|---|---|---|
| 2 | 2 | 2 |
| 3 | 3 | 5 |
| 4 | 2 | 7 |
| 5 | 5 | 12 |
| 10 | 2 | 28 |

The first three rows match the sample output.

## Code

**Input and queries.** The reader stores all queries and finds the largest one.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var requestedValues = newSeq[int](caseCount)
var largestValue = 0
for caseIndex in 0 .. caseCount - 1:
  let requestedValue = nextInt(inputData, scanPos)
  requestedValues[caseIndex] = requestedValue
  if requestedValue > largestValue:
    largestValue = requestedValue
```

The largest query fixes the sieve size.
Queries stay in their original order for output.
The buffer accumulates answer lines.

**Sieve and prefix.** The sieve fills factors and one pass builds the sequence.

```nim
var smallestPrimeFactor = newSeq[int32](largestValue + 1)
if largestValue >= 2:
  for primeCandidate in 2 .. largestValue:
    if smallestPrimeFactor[primeCandidate] == 0:
      smallestPrimeFactor[primeCandidate] = int32(primeCandidate)
      if int64(primeCandidate) * int64(primeCandidate) <= int64(largestValue):
        var multiple = primeCandidate * primeCandidate
        while multiple <= largestValue:
          if smallestPrimeFactor[multiple] == 0:
            smallestPrimeFactor[multiple] = int32(primeCandidate)
          multiple += primeCandidate

var sequenceValues = newSeq[int64](largestValue + 1)
if largestValue >= 2:
  for valueIndex in 2 .. largestValue:
    sequenceValues[valueIndex] = sequenceValues[valueIndex - 1] + int64(smallestPrimeFactor[valueIndex])

for caseIndex in 0 .. caseCount - 1:
  appendOutput($sequenceValues[requestedValues[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each composite receives its first prime divisor.
The prefix pass uses int64 to avoid overflow.
Each query then reads one stored value.

## Complexity

Precomputation runs once up to the largest query.

| phase | time | space |
|---|---|---|
| input read | one pass over all queries | one input string |
| sieve | one marking pass per prime | factor array |
| prefix and output | one step per index, one line per case | int64 array |

The sieve dominates the runtime.

| measure | Big O |
|---|---|
| time | O(largest N log log largest N plus T) |
| space | O(largest N) |

Trial division for every query would repeat far more work than one shared sieve.
The shared table keeps a hundred large queries cheap.
