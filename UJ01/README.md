# UJ01 — Save the Scofield !! (SPOJ)

<https://www.spoj.com/problems/UJ01/>

## Problem

Merge the two multiplication tables of A and B, keep each value once, and report the Nth smallest merged value.

Input starts with a test count T. Each test gives three integers A, B, and N. Print the Nth distinct number that is a multiple of A or a multiple of B. N counts from 1.

| item | bound |
|---|---|
| tests T | 1 to 300000 |
| A, B | 1 to 1000 |
| rank N | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The merged table is the sorted set of all positive multiples of A or B. A shared multiple appears once.

Sample input:

```
4
3 5 2
3 5 3
2 3 4
2 3 6
```

Sample output:

```
5
6
6
9
```

## Idea

Count how many merged values sit at or below a guess. Then find the smallest guess whose count reaches N. This is like finding a page by cutting the book in half.

The algorithm is binary search on the answer value. Inclusion-exclusion counts multiples of A, multiples of B, and subtracts shared multiples of the least common multiple. Each count costs O(1), so a test takes O(log(A·N)) steps. Listing the table up to the answer would take O(N) steps and overflow both time and memory at large N.

## Why It Works

1. Every merged value is a positive multiple of A or of B.
2. The count up to x is x/A + x/B − x/L, where L is the least common multiple.
3. Subtracting x/L removes each shared multiple counted twice.
4. The count never decreases as x grows, so binary search applies.
5. The smallest x with count at least N is exactly the Nth merged value.

| term | meaning |
|---|---|
| `firstStep` | the step A of the first table |
| `secondStep` | the step B of the second table |
| `commonStep` | the least common multiple L |
| `targetRank` | the requested rank N |
| `countMultiples` | merged values at or below a guess |

The worked example uses A = 3, B = 5, and N = 2 from the sample.

| guess x | x/3 | x/5 | x/15 | count | at least 2 |
|---|---|---|---|---|---|
| 3 | 1 | 0 | 0 | 1 | no |
| 4 | 1 | 0 | 0 | 1 | no |
| 5 | 1 | 1 | 0 | 2 | yes |

The smallest qualifying guess is 5, which matches the sample output.

The search upper bound is N times the smaller step. That bound alone supplies at least N distinct multiples, so the answer always lies inside it. Products stay below 1e12 and fit in int64.

## Code

**Input and helpers.** The reader loads stdin once and supplies a hand scanner, a gcd routine, and a block-buffered writer.

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

proc gcdValues(left: int64, right: int64): int64 =
  var first = left
  var second = right
  while second != 0:
    let remainder = first mod second
    first = second
    second = remainder
  return first

proc countMultiples(limit: int64, firstStep: int64, secondStep: int64, commonStep: int64): int64 =
  return limit div firstStep + limit div secondStep - limit div commonStep

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The gcd drives the least common multiple without overflow.
The counting formula is the inclusion-exclusion rule above.
All arithmetic uses int64 for large ranks.

**Binary search.** Each test narrows the interval until one value remains.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstStep = int64(nextInt(inputData, scanPos))
  let secondStep = int64(nextInt(inputData, scanPos))
  let targetRank = int64(nextInt(inputData, scanPos))
  let smallerStep = if firstStep < secondStep: firstStep else: secondStep
  let divisor = gcdValues(firstStep, secondStep)
  let commonStep = firstStep div divisor * secondStep
  var lowBound: int64 = 1
  var highBound: int64 = targetRank * smallerStep
  while lowBound < highBound:
    let middle = lowBound + (highBound - lowBound) div 2
    if countMultiples(middle, firstStep, secondStep, commonStep) >= targetRank:
      highBound = middle
    else:
      lowBound = middle + 1
  appendOutput($lowBound)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The interval shrinks by half on every pass.
The smallest passing guess is the answer.
Results are appended to the shared output buffer.

## Complexity

Each test searches a bounded integer interval and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over the triples | one input string |
| binary search | about 40 counting steps | constant state |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time per test | O(log(A·N)) |
| space per test | O(1) beyond input |

Generating every merged value up to the answer would take O(answer) time and fail for large ranks.
Counting first makes each step constant and the whole test logarithmic.

Binary search needs the monotonic count from fact 3; without inclusion-exclusion the count would overcount shared multiples.
