## Problem

Read a triangle-free connected board with `n` squares and `m` adjacent pairs. Two pieces start on given squares. Player A moves first in each turn, then player B moves. Each move stays put or steps to an adjacent square. Print `No` when B cannot force a catch. Otherwise print the turn count when both play well.

| Quantity | Bound |
| --- | --- |
| Board squares | 2 to 3000 |
| Adjacent pairs | n - 1 to 15000 |
| Test cases | not bounded in the statement |
| Time limit | 5 s |
| Memory limit | 1536 MB |

The triangle-free rule makes a catch possible only at a leaf.

## Idea

Strip leaves to find the core of the board. A runner placed in the core escapes forever, so the answer is `No` there. For other starts, solve a turn-count game over ordered pairs of squares. A bucket sweep settles pairs in increasing turn count and stops at the start pair. Each settled pair costs work proportional to one square's degree.

## Why It Works

Neighbors of any square form an independent set on a triangle-free board. A runner next to the cop can step to another neighbor at distance two, unless that runner sits at a leaf. So a catch needs the runner at a leaf with the cop adjacent.

The core survives leaf stripping. A runner there keeps stepping inside the core and never becomes a leaf. That runner escapes.

For a pair `(runner, cop)` after the runner moves, the cop either catches or moves. Define `after(r, c) = 1` when the squares are adjacent. Otherwise `after(r, c) = 1 + min(before(r, c'))` over cop moves `c'`. Before the runner moves, `before(r, c) = max(after(r', c))` over runner moves `r'`. Values only rise, so buckets in increasing order settle each pair once.

The sample board has core squares 1, 2, 3, 4, 5, 7, 8. The runner starts at 9 and the cop at 4. Both play well:

| Turn | Runner | Cop | Action |
| --- | --- | --- | --- |
| 1 | 9 | 4 | Runner stays at 9; cop steps to 8 |
| 2 | 9 | 8 | Runner steps to 6; cop steps to 9 |
| 3 | 6 | 9 | Runner stays at 6; cop steps onto 6 |

The cop catches in turn 3, which matches the sample output.

## Code

The scanner reads all input once and skips whitespace between test cases.

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
```

The buffer flushes per block, never per answer. The checks pragma keeps the judge's debug build fast.

Leaf stripping marks peeled squares and fills the core distances.

```nim
  var removed = newSeq[bool](nodeCount)
  var peelDegree = newSeq[int](nodeCount)
  var queue = newSeq[int](nodeCount)
  var queueHead = 0
  var queueTail = 0
  for i in 0..<nodeCount:
    peelDegree[i] = degree[i]
    if degree[i] <= 1:
      queue[queueTail] = i
      queueTail += 1
  while queueHead < queueTail:
    let u = queue[queueHead]
    queueHead += 1
    if removed[u]:
      continue
    removed[u] = true
    var e = head[u]
    while e != -1:
      let v = neighborTo[e]
      if not removed[v]:
        peelDegree[v] -= 1
        if peelDegree[v] == 1:
          queue[queueTail] = v
          queueTail += 1
      e = neighborNext[e]
```

The queue holds at most one entry per square. The multi-source pass sets distance zero on core squares.

The runner wins at once when the start lies in the core. Otherwise the path toward the core is checked for a cop block.

```nim
  var runnerWins = false
  if not removed[runnerStart]:
    runnerWins = true
  elif distToCore[runnerStart] != farDistance:
    var distFromChaser = newSeq[int](nodeCount)
    for i in 0..<nodeCount:
      distFromChaser[i] = farDistance
    queueHead = 0
    queueTail = 0
    distFromChaser[chaserStart] = 0
    queue[queueTail] = chaserStart
    queueTail += 1
    while queueHead < queueTail:
      let u = queue[queueHead]
      queueHead += 1
      var e = head[u]
      while e != -1:
        let v = neighborTo[e]
        if distFromChaser[v] == farDistance:
          distFromChaser[v] = distFromChaser[u] + 1
          queue[queueTail] = v
          queueTail += 1
        e = neighborNext[e]
    var current = runnerStart
    var steps = 0
    while true:
      if distFromChaser[current] <= steps:
        break
      if distToCore[current] == 0:
        runnerWins = true
        break
      var e = head[current]
      var nextVertex = -1
      while e != -1:
        let v = neighborTo[e]
        if distToCore[v] < distToCore[current]:
          nextVertex = v
          break
        e = neighborNext[e]
      if nextVertex < 0:
        break
      current = nextVertex
      steps += 1
