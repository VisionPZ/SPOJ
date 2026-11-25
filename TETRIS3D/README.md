<https://www.spoj.com/problems/TETRIS3D/>

## Problem

Find the final height of the tallest point after cuboids fall onto a rectangular platform in a fixed order. Each cuboid drops vertically with its `d` by `s` face down and stops on the highest obstacle under its footprint. It then raises every cell of that footprint to that support height plus its own height `w`.

The first input line holds `D S N`: platform length, depth, and block count. Each of the next `N` lines holds `d s w x y`, where `(x,y)` is the lower-left corner of the footprint. Output one integer: the highest final height.

| item | bound |
|---|---|
| platform D, S | 1 to 1000 |
| block count N | 1 to 20000 |
| block height w | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The sample input:

```
7 5 4
4 3 2 0 0
3 3 1 3 0
7 1 2 0 3
2 3 3 2 2
```

The sample output:

```
6
```

## Idea

Think of the platform as a floor of tiles whose heights you can query and raise in rectangles. A quadtree stores the maximum height of each square region, like a map that zooms into four quadrants. A lazy tag lets one rectangle update stop at a whole covered quadrant instead of visiting every tile. One block then costs about `log^2(1000)` node visits, not a scan of its whole footprint.

## Why It Works

1. A falling block rests on the maximum height over its footprint, because that is the first obstacle it meets.
2. After landing, every cell of the footprint holds the same new height: support plus `w`.
3. A quadtree node stores the maximum of its four child quadrants, so the root stores the global maximum.
4. A rectangle query visits only quadrants that touch the rectangle and returns the maximum of their stored values.
5. A rectangle update marks a fully covered quadrant with a lazy value, so its children are fixed only when a later operation descends into them.
6. Pushing a lazy value sets all four children to it and clears the parent tag, keeping every node consistent.
7. Processing blocks in input order gives the same state as the physical fall, so the final root value is the answer.

| term | meaning |
|---|---|
| `gridSize` | smallest power of two covering both platform sides |
| `treeMax` | stored maximum height for each quadtree node |
| `treeLazy` | pending uniform height for a node |
| `pushHeight` | sends a pending height to the four children |
| `supportHeight` | highest existing cell under the current footprint |

The table names the tree arrays and the landing computation.

A worked trace of the sample:

| block | footprint | support | new height |
|---|---|---|---|
| 1 | x 0-3, y 0-2 | 0 | 2 |
| 2 | x 3-5, y 0-2 | 2 | 3 |
| 3 | x 0-6, y 3 | 0 | 2 |
| 4 | x 2-3, y 2-4 | 3 | 6 |

The last block rests on the height-3 cell left by block 2, so the answer is 6.

## Code

**Input, buffer, and tree storage.** All lines enter one buffer, and the quadtree arrays are allocated once.

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

Both coordinates are non-negative, so the scanner needs no sign branch.
The heap-style child indices `4*i-2` through `4*i+1` stay inside `nodeCapacity`.

**Lazy tags.** A pending value covers a whole quadrant and moves to its children on demand.

```nim
proc applyHeight(nodeIndex: int, value: int) =
  treeMax[nodeIndex] = value
  treeLazy[nodeIndex] = value

proc pushHeight(nodeIndex: int) =
  let pending = treeLazy[nodeIndex]
  if pending != 0:
    let firstChild = 4 * nodeIndex - 2
    applyHeight(firstChild, pending)
    applyHeight(firstChild + 1, pending)
    applyHeight(firstChild + 2, pending)
    applyHeight(firstChild + 3, pending)
    treeLazy[nodeIndex] = 0
```

A zero tag means no pending work, and all real heights are positive.
After pushing, the parent maximum stays correct because both children hold the same value.

**Rectangle update.** Fully covered quadrants are tagged; partial ones split into four children.

