<https://www.spoj.com/problems/PIHU1/>

## Problem

Given N integers and a target P, decide whether three distinct array positions have values summing to P. Print `YES` or `NO` for each test case.

Input starts with test count T. Each case gives N, then N values, then P. Output one word per case.

| item | bound |
|---|---|
| tests T | 1 to 15 |
| array size N | 3 to 1000 |
| each value | 1 to 1000000000 |
| target P | 1 to 3000000000 |
| judge limit | 100 ms, 1536 MB |

The three chosen positions must be distinct; equal values at different positions are allowed.

Sample input:

```
1
3
1 2 3
6
```

Sample output:

```
YES
```

## Idea

Sort the values, then squeeze a pair around each fixed first value, like closing two hands toward each other.

The real algorithm is sort plus a two-pointer scan, at O(N²) cost per case. Checking all triples costs O(N³) and misses the tight limit. Move the left pointer up for a small sum and the right pointer down for a large sum.

## Why It Works

1. Sorting puts smaller values to the left and larger values to the right.
2. Fixing the first position leaves a sorted suffix to search.
3. A low sum means only a larger right partner can help, so advance the left pointer.
4. A high sum means only a smaller right partner can help, so retreat the right pointer.
5. Every pair of positions is visited at most once per first position.
6. Finding an exact sum proves a valid triple exists.
7. Exhausting all first positions proves none exists.

| term | meaning |
|---|---|
| `values` | sorted array for one case |
| `targetSum` | value P, held in int64 |
| `firstIndex` | fixed first position |
| `leftIndex` | lower end of the search window |
| `rightIndex` | upper end of the search window |

A script checked the sample: sorted values are `1 2 3`, and `1 + 2 + 3 = 6`, so the answer is `YES`.

Sums reach `3 * 10^9`, above a signed 32-bit range, so every addition uses `int64`.

## Code

**Input and scanning.** One string holds every test case, and the scanner ignores line breaks.

```nim
import algorithm

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

Nim's sort needs an explicit comparator in this compiler version.
The scanner reads values regardless of their line layout.

**Buffered output.** Answers accumulate in one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0
```

The buffer flushes by block, not by line.
The comparator orders values from low to high.

**Two-pointer scan.** Each first position starts a fresh shrinking window.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let arraySize = nextInt(inputData, scanPos)
  var values = newSeq[int](arraySize)
  var valueIndex = 0
  while valueIndex < arraySize:
    values[valueIndex] = nextInt(inputData, scanPos)
    valueIndex += 1
  let targetSum = int64(nextInt(inputData, scanPos))
  values.sort(ascending)
  var foundTriple = false
  var firstIndex = 0
  while firstIndex < arraySize - 2 and not foundTriple:
    var leftIndex = firstIndex + 1
    var rightIndex = arraySize - 1
    while leftIndex < rightIndex and not foundTriple:
      let threeSum = int64(values[firstIndex]) + int64(values[leftIndex]) + int64(values[rightIndex])
      if threeSum == targetSum:
        foundTriple = true
      elif threeSum < targetSum:
        leftIndex += 1
      else:
        rightIndex -= 1
    firstIndex += 1
  if foundTriple:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Distinct positions are enforced by the pointer bounds.
The scan stops at the first matching triple.
The final write emits all answers together.

## Complexity

Sorting and the pointer scan dominate each case.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| sort | O(N log N) per case | array of N values |
| two-pointer scan | O(N²) per case | constant |
| output | one word per case | block buffer |

| measure | Big O |
|---|---|
| time | O(T · N²) |
| space | O(N) per case |

Trying every triple would cost O(T · N³) time.

Sort once, squeeze the pair, and emit one word per case.
