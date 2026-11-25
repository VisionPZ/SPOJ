# FUSION — Fusion Cube (SPOJ)

<https://www.spoj.com/problems/FUSION/>

## Problem

Each source in a cube fires one electron along a coordinate axis at time zero.
Choose a direction for every source so the first wall hit happens as late as possible.
Report that delay for each test case.

The first line holds the test count `T`.
Each case starts with `K` and `N`, the source count and cube side length.
Then `K` lines each hold three integers `X Y Z`, a source point strictly inside the cube.
Print one integer per case: the largest achievable delay.

| Item | Bound |
|---|---|
| Test cases T | 1 to 50 |
| Sources K | 1 to 100 |
| Cube side N | 1 to 1000 |
| Coordinates | 1 to N-1 on each axis |
| Judge limit | 1000 ms, 1536 MB |

Distances to the six walls are `X`, `N-X`, `Y`, `N-Y`, `Z`, and `N-Z`.

Sample input:

```
2
1 10
5 5 5
2 10
1 1 1
1 1 2
```

Sample output:

```
5
9
```

## Idea

Collisions swap electron identities, like runners passing a baton, so no travel path changes.
Treat each source as choosing its longest clear run, then take the shortest run among sources.
The algorithm finds the largest of six wall distances per source, then the minimum of those maxima.
Each source costs six comparisons, so a case costs O(K) time.
Tracking every collision would add many events without changing the answer.
One pass over the sources settles the case.

## Why It Works

1. A head-on rebound equals two electrons passing through with their names exchanged.
2. A side-on turn equals two electrons exchanging velocity vectors at the contact point.
3. Both exchanges leave the set of straight paths unchanged, so collision times do not matter.
4. A source at coordinate `X` reaches a wall after `X` seconds along the minus axis.
5. The same source reaches the opposite wall after `N-X` seconds along the plus axis.
6. The six axis distances give every allowed direction, and the largest one is best for that source.
7. Directions are independent, so the largest common delay is the minimum of the per-source maxima.

| Term | Meaning |
|---|---|
| `cubeSide` | side length N of the cube |
| `coordinateX` | source position along the X axis |
| `bestDistance` | longest wall distance for one source |
| `firstWallTime` | earliest wall hit among all chosen directions |

For the second sample case with side 10, the point (1, 1, 1) has distances 1 and 9 on every axis.
Its longest run is 9 seconds.
The point (1, 1, 2) has distances 1, 9, 1, 9, 2, 8, so its longest run is also 9 seconds.
The smallest of the two maxima is 9, matching the sample output.

Coordinate differences stay positive because sources lie strictly inside the cube.
All distances are integers, so the answer is an integer with no rounding step.

## Code

**Input and hand scanner.** The reader loads all text once and parses integers without library calls.

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

`scanPos` advances past separators and digits.
The value 48 converts a digit character into its numeric value.
The buffer keeps one copy of the whole input.

**Buffered solution loop.** Each source contributes its longest run, and the case answer is the minimum.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
for testCaseIndex in 0 .. testCaseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  let cubeSide = nextInt(inputData, scanPos)
  var firstWallTime = cubeSide
  for sourceIndex in 0 .. sourceCount - 1:
    let coordinateX = nextInt(inputData, scanPos)
    let coordinateY = nextInt(inputData, scanPos)
    let coordinateZ = nextInt(inputData, scanPos)
    var bestDistance = coordinateX
    if cubeSide - coordinateX > bestDistance:
      bestDistance = cubeSide - coordinateX
    if coordinateY > bestDistance:
      bestDistance = coordinateY
    if cubeSide - coordinateY > bestDistance:
      bestDistance = cubeSide - coordinateY
    if coordinateZ > bestDistance:
      bestDistance = coordinateZ
    if cubeSide - coordinateZ > bestDistance:
      bestDistance = cubeSide - coordinateZ
    if bestDistance < firstWallTime:
      firstWallTime = bestDistance
  appendOutput($firstWallTime)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Six comparisons update `bestDistance` for the current source.
A smaller `bestDistance` lowers `firstWallTime` for the case.
`appendOutput` writes to `stdout` only when the block fills.
The final write flushes the remaining text.

## Complexity

Each case reads its sources once and emits one answer.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all integers | one input string |
| Direction scan | six comparisons per source | constant working space |
| Output | one line per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(K) |
| Space | O(K + input size) |

Simulating collisions step by step would spend time on events that never change path lengths.
Each case collapses to one scan over `sourceCount` sources.
