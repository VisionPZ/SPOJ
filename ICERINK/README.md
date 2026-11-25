# ICERINK — Icerink (SPOJ)

<https://www.spoj.com/problems/ICERINK/>

## Problem

A skater crosses a square rink dotted with polygon obstacles. Each push slides in a straight line until a wall stops the motion.

Read `t` cases. Each case gives start `x`, start `y`, finish `x`, finish `y`, and an obstacle count. Each obstacle then gives its wall count and that many vertex pairs.

Print the fewest slides that reach the finish, or `NO` when no route exists.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Rink side | 10000 |
| Obstacles per case | at most 2500 |
| Total walls per case | at most 10000 |
| Coordinates | 0 to 10000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The wall count, not the rink area, sets the work per case.

The sample case:

```
1
40 10
5 40
3
6
0 15
0 60
20 60
20 55
5 55
5 15
12
30 55
30 60
60 60
60 0
0 0
0 5
55 5
55 35
50 35
50 40
55 40
55 55
6
30 25
15 25
15 30
35 30
35 15
30 15
```

```
4
```

## Idea

Picture a city where you slide down an avenue until a building faces you, then turn. Each wall you hit becomes a new decision point.

The model uses one state per directed wall. Two sweeps, one along `x` and one along `y`, compute the landing wall for every state in both directions. A Fenwick tree (a prefix-count array with fast prefix sums) finds the nearest active wall at each sweep line.

Breadth-first search then walks those landings in slide order, so the first finish hit is shortest.

Each state costs two direction checks and O(log 10000) sweep work. Scanning every wall from every state would cost O(V) per slide instead of one table read. A precomputed landing table keeps the search cheap.

## Why It Works

Five facts make the search exact.

1. A slide stops at the nearest perpendicular wall whose interior lies ahead of the motion. Walls parallel to the slide never stop it.
2. At a sweep line, active walls are exactly the walls crossing that line. A Fenwick tree holds their positions and finds the nearest active wall in logarithmic time.
3. At a reflex corner, the slide stops on the adjacent wall. `isRightCorner` rejects a wall that does not bound the interior toward the sliding point.
4. The `landing` table stores the next wall for each state and direction. Breadth-first search visits states in slide order, so the first finish hit is minimal.
5. `isLeft` multiplies with `int64`, so coordinates up to 10000 cannot overflow the cross product.

The main structures and their roles:

| Term | Meaning |
| --- | --- |
| `Solver` | holds wall rings, landing table, and search state |
| `nextVertex` | ring successor ending each directed wall |
| `landing` | next wall for each state and slide direction |
| `treeFind` | nearest active wall on a requested side |
| `isRightCorner` | test for a reflex corner facing the slide |
| `depth` | current slide count |

These fields let one wall lookup serve every slide from that state.

A script traces the sample route through the rink:

```
(40,10) -> E(55,10) -> S(55,35) -> W(5,35) -> S(5,40)
```

The route uses four slides: east, south, west, and south again. The finish point `(5,40)` is reached at slide four, which matches the sample output.

## Code

**Setup and scanner.** The read loop loads one buffer, and a hand scanner parses coordinates.

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

The scan skips blank lines between cases. Sweep buffers are allocated once and reused. Output leaves in 256 KiB blocks.

**State and corner test.** `isLeft` uses an int64 cross product, and `isRightCorner` filters reflex corners.

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

The object stores wall endpoints and both landing directions. The corner test keeps only walls facing the slide. `int64` products avoid overflow at the rink edge.

**Horizontal slide.** The queue receives the landing wall, its corner, and the continuing edge.

