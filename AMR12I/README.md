# AMR12I — Saruman of Many Colours (SPOJ)

<https://www.spoj.com/problems/AMR12I/>

## Problem

A row of soldiers needs target colors. One stroke paints any block of exactly `K` consecutive soldiers in a single chosen color, and strokes may overlap. Find the fewest strokes that produce the target, or report impossibility.

Input starts with `T`, the test count. Each case gives `N` and `K`, then a string of `N` lowercase color letters. Print one integer per case: the minimum stroke count, or `-1` when the target cannot be produced.

| item | bound |
|---|---|
| test cases `T` | 1 to 50 |
| soldiers `N` | 1 to 20000 |
| stroke width `K` | 1 to `N` |
| colors | lowercase `a` to `z` |
| judge limit | 2000 ms, 1536 MB |

A stroke must fit inside the row, so its start index cannot exceed `N - K`.

Sample input:

```
2
3 2
rgg
3 3
rgg
```

Sample output:

```
2
-1
```

## Idea

Look at the last stroke that covers the newest soldier, like choosing the final brush pass when repainting a fence. That stroke starts within the last `K` positions and must cover a run of one color ending at this soldier. The cost is one plus the best prefix cost at a legal start. Keep the best prefix costs in per-color queues, ordered by start so old starts leave on time.

A scan over all starts at every position costs O(N × K). The per-color queue keeps only the smallest cost for the current run and drops expired starts in constant time. The takeaway is that only one color queue is read at each position.

## Why It Works

1. The stroke covering soldier `i` starts at a position from `i - K` up to `i - 1`.
2. That same stroke also covers every soldier from its start through `i - 1`.
3. Those soldiers must all already carry the target color of soldier `i`, so the start lies inside one color run.
4. A queue per color stores the smallest prefix cost among starts in that run.
5. Starts older than `i - K` leave the queue front and can never serve position `i`.
6. If the active queue is empty, no legal final stroke exists and the case fails.

| term | meaning |
|---|---|
| `dp` | minimum strokes for each prefix length |
| `lastStart` | largest legal stroke start |
| `earliestStart` | smallest start still covering the current soldier |
| `candidatePos` | start positions kept in a per-color queue |
| `candidateValue` | prefix costs kept in the same order |
| `dequeHead` | queue front index |
| `dequeTail` | queue end index |

The table names the arrays that hold the sliding-window minimum.

A script trace of the first sample case follows, with K = 2 and one legal start.

| soldier | color | legal starts | chosen prefix cost | result |
|---|---|---|---|---|
| 1 | r | 0 | 0 | 1 |
| 2 | g | 1 | 1 | 2 |
| 3 | g | 1 | 1 | 2 |

With K = 3, the only legal start is 0, the second run has no valid start, and the answer is `-1`.

## Code

**Input and input helpers.** All input is read once, then each case header and color string are taken from it.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const impossible = 1000000007

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    word.add data[pos]
    pos += 1
  return word
```

`nextInt` reads the case sizes.
`nextWord` returns the color string.
`impossible` marks a prefix that cannot be painted.

**Buffered output and sliding queues.** Each color keeps one monotone queue of start costs.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let soldierCount = nextInt(inputData, scanPos)
  let strokeWidth = nextInt(inputData, scanPos)
  let colorText = nextWord(inputData, scanPos)
  var candidatePos: array[alphabetSize, seq[int]]
  var candidateValue: array[alphabetSize, seq[int]]
  var dequeHead: array[alphabetSize, int]
  var dequeTail: array[alphabetSize, int]
  for colorIndex in 0 .. alphabetSize - 1:
    candidatePos[colorIndex] = newSeq[int](soldierCount + 1)
    candidateValue[colorIndex] = newSeq[int](soldierCount + 1)
    dequeHead[colorIndex] = 0
    dequeTail[colorIndex] = 0
  var dp = newSeq[int](soldierCount + 1)
  dp[0] = 0
  let lastStart = soldierCount - strokeWidth
  for soldierIndex in 1 .. soldierCount:
    let colorIndex = int(colorText[soldierIndex - 1]) - int('a')
    if soldierIndex == 1 or int(colorText[soldierIndex - 2]) - int('a') != colorIndex:
      dequeHead[colorIndex] = 0
      dequeTail[colorIndex] = 0
    if soldierIndex - 1 <= lastStart and dp[soldierIndex - 1] < impossible:
      var tailIndex = dequeTail[colorIndex] - 1
      while tailIndex >= dequeHead[colorIndex] and candidateValue[colorIndex][tailIndex] >= dp[soldierIndex - 1]:
        tailIndex -= 1
      dequeTail[colorIndex] = tailIndex + 1
      candidatePos[colorIndex][dequeTail[colorIndex]] = soldierIndex - 1
      candidateValue[colorIndex][dequeTail[colorIndex]] = dp[soldierIndex - 1]
      dequeTail[colorIndex] += 1
    let earliestStart = soldierIndex - strokeWidth
    while dequeHead[colorIndex] < dequeTail[colorIndex] and candidatePos[colorIndex][dequeHead[colorIndex]] < earliestStart:
      dequeHead[colorIndex] += 1
    if dequeHead[colorIndex] < dequeTail[colorIndex]:
      dp[soldierIndex] = candidateValue[colorIndex][dequeHead[colorIndex]] + 1
    else:
      dp[soldierIndex] = impossible
  if dp[soldierCount] >= impossible:
    appendOutput("-1\n")
  else:
    appendOutput($dp[soldierCount])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A color change clears that color's queue.
`earliestStart` expires starts that no longer cover the current soldier.
`appendOutput` writes the verdict for the case.

## Complexity

Each soldier enters one queue once and leaves it once.

| phase | time | space |
|---|---|---|
| input read | one pass over the color string | one input string |
| queue processing | O(1) amortized per soldier | two queues per color |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N × 26) for queue setup, O(N) for the scan |
| extra space | O(N) for queues and costs |

Scanning every legal start at every soldier costs O(N × K) and grows with the stroke width. The monotone queue removes that factor and keeps the scan linear in the row length.
