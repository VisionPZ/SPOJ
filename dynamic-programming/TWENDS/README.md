# TWENDS — Two Ends (SPOJ)
<https://www.spoj.com/problems/TWENDS/>

## Problem

Two players take cards from either end of a row. The second player always takes the larger end, preferring the left on a tie. Report the largest score gap the first player can reach against that fixed greedy strategy.

| item | bound |
|---|---|
| cards per game | even, at most 1000 |
| card value | positive integer |
| total per game | at most 1,000,000 |
| judge limit | 1000 ms, 1536 MB |

A line with a single zero ends the input.

Sample input:

```
4 3 2 10 4
8 1 2 3 4 5 6 7 8
8 2 2 1 5 3 8 7 3
0
```

Sample output:

```
In game 1, the greedy strategy might lose by as many as 7 points.
In game 2, the greedy strategy might lose by as many as 4 points.
In game 3, the greedy strategy might lose by as many as 5 points.
```

## Idea

Think of choosing cards like taking coins from a row where the opponent follows a fixed recipe. Once that recipe is known, each reply is predictable, so the first player can plan ahead. The algorithm solves short intervals first and builds longer ones from them. Trying every move sequence would branch exponentially.

## Why It Works

1. After each pair of moves, the remaining cards form one shorter interval.
2. The greedy reply depends only on the two ends left after the first move.
3. A state is therefore a left index and an even interval length.
4. The first move adds its card, subtracts the greedy reply, and adds the solved shorter interval.
5. Taking the better of the two ends yields the best gap for that state.

| term | meaning |
|---|---|
| `cards` | values in the current row |
| `previous` | best gaps for intervals of length `intervalLength` minus two |
| `current` | best gaps for intervals of the current length |
| `intervalLength` | even number of cards left in a state |

For `3 2 10 4`, the two-card gaps are 1, 8, and 6. For the full row, taking 3 leaves `2 10 4`; greedy takes 4, leaving the two-card gap 8, so the total is 3 - 4 + 8 = 7. Taking 4 leaves `3 2 10`; greedy takes 10, leaving gap 1, so the total is 4 - 10 + 1 = -5. The maximum is 7, which matches the sample.

The tie rule uses `>=`, so an equal left end is removed by the greedy player.

## Code

**Input and output helpers.** The reader loads all text once and writes through one buffer.

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

All values are positive, so the scanner skips only separators.
The block flush keeps writes rare.
One final write ends the output path.

**Game solver.** Each length uses the solved lengths before it.

```nim
var gameNumber = 0
while true:
  let cardCount = nextInt(inputData, scanPos)
  if cardCount == 0:
    break
  gameNumber += 1
  var cards = newSeq[int](cardCount)
  for cardIndex in 0 .. cardCount - 1:
    cards[cardIndex] = nextInt(inputData, scanPos)
  var previous = newSeq[int](cardCount + 2)
  var current = newSeq[int](cardCount + 2)
  var intervalLength = 2
  while intervalLength <= cardCount:
    for leftIndex in 0 .. cardCount - intervalLength:
      let rightIndex = leftIndex + intervalLength - 1
      var firstValue = 0
      if cards[leftIndex + 1] >= cards[rightIndex]:
        firstValue = cards[leftIndex] - cards[leftIndex + 1] + previous[leftIndex + 2]
      else:
        firstValue = cards[leftIndex] - cards[rightIndex] + previous[leftIndex + 1]
      var secondValue = 0
      if cards[leftIndex] >= cards[rightIndex - 1]:
        secondValue = cards[rightIndex] - cards[leftIndex] + previous[leftIndex + 1]
      else:
        secondValue = cards[rightIndex] - cards[rightIndex - 1] + previous[leftIndex]
      if firstValue > secondValue:
        current[leftIndex] = firstValue
      else:
        current[leftIndex] = secondValue
    swap previous, current
    intervalLength += 2
  appendOutput("In game ")
  appendOutput($gameNumber)
  appendOutput(", the greedy strategy might lose by as many as ")
  appendOutput($previous[0])
  appendOutput(" points.\n")
```

Taking the left end leaves an odd row for the greedy reply.
Taking the right end mirrors that choice.
Swapping the two rows makes each new length reuse the old results.
The full row's best gap is written once per game.

## Complexity

| phase | time | space |
|---|---|---|
| read cards | one pass over each game | one input string |
| interval sweep | n/2 lengths times n states | two arrays of n gaps |
| output | one line per game | block buffer |

| measure | Big O |
|---|---|
| per game | O(n^2) time |
| space | O(n) |

Exploring both moves at every turn would take exponential time.
