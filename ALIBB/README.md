## Problem

Alibaba walks along a straight road to collect treasures. Each treasure has a position and a deadline. He chooses where to start, and walking one unit of distance takes one unit of time. Collecting a treasure takes no time. Print the earliest time at which he can collect every treasure strictly before its deadline, or print `No solution`.

| Quantity | Bound |
| --- | --- |
| Datasets | at most 10 |
| Treasures per dataset | at most 10,000 |
| Time limit | 1 s |
| Memory limit | 1536 MB |

A dataset can hold 10,000 treasures, so the work per dataset drives the design.

## Idea

Treat the collected treasures as one block of consecutive positions. After any walk, Alibaba stands at the left or right end of that block. A state stores the block and the end where he stands. Each step adds the next treasure at one end, so a small table answers the whole dataset. Trying every visiting order instead takes factorial time.

Cost: one state per block and end, with constant work per state.

## Why It Works

Walking past a treasure collects it for free. The collected block therefore grows by one treasure at a time. The new treasure is collected last, so only its arrival time needs a deadline check. An arrival equal to the deadline is too late, so the program marks that state with `infinity`.

The two updates use these values:

- `curLeft[leftIndex]` adds the left treasure after a walk ending on the left or right.
- `curRight[leftIndex]` adds the right treasure after a walk ending on the left or right.
- A value at least the new deadline becomes `infinity`.
- `prevLeft` and `prevRight` hold the shorter block from the previous right end.

If every deadline exceeds the span of the whole road, a walk from one end to the other works. That walk finishes at `span`, and no walk can finish sooner.

This table comes from the generator script for the first sample. Each entry gives the best time ending at the left end and at the right end.

```
right 1, left 1 -> (0, 0)
right 2, left 1 -> (2, inf)
right 3, left 1 -> (inf, 6)
right 4, left 1 -> (inf, 9)
right 5, left 1 -> (inf, 11)
right 5, left 2 -> (inf, 7)
right 5, left 3 -> (5, 5)
right 5, left 4 -> (2, 2)
answer 11
```

The last row ends at the right end of the full block, which gives the answer 11.

## Code

The program reads stdin once into `inputData` and scans digits by hand. One `outputBuffer` flushes in large blocks.

```nim
{.checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = 1 shl 60

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and newlines, so input whitespace needs no special cases. `scanPos` advances past each number, and no token objects are built. Named constants replace digits and the flush size.

The main loop reads one dataset and tests the span shortcut.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let treasureCount = nextInt(inputData, scanPos)
  var position = newSeq[int](treasureCount + 1)
  var deadline = newSeq[int](treasureCount + 1)
  for k in 1..treasureCount:
    position[k] = nextInt(inputData, scanPos)
    deadline[k] = nextInt(inputData, scanPos)
  let span = position[treasureCount] - position[1]
  var allDeadlinesLoose = true
  for k in 1..treasureCount:
    if deadline[k] <= span:
      allDeadlinesLoose = false
      break
  var answer = 0
  if allDeadlinesLoose:
    answer = span
  elif treasureCount > 1:
```

The inner loops run once per treasure. The shortcut avoids the table when no deadline can bind. A strict comparison keeps the equal-deadline case in the table.

The table keeps only two rows, one for each end of the current block.

```nim
    var prevLeft = newSeq[int](treasureCount + 2)
    var prevRight = newSeq[int](treasureCount + 2)
    var curLeft = newSeq[int](treasureCount + 2)
    var curRight = newSeq[int](treasureCount + 2)
    for k in 0..treasureCount + 1:
      prevLeft[k] = infinity
      prevRight[k] = infinity
      curLeft[k] = infinity
      curRight[k] = infinity
    prevLeft[1] = 0
    prevRight[1] = 0
    for rightIndex in 2..treasureCount:
      curLeft[rightIndex] = 0
      curRight[rightIndex] = 0
      var leftIndex = rightIndex - 1
      while leftIndex >= 1:
        var bestLeft = curLeft[leftIndex + 1] + position[leftIndex + 1] - position[leftIndex]
        let crossLeft = curRight[leftIndex + 1] + position[rightIndex] - position[leftIndex]
        if crossLeft < bestLeft: bestLeft = crossLeft
        if bestLeft >= deadline[leftIndex]: bestLeft = infinity
        curLeft[leftIndex] = bestLeft
        var bestRight = prevLeft[leftIndex] + position[rightIndex] - position[leftIndex]
        let crossRight = prevRight[leftIndex] + position[rightIndex] - position[rightIndex - 1]
        if crossRight < bestRight: bestRight = crossRight
        if bestRight >= deadline[rightIndex]: bestRight = infinity
        curRight[leftIndex] = bestRight
        leftIndex -= 1
      swap prevLeft, curLeft
      swap prevRight, curRight
    answer = min(prevLeft[1], prevRight[1])
```

`rightIndex` grows from 2 to the treasure count, and `leftIndex` walks down to 1. Setting both single-treasure rows to zero lets Alibaba start at any treasure. The downward order keeps the wider row ready when a state needs it. Each pair of indices costs constant time.

The program writes one result per dataset and flushes the last block.

```nim
  if answer >= infinity:
    appendOutput("No solution")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

An unreachable answer stays at `infinity` and prints `No solution`. Each result ends with a newline. The final write emits the bytes left in the buffer.

## Complexity

Reading input costs one pass over the numbers. The table costs O(n²) time and O(n) space per dataset, and the span shortcut costs O(n) time. Total time is O(n²) per dataset, with O(n) space for the two row pairs. Enumerating every visiting order instead takes O(n!) time.
