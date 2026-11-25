# BOKAM143SOU — Checking cubes. (SPOJ)
<https://www.spoj.com/problems/BOKAM143SOU/>

## Problem

Given one integer N, count the ways to write N as a sum of at most five positive cubes. Changing the order of the cubes does not make a new way.

Input holds one line with the integer N. Output holds one line with the count.

| quantity | bound |
|---|---|
| target N | 1 to 125000 |
| cubes per way | 1 to 5 |
| cube values | 1, 8, 27, and so on |
| judge limit | 1000 ms, 1536 MB |

The target fits in a table of sums, so one dynamic program answers the whole input.

Sample input:

```
64
```

Sample output:

```
2
```

The two ways are 64 and 27 plus 27 plus 8 plus 1 plus 1.

## Idea

Packing boxes from a shelf is a good picture: take box sizes in shelf order, so each packing is counted once. The program walks through cube values and records how many sums each cube count can reach.

The table has one row for each count from zero to five and one column for each sum. Adding cube value c to a sum s minus c extends every way with one fewer cube. This is unbounded knapsack with an exact item count, and it costs O(R times 5 times N) for R cube values.

Listing every multiset would test about C(R plus 5, 5) combinations, which is much larger than the table sweep.

Count each multiset once by visiting cube values in increasing order.

## Why It Works

1. A way is a multiset of positive cubes, because order does not matter.
2. Processing cube values in order fixes that multiset order.
3. A row k holds ways to reach a sum with exactly k cubes.
4. Adding one cube c moves a way from row k minus one into row k.
5. Reading rows k minus one after earlier cube values lets a cube repeat.
6. Summing rows one through five gives every allowed way.

| term | meaning |
|---|---|
| `targetSum` | input value N to represent |
| `maxRoot` | largest root whose cube fits in N |
| `cubeValues` | list of positive cubes up to N |
| `representationCounts` | ways indexed by cube count and sum |
| `answer` | total over all allowed cube counts |

The empty sum seeds row zero with one way and every other cell with zero.

For N equals 64, the cube values are 1, 8, 27, and 64. Row one reaches 64 once through the cube 64. Row five reaches 64 once through 27 plus 27 plus 8 plus 1 plus 1. The sum of rows one to five is 2.

For N equals 1, only the cube 1 works, so the answer is 1. For N equals 905, no multiset of at most five cubes adds up, so the answer is 0.

Counts stay small for this limit, but the table uses `int64` so additions cannot wrap.

## Code

**Input and cube list.** The reader parses N and builds all cubes up to it.

```nim
const flushBlockBytes = 1 shl 17
const maxCubeCount = 5

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

let targetSum = nextInt(inputData, scanPos)
var maxRoot = 1
while int64(maxRoot + 1) * int64(maxRoot + 1) * int64(maxRoot + 1) <= int64(targetSum):
  maxRoot = maxRoot + 1

var cubeValues = newSeq[int](maxRoot)
for rootValue in 1 .. maxRoot:
  cubeValues[rootValue - 1] = rootValue * rootValue * rootValue
```

The cube root search uses `int64` products.
The cube values are sorted by construction.
Each value will be processed once.

**Counting table.** The sweep fills all rows and prints their total at N.

```nim
var representationCounts = newSeq[seq[int64]](maxCubeCount + 1)
for countIndex in 0 .. maxCubeCount:
  representationCounts[countIndex] = newSeq[int64](targetSum + 1)
representationCounts[0][0] = 1

for cubeValue in cubeValues:
  for cubeCount in 1 .. maxCubeCount:
    for sumValue in cubeValue .. targetSum:
      representationCounts[cubeCount][sumValue] = representationCounts[cubeCount][sumValue] + representationCounts[cubeCount - 1][sumValue - cubeValue]

var answer: int64 = 0
for cubeCount in 1 .. maxCubeCount:
  answer = answer + representationCounts[cubeCount][targetSum]
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Row zero starts with a single empty way.
The inner loop extends smaller sums into larger ones.
The final loop totals all five rows.

## Complexity

The cube list is short, and the sum table drives the work.

| phase | time | space |
|---|---|---|
| input read | one integer | one input string |
| cube list | up to the cube root of N | R integers |
| table fill | R times five times N updates | six rows of N plus one |
| output | one line | block buffer |

At N equals 125000, R is 50 and the table has about 31 million cells to update.

| measure | Big O |
|---|---|
| time | O(R * N) with a factor of five |
| space | O(N) |

Listing every multiset would cost O(R^5) in the worst case.

The table sweep counts all representations with one pass over cube values.
