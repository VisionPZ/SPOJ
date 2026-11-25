<https://www.spoj.com/problems/NAUGHTY/>

## Problem

Each of n balls shows one number on top and another on the bottom. Flip balls at one move each so at least half show the same top number, and report the fewest moves.

Input gives n, then n lines with a top and bottom label. Output the minimum move count, or `Impossible` when no label reaches half the balls.

| item | bound |
|---|---|
| balls n | 1 to 100000 |
| each label | 0 to 100000 |
| target count | ceil(n/2) |
| judge limit | 1000 ms, 1536 MB |

A ball counts for a label at zero cost when the label is already on top, and at one move when the label is underneath.

Sample input:

```
3
3 100
100 3
5 4
```

Sample output:

```
1
```

## Idea

Treat each label like a candidate team captain and count free players before paid substitutes.

The real algorithm is a histogram sweep over labels, at O(n + 100001) cost. Trying every candidate against every ball costs O(n²) and fails at 100000 balls. Tally the two sides once, then read each label's answer.

## Why It Works

1. At least `ceil(n/2)` balls must show one chosen label.
2. A ball with that label already on top costs nothing.
3. A ball with that label underneath costs one move.
4. A ball with equal labels is counted once as free.
5. The cheapest plan uses every free ball before flipping any ball.
6. A label works when free plus flippable balls reaches the target.
7. The answer is the smallest flip count over all labels.

| term | meaning |
|---|---|
| `requiredCount` | ceil(n/2), the number of matching tops needed |
| `topCounts` | balls already showing each label |
| `bottomCounts` | balls hiding each label |
| `bothCounts` | balls with equal labels, counted once |
| `bestMoves` | smallest flip count found so far |

For the sample, a script checked each label. Label 100 has one free ball and one flippable ball, so it needs one move. Label 3 also needs one move, and the answer is `1`.

The second sample has three balls already showing 5, so the answer is `0`. The third sample leaves every label with only one reachable ball, so the answer is `Impossible`.

## Code

**Input and scanning.** All pairs are read from one input string.

```nim
const flushBlockBytes = 1 shl 17
const maxLabel = 100000

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

Labels are non-negative, so the scanner skips separators only.
The largest legal label fixes the table size.

**Buffered output.** One string collects the result line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in blocks.
A single final write ends the output.

**Histogram sweep.** Tables are filled once, then each label is priced.

```nim
let ballCount = nextInt(inputData, scanPos)
let requiredCount = (ballCount + 1) div 2
var topCounts = newSeq[int](maxLabel + 1)
var bottomCounts = newSeq[int](maxLabel + 1)
var bothCounts = newSeq[int](maxLabel + 1)
var ballIndex = 0
while ballIndex < ballCount:
  let topLabel = nextInt(inputData, scanPos)
  let bottomLabel = nextInt(inputData, scanPos)
  topCounts[topLabel] += 1
  bottomCounts[bottomLabel] += 1
  if topLabel == bottomLabel:
    bothCounts[topLabel] += 1
  ballIndex += 1
var bestMoves = ballCount + 1
var label = 0
while label <= maxLabel:
  let freeCount = topCounts[label]
  let flippableCount = bottomCounts[label] - bothCounts[label]
  if freeCount + flippableCount >= requiredCount:
    var neededMoves = requiredCount - freeCount
    if neededMoves < 0:
      neededMoves = 0
    if neededMoves <= flippableCount and neededMoves < bestMoves:
      bestMoves = neededMoves
  label += 1
if bestMoves <= ballCount:
  appendOutput($bestMoves)
else:
  appendOutput("Impossible")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal-label balls are removed from the flippable pool.
A sentinel larger than n marks failure.
Free balls are always spent before any flip.

## Complexity

Filling tables and sweeping labels dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over n pairs | one input string |
| tallies | one update per ball | three label tables |
| label sweep | 100001 checks | constant |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(n + 100001) |
| space | O(n + 100001) |

Testing every label against every ball would cost O(n · 100001) time.

Count once per ball, sweep labels, and print the cheapest plan.
