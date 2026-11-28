# INS14A — BSTRING (SPOJ)

<https://www.spoj.com/problems/INS14A/>

## Problem

Move ones with adjacent swaps until some block of M positions holds M ones. Find the fewest swaps for each binary string. The string always contains at least M ones.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| string length N | 1 to 50000 |
| ones wanted M | 1 to N |
| sum of N | at most 50000 |
| judge limit | 1000 ms, 1536 MB |

A swap exchanges two neighboring characters. The final block may start anywhere.

Sample input:

```
2
3
101001
2
101001
```

Sample output:

```
3
1
```

## Idea

Treat the chosen ones like people filling M adjacent seats, like a row of friends sliding to the middle. Each person walks to a reserved seat, and the best reserved seats center on the median position. Subtract the seat index from each one's index, then sum distances to that median.

Use a prefix sum of these adjusted indexes to price every window in constant time. A sliding scan then tries all groups of M ones.

## Why It Works

1. List the indexes of all ones as `onesPositions`, sorted by construction.
2. A group of M ones ends in M consecutive seats starting at some position.
3. Pair the j-th chosen one with the j-th seat, since crossings never help.
4. Its adjusted index is one index minus its group offset j.
5. All chosen seats shift together, so one common offset minimizes total movement.
6. The median of the adjusted indexes is the best common offset.
7. Prefix sums give the left and right distance sums without rescanning.

| term | meaning |
|---|---|
| adjusted index | one index minus its position inside the group |
| medianValue | adjusted index at the middle of the group |
| adjustedPrefix | running sum of adjusted indexes |
| windowCost | swaps needed for one group of M ones |

For `101001` and M = 3, the ones sit at 0, 2, 5. Adjusted indexes are 0, 1, 3, the median is 1, and the cost is 1 + 0 + 2 = 3.

## Code

**Input and scanning.** The reader takes M and then the binary string for each case.

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

proc nextBinary(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '1'):
    pos += 1
  var collected = ""
  while pos < data.len and (data[pos] == '0' or data[pos] == '1'):
    collected.add data[pos]
    pos += 1
  return collected

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The binary reader stops at whitespace without parsing digits as numbers.
The scanner position advances past both fields of every case.

**Median windows.** Prefix sums price each consecutive group of ones.

```nim
let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let onesNeeded = nextInt(inputData, scanPos)
  let binaryString = nextBinary(inputData, scanPos)
  var onesPositions = newSeq[int]()
  for charIndex in 0 .. binaryString.len - 1:
    if binaryString[charIndex] == '1':
      onesPositions.add charIndex
  var adjustedPrefix = newSeq[int64](onesPositions.len + 1)
  for positionIndex in 0 .. onesPositions.len - 1:
    adjustedPrefix[positionIndex + 1] = adjustedPrefix[positionIndex] + int64(onesPositions[positionIndex] - positionIndex)
  let windowCount = onesPositions.len - onesNeeded + 1
  var minimumSwaps: int64 = int64(binaryString.len) * int64(binaryString.len)
  for windowStart in 0 .. windowCount - 1:
    let medianIndex = windowStart + onesNeeded div 2
    let medianValue = int64(onesPositions[medianIndex] - medianIndex)
    let leftCount = onesNeeded div 2
    let rightCount = onesNeeded - leftCount - 1
    let leftCost = medianValue * int64(leftCount) - (adjustedPrefix[medianIndex] - adjustedPrefix[windowStart])
    let windowEnd = windowStart + onesNeeded
    let rightCost = (adjustedPrefix[windowEnd] - adjustedPrefix[medianIndex + 1]) - medianValue * int64(rightCount)
    let windowCost = leftCost + rightCost
    if windowCost < minimumSwaps:
      minimumSwaps = windowCost
  appendOutput($minimumSwaps)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The median sits at the middle adjusted index of the window.
Left and right costs use two prefix differences each.
The smallest window cost is written once per case.

## Complexity

Collecting ones costs one pass over the string.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| prefix build | one pass over the ones | array of prefix sums |
| window scan | one pass over the ones | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N) |
| space per case | O(N) |

Testing every target block by moving ones one step at a time would cost O(N²).

The single median scan keeps each case linear in the string length.
