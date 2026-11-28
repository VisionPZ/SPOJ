# CHASE1 — Chase (SPOJ)
<https://www.spoj.com/problems/CHASE1/>

## Problem

Two pieces move on a triangle-free graph, with the runner stepping before the chaser each turn. Decide whether the chaser can force a meeting, and print the turns needed under optimal play.

Input starts with a test count. Each case gives square count n, adjacent-pair count m, the runner's start a, and the cop's start b, then m edges. Output `No` when the cop cannot win, otherwise the number of turns.

The board limits are these:

| Quantity | Bound |
| --- | --- |
| Board squares | 2 to 3000 |
| Adjacent pairs | n - 1 to 15,000 |
| Test cases | not bounded in the statement |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The triangle-free rule makes a catch possible only at a leaf.

The sample input and output:

```
1
9 11 9 4
1 2
3 2
1 4
4 7
7 5
5 1
6 9
8 5
9 8
5 3
4 8
```

```
3
```

The cop catches the runner on turn three.

## Idea

Peel away leaves to find the board's core. A runner standing in the core can run forever, so the answer is `No` there. For other starts, run a bucket sweep over ordered pairs of squares and settle them by increasing turn count. Think of draining a graph from its edges inward: what remains is the safe center.

The peel and distance passes cost O(n + m). The bucket sweep settles each ordered pair once, with work proportional to one square's degree, so it stays near O(n squared + m). Searching the full game tree would be far larger.

Takeaway: strip leaves first, then settle pairs by turn count.

## Why It Works

1. Neighbors of any square form an independent set on a triangle-free board.
2. A runner next to the cop can step to another neighbor at distance two, unless that runner sits at a leaf.
3. A catch therefore needs the runner at a leaf with the cop adjacent.
4. The core survives leaf stripping, so a runner there keeps stepping inside and never becomes a leaf.
5. Before the runner moves, `before(r, c)` takes the maximum of `after(r', c)` over runner moves. After the runner moves, `after(r, c)` is one plus the minimum over cop moves. Adjacent squares give one directly.
6. Values only rise, so buckets in increasing order settle each pair once, and the start pair gives the answer.

The game state uses these terms.

| Term | Meaning |
| --- | --- |
| `distToCore` | steps from a square to the remaining core |
| `distFromChaser` | steps from the cop's start to each square |
| `isClosed` | pairs where cop and runner are equal or adjacent |
| `pending` | remaining moves before a pair is finalized |
| `bucketHead` | linked lists of events grouped by turn value |

A finalized pair never changes, so each event runs once.

A script traced the sample board with runner at 9 and cop at 4:

| Turn | Runner | Cop | Action |
| --- | --- | --- | --- |
| 1 | 9 | 4 | Runner stays at 9; cop steps to 8 |
| 2 | 9 | 8 | Runner steps to 6; cop steps to 9 |
| 3 | 6 | 9 | Runner stays at 6; cop steps onto 6 |

The cop catches in turn three, matching the sample output.

## Code

**Constants, scanner, and output helper.**
```nim
{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const farDistance = 1000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
```
The buffer gathers every line, and `nextInt` walks the digits. `farDistance` marks unreached squares. `appendOutput` flushes in blocks.

**Case input and closed pairs.**
```nim
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let runnerStart = nextInt(inputData, scanPos) - 1
  let chaserStart = nextInt(inputData, scanPos) - 1

  var head = newSeq[int](nodeCount)
  for nodeIdx in 0..<nodeCount:
    head[nodeIdx] = -1
  var neighborTo = newSeq[int](2 * edgeCount)
  var neighborNext = newSeq[int](2 * edgeCount)
  var degree = newSeq[int](nodeCount)
  var edgeSlot = 0
  for edgeIndex in 0..<edgeCount:
    let fromNode = nextInt(inputData, scanPos) - 1
    let toNode = nextInt(inputData, scanPos) - 1
    neighborTo[edgeSlot] = toNode
    neighborNext[edgeSlot] = head[fromNode]
    head[fromNode] = edgeSlot
    edgeSlot += 1
    degree[fromNode] += 1
    neighborTo[edgeSlot] = fromNode
    neighborNext[edgeSlot] = head[toNode]
    head[toNode] = edgeSlot
    edgeSlot += 1
    degree[toNode] += 1

  let stateCount = nodeCount * nodeCount
  var isClosed = newSeq[bool](stateCount)
  for nodeIdx in 0..<nodeCount:
    isClosed[nodeIdx * nodeCount + nodeIdx] = true
    var edgeIdx = head[nodeIdx]
    while edgeIdx != -1:
      isClosed[nodeIdx * nodeCount + neighborTo[edgeIdx]] = true
      edgeIdx = neighborNext[edgeIdx]
```
Adjacency is stored in forward-star arrays with a `degree` count. `isClosed` marks pairs that are equal or one edge apart, which ends the game immediately.

