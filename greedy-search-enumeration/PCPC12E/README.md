# PCPC12E — Snakes and Ladders (SPOJ)

<https://www.spoj.com/problems/PCPC12E/>

## Problem

Find the fewest die throws to travel from square 0 to the last square of a numbered board. A throw moves up one to six squares, and landing on a snake head or ladder bottom moves the token again until it rests on a stable square. Overshooting the top leaves the token where it was.

Input holds test cases until end of file. Each case gives rows, columns, snake count, and ladder count. Snake and ladder lines follow. Output one minimum throw count per case, or -1 when the top stays unreachable.

The statement gives these bounds.

| item | bound |
|---|---|
| rows N | 1 to 100 |
| columns M | 1 to 100 |
| board squares | up to 10000 |
| die faces | 6 |
| judge limit | 1000 ms, 1536 MB |

The board size sets the work, since each throw has six choices.

Sample input:

```
1 1 0 0
1 2 1 0
2 1
5 10 3 5
16 6
47 26
49 11
1 38
4 14
9 31
40 42
36 44
```

Sample output:

```
1
-1
3
```

## Idea

Resolve each landing square first, then walk outward one throw at a time, like counting how many hops reach the far end of a path.

The algorithm collapses every snake and ladder chain to one stable destination, then runs a breadth-first search over die rolls. Each square has six outgoing edges, so one expansion costs six steps. A simulation that tries roll sequences would repeat states many times. Visiting each square once removes that repetition.

## Why It Works

1. A snake or ladder moves the token once, and the new square may move it again.
2. Following the chain until it stops gives a single stable destination per square.
3. The last snake or ladder read for a square wins, since each assignment overwrites the earlier one.
4. A die roll either advances up to six squares or leaves the token on the same square.
5. Breadth-first search reaches each square at its smallest throw count.

The main terms are listed below.

| term | meaning |
|---|---|
| `destination` | the snake or ladder target for a square, zero when stable |
| `finalSquare` | the stable square reached after following a chain |
| `dieFaces` | the six equally likely roll results |
| `unreachable` | the marker used for an unvisited distance |

The chain resolution removes hidden moves, and the search counts visible throws.

A script trace on sample case 3 lists the newly reached squares per throw.

```
throw 1: new=[2, 3, 5, 6, 14, 38] top_reached=False
throw 2: new=[7, 8, 10, 11, 12, 15, 17, 18, 19, 20, 31, 39, 41, 42, 43, 44] top_reached=False
throw 3: new=[13, 21, 22, 23, 24, 25, 26, 32, 33, 34, 35, 37, 45, 46, 48, 50] top_reached=True
```

Square 50 first appears after three throws, which matches the sample answer.

A top square with a snake cannot be a resting place, so that case prints -1.

## Code

**Input and helpers.** The reader loads input, and the scanner reads integers.

```nim
const flushBlockBytes = 1 shl 17
const dieFaces = 6
const unreachable = -1

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

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The end-of-file loop needs a lookahead for the next integer.
Buffered output writes once per block instead of once per case.

**Chain resolution.** Each square is reduced to the stable square where it rests.

```nim
while hasMoreData(inputData, scanPos):
  let boardRows = nextInt(inputData, scanPos)
  let boardColumns = nextInt(inputData, scanPos)
  let snakeCount = nextInt(inputData, scanPos)
  let ladderCount = nextInt(inputData, scanPos)
  let topSquare = boardRows * boardColumns
  var destination = newSeq[int](topSquare + 1)
  for snakeIndex in 0 ..< snakeCount:
    let snakeHead = nextInt(inputData, scanPos)
    let snakeTail = nextInt(inputData, scanPos)
    destination[snakeHead] = snakeTail
  for ladderIndex in 0 ..< ladderCount:
    let ladderBottom = nextInt(inputData, scanPos)
    let ladderTop = nextInt(inputData, scanPos)
    destination[ladderBottom] = ladderTop
  var finalSquare = newSeq[int](topSquare + 1)
  for square in 1 .. topSquare:
    if finalSquare[square] != 0:
      continue
    var path: seq[int] = @[]
    var current = square
    var steps = 0
    while steps <= topSquare:
      if finalSquare[current] != 0 or destination[current] == 0:
        break
      path.add current
      current = destination[current]
      steps += 1
    var baseSquare = current
    if finalSquare[current] != 0:
      baseSquare = finalSquare[current]
    for node in path:
      finalSquare[node] = baseSquare
    finalSquare[square] = baseSquare
```

Reading snakes before ladders makes a later ladder win on a shared square.
The path list lets every square on a chain reuse one resolved answer.
The step guard keeps malformed cyclic data from stalling the run.

**Breadth-first search.** Each queue level adds one throw to every reachable square.

```nim
  var distance = newSeq[int](topSquare + 1)
  for square in 0 .. topSquare:
    distance[square] = unreachable
  var queue = newSeq[int](topSquare + 1)
  var queueHead = 0
  var queueTail = 0
  distance[0] = 0
  queue[queueTail] = 0
  queueTail += 1
  while queueHead < queueTail:
    let current = queue[queueHead]
    queueHead += 1
    for dieFace in 1 .. dieFaces:
      let rawSquare = current + dieFace
      if rawSquare > topSquare:
        break
      let landing = finalSquare[rawSquare]
      if distance[landing] == unreachable:
        distance[landing] = distance[current] + 1
        queue[queueTail] = landing
        queueTail += 1
  if distance[topSquare] == unreachable:
    appendOutput("-1")
  else:
    appendOutput($distance[topSquare])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Overshooting the top stops the die loop early.
Each square enters the queue once, so its distance is minimal.
An unset distance at the top produces the -1 line.

## Complexity

Resolution and search both scale with the number of board squares.

| phase | time | space |
|---|---|---|
| input read | one pass over the case data | one input string |
| chain resolution | one pass with memoized paths | two arrays of squares |
| breadth-first search | six edges per square | distance and queue arrays |
| output | one line per case | block buffer |

Resolution walks each chain once, and the search visits each square once.

| measure | Big O |
|---|---|
| time | O(N M) per case |
| space | O(N M) per case |

Trying every roll sequence would grow exponentially, while one visit per square stays linear.

Resolving first and searching once keeps each board cheap.
