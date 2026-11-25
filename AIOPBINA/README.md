# AIOPBINA — Simple Search (SPOJ)

<https://www.spoj.com/problems/AIOPBINA/>

## Problem

A sorted array and a target value are given several times. Decide for each case whether the target appears in the array.

The input starts with the test count. Each case gives the array size and target, then the sorted array. Print YES or NO per case.

| item | bound |
|---|---|
| tests T | 1 to 15 |
| array size N | 1 to 100000 |
| target K | 1 to 100000 |
| judge limit | 300 ms, 1536 MB |

The array is already sorted, so no preparation is needed.

Sample input:

```
2
5 10
1 4 7 10 20
6 13
1 4 6 7 8 23
```

Sample output:

```
YES
NO
```

## Idea

Open the array in the middle, like finding a word in a dictionary by halving the page range each time. If the middle is too small, search the right half; if too large, search the left half. Each step discards half the remaining positions. A linear scan would inspect every position for every case.

## Why It Works

1. The array values never decrease from left to right.
2. A middle value smaller than the target rules out the whole left half.
3. A middle value larger than the target rules out the whole right half.
4. Equal middle values end the search at once.

| term | meaning |
|---|---|
| `sortedValues` | the sorted array for one case |
| `lowIndex` | first position still possible |
| `highIndex` | last position still possible |
| `targetValue` | value being searched for |

The interval shrinks until it is empty or the target is found.

Script-generated trace for the first sample case:

```
low | high | middle | value | action
0 | 4 | 2 | 7 | go right
3 | 4 | 3 | 10 | found
```

The target 10 is found, so the program prints YES.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

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
```

All values are parsed before the searches begin.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Binary search and output.** Two bounds halve the search interval.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberCount = nextInt(inputData, scanPos)
  let targetValue = nextInt(inputData, scanPos)
  var sortedValues = newSeq[int](numberCount)
  for numberIndex in 0 .. numberCount - 1:
    sortedValues[numberIndex] = nextInt(inputData, scanPos)
  var lowIndex = 0
  var highIndex = numberCount - 1
  var found = false
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] == targetValue:
      found = true
      break
    if sortedValues[middleIndex] < targetValue:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if found:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each step reads one middle value.
The interval never grows back.
Each case writes one buffered line.

## Complexity

Halving the interval keeps each search short.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | one input string |
| binary search | O(log N) comparisons | array of N integers |
| output | one line per case | block buffer |

The array is stored because random access needs indexing.

| measure | Big O |
|---|---|
| time | O(T log N) after input |
| space | O(N) |

Scanning every value would cost O(N) per case and wastes the sorted order.
