## Problem

Read t test cases. Each case gives a stick length N and a string of N segments, with '1' for sweet and '0' for sour. Break the stick at connections so that pieces with more sweet than sour segments can be sold. Print the largest total sold length.

The judge bounds appear below.

| Quantity | Bound |
| --- | --- |
| Test cases | not stated |
| Stick length N | 1 to 200 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The small stick length keeps each case cheap, so the number of cases drives the design.

## Idea

We score sweet segments +1 and sour segments -1, then use dynamic programming with a prefix-maximum index (a Fenwick tree). Each step keeps the best total for blocks ending at the current position, using one prefix-maximum query instead of trying every start. Trying every start and end would cost O(N squared) per case.

Each segment costs O(log N) time and O(1) extra space.

## Why It Works

prefixScore is the running sum after a given number of segments. The score of the block from k+1 to i equals prefixScore[i] - prefixScore[k], which is positive exactly when prefixScore[k] < prefixScore[i].

bestSold[i] takes the larger of two values:

- leave segment i unsold, giving bestSold[i-1];
- sell a block ending at i, giving bestSold[k] + i - k.

Rewrite the second value as i + (bestSold[k] - k). We need the largest bestSold[k] - k among all earlier k whose prefix score is smaller than prefixScore[i]. scoreIndex shifts each prefix score by N+1, so indexes stay between 1 and 2N+1. The query reads scores up to scoreIndex - 1, which enforces a strict inequality. Each tree cell holds the largest value seen at that score, and the low-bit walk visits O(log N) cells.

The table below comes from a script run on the stick 10011001.

| i | char | prefixScore | scoreIndex | best[k]-k | candidate | bestSold |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 10 | 0 | 1 | 1 |
| 2 | 0 | 0 | 9 | none | none | 1 |
| 3 | 0 | -1 | 8 | none | none | 1 |
| 4 | 1 | 0 | 9 | -2 | 2 | 2 |
| 5 | 1 | 1 | 10 | 0 | 5 | 5 |
| 6 | 0 | 0 | 9 | -2 | 4 | 5 |
| 7 | 0 | -1 | 8 | none | none | 5 |
| 8 | 1 | 0 | 9 | -2 | 6 | 6 |

The answer is 6: sell segment 1, then the block from 4 to 8.

## Code

Constants and input scanner:

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const negInfinite = -1000000000
const maxStickLength = 200
const treeCapacity = 2 * maxStickLength + 3

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop visits each input line once and stops at end of file. nextInt skips whitespace, so a newline is never read as a digit. The scan makes one pass over `inputData`.

Output buffer:

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

appendOutput flushes when the buffer reaches flushBlockBytes. setLen 0 reuses the same string. Memory stays at the block size.

Prefix-maximum index:

```nim
var fenwick: array[treeCapacity, int]
var fenwickSize = 0

proc fenwickUpdate(index: int, value: int) =
  var j = index
  while j <= fenwickSize:
    if value > fenwick[j]:
      fenwick[j] = value
    j += j and (-j)

proc fenwickPrefixMax(index: int): int =
  result = negInfinite
  var j = index
  while j > 0:
    if fenwick[j] > result:
      result = fenwick[j]
    j -= j and (-j)
```

The low-bit step j and (-j) walks O(log N) tree cells per call. The update raises cells on the path; the query reads cells on the reverse path. negInfinite marks a score with no recorded k.

Main loop:

```nim
let caseCount = nextInt(inputData, scanPos)
for k in 0..<caseCount:
  let stickLength = nextInt(inputData, scanPos)
  while scanPos < inputData.len and inputData[scanPos] != '0' and inputData[scanPos] != '1':
    scanPos += 1
  fenwickSize = 2 * stickLength + 2
  for j in 0..<treeCapacity:
    fenwick[j] = negInfinite
  fenwickUpdate(stickLength + 1, 0)
  var prefixScore = 0
  var bestSold = 0
  for i in 1..stickLength:
    if inputData[scanPos] == '1':
      prefixScore += 1
    else:
      prefixScore -= 1
    scanPos += 1
    let scoreIndex = prefixScore + stickLength + 1
    let candidate = i + fenwickPrefixMax(scoreIndex - 1)
    if candidate > bestSold:
      bestSold = candidate
    fenwickUpdate(scoreIndex, bestSold - i)
  appendOutput($(bestSold))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs caseCount times and the inner loop runs stickLength times. Reading exactly stickLength pattern characters keeps the next case's digits out of the scan. Each case resets the tree and inserts k = 0 before reading any segment.

## Complexity

Input costs O(B) for B input bytes. Each case costs O(N log N) time and O(N) space for the tree. Output costs O(t) amortized with block flushing.

The total is O(B + sum of N log N) time and O(max N) working space. The naive form tries every block for every position and costs O(N squared) per case. Brute force over all partitions costs O(2 to the N) per case.