**Leaf peeling and core distances.**
```nim
  var removed = newSeq[bool](nodeCount)
  var peelDegree = newSeq[int](nodeCount)
  var queue = newSeq[int](nodeCount)
  var queueHead = 0
  var queueTail = 0
  for nodeIdx in 0..<nodeCount:
    peelDegree[nodeIdx] = degree[nodeIdx]
    if degree[nodeIdx] <= 1:
      queue[queueTail] = nodeIdx
      queueTail += 1
  while queueHead < queueTail:
    let vertex = queue[queueHead]
    queueHead += 1
    if removed[vertex]:
      continue
    removed[vertex] = true
    var edgeIdx = head[vertex]
    while edgeIdx != -1:
      let neighbor = neighborTo[edgeIdx]
      if not removed[neighbor]:
        peelDegree[neighbor] -= 1
        if peelDegree[neighbor] == 1:
          queue[queueTail] = neighbor
          queueTail += 1
      edgeIdx = neighborNext[edgeIdx]

  var distToCore = newSeq[int](nodeCount)
  for nodeIdx in 0..<nodeCount:
    distToCore[nodeIdx] = farDistance
  queueHead = 0
  queueTail = 0
  for nodeIdx in 0..<nodeCount:
    if not removed[nodeIdx]:
      distToCore[nodeIdx] = 0
      queue[queueTail] = nodeIdx
      queueTail += 1
  while queueHead < queueTail:
    let vertex = queue[queueHead]
    queueHead += 1
    var edgeIdx = head[vertex]
    while edgeIdx != -1:
      let neighbor = neighborTo[edgeIdx]
      if distToCore[neighbor] == farDistance:
        distToCore[neighbor] = distToCore[vertex] + 1
        queue[queueTail] = neighbor
        queueTail += 1
      edgeIdx = neighborNext[edgeIdx]

```
A queue removes squares of degree at most one, then a second breadth-first pass computes `distToCore` from the survivors. Removed squares form the outer layers.

**Runner escape check.**
```nim
  var runnerWins = false
  if not removed[runnerStart]:
    runnerWins = true
  elif distToCore[runnerStart] != farDistance:
    var distFromChaser = newSeq[int](nodeCount)
    for nodeIdx in 0..<nodeCount:
      distFromChaser[nodeIdx] = farDistance
    queueHead = 0
    queueTail = 0
    distFromChaser[chaserStart] = 0
    queue[queueTail] = chaserStart
    queueTail += 1
    while queueHead < queueTail:
      let vertex = queue[queueHead]
      queueHead += 1
      var edgeIdx = head[vertex]
      while edgeIdx != -1:
        let neighbor = neighborTo[edgeIdx]
        if distFromChaser[neighbor] == farDistance:
          distFromChaser[neighbor] = distFromChaser[vertex] + 1
          queue[queueTail] = neighbor
          queueTail += 1
        edgeIdx = neighborNext[edgeIdx]
    var current = runnerStart
    var steps = 0
    while true:
      if distFromChaser[current] <= steps:
        break
      if distToCore[current] == 0:
        runnerWins = true
        break
      var edgeIdx = head[current]
      var nextVertex = -1
      while edgeIdx != -1:
        let neighbor = neighborTo[edgeIdx]
        if distToCore[neighbor] < distToCore[current]:
          nextVertex = neighbor
          break
        edgeIdx = neighborNext[edgeIdx]
      if nextVertex < 0:
        break
      current = nextVertex
      steps += 1

  if runnerWins:
    appendOutput("No")
    outputBuffer.add '\n'
    continue
```
A runner in the core escapes at once. Otherwise a breadth-first pass from the cop gives `distFromChaser`, and a greedy walk toward the core checks whether the runner survives the chase.

