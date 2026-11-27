<https://www.spoj.com/problems/VPL0_C/>

## Problem

Take the chain 1, 1+K+1, 1+K+1+K+2, ... and report its member not above N that has the most divisors; on a tie report the smaller member. Print one labeled line per test case with that member and its divisor count.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| maximum N | 1 to 10000000 |
| progression step K | 0 to 100 |
| judge limit | 1000 ms, 1536 MB |

The n-th member equals 1 + nK + n(n+1)/2, so the chain has about 4470 members at N = 10000000.

Sample input:

```
4
4 0
28 1
2 2
78 3
```

Sample output:

```
Scenario #1: 4 3
Scenario #2: 28 6
Scenario #3: 1 1
Scenario #4: 40 8
```

## Idea

Dividing a rope into evenly growing chunks is like this chain: each step adds one more unit than the last. A sieve writes every divisor count once, then each member is a table lookup. Counting divisors for every member by trial division repeats the same work for every test case.

The sieve adds 1 to each multiple of every divisor. One pass builds all counts up to the largest N in the input.

Scan chain members in increasing order and replace the best only on a strict improvement; ties keep the smaller member.

## Why It Works

1. Member n is 1 plus K added n times plus the triangular number n(n+1)/2.
2. The members strictly increase, since each step adds K+n+1 > 0.
3. After the sieve, `divisorCounts[termValue]` holds the divisor count of that member.
4. A strict improvement keeps the first member with a given count, which is the smaller one.

| term | meaning |
|---|---|
| `termValue` | current member of the chain |
| `progressionStep` | the given constant K |
| `divisorCounts` | divisor count for every value up to the largest N |
| `bestDivisors` | largest divisor count seen in this case |

For N = 28 and K = 1 the members are 1, 3, 6, 10, 15, 21, 28 with counts 1, 2, 4, 4, 4, 4, 6.

The sieve cost is one harmonic sum over the largest N; the case cost is one pass over the chain.

## Code

**Input and scanning.** The reader loads every test case before the sieve chooses its size.

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

Whitespace between tokens is ignored by the scanner.
One string holds all input and one string holds all output.

**Divisor sieve.** Each divisor increments the count of each of its multiples once.

```nim
let caseCount = nextInt(inputData, scanPos)
var numberLimits = newSeq[int](caseCount)
var progressionOffsets = newSeq[int](caseCount)
var largestLimit = 0
for caseIndex in 0 .. caseCount - 1:
  numberLimits[caseIndex] = nextInt(inputData, scanPos)
  progressionOffsets[caseIndex] = nextInt(inputData, scanPos)
  if numberLimits[caseIndex] > largestLimit:
    largestLimit = numberLimits[caseIndex]

var divisorCounts = newSeq[int16](largestLimit + 1)
for divisor in 1 .. largestLimit:
  var multiple = divisor
  while multiple <= largestLimit:
    inc divisorCounts[multiple]
    multiple += divisor
```

The table is sized once from the largest N.
Counts fit in 16 bits because the maximum count stays far below that range.

**Case scan.** The chain walk stops at the first member above N.

```nim
for caseIndex in 0 .. caseCount - 1:
  let numberLimit = numberLimits[caseIndex]
  let progressionStep = progressionOffsets[caseIndex]
  var bestNumber = 0
  var bestDivisors = 0
  var termIndex = 0
  while true:
    let termValue = 1 + termIndex * progressionStep + termIndex * (termIndex + 1) div 2
    if termValue > numberLimit:
      break
    let divisorTotal = int(divisorCounts[termValue])
    if divisorTotal > bestDivisors:
      bestDivisors = divisorTotal
      bestNumber = termValue
    termIndex += 1
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $bestNumber & " " & $bestDivisors)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A strict comparison resolves ties toward the smaller member.
The final flush writes all labeled lines at once.

## Complexity

The sieve touches each multiple once per divisor.

| phase | time | space |
|---|---|---|
| input read | one pass over the token stream | one input string |
| divisor sieve | N log N increments | counts up to largest N |
| case scan | about sqrt(2N) lookups per case | two case arrays |

| measure | Big O |
|---|---|
| time | O(N log N + T sqrt(N)) |
| space | O(N) |

Trial division per member would multiply the chain length by another square root.

Build the table once, then answer every case with a short chain walk.