```nim
proc updateRectangle(nodeIndex: int, leftEdge: int, topEdge: int, rightEdge: int,
                     bottomEdge: int, queryLeft: int, queryTop: int,
                     queryRight: int, queryBottom: int, value: int) =
  if queryRight <= leftEdge or queryLeft >= rightEdge or
     queryBottom <= topEdge or queryTop >= bottomEdge:
    return
  if queryLeft <= leftEdge and rightEdge <= queryRight and
     queryTop <= topEdge and bottomEdge <= queryBottom:
    applyHeight(nodeIndex, value)
    return
  pushHeight(nodeIndex)
  let middleX = (leftEdge + rightEdge) div 2
  let middleY = (topEdge + bottomEdge) div 2
  updateRectangle(4 * nodeIndex - 2, leftEdge, topEdge, middleX, middleY,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex - 1, middleX, topEdge, rightEdge, middleY,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex, leftEdge, middleY, middleX, bottomEdge,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex + 1, middleX, middleY, rightEdge, bottomEdge,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  var highest = treeMax[4 * nodeIndex - 2]
  if treeMax[4 * nodeIndex - 1] > highest:
    highest = treeMax[4 * nodeIndex - 1]
  if treeMax[4 * nodeIndex] > highest:
    highest = treeMax[4 * nodeIndex]
  if treeMax[4 * nodeIndex + 1] > highest:
    highest = treeMax[4 * nodeIndex + 1]
  treeMax[nodeIndex] = highest
```

The first guard skips quadrants that miss the footprint.
The last lines recompute the parent maximum from its four children.

**Rectangle query.** The same quadrant split returns the highest supporting cell.

```nim
proc queryRectangle(nodeIndex: int, leftEdge: int, topEdge: int, rightEdge: int,
                    bottomEdge: int, queryLeft: int, queryTop: int,
                    queryRight: int, queryBottom: int): int =
  if queryRight <= leftEdge or queryLeft >= rightEdge or
     queryBottom <= topEdge or queryTop >= bottomEdge:
    return 0
  if queryLeft <= leftEdge and rightEdge <= queryRight and
     queryTop <= topEdge and bottomEdge <= queryBottom:
    return treeMax[nodeIndex]
  pushHeight(nodeIndex)
  let middleX = (leftEdge + rightEdge) div 2
  let middleY = (topEdge + bottomEdge) div 2
  var highest = queryRectangle(4 * nodeIndex - 2, leftEdge, topEdge, middleX, middleY,
                               queryLeft, queryTop, queryRight, queryBottom)
  let second = queryRectangle(4 * nodeIndex - 1, middleX, topEdge, rightEdge, middleY,
                              queryLeft, queryTop, queryRight, queryBottom)
  if second > highest:
    highest = second
  let third = queryRectangle(4 * nodeIndex, leftEdge, middleY, middleX, bottomEdge,
                             queryLeft, queryTop, queryRight, queryBottom)
  if third > highest:
    highest = third
  let fourth = queryRectangle(4 * nodeIndex + 1, middleX, middleY, rightEdge, bottomEdge,
                              queryLeft, queryTop, queryRight, queryBottom)
  if fourth > highest:
    highest = fourth
  return highest
```

A missed quadrant contributes zero to the maximum.
Pushing before descending exposes children that a parent tag hides.

**Block loop.** Each block reads its footprint, queries support, and writes the new height.

```nim
for blockIndex in 0 .. blockCount - 1:
  let blockLength = nextInt(inputData, scanPos)
  let blockDepth = nextInt(inputData, scanPos)
  let blockHeight = nextInt(inputData, scanPos)
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let supportHeight = queryRectangle(1, 0, 0, gridSize, gridSize,
                                     startX, startY, startX + blockLength, startY + blockDepth)
  updateRectangle(1, 0, 0, gridSize, gridSize, startX, startY,
                  startX + blockLength, startY + blockDepth, supportHeight + blockHeight)

appendOutput($treeMax[1])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The root maximum is the tallest point after every block has landed.
Heights fit in an `int` because 20000 blocks of height 100000 stay below 2^31.

## Complexity

Each rectangle operation visits only quadrants that cover or border the footprint, and the tree depth is ten.

| phase | time | space |
|---|---|---|
| input read | one pass over `5N + 3` integers | one input string |
| support query | O(log^2 gridSize) node visits | quadtree arrays |
| landing update | O(log^2 gridSize) node visits | quadtree arrays |
| output | one line | block buffer |

The phase table shows that queries and updates dominate for large `N`.

| measure | Big O |
|---|---|
| time | O(N * log^2(D+S)) |
| space | O(gridSize^2) |

Scanning each footprint cell costs O(d*s*N) and reaches two times ten to the ten cell writes. Lazy quadrant tags replace that scan with about a hundred node visits per block.
