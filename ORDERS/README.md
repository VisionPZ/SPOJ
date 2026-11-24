## Problem

Soldiers line up in an unknown order. Each one holds a distinct rank from 1 to n. The number w[i] tells how many higher-ranked soldiers stand before the soldier at position i. Print the ranks from left to right.

The judge limits are:

| Quantity | Bound |
| --- | --- |
| Test cases | at most 50 |
| Soldiers per case | 1 to 200000 |
| Walk count w[i] | 0 to i |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The total soldier count across all cases drives the running time.

## Idea

Build the lineup from right to left. At step i, the ranks in later positions are already fixed. The free ranks are the ones left for positions zero through i.

The rank at position i must leave w[i] free ranks larger than itself. Those larger ranks fill earlier positions. So the answer is the (w[i]+1)-th largest free rank, or the (i+1-w[i])-th smallest free rank.

A Fenwick tree (an array that tracks counts over rank values) stores the free ranks. It finds the k-th smallest free rank and removes a rank in logarithmic time.

Cost per soldier: one k-th query and one removal, each O(log n). Trying every rank for every position would cost O(n^2).

## Why It Works

A stepping soldier passes each higher rank that stands before him. So w[i] counts the earlier ranks larger than the rank at position i.

Once positions after i are fixed, every free rank larger than the rank at i must go into an earlier position. Exactly w[i] earlier positions hold larger ranks. Therefore the rank at i is the (w[i]+1)-th largest free rank.

Number positions from zero. The target index in the sorted free ranks is:

k = i + 1 - w[i]

- i + 1 is the number of free ranks before placement.
- w[i] is the number of those ranks larger than the chosen rank.
- k is the one-based index of the chosen rank among free ranks.

The worked example uses w = 0 1 2 0 1 from the sample. A script in gen.py produces the table by removing ranks from a sorted list.

| Position | w[i] | k | Chosen rank | Free ranks left |
| --- | --- | --- | --- | --- |
| 5 | 1 | 4 | 4 | 1 2 3 5 |
| 4 | 0 | 4 | 5 | 1 2 3 |
| 3 | 2 | 1 | 1 | 2 3 |
| 2 | 1 | 1 | 2 | 3 |
| 1 | 0 | 1 | 3 | (empty) |

Reading the chosen ranks from position 1 to 5 gives 3 2 1 5 4, the sample answer.

## Code

The program reads all input before it parses numbers, and it writes output in blocks.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The loop reads every input line into inputData before parsing. nextInt walks the buffer with scanPos and builds values digit by digit. appendOutput flushes at flushBlockBytes, so no write happens per number.

The main loop builds the tree, places every rank, and emits the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  var walkCounts = newSeq[int](soldierCount)
  for i in 0..<soldierCount:
    walkCounts[i] = nextInt(inputData, scanPos)

  var bitTree = newSeq[int](soldierCount + 1)
  for i in 1..soldierCount:
    bitTree[i] = i and (-i)

  var highestStep = 1
  while highestStep shl 1 <= soldierCount:
    highestStep = highestStep shl 1

  var answer = newSeq[int](soldierCount)
  for i in countdown(soldierCount - 1, 0):
    var targetRank = i + 1 - walkCounts[i]
    var treePos = 0
    var l = highestStep
    while l > 0:
      let nextPos = treePos + l
      if nextPos <= soldierCount and bitTree[nextPos] < targetRank:
        treePos = nextPos
        targetRank -= bitTree[nextPos]
      l = l shr 1
    let rankValue = treePos + 1
    answer[i] = rankValue
    var k = rankValue
    while k <= soldierCount:
      bitTree[k] -= 1
      k += k and (-k)

  for i in 0..<soldierCount:
    if i > 0:
      outputBuffer.add ' '
    appendOutput($(answer[i]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per case, and soldierCount bounds every inner loop. Setting bitTree[i] to its low bit builds the prefix counters in O(n). The countdown loop visits positions from the last one down to zero. Binary lifting finds the target rank in O(log n), and the update loop removes it in O(log n).

## Complexity

Input parsing reads the stream once. It costs O(total bytes) time and space. Tree setup costs O(n) time and O(n) space per case. Placement costs O(n log n) time per case. Output costs O(n) time per case.

With T soldiers across all cases, the total time is O(T log n) and the peak space is O(n). A brute-force search over ranks costs O(n^2) per case.
