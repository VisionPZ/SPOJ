## Problem

A skater starts at one point of a square rink and must reach a finish point. Obstacles are orthogonal polygons with no shared points. A slide runs along an axis until it meets the first wall whose interior lies ahead of the slide, or until it passes the finish point. Write the minimum number of slides, or `NO` when no route reaches the finish.

| Quantity | Bound |
| --- | --- |
| Rink side | 10000 |
| Obstacles per case | 2500 |
| Total walls per case | 10000 |
| Coordinates | 0 to 10000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The wall count, not the rink area, sets the work per case.

## Idea

Model every obstacle wall as a state and slide from one wall to the next wall that faces the motion. A sweep over x and a sweep over y compute the landing wall for every state and both slide directions. Breadth-first search over those transitions gives the minimum slide count.
One state costs two direction checks and constant work.

## Why It Works

A slide stops at the nearest perpendicular wall whose interior is on the far side. Walls parallel to the slide never stop it.
At a sweep line, the active walls are exactly the walls crossing that line. A Fenwick tree holds their positions and finds the nearest active wall in logarithmic time.
At a reflex corner, the slide stops on the adjacent wall. The `isLeft` test finds those corners after both sweeps.
The `landing` table stores the next wall for each state and direction. Breadth-first search visits states in slide order, so the first finish hit is minimal.

`cell` coordinates are not needed. State `i` denotes the wall starting at vertex `i`, and `nextVertex[i]` ends that wall.

A script in `gen.py --example` traces the sample. Its output is:

`(40,10) -> E(55,10) -> S(55,35) -> W(5,35) -> S(5,40)`

That route uses four slides, which matches the sample output.

## Code

```nim
{.push checks: off.}
{.passC: "-O2".}
import std/algorithm
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const rinkExtent = 10000
const infinity = 65535

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

var outputBuffer = ""
var sweepStarts = newSeq[seq[int]](rinkExtent + 1)
var sweepEnds = newSeq[seq[int]](rinkExtent + 1)
var touchedLines: seq[int] = @[]

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop stores all input in one string. The scanner skips the blank lines between cases. Sweep buffers are allocated once and reused, so many small cases stay cheap.

```nim
type
  Solver = object
    px: seq[int]
    py: seq[int]
    nextVertex: seq[int]
    prevVertex: seq[int]
    landing: array[2, seq[int]]
    startX, startY, finishX, finishY: int
    vertexCount: int
    depth: int
    seen: seq[int]
    answer: int

proc isLeft(solver: Solver, xOne, yOne, xTwo, yTwo, pointX, pointY: int): bool =
  int64(yOne - pointY) * int64(xTwo - xOne) < int64(yOne - yTwo) * int64(pointX - xOne)

proc isRightCorner(solver: Solver, vertex, pointX, pointY: int): bool =
  let after = solver.nextVertex[vertex]
  let before = solver.prevVertex[vertex]
  let first = solver.px[vertex] == pointX and solver.py[vertex] == pointY and
    not solver.isLeft(solver.px[before], solver.py[before], solver.px[vertex], solver.py[vertex],
                      solver.px[after], solver.py[after])
  let second = solver.px[after] == pointX and solver.py[after] == pointY and
    not solver.isLeft(solver.px[vertex], solver.py[vertex], solver.px[after], solver.py[after],
                      solver.px[solver.nextVertex[after]], solver.py[solver.nextVertex[after]])
  return first or second
```

The object holds the wall rings and the landing table. `isRightCorner` rejects a wall that does not bound the interior toward the sliding point. The cross product uses `int64` so large coordinates cannot overflow.

```nim
proc routeX(solver: var Solver, dirRight: bool, state, landing: int,
            qOne: var seq[int], qTwo: var seq[int]) =
  if solver.py[state] == solver.finishY:
    var edgeX = solver.px[state]
    let otherX = solver.px[solver.nextVertex[state]]
    if (edgeX > otherX) == dirRight:
      edgeX = otherX
    if dirRight:
      if solver.finishX > edgeX and (landing == 0 or solver.finishX <= solver.px[landing]):
        solver.answer = solver.depth + 1
        return
    elif solver.finishX < edgeX and (landing == 0 or solver.finishX >= solver.px[landing]):
      solver.answer = solver.depth + 1
      return
  if landing == 0:
    return
  solver.addQueue(1, landing, qOne, qTwo)
  if solver.py[landing] == solver.py[state]:
    solver.addQueue(1, solver.prevVertex[landing], qOne, qTwo)
  elif solver.py[solver.nextVertex[landing]] == solver.py[state]:
    solver.addQueue(1, solver.nextVertex[landing], qOne, qTwo)
  if (solver.px[state] < solver.px[solver.nextVertex[state]]) == dirRight:
    solver.addQueue(2, solver.nextVertex[state], qOne, qTwo)
  else:
    solver.addQueue(2, solver.prevVertex[state], qOne, qTwo)
