# GDGALKN — Gordon and Gallery (SPOJ)

<https://www.spoj.com/problems/GDGALKN/>

## Problem

A bank has the shape of an irregular closed polygon with `N` corners. A camera fixed at a corner swivels across the interior wedge between the two walls that meet there and sees every point in that wedge. Gordon wants the fewest cameras that together watch the whole interior of the bank.

The input starts with the number of test cases `T`. Each of the following `T` lines holds one polygon size `N`. Print one answer per case: the minimum number of cameras.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 1000 |
| Polygon sides `N` | 3 to 100000 |
| Judge limit | 1000 ms |
| Memory | 1536 MB |

The largest `N` is large but each case needs only one integer operation.

The sample input:

```
1
8
```

The sample output:

```
2
```

## Idea

Think of museum guards standing in the corners of a crooked gallery. A guard at one corner watches the whole triangular wedge in front of that corner. Chvátal's art gallery theorem gives the exact answer: `N` corners need at most `floor(N / 3)` guards. Some polygon shapes need that many.

Triangulate the polygon and color its vertices with three colors, one per triangle. The smallest color class has at most `floor(N / 3)` vertices. Cameras on those vertices cover every triangle. A comb-shaped polygon with three spikes per guard shows the bound cannot be improved.

Each test case costs one division by three, after one pass over the input tokens.

## Why It Works

1. Triangulation splits an `N`-gon into `N - 2` triangles whose vertices are polygon corners.
2. Fan coloring gives three classes, so the smallest class holds at most `floor(N / 3)` corners.
3. Every triangle contains one corner of each class, so cameras on the smallest class see every triangle.
4. A polygon built from `K` separated spikes needs one camera per spike, which matches `floor(N / 3)`.

| Term | Meaning |
|---|---|
| `N` | number of polygon sides, equal to the number of corners |
| `triangulation` | split of the polygon into triangles using only its corners |
| `color class` | set of corners sharing one of the three colors |
| `floor(N / 3)` | integer division of `N` by three |

The smallest color class is the set of corners that carry the cameras.

A script-generated view of the answer rule:

```
N = 3   -> 3 div 3 = 1
N = 4   -> 4 div 3 = 1
N = 5   -> 5 div 3 = 1
N = 6   -> 6 div 3 = 2
N = 8   -> 8 div 3 = 2
```

The last row is the sample answer: eight corners need two cameras.

## Code

**Input and scanner.** One string holds all lines and a hand scanner reads each integer.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The loop appends one newline per input line, so token boundaries survive. `scanPos` advances through the string without copying tokens.

**Output buffer.** Answers accumulate until the block limit is reached.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush keeps memory bounded and avoids one write call per answer. The size check uses a power of two.

**Answer loop.** Each polygon contributes one division result.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let sideCount = nextInt(inputData, scanPos)
  appendOutput($(sideCount div 3))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`caseIndex` runs exactly `caseCount` times. The final flush emits bytes left in the buffer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| One case | one integer division | constant |
| Output | one write per 128 KiB block | one buffer |

The case loop does no work beyond parsing and dividing.

| Measure | Big O |
|---|---|
| Time | O(T) after reading input |
| Space | O(input bytes) |

Trying every subset of corners would take exponential time; the theorem gives a single division.