**Bucket game sweep.**
```nim
  var finalizedRunner = newSeq[bool](stateCount)
  var finalizedChaser = newSeq[bool](stateCount)
  var pushedChaser = newSeq[bool](stateCount)
  var pending = newSeq[uint16](stateCount)
  for runnerPos in 0..<nodeCount:
    let startCount = uint16(degree[runnerPos] + 1)
    let base = runnerPos * nodeCount
    for chaserPos in 0..<nodeCount:
      pending[base + chaserPos] = startCount

  let maxBucket = nodeCount + 4
  var bucketHead = newSeq[int32](maxBucket + 1)
  var eventNext = newSeq[int32](2 * stateCount)

  for runnerPos in 0..<nodeCount:
    var code = (runnerPos * nodeCount + runnerPos) * 2 + 1
    eventNext[code] = bucketHead[0]
    bucketHead[0] = int32(code + 1)
    var edgeIdx = head[runnerPos]
    while edgeIdx != -1:
      code = (runnerPos * nodeCount + neighborTo[edgeIdx]) * 2 + 1
      eventNext[code] = bucketHead[1]
      bucketHead[1] = int32(code + 1)
      edgeIdx = neighborNext[edgeIdx]

  var answer = -1
  let targetState = runnerStart * nodeCount + chaserStart
  for value in 0..maxBucket:
    while bucketHead[value] != 0:
      let code = int(bucketHead[value]) - 1
      bucketHead[value] = eventNext[code]
      let eventType = code and 1
      let state = code shr 1
      let runnerPos = state div nodeCount
      let chaserPos = state - runnerPos * nodeCount
      if eventType == 1:
        if finalizedChaser[state]:
          continue
        finalizedChaser[state] = true
        var runnerState = runnerPos * nodeCount + chaserPos
        if not finalizedRunner[runnerState]:
          pending[runnerState] = pending[runnerState] - uint16(1)
          if pending[runnerState] == uint16(0):
            finalizedRunner[runnerState] = true
            let nextCode = runnerState * 2
            eventNext[nextCode] = bucketHead[value]
            bucketHead[value] = int32(nextCode + 1)
        var edgeIdx = head[runnerPos]
        while edgeIdx != -1:
          runnerState = neighborTo[edgeIdx] * nodeCount + chaserPos
          if not finalizedRunner[runnerState]:
            pending[runnerState] = pending[runnerState] - uint16(1)
            if pending[runnerState] == uint16(0):
              finalizedRunner[runnerState] = true
              let nextCode = runnerState * 2
              eventNext[nextCode] = bucketHead[value]
              bucketHead[value] = int32(nextCode + 1)
          edgeIdx = neighborNext[edgeIdx]
      else:
        if state == targetState:
          answer = value
          break
        var chaserState = runnerPos * nodeCount + chaserPos
        if not finalizedChaser[chaserState] and not pushedChaser[chaserState]:
          if not isClosed[chaserState]:
            pushedChaser[chaserState] = true
            let nextValue = value + 1
            if nextValue <= maxBucket:
              let nextCode = chaserState * 2 + 1
              eventNext[nextCode] = bucketHead[nextValue]
              bucketHead[nextValue] = int32(nextCode + 1)
        var edgeIdx = head[chaserPos]
        while edgeIdx != -1:
          chaserState = runnerPos * nodeCount + neighborTo[edgeIdx]
          if not finalizedChaser[chaserState] and not pushedChaser[chaserState]:
            if not isClosed[chaserState]:
              pushedChaser[chaserState] = true
              let nextValue = value + 1
              if nextValue <= maxBucket:
                let nextCode = chaserState * 2 + 1
                eventNext[nextCode] = bucketHead[nextValue]
                bucketHead[nextValue] = int32(nextCode + 1)
          edgeIdx = neighborNext[edgeIdx]
    if answer >= 0:
      break

  if answer < 0:
    appendOutput("No")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
`pending` counts the moves that must settle before a pair is finalized. Two event types handle chaser and runner updates. `bucketHead` processes turn values in order, and the target pair returns the answer.

## Complexity

Pair states dominate the final phase.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Graph build | O(m) | O(n + m) |
| Leaf peel and distances | O(n + m) | O(n) |
| Escape check | O(n + m) | O(n) |
| Bucket sweep | O(n squared + m) | O(n squared) |
| Output | one write per block | flushBlockBytes |

Square count sets the pair table size.

| Measure | Big O |
| --- | --- |
| Time per case | O(n squared + m) |
| Space per case | O(n squared) |

Exploring every joint move sequence would be exponential, while monotone bucket settling fixes each pair once.