```

The finish check compares the slide endpoint with the landing wall. The queue receives the landing wall and the corner at the same height. The second queue receives the wall reached by continuing along the current edge. `routeY` mirrors this block for vertical slides.

```nim
  for k in 0..<begins.len:
    let first = begins[k]
    let last = if k + 1 < begins.len: begins[k + 1] else: pointXs.len
    let wallTotal = last - first
    if pointXs[first] != pointXs[first + 1]:
      solver.px.add pointXs[last - 1]
      solver.py.add pointYs[last - 1]
      solver.px.add pointXs[first]
      solver.py.add pointYs[first]
      solver.px.add pointXs[first + 1]
      solver.py.add pointYs[first + 1]
      for j in 4..wallTotal:
        solver.px.add pointXs[first + j - 2]
        solver.py.add pointYs[first + j - 2]
      count += wallTotal
    else:
      solver.px.add pointXs[first]
      solver.py.add pointYs[first]
      solver.px.add pointXs[first + 1]
      solver.py.add pointYs[first + 1]
      for j in 3..wallTotal:
        solver.px.add pointXs[first + j - 1]
        solver.py.add pointYs[first + j - 1]
      count += wallTotal
    for j in count - wallTotal + 1..<count:
      solver.nextVertex.add j + 1
    solver.nextVertex.add count - wallTotal + 1
```

The loop walks every polygon and closes each ring. When the first edge is horizontal, it rotates the ring so odd vertices start vertical walls. This keeps parity meaningful for the two sweeps.

```nim
  proc treeFind(tree: Tree, pos: int, dirRight: bool): int =
    if dirRight:
      let before = treeSum(tree, pos)
      let total = treeSum(tree, rinkExtent)
      if before == total:
        return 0
      var order = before + 1
      var idx = 0
      var step = 1
      while step shl 1 <= rinkExtent + 1:
        step = step shl 1
      while step > 0:
        let candidate = idx + step
        if candidate <= rinkExtent + 1 and tree.bit[candidate] < order:
          idx = candidate
          order -= tree.bit[candidate]
        step = step div 2
      return tree.leaf[idx]
    else:
      let before = treeSum(tree, pos - 1)
      if before == 0:
        return 0
      var order = before
      var idx = 0
      var step = 1
      while step shl 1 <= rinkExtent + 1:
        step = step shl 1
      while step > 0:
        let candidate = idx + step
        if candidate <= rinkExtent + 1 and tree.bit[candidate] < order:
          idx = candidate
          order -= tree.bit[candidate]
        step = step div 2
      return tree.leaf[idx]
```

The tree holds one wall per active coordinate. `treeFind` returns the nearest active wall on the requested side, or zero. Each query walks fourteen levels, so it takes logarithmic time.

```nim
      for kk in 0..1:
        let bucket = if kk == 0: sweepStarts[line] else: sweepEnds[line]
        for q in bucket:
          if sweepVertical:
            if solver.py[q] == line:
              solver.landing[1][solver.prevVertex[q]] = treeFind(tree, solver.px[q], solver.py[q] > solver.py[solver.nextVertex[q]])
            else:
              solver.landing[0][solver.nextVertex[q]] = treeFind(tree, solver.px[q], solver.py[q] > solver.py[solver.nextVertex[q]])
          else:
            if solver.px[q] == line:
              solver.landing[1][solver.prevVertex[q]] = treeFind(tree, solver.py[q], solver.px[q] < solver.px[solver.nextVertex[q]])
            else:
              solver.landing[0][solver.nextVertex[q]] = treeFind(tree, solver.py[q], solver.px[q] < solver.px[solver.nextVertex[q]])
```

Walls enter the tree at their low coordinate and leave at their high coordinate. The sweep writes `landing` only at wall endpoints. The two directions use separate table entries.

```nim
  while true:
    solver.depth += 1
    var qZero = qOne
    qOne = qTwo
    qTwo = @[]
    for state in qZero:
      if state mod 2 == 1:
        solver.routeY(solver.py[state] > solver.py[solver.nextVertex[state]], state, solver.landing[0][state], qOne, qTwo)
        solver.routeY(solver.py[state] < solver.py[solver.nextVertex[state]], state, solver.landing[1][state], qOne, qTwo)
      else:
        solver.routeX(solver.px[state] > solver.px[solver.nextVertex[state]], state, solver.landing[0][state], qOne, qTwo)
        solver.routeX(solver.px[state] < solver.px[solver.nextVertex[state]], state, solver.landing[1][state], qOne, qTwo)
      if solver.answer >= 0:
        return solver.answer
    if qOne.len == 0 and qTwo.len == 0:
      return -1
```

The search swaps the two queues each round, so `depth` counts slides. Parity selects the vertical or horizontal wall family. An empty next queue ends the search with `NO`.

```nim
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Every case writes one line. The final write flushes the remaining buffer.

## Complexity

Let V be the vertex count.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(V) | O(V) |
| Wall ring setup | O(V) | O(V) |
| Both sweeps | O(V log 10000) | O(10000) |
| Breadth-first search | O(V) | O(V) |

Total time is O(V log 10000) and total space is O(V + 10000). Scanning every wall from every state would cost O(V) per slide instead of one table read.
