# RAHIA — Riyad And His Increasing Array (SPOJ)

<https://www.spoj.com/problems/RAHIA/>

## Problem

Decide whether an array can be made strictly increasing by repeatedly decreasing positive entries. Print YES when it can and NO otherwise.

The first line gives the element count. The next line holds the array values, each between 1 and 10^9. A decrease may be applied any number of times, but an entry can never go below zero.

| item | bound |
|---|---|
| element count | 1 to 100000 |
| each value | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

Entries may be left unchanged, so only decreases are available.

Sample input:

```
7
5 2 3 9 88 9 10
```

Sample output:

```
YES
```

## Idea

Think of filling N ordered slots with distinct whole numbers starting from zero. The smallest possible strictly increasing array is 0, 1, 2 and so on. Slot i therefore needs at least i, and every original value that meets this floor can be lowered to it.

The real algorithm checks each value against its zero-based index in one forward pass. Each element costs constant work. Trying every possible final value by brute force would be exponential. The takeaway is that the minimum increasing sequence gives a per-position floor.

## Why It Works

1. Decreasing an entry never raises it above its original value.
2. A strictly increasing array of non-negative integers has value at least i at index i.
3. If the original value at index i is below i, no sequence of decreases can reach that floor.
4. If every original value is at least its index, setting each value to its index works.
5. The resulting array is 0, 1, 2 and so on, which is strictly increasing.

| term | meaning |
|---|---|
| `elementCount` | number of array entries |
| `currentValue` | value read at the current index |
| `elementIndex` | zero-based position of the current entry |
| `possible` | false once any value falls below its index |

For the sample, the values at indices two and six are 3 and 10. Both meet their floors, so setting the array to 0 through 6 is valid and the answer is YES.

The lowest allowed final value is zero, which makes the floor exact.

## Code

**Input and scanner.** The hand reader loads the count and every array value.

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

Whitespace between values is skipped.
Each value advances the scan position.
Buffered output writes one decision line.

**Floor check.** Each entry is compared with its zero-based position.

```nim
let elementCount = nextInt(inputData, scanPos)
var possible = true
for elementIndex in 0 .. elementCount - 1:
  let currentValue = int64(nextInt(inputData, scanPos))
  if currentValue < int64(elementIndex):
    possible = false
if possible:
  appendOutput("YES")
else:
  appendOutput("NO")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The comparison uses int64 for large values.
One violation is enough to reject the array.
The scan still consumes the remaining input values.
The final write flushes the answer.

## Complexity

The program reads the array once and checks one condition per element.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| floor check | constant work per element | constant extra space |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(1) beyond input and output |

Exploring all reachable arrays would take exponential time.
The index floor reduces the decision to one linear pass.
