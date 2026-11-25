<https://www.spoj.com/problems/AGPC01F/>

## Problem

An array of n values and q queries are given. Each query supplies a position b, and the answer is the smallest value among the first b array entries. Positions are counted from one.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| array size n | 1 to 100000 |
| query count q | 1 to 100000 |
| array values | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Blank lines may separate test cases, so parsing must depend only on whitespace.

Sample input:

```
1
4 2
2 2 3 1
3 4
```

Sample output:

```
2
1
```

## Idea

Keep a running minimum, like noting the lowest price seen while walking down a street. Store that minimum after every array position. A query then reads one slot and answers at once.

## Why It Works

1. The running minimum after position i equals the minimum of entries one through i.
2. Query value b maps directly to stored slot b minus one.
3. One prefix array serves every query in constant time.
4. Integer tokens are read by index, so blank lines never shift values.

| term | meaning |
|---|---|
| `prefixMinimum` | minimum of the first i entries, stored at slot i minus one |
| `runningMinimum` | smallest value seen while scanning left to right |
| `rangeEnd` | query value b |
| `flushBlockBytes` | output block size of 128 KiB |

One linear scan prepares all answers before any query is read.

## Code

**Input and prefix construction.** The scanner and one scan build the prefix array.

```nim
const flushBlockBytes = 1 shl 17
const initialSentinel = 1000000000

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

The sentinel exceeds every allowed array value.
The scan updates the minimum before storing it.
Reading tokens by index handles empty lines.

**Query answering and output.** Each query indexes the prepared array.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var prefixMinimum = newSeq[int](elementCount)
  var runningMinimum = initialSentinel
  for elementIndex in 0 .. elementCount - 1:
    let currentValue = nextInt(inputData, scanPos)
    if currentValue < runningMinimum:
      runningMinimum = currentValue
    prefixMinimum[elementIndex] = runningMinimum
  for queryIndex in 0 .. queryCount - 1:
    let rangeEnd = nextInt(inputData, scanPos)
    appendOutput($prefixMinimum[rangeEnd - 1])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

rangeEnd minus one converts a position into a slot.
No second scan of the array is ever needed.
The buffer flushes after reaching 128 KiB.

## Complexity

The prefix scan and the output loop are separate passes.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| prefix scan | one pass over n values | array of n integers |
| output | one write per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(n + q) per test case |
| space | O(n) for the prefix array |

Rescanning the prefix for each query would cost O(nq) instead of O(q).

