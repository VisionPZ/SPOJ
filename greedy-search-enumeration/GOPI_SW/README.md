# GOPI_SW — Gopi and Sandwich (SPOJ)

<https://www.spoj.com/problems/GOPI_SW/>

## Problem

Split one whole sandwich into n parts, each part a unit fraction, and make the smallest part as tiny as possible. Report the denominator of that smallest part, modulo 1000000007.

Input starts with the test count t. Each following line gives one part count n, from 2 to 1000000. Output one denominator per line.

| item | bound |
|---|---|
| test count t | 1 to 100000 |
| part count n | 2 to 1000000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The large test count makes a precomputed table necessary.

Sample input:

```
1
3
```

Sample output:

```
6
```

## Idea

Splitting a unit fraction is like breaking one link into two longer links; always breaking the longest link gives the tiniest final piece. The real algorithm uses the Sylvester term sequence and stores every answer in a table. Each test then costs one lookup, while precomputation costs O(max n) steps. Testing every possible split would grow far faster.

A table of denominators answers all tests without repeated work.

## Why It Works

1. Replacing 1 over p by 1 over p plus 1 and 1 over p times p plus 1 keeps the total unchanged and adds one part.
2. A split of p creates the denominator p times p plus 1, which grows with p.
3. Splitting the current largest denominator gives the largest possible next denominator.
4. Starting from two halves gives denominators 2, 6, 42, 1806 and so on.
5. The nth answer equals the product of the first n minus 1 Sylvester terms, taken modulo the modulus.

| term | meaning |
|---|---|
| `smallestPossible` | stored answer for each part count |
| `largestSplit` | largest part count in the input range |
| `modulusValue` | the prime modulus 1000000007 |
| `partCount` | number of unit fractions in one test |

For the sample n = 3, two halves become 1/2, 1/3 and 1/6. The largest denominator is 2 times 3, which is 6. The table stores 6 at index 3 and prints it.

The recurrence multiplies numbers below the modulus, so each product stays inside int64.

## Code

**Input and table setup.** The reader parses all tests while the table is filled once.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007
const largestSplit = 1000000

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

The table covers the full input range of one million parts.
The modulus keeps every stored value below 1000000007.
The output buffer collects lines before writing.

**Recurrence and lookups.** One pass fills the table and each test reads one entry.

```nim
var smallestPossible = newSeq[int64](largestSplit + 1)
smallestPossible[2] = 2
for splitCount in 3 .. largestSplit:
  let previous = smallestPossible[splitCount - 1]
  smallestPossible[splitCount] = (previous * (previous + 1)) mod modulusValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let partCount = nextInt(inputData, scanPos)
  appendOutput($smallestPossible[partCount])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop starts at 2 because two halves are the base case.
A part count of one million needs one million recurrence steps.
Each test appends one line through the shared buffer.

## Complexity

Precomputation dominates the cost because each query is a lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table fill | one recurrence step per part count | one million integers |
| output | one flush per block | block buffer |

Queries add only O(t) work after the table is ready.

| measure | Big O |
|---|---|
| time | O(max n + t) |
| space | O(max n) for the table |

Searching all split patterns for every test would be exponential.

The table keeps all 100000 tests well inside the time limit.
