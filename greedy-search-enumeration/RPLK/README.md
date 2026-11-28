# RPLK — Kind and gently (SPOJ)

<https://www.spoj.com/problems/RPLK/>

## Problem

Boards are cut into equal-width stair steps, and the goal is the tallest staircase allowed by a step budget. Each step adds its board height plus a fixed separator height.

The first line holds the number of cases. Each case starts with E, M, K, and W. Then E lines give each board's height and width. Print `Scenario #i: ` followed by the maximum total height.

| item | bound |
|---|---|
| boards E | 1 to 100000 |
| overlap M | 1 to 1000 |
| separator K | 1 to 100000 |
| step budget W | 1 to 10000 |
| board width and height | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

The board count and the step budget drive the design, since enumerating every step can be costly.

Sample input:

```
3
5 1 1 3
6 2
5 10
4 20
3 15
1 1
3 1 0 5
3 15
2 20
1 60
2 1 1 25
15 10
12 10
```

Sample output:

```
Scenario #1: 19
Scenario #2: 15
Scenario #3: 145
```

## Idea

Take the tallest available steps first, like picking the tallest books off a row of shelves. A counting array groups steps by height, so the program scans heights from high to low instead of sorting a huge step list.

A board of width WE yields WE div (M+1) steps, each worth HE+K. The greedy scan takes the allowed number of steps from the largest value downward. One case costs O(E + V), where V is the largest step value.

Enumerating every step would create up to 100 million entries for the largest case. Sorting that list would be far slower than counting heights. The takeaway is to count equal-height steps together.

## Why It Works

1. Every step consumes exactly M+1 units of board width.
2. A board therefore supplies WE div (M+1) identical steps.
3. A step contributes HE + K, combining board height and separator height.
4. Contributions are positive, so the best staircase uses L = min(W, total steps) steps.
5. The largest possible sum of L values comes from taking the L largest step values.
6. Buckets indexed by step value give those largest values in descending order.

| term | meaning |
|---|---|
| `stepWidth` | required width per step, M+1 |
| `WoodPiece` | stored height and width of one board |
| `buckets` | count of steps available at each value |
| `largestValue` | highest step value seen in the case |
| `remainingSteps` | number of steps still allowed |
| `totalHeight` | accumulated height, held in 64 bits |

The table names the data kept for one case.

A script trace for the first sample uses M = 1 and K = 1. The step width is 2, and the step values are 7, 6, 5, 4, and 2.

| board | steps | value per step |
|---|---|---|
| 6 x 2 | 1 | 7 |
| 5 x 10 | 5 | 6 |
| 4 x 20 | 10 | 5 |
| 3 x 15 | 7 | 4 |
| 1 x 1 | 0 | 2 |

Taking the three largest values gives 7 + 6 + 6 = 19. This matches the first sample answer.

Width division is exact integer division, so no rounding appears. The bucket array is sized from the largest observed value, which avoids fixed guesses.

## Code

**Input and helpers.** The reader loads all lines, extracts integers, and defines one board record.

```nim
const flushBlockBytes = 1 shl 17

type WoodPiece = object
  height: int
  width: int

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

The record keeps each board until buckets are ready.
The scanner skips spaces and line breaks.
One input string serves every case.

**Bucketing.** Each board adds its step count to the bucket for its step value.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pieceCount = nextInt(inputData, scanPos)
  let overlap = nextInt(inputData, scanPos)
  let separatorHeight = nextInt(inputData, scanPos)
  let maxSteps = nextInt(inputData, scanPos)
  let stepWidth = overlap + 1
  var pieces: seq[WoodPiece] = @[]
  var largestValue = 0
  for pieceIndex in 1 .. pieceCount:
    var piece: WoodPiece
    piece.height = nextInt(inputData, scanPos)
    piece.width = nextInt(inputData, scanPos)
    pieces.add piece
    let candidateValue = piece.height + separatorHeight
    if candidateValue > largestValue:
      largestValue = candidateValue
  var buckets = newSeq[int](largestValue + 1)
  for pieceIndex in 0 .. pieces.len - 1:
    let piece = pieces[pieceIndex]
    let stepCount = piece.width div stepWidth
    if stepCount > 0:
      buckets[piece.height + separatorHeight] += stepCount
```

`largestValue` sets the exact bucket range.
Boards narrower than one step add nothing.
`appendOutput` flushes only after a full block.

**Greedy scan.** Heights are visited from high to low until the budget runs out.

```nim
  var remainingSteps = maxSteps
  var totalHeight: int64 = 0
  var valueCursor = largestValue
  while valueCursor >= 0 and remainingSteps > 0:
    let takenSteps = buckets[valueCursor]
    if takenSteps > 0:
      if takenSteps > remainingSteps:
        totalHeight += int64(valueCursor) * int64(remainingSteps)
        remainingSteps = 0
      else:
        totalHeight += int64(valueCursor) * int64(takenSteps)
        remainingSteps -= takenSteps
    valueCursor -= 1
  appendOutput("Scenario #")
  appendOutput($caseIndex)
  appendOutput(": ")
  appendOutput($totalHeight)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan stops as soon as the budget is spent.
`totalHeight` uses 64 bits for large products.
The final write flushes the buffered answers.

## Complexity

Boards are read once, then counted into height buckets.

| phase | time | space |
|---|---|---|
| input read | one pass over board lines | board records |
| bucketing | one division per board | bucket array |
| greedy scan | one pass over value range | constant scratch |
| output | buffered writes | one output buffer |

Bucketing and the greedy scan dominate the board read.

| measure | Big O |
|---|---|
| time | O(E + V) per case, with V the largest value |
| space | O(E + V) per case |

Sorting every available step would cost O(S log S) for S steps. Counting equal values removes that sorting pass entirely.
