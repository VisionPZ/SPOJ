# AFS — Amazing Factor Sequence (SPOJ)
<https://www.spoj.com/problems/AFS/>

## Problem

The sequence starts with a0 = a1 = 0. For n greater than 1, a_n adds the sum of proper divisors of n to the previous term. Answer each query with the requested sequence value.

Input starts with T, the number of queries. Each of the next T lines holds one integer N with 1 < N < 1000000.

Output is one line per query with a_N.

The input bounds are:

| item | bound |
|---|---|
| queries T | up to 100 |
| query value N | 2 to 999999 |
| largest sequence value | under 10^12 |
| judge limit | 1000 ms, 1536 MB |

A proper divisor of n is a positive divisor smaller than n, so 1 counts for every n greater than 1.

Sample input:

```
3
3
4
5
```

Sample output:

```
2
5
6
```

## Idea

Add each divisor to all of its multiples, like stamping every second seat with the number 2. One sieve pass builds every divisor sum, and prefix sums turn each query into a table lookup.

The real algorithm is a divisor-sum sieve followed by a prefix-sum array. Sieve work is O(N log N) once, and each query costs O(1).

Testing divisors separately for each n would repeat the same work many times. One shared sieve serves all queries.

## Why It Works

1. A proper divisor d of n satisfies d < n and n mod d = 0.
2. Visiting the multiples 2d, 3d, and so on adds d to exactly those n where d is proper.
3. After the sieve, the entry for n holds f(n), the sum of its proper divisors.
4. The recurrence makes a_N the sum of f(k) for k from 2 through N.
5. A prefix array stores every such running sum, so each query reads one entry.

The main terms are:

| term | meaning |
|---|---|
| `divisorSums` | proper divisor sum for each value |
| `sequenceValues` | running total of divisor sums |
| `properDivisor` | current divisor in the sieve |
| `multiple` | current multiple receiving that divisor |
| `largestQuery` | highest N among all queries |

A short script over the sample gives these entries:

| n | proper divisors | f(n) | a_n |
|---|---|---|---|
| 2 | 1 | 1 | 1 |
| 3 | 1 | 1 | 2 |
| 4 | 1, 2 | 3 | 5 |
| 5 | 1 | 1 | 6 |

The last column matches the sample output.
The totals use int64 because they reach beyond 32-bit range.

## Code

**Input and scanning.** The reader collects all queries before sizing the sieve.

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
```

The scanner ignores spacing and line breaks.
The largest query sets the sieve size.
No work is spent beyond the highest N.

**Sieve and prefix sums.** Every divisor is stamped on its proper multiples.

```nim
let testCount = nextInt(inputData, scanPos)
var queries = newSeq[int](testCount)
var largestQuery = 1
for queryIndex in 0 .. testCount - 1:
  queries[queryIndex] = nextInt(inputData, scanPos)
  if queries[queryIndex] > largestQuery:
    largestQuery = queries[queryIndex]

var divisorSums = newSeq[int64](largestQuery + 1)
var properDivisor = 1
while properDivisor <= largestQuery:
  var multiple = properDivisor * 2
  while multiple <= largestQuery:
    divisorSums[multiple] = divisorSums[multiple] + int64(properDivisor)
    multiple += properDivisor
  properDivisor += 1

var sequenceValues = newSeq[int64](largestQuery + 1)
for position in 2 .. largestQuery:
  sequenceValues[position] = sequenceValues[position - 1] + divisorSums[position]
```

The inner loop starts at twice the divisor.
Each stamp adds one proper divisor to one multiple.
The prefix loop turns local sums into sequence values.

**Final write.** One lookup answers each query.

```nim
for queryIndex in 0 .. testCount - 1:
  appendOutput($sequenceValues[queries[queryIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each answer is written from the prefix array.
The buffer collects all lines before one final flush.
The program writes nothing per divisor.

## Complexity

Precomputation dominates the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over T queries | query array |
| divisor sieve | N harmonic steps | array of N integers |
| prefix pass | one pass over N values | prefix array of N integers |
| output | one line per query | block buffer |

The sieve is the only phase that grows with the query values.

| measure | Big O |
|---|---|
| time | O(N log N + T) |
| space | O(N) |

Trial division for every n would cost much more than one shared sieve.
One sieve and one prefix pass finish all queries, which ends the work.
