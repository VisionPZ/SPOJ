# UOFTCC — A Subtle Surf (SPOJ)

<https://www.spoj.com/problems/UOFTCC/>

## Problem

Starting from channel 1, reach the largest girliness possible by switching channels. Each switch must wait `T` seconds first, and a new channel may exceed the current girliness by at most `C`.

Line 1 holds the day count `D`. Each day has a line with `N C T`, then a line with `N` girliness values `G1..GN`. Print the maximum reachable girliness and the minimum seconds to reach it, separated by a space, once per day.

| item | bound |
|---|---|
| days D | 1 to 100 |
| channels N | 1 to 100000 |
| jump limit C | 1 to 1000000000 |
| wait T | 1 to 1000 |
| girliness Gi | 0 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

A switch to a lower value is legal, but never helps reach a higher final value.

Sample input:

```
2
6 3 5
3 4 0 8 12 6
4 1 2
5 7 7 5
```

Sample output:

```
8 10
5 0
```

Those two lines are the exact expected output.

## Idea

Think of the channels as stepping stones: from any stone you can hop to any stone within C steps, and each hop costs T seconds. Greedy stepping chooses the farthest reachable stone every time.

The algorithm sorts the values once, then binary-searches the largest value within C of the current one. Each search costs O(log N), and the number of jumps is at most N. A breadth-first search over all channels would examine many more transitions.

The farthest first hop keeps the next hop's reach as large as possible.

## Why It Works

1. Waiting T seconds is the only time cost; staying on a channel costs zero.
2. Switching downward lowers the next reach, so it cannot help.
3. From value v, any listed value at most v+C is reachable in one jump.
4. Taking the largest such value gives the largest reach after that jump.
5. Induction: after k jumps, the greedy value is the largest value reachable in k jumps.
6. The process stops when no value exceeds the current one within C.
7. The seconds are the jump count times T.

| term | meaning |
|---|---|
| `jumpLimit` | C, the largest allowed girliness gain |
| `waitSeconds` | T, the cost of one switch |
| `girlinessValues` | sorted channel girliness values |
| `startGirliness` | girliness of channel 1 |
| `reachLimit` | current girliness plus C |
| `bestIndex` | last sorted index within the reach |

The labels above match the identifiers in the code.

The first sample day sorts to 0 3 4 6 8 12, starts at 3, and sets C=3.

| jump | reachLimit | chosen value | jump count |
|---|---|---|---|
| 1 | 6 | 6 | 1 |
| 2 | 9 | 8 | 2 |
| 3 | 11 | 8, so stop | 2 |

The answer is 8 girliness and 2 times 5, or 10 seconds.

## Code

**Input and scanner.** The reader stores the whole input, then parses each day's header and values.

```nim
import algorithm

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

One newline ends each stored line.
The scanner skips spaces and line breaks.
The sort comparator orders values from small to large.

**Day setup.** Channel 1 is saved before sorting, and answers are buffered.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dayCount = nextInt(inputData, scanPos)
for dayIndex in 0 .. dayCount - 1:
  let channelCount = nextInt(inputData, scanPos)
  let jumpLimit = nextInt(inputData, scanPos)
  let waitSeconds = nextInt(inputData, scanPos)
  var girlinessValues = newSeq[int](channelCount)
  for channelIndex in 0 .. channelCount - 1:
    girlinessValues[channelIndex] = nextInt(inputData, scanPos)
  let startGirliness = girlinessValues[0]
  girlinessValues.sort(proc (leftValue, rightValue: int): int = system.cmp(leftValue, rightValue))
```

The starting value comes from the original channel order.
Sorting happens after that value is saved.
The buffer flushes by block, not by line.

**Greedy jumps.** A binary search takes the farthest value within reach until none remains.

```nim
  var currentGirliness = startGirliness
  var jumpCount = 0
  while true:
    let reachLimit = int64(currentGirliness) + int64(jumpLimit)
    var lowIndex = 0
    var highIndex = channelCount - 1
    var bestIndex = -1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if int64(girlinessValues[middleIndex]) <= reachLimit:
        bestIndex = middleIndex
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    if bestIndex < 0 or girlinessValues[bestIndex] <= currentGirliness:
      break
    currentGirliness = girlinessValues[bestIndex]
    jumpCount += 1
  appendOutput($currentGirliness)
  appendOutput(" ")
  appendOutput($(int64(jumpCount) * int64(waitSeconds)))
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The reach uses int64 to avoid overflow.
A jump happens only when the chosen value is larger.
The final line flushes the buffered answers.

## Complexity

Each day reads N values, sorts them, then binary-searches for every jump.

| phase | time | space |
|---|---|---|
| input scan | one pass over N values | one input string |
| sorting | N log N comparisons | sorted value array |
| greedy jumps | at most N searches of log N | a few index variables |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per day | O(N log N) |
| space per day | O(N) |

Trying every channel pair would cost far more than sorting and searching.

Sorting once keeps the greedy loop simple and fast.