```nim
proc addQueue(solver: var Solver, dirIndex, vertex: int, qOne: var seq[int], qTwo: var seq[int]) =
  if vertex == 0:
    return
  if solver.seen[vertex] <= solver.depth + dirIndex:
    return
  solver.seen[vertex] = solver.depth + dirIndex
  if dirIndex == 1:
    qOne.add vertex
  else:
    qTwo.add vertex

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

The finish check compares the slide endpoint with the landing wall. `addQueue` rejects a state already seen at this depth. The two queues split slides that finish this round from slides that continue.

**Wall rings.** Each obstacle becomes a closed ring with alternating wall parity.

```nim
proc solveCase(startX, startY, finishX, finishY: int, pointXs, pointYs, begins: seq[int]): int =
  var solver = Solver(
    px: @[startX], py: @[startY], nextVertex: @[0], prevVertex: @[0],
    landing: [@[0], @[0]],
    startX: startX, startY: startY, finishX: finishX, finishY: finishY,
    vertexCount: 0, depth: 0, answer: -1, seen: @[]
  )
  var count = 0
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

  solver.vertexCount = count
  solver.nextVertex.setLen(count + 1)
  solver.prevVertex.setLen(count + 1)
  for i in 0..count:
    solver.prevVertex[solver.nextVertex[i]] = i
  solver.landing[0].setLen(count + 1)
  solver.landing[1].setLen(count + 1)
  for i in 0..count:
    solver.landing[0][i] = 0
    solver.landing[1][i] = 0
  solver.seen = newSeq[int](count + 1)
  for i in 0..count:
    solver.seen[i] = infinity
```

The loop walks every polygon and closes each ring. A horizontal first edge rotates the ring so odd states start vertical walls. Parity then selects the sweep direction.

**Nearest active wall.** The Fenwick tree answers a nearest-wall query in logarithmic time.

```nim
  type Tree = object
    bit: seq[int]
    leaf: seq[int]
  proc treeAdd(tree: var Tree, coord, value: int) =
    tree.leaf[coord] = value
    var idx = coord + 1
    while idx <= rinkExtent + 1:
      tree.bit[idx] += 1
      idx += idx and (-idx)
  proc treeDel(tree: var Tree, coord: int) =
    tree.leaf[coord] = 0
    var idx = coord + 1
    while idx <= rinkExtent + 1:
      tree.bit[idx] -= 1
      idx += idx and (-idx)
  proc treeSum(tree: Tree, coord: int): int =
    var idx = coord + 1
    var total = 0
    while idx > 0:
      total += tree.bit[idx]
      idx -= idx and (-idx)
    return total
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

The tree holds one wall per active coordinate. `treeFind` walks fourteen levels, then returns the leaf for the nearest wall. A zero result means no wall lies on that side.

**Sweep events.** Walls enter at their low coordinate and leave at their high coordinate.

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

The sweep writes `landing` only at wall endpoints. The two directions use separate table entries. Each event costs one logarithmic tree query.

**Breadth-first search.** The two queues swap each round, so `depth` counts slides.

```nim
  for i in 1..solver.vertexCount:
    if solver.isLeft(solver.px[solver.prevVertex[i]], solver.py[solver.prevVertex[i]], solver.px[i], solver.py[i],
                     solver.px[solver.nextVertex[i]], solver.py[solver.nextVertex[i]]):
      solver.landing[1][solver.prevVertex[i]] = i
      solver.landing[0][i] = solver.prevVertex[i]

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

Reflex corners get their landing entries before the search starts. Parity picks vertical or horizontal walls. Empty queues end the search with no route.

**Driver.** The case loop reads obstacles and prints one answer per case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0..<caseCount:
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let finishX = nextInt(inputData, scanPos)
  let finishY = nextInt(inputData, scanPos)
  let obstacleCount = nextInt(inputData, scanPos)
  var pointXs: seq[int] = @[]
  var pointYs: seq[int] = @[]
  var begins: seq[int] = @[]
  for k in 0..<obstacleCount:
    begins.add pointXs.len
    let wallCount = nextInt(inputData, scanPos)
    for l in 0..<wallCount:
      pointXs.add nextInt(inputData, scanPos)
      pointYs.add nextInt(inputData, scanPos)
  let answer = solveCase(startX, startY, finishX, finishY, pointXs, pointYs, begins)
  if answer < 0:
    appendOutput("NO")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`begins` marks where each polygon starts in the flat point arrays. Each case writes one line. The final write flushes the remaining buffer.

## Complexity

Let `V` be the total wall count in one case.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(V) | input buffer |
| Wall ring setup | O(V) | O(V) wall arrays |
| Both sweeps | O(V log 10000) | O(10000) tree arrays |
| Breadth-first search | O(V) | O(V) landing and seen arrays |

The fixed rink extent keeps every tree query shallow.

| Measure | Big O |
| --- | --- |
| Time | O(V log 10000) per case |
| Space | O(V + 10000) per case |

Scanning every wall from every slide state costs O(V) per slide instead of one landing-table read.