```

`steps` equals the runner's distance to the current square. A cop distance no larger than `steps` blocks the escape. The branch costs one breadth-first pass.

The sweep seeds adjacent pairs at turn one and stores events in value buckets.

```nim
  let maxBucket = nodeCount + 4
  var bucketHead = newSeq[int32](maxBucket + 1)
  var eventNext = newSeq[int32](2 * stateCount)

  for r in 0..<nodeCount:
    var code = (r * nodeCount + r) * 2 + 1
    eventNext[code] = bucketHead[0]
    bucketHead[0] = int32(code + 1)
    var e = head[r]
    while e != -1:
      code = (r * nodeCount + neighborTo[e]) * 2 + 1
      eventNext[code] = bucketHead[1]
      bucketHead[1] = int32(code + 1)
      e = neighborNext[e]
```

Each pair gets one event per phase. Linked buckets avoid a priority queue. Seeding costs one pass over the closed neighborhoods.

The main loop settles pairs and records the start pair's turn count.

```nim
  var answer = -1
  let targetState = runnerStart * nodeCount + chaserStart
  for value in 0..maxBucket:
    while bucketHead[value] != 0:
      let code = int(bucketHead[value]) - 1
      bucketHead[value] = eventNext[code]
      let eventType = code and 1
      let state = code shr 1
      let r = state div nodeCount
      let c = state - r * nodeCount
      if eventType == 1:
        if finalizedX[state]:
          continue
        finalizedX[state] = true
        var stateA = r * nodeCount + c
        if not finalizedA[stateA]:
          pending[stateA] = pending[stateA] - uint16(1)
          if pending[stateA] == uint16(0):
            finalizedA[stateA] = true
            let nextCode = stateA * 2
            eventNext[nextCode] = bucketHead[value]
            bucketHead[value] = int32(nextCode + 1)
        var e = head[r]
        while e != -1:
          stateA = neighborTo[e] * nodeCount + c
          if not finalizedA[stateA]:
            pending[stateA] = pending[stateA] - uint16(1)
            if pending[stateA] == uint16(0):
              finalizedA[stateA] = true
              let nextCode = stateA * 2
              eventNext[nextCode] = bucketHead[value]
              bucketHead[value] = int32(nextCode + 1)
          e = neighborNext[e]
      else:
        if state == targetState:
          answer = value
          break
        var stateX = r * nodeCount + c
        if not finalizedX[stateX] and not pushedX[stateX]:
          if not closedFlag[stateX]:
            pushedX[stateX] = true
            let nextValue = value + 1
            if nextValue <= maxBucket:
              let nextCode = stateX * 2 + 1
              eventNext[nextCode] = bucketHead[nextValue]
              bucketHead[nextValue] = int32(nextCode + 1)
        var e = head[c]
        while e != -1:
          stateX = r * nodeCount + neighborTo[e]
          if not finalizedX[stateX] and not pushedX[stateX]:
            if not closedFlag[stateX]:
              pushedX[stateX] = true
              let nextValue = value + 1
              if nextValue <= maxBucket:
                let nextCode = stateX * 2 + 1
                eventNext[nextCode] = bucketHead[nextValue]
                bucketHead[nextValue] = int32(nextCode + 1)
          e = neighborNext[e]
    if answer >= 0:
      break
```

`pending` counts runner moves that still lack a cop response. A pair settles when that count reaches zero. The loop stops as soon as the start pair settles.

## Complexity

Input reading takes time linear in token count. Core peeling and the two searches take O(n + m). The sweep handles n² pairs and touches each closed neighborhood, so it takes O(n² + n·m) time. Arrays of n² pairs use O(n²) space. A recursive minimax without memoization repeats states and grows exponentially.
