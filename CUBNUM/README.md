# CUBNUM — Cube Numbers (SPOJ)

<https://www.spoj.com/problems/CUBNUM/>

## Problem

Write each integer as a sum of positive cubes using the fewest terms, and print that smallest term count. Input runs until end of file, and each answer is labeled with its case number.

Each line of input holds one integer. Print `Case #X: M` for the X-th value, where M is the minimum number of cubes. No extra spaces or blank lines appear.

| Item | Bound |
|---|---|
| Value per case | 1 to 100000 |
| Total cases | fewer than 100000 |
| Judge limit | 200 ms, 1536 MB |

Cubes up to 46 cubed, which is 97336, are relevant for this bound.

The sample lists five values:

```
1
2
5
8
35
```

The expected output is:

```
Case #1: 1
Case #2: 2
Case #3: 5
Case #4: 1
Case #5: 2
```

## Idea

Fill a recipe book once, where every total stores the shortest recipe built from earlier totals plus one cube, like writing a multiplication table before answering questions about it. Use unbounded coin-change dynamic programming with the cubes as coin values. Each table entry costs one check per cube, while recomputing a search per input value would repeat the same work many times. Answering a case is then one table lookup.

## Why It Works

1. Every positive cube is at most the target value, so only cubes up to 46 cubed matter.
2. A representation with k cubes ends with one cube c and a representation of the value minus c.
3. Trying every possible last cube finds the smallest k for that value.
4. Values are filled in increasing order, so the smaller remainder is already solved.
5. Reusing the cube at a later step is allowed, which matches an unbounded coin change.
6. Every integer is a sum of at most nine positive cubes, so a small answer always exists.

| Term | Meaning |
|---|---|
| `maximumValue` | largest input value, 100000 |
| `largestCubeRoot` | largest root whose cube stays within the bound |
| `cubeValues` | the positive cubes used as summands |
| `minimumCubes` | fewest cubes needed for each amount |
| `caseIndex` | one-based number printed with each answer |

The table covers every legal input, so lookups never fail.

Building totals for the first few values gives:

```
value 1: 1 = 1^3                     -> 1 cube
value 2: 2 = 1^3 + 1^3               -> 2 cubes
value 5: 5 = five copies of 1^3      -> 5 cubes
value 8: 8 = 2^3                     -> 1 cube
value 35: 35 = 2^3 + 3^3             -> 2 cubes
```

The trace matches all five sample answers.

## Code

**Input and scanning.** The hand reader loads the whole file once.

```nim
const flushBlockBytes = 1 shl 17
const maximumValue = 100000
const largestCubeRoot = 46

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

Input ends at EOF, so no case count is present.
The scanner skips line breaks between values.
All values are positive, so no sign branch is needed.

**Precomputation.** One pass fills the shortest-recipe table.

```nim
var cubeValues = newSeq[int](largestCubeRoot)
for cubeRoot in 1 .. largestCubeRoot:
  cubeValues[cubeRoot - 1] = cubeRoot * cubeRoot * cubeRoot
var minimumCubes = newSeq[int](maximumValue + 1)
for amount in 1 .. maximumValue:
  minimumCubes[amount] = amount
  for cubeIndex in 0 .. largestCubeRoot - 1:
    let cubeValue = cubeValues[cubeIndex]
    if cubeValue > amount:
      break
    let candidate = minimumCubes[amount - cubeValue] + 1
    if candidate < minimumCubes[amount]:
      minimumCubes[amount] = candidate
```

Using ones alone gives a valid starting count for every amount.
The cube loop stops once a cube exceeds the amount.
Each smaller remainder is already solved because amounts rise in order.

**Output loop.** Values are consumed until no digits remain.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseIndex = 1
while true:
  var lookaheadPos = scanPos
  while lookaheadPos < inputData.len and (inputData[lookaheadPos] < '0' or inputData[lookaheadPos] > '9'):
    lookaheadPos += 1
  if lookaheadPos >= inputData.len:
    break
  scanPos = lookaheadPos
  let targetValue = nextInt(inputData, scanPos)
  appendOutput("Case #" & $caseIndex & ": " & $minimumCubes[targetValue])
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The lookahead detects EOF before scanning a number.
Each answer combines the case label and the table value.
The block buffer flushes large answer lists in chunks.

## Complexity

The precomputation dominates the run, since each case is a lookup.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the case list | one input string |
| Precompute | up to 100000 times 46 cube checks | two integer tables |
| Output | one labeled line per case | block buffer |

No per-case search is performed.

| Measure | Big O |
|---|---|
| Time | O(100000 × 46 + T) |
| Space | O(100000) |

A fresh search for each case would repeat the whole table build, so precomputation wins.
