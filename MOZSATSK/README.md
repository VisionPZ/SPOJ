# MOZSATSK — Sharmeen and the strange keyboard (SPOJ)

<https://www.spoj.com/problems/MOZSATSK/>

## Problem

Starting on the first digit of a digit string, hop at most two positions per minute. A hop is legal only when the target digit is the current digit or one of its two cyclic neighbors. Report the fewest minutes to reach the last digit, or say it cannot be done.

Input holds one string of digits and no count. Output is `yes` followed by the minute count, or `no` alone.

| item | bound |
|---|---|
| string length n | 1 to 100000 |
| digits | 0 to 9, any repeats |
| hop distance | 1 or 2 positions |
| judge limit | 1000 ms, 1536 MB |

The digit cycle wraps, so 0 neighbors 9 and 1.

Sample input:

```
5495
```

Sample output:

```
yes
2
```

## Idea

Think of each position as a room whose doors depend on the digit you carry. At each minute, the doors open to four nearby positions whose digits differ by at most one around the clock. Breadth-first search walks rooms in order of minutes, so the first arrival at the last room is optimal.

The search costs four checks per visited position, hence linear time. Trying every hop sequence would branch exponentially and never finish for n = 100000.

## Why It Works

1. The state after a press is fully described by the position, since its digit is fixed.
2. From digit d, the next allowed digits are d-1, d, and d+1 modulo 10.
3. A hop reaches a position one or two steps left or right.
4. Breadth-first search visits states in nondecreasing minute count.
5. The first visit to the last position therefore gives the minimum minutes.

| term | meaning |
|---|---|
| `keyString` | the row of digit keys |
| `reachOffsets` | the four allowed position changes |
| `distances` | minutes for the first visit to each position |
| `digitDifference` | cyclic gap between two digits |

For the sample `5495`, minute 0 reaches only position 0 with digit 5.

| minute | newly reached positions | reason |
|---|---|---|
| 0 | 0 | first key is free |
| 1 | 1 | digit 4 neighbors 5 |
| 2 | 3 | digit 5 neighbors 4 |

The last position is reached at minute 2, matching the sample.

## Code

**Input and scanning.** The reader loads stdin and extracts the digit string.

```nim
const flushBlockBytes = 1 shl 17
const reachOffsets = [-2, -1, 1, 2]
const digitBase = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The token reader keeps every digit and skips the trailing newline. The four offsets are the reachable neighbors.

**Breadth-first search and output.** A queue visits each position once, in minute order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let keyString = nextToken(inputData, scanPos)
let keyCount = keyString.len
var distances = newSeq[int](keyCount)
for position in 0 .. keyCount - 1:
  distances[position] = -1
var queue = newSeq[int](keyCount)
queue[0] = 0
distances[0] = 0
var queueHead = 0
var queueTail = 1
while queueHead < queueTail:
  let currentPosition = queue[queueHead]
  queueHead += 1
  let currentDigit = int(keyString[currentPosition]) - 48
  for offsetIndex in 0 .. 3:
    let nextPosition = currentPosition + reachOffsets[offsetIndex]
    if nextPosition < 0 or nextPosition >= keyCount:
      continue
    if distances[nextPosition] != -1:
      continue
    let nextDigit = int(keyString[nextPosition]) - 48
    let digitDifference = (nextDigit - currentDigit + digitBase) mod digitBase
    if digitDifference == 0 or digitDifference == 1 or digitDifference == digitBase - 1:
      distances[nextPosition] = distances[currentPosition] + 1
      queue[queueTail] = nextPosition
      queueTail += 1
if distances[keyCount - 1] == -1:
  appendOutput("no\n")
else:
  appendOutput("yes\n")
  appendOutput($(distances[keyCount - 1]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A distance of -1 means the position was never visited. The cyclic difference check accepts wraps such as 0 to 9. One buffered write emits the two-line answer.

## Complexity

The queue holds each position at most once.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| search | four neighbor checks per position | distance and queue arrays |
| output | one buffered answer | block buffer |

Each position enters the queue once, so the search is linear.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

Enumerating hop sequences would take exponential time, while the queue settles each position in constant work. That queue sets the cost.
