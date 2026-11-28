# EKO — Eko (SPOJ)

<https://www.spoj.com/problems/EKO/>

## Problem

A sawblade at integer height H removes the part of every tree above H. Choose the highest H that still removes at least M meters of wood in total.

Input is one case. The first line gives N and M. The second line gives N tree heights in meters. Output one integer: the highest valid H.

| item | bound |
|---|---|
| tree count N | 1 to 1000000 |
| required wood M | 1 to 2000000000 |
| tree height | positive, below 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The total wood at H = 0 exceeds M, so a valid height always exists.

Sample input:

```
4 7
20 15 10 17
```

Sample output:

```
15
```

## Idea

Cutting higher removes less wood, like lowering a bar that each tree must reach under. Binary search on H finds the last height whose total reaches M.

Each probe scans all N trees once and adds `treeHeights[treeIndex] - middleHeight` for the trees that are taller. That is O(N) per probe and O(N log Hmax) overall. A linear scan from zero to Hmax would take O(N · Hmax), which is far larger when heights reach one billion. Binary search keeps the work near thirty scans.

## Why It Works

1. The wood removed by one tree at height H is max(0, tree height − H).
2. The total removed wood decreases as H rises, so the predicate "total ≥ M" is monotone.
3. Monotonicity lets binary search jump to the largest true H.
4. The answer lies between 0 and the largest tree height.
5. Sums reach about 10^15, so `collectedWood` uses `int64`.

| term | meaning |
|---|---|
| `treeHeights` | heights of all trees in input order |
| `middleHeight` | trial sawblade height in one probe |
| `collectedWood` | 64-bit total removed in one probe |
| `lowHeight` | lowest height known to remove enough wood |

For the sample 20 15 10 17 with M = 7, the table shows the removed wood at trial heights.

| H | removed per tree | total | enough |
|---|---|---|---|
| 15 | 5, 0, 0, 2 | 7 | yes |
| 16 | 4, 0, 0, 1 | 5 | no |

Height 15 is the largest true height, so it is the answer.

The midpoint formula adds one before dividing to avoid an infinite loop when two values differ by one. No rounding applies because every height is an integer.

## Code

**Input and scanner.** The reader loads the whole case and parses both header values and all heights.

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
```

Each `readLine` adds one trailing newline to the single input string.
The scanner skips separators and builds each value from its digits.
Heights are positive, so no minus branch is needed.

**Output buffer.** One string collects output and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after it passes `flushBlockBytes`.
One final write emits the single answer line.

**Binary search.** Each probe totals the wood cut above the trial height.

```nim
let treeCount = nextInt(inputData, scanPos)
let requiredWood = nextInt(inputData, scanPos)
var treeHeights = newSeq[int](treeCount)
var maxHeight = 0
for treeIndex in 0 .. treeCount - 1:
  let currentHeight = nextInt(inputData, scanPos)
  treeHeights[treeIndex] = currentHeight
  if currentHeight > maxHeight:
    maxHeight = currentHeight

var lowHeight = 0
var highHeight = maxHeight
while lowHeight < highHeight:
  let middleHeight = (lowHeight + highHeight + 1) div 2
  var collectedWood: int64 = 0
  for treeIndex in 0 .. treeCount - 1:
    if treeHeights[treeIndex] > middleHeight:
      collectedWood = collectedWood + int64(treeHeights[treeIndex] - middleHeight)
  if collectedWood >= int64(requiredWood):
    lowHeight = middleHeight
  else:
    highHeight = middleHeight - 1

appendOutput($lowHeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The upper bound starts at the tallest tree.
A true probe moves `lowHeight` up; a false probe moves `highHeight` down.
The loop ends with the highest valid height in `lowHeight`.

## Complexity

The program reads the trees once, then probes about thirty heights.

| phase | time | space |
|---|---|---|
| input read | one pass over N heights | one input string |
| height search | about log2(Hmax) probes of N trees | array of N integers |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N log Hmax) |
| space | O(N) |

A linear height scan would cost O(N · Hmax) instead of about thirty tree passes. Binary search trims a billion-height range to a few dozen probes.
