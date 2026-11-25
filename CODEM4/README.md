# CODEM4 — Problem4 (SPOJ)
<https://www.spoj.com/problems/CODEM4/>

## Problem

Two players remove numbers from an even-length row, taking either end each turn. Player one plays well, while player two either picks without thought or plays to lower player one's score. Report player one's best total under each kind of opponent.

The first line holds T. Each case has one line with the even size, then one line with the array values.
Print two integers per case: the score against a dumb second player, then the score against a smart one.

The bounds are:

| item | bound |
|---|---|
| test cases T | less than 20 |
| array size | even, at most 30 |
| array value | fits in an int |
| judge limit | 8846 ms, 1536 MB |

The small size allows a table for every interval.

Sample input:

```
2
4
5 8 4 2
4
8 5 4 2
```

Two cases use the same length of four.

Sample output:

```
13 10
13 12
```

The first number of each line assumes a dumb opponent.

## Idea

Think of the remaining row as a corridor with one door at each end, and each turn closes one door.

Use interval DP keyed by the left and right ends. An even remaining length means player one moves and takes the better end. An odd length means player two moves. A dumb opponent leaves the larger continuation, and a smart opponent leaves the smaller. Enumerating full play sequences grows exponentially, while the DP visits each interval once.

One pass over interval lengths fills both score tables.

## Why It Works

1. An even remaining length gives player one the turn.
2. An odd remaining length gives player two the turn.
3. A single remaining value goes to player two, so player one scores zero.
4. On player one's turn the score is the larger of the two end choices.
5. A dumb second player leaves the larger continuation score.
6. A smart second player leaves the smaller continuation score.
7. Shorter intervals are filled first, so every lookup is ready.

The main names are:

| term | meaning |
|---|---|
| `smartScores` | best score for player one against a smart opponent |
| `dumbScores` | best score for player one against a dumb opponent |
| `pickedValues` | array values in their original order |
| `windowLength` | number of values still in the interval |
| `cellIndex` | flat position for one left-right pair |

The two tables separate the opponent models.

The generator produced these intervals for the row 5 8 4 2:

| interval | length | dumb score | smart score |
|---|---|---|---|
| 5 8 | 2 | 8 | 8 |
| 8 4 | 2 | 8 | 8 |
| 4 2 | 2 | 4 | 4 |
| 5 8 4 | 3 | 8 | 8 |
| 8 4 2 | 3 | 8 | 4 |
| 5 8 4 2 | 4 | 13 | 10 |

The full row has length four, so player one moves first.

A length-one interval scores zero because player two takes the last value. The flat index uses the left end times the array size plus the right end.

## Code

**Input and output helpers.** The program reads all tokens once and buffers its answers.

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

Integer parsing skips spaces and line breaks.
The output buffer flushes only when it grows large.
No value is written directly to stdout.

**Interval tables.** The nested loops fill shorter intervals before longer ones.

```nim
for caseIndex in 0 .. testCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var pickedValues = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    pickedValues[elementIndex] = int64(nextInt(inputData, scanPos))
  var smartScores = newSeq[int64](elementCount * elementCount)
  var dumbScores = newSeq[int64](elementCount * elementCount)
  for windowLength in 1 .. elementCount:
    for leftIndex in 0 .. elementCount - windowLength:
      let rightIndex = leftIndex + windowLength - 1
      let cellIndex = leftIndex * elementCount + rightIndex
      if windowLength == 1:
        smartScores[cellIndex] = 0
        dumbScores[cellIndex] = 0
      elif windowLength mod 2 == 0:
        let takeLeft = pickedValues[leftIndex] + smartScores[(leftIndex + 1) * elementCount + rightIndex]
        let takeRight = pickedValues[rightIndex] + smartScores[leftIndex * elementCount + rightIndex - 1]
        smartScores[cellIndex] = if takeLeft > takeRight: takeLeft else: takeRight
        let dumbLeft = pickedValues[leftIndex] + dumbScores[(leftIndex + 1) * elementCount + rightIndex]
        let dumbRight = pickedValues[rightIndex] + dumbScores[leftIndex * elementCount + rightIndex - 1]
        dumbScores[cellIndex] = if dumbLeft > dumbRight: dumbLeft else: dumbRight
      else:
        let smartLeft = smartScores[(leftIndex + 1) * elementCount + rightIndex]
        let smartRight = smartScores[leftIndex * elementCount + rightIndex - 1]
        smartScores[cellIndex] = if smartLeft < smartRight: smartLeft else: smartRight
        let dumbLeft = dumbScores[(leftIndex + 1) * elementCount + rightIndex]
        let dumbRight = dumbScores[leftIndex * elementCount + rightIndex - 1]
        dumbScores[cellIndex] = if dumbLeft > dumbRight: dumbLeft else: dumbRight
  appendOutput($dumbScores[elementCount - 1] & " " & $smartScores[elementCount - 1])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

Even lengths take the larger end value.
Odd lengths compare continuations for the second player.
The full row sits at the end of each table.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| table fill | one constant step per interval | two size-squared tables |
| output | one line per case | block buffer |

The table fill dominates the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O(T times size squared) |
| space | O(size squared) |

A full game-tree search branches at every turn and grows exponentially.

The DP reuses each interval score and keeps every case small.
