# TCOUNT2 — Counting Triangles II (SPOJ)

<https://www.spoj.com/problems/TCOUNT2/>

## Problem

A level N triangle has side N on a triangular grid. Six such triangles join into a level N hexagon. Count every equilateral triangle, of any side length, that fits in that hexagon.

The first line gives the number of test cases. Each following line gives one level N. Print one count per line. Counts fit in an unsigned 64-bit integer.

| item | bound |
|---|---|
| test cases | given on the first line |
| level N | positive integer with a 64-bit answer |
| answer | unsigned 64-bit integer |
| judge limit | 100 ms |

The answer depends only on N, so each case costs one arithmetic evaluation.

Sample input:

```
1
1
```

Sample output:

```
6
```

## Idea

Treat the hexagon as six copies of one triangle, like six slices of the same pie, and count all triangles in the whole picture with one polynomial.

The algorithm evaluates a cubic formula with a parity split. Each case costs a fixed number of 64-bit operations. Enumerating triangles by side and position costs at least cubic time per case and grows too large for big levels.

A closed form replaces geometric enumeration entirely.

## Why It Works

1. A level N hexagon covers six level N triangles and has side N in grid units.
2. Direct enumeration for levels 1 to 8 gives 6, 38, 116, 262, 496, 840, 1314, 1940.
3. Those values follow a cubic sequence with a period of two.
4. For an odd level the count is `currentLevel` times ((7 times its square plus 1) divided by 2), plus two adjacent odd halves.
5. For an even level the extra ring contributes 3N(3N minus 1) plus 3N(N minus 2) divided by 2 plus 2, then the odd formula uses N minus 1.

| term | meaning |
|---|---|
| `rawLevel` | level read from the input line |
| `currentLevel` | level used by the odd formula |
| `triangleTotal` | accumulated count for one case |

The table names the only values the program needs.

A trace for the first two levels:

```
level  even ring  odd part  total
1      0          6         6
2      32         6         38
```

The trace reproduces both the sample and the next enumerated level.

## Code

**Input and output setup.** The program reads all input once and buffers all answers.

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

The scanner skips separators and builds integers digit by digit.
One buffer collects every answer line.
Flushing happens once per 128 KiB and once at the end.

**Level evaluation.** Each line becomes one 64-bit count.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let rawLevel = nextInt(inputData, scanPos)
  if rawLevel == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  var currentLevel = uint64(rawLevel)
  var triangleTotal: uint64 = 0'u64
  if (currentLevel and 1'u64) == 0'u64:
    triangleTotal = 3'u64 * currentLevel * (3'u64 * currentLevel - 1'u64) +
                    3'u64 * currentLevel * (currentLevel - 2'u64) div 2'u64 + 2'u64
    currentLevel = currentLevel - 1'u64
  triangleTotal = triangleTotal +
                  currentLevel * ((7'u64 * currentLevel * currentLevel + 1'u64) div 2'u64) +
                  ((3'u64 * currentLevel + 1'u64) div 2'u64) *
                  ((3'u64 * currentLevel - 1'u64) div 2'u64)
  appendOutput($triangleTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Even levels first add the outer ring and step down by one.
Odd levels use the cubic expression directly.
Unsigned division keeps exact halves, and 64-bit words hold the full answer.

## Complexity

Each case uses a constant number of arithmetic operations.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| level evaluation | constant work per case | one counter per case |
| output | one line per case | block buffer |

The phase table shows that input size, not level size, drives the run time.

| measure | Big O |
|---|---|
| time | O(input bytes) |
| space | O(input bytes) |

Enumerating every triangle would cost cubic time per level, while the formula costs one step.
