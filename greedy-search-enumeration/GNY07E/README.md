# GNY07E — Flipping Burned Pancakes (SPOJ)

<https://www.spoj.com/problems/GNY07E/>

## Problem

Sort a stack of pancakes by size with the smallest on top and every burned side facing down. One move flips the top k pancakes as a group: it reverses their order and turns each burned side over. Any sequence of at most 3n-2 flips that sorts the stack is accepted.

Input starts with the dataset count. Each dataset line gives M, then the sizes 1 through M in any order, each signed plus for burned-down or minus for burned-up. Output one line per dataset: the dataset number, the flip count, and the flip sizes in order.

| item | bound |
|---|---|
| pancakes M | at most 30 |
| allowed flips | at most 3n-2 |
| datasets | statement gives no numeric cap |
| judge limit | 10900 ms, 1536 MB |

The flip bound drives the choice of a greedy sort from the largest pancake down.

Sample input:

```
3
3 +1 –3 –2
4 –3 +1 –2 –4
5 +1 +2 +3 +4 -5
```

Sample output:

```
1 6 2 1 3 1 2 1
2 6 4 1 4 3 1 2
3 3 5 1 5
```

## Idea

Picture placing one pancake at a time onto a finished pile at the bottom. Bring the largest unsorted pancake to the top, turn it burned-side up, then flip the whole active stack so it lands at the bottom burned-side down. Repeat for smaller sizes. A pancake needs at most three flips, and the final one costs one more, so the count stays within the bound. Searching all flip orders would be exponential, while this greedy pass is linear in the stack size.

## Why It Works

1. A plus sign means burned side down, which is the final orientation.
2. Flipping the top k reverses their order and inverts every sign.
3. A pancake at the top with burned side up lands burned-side down after a full flip.
4. Processing sizes from largest down fixes one final position each step.
5. Each step uses at most three flips, and the last pancake may need one extra flip.

| term | meaning |
|---|---|
| `activeSize` | number of pancakes still unsorted at the top |
| `targetSize` | size being placed into its final position |
| `burnedUp` | true when the target shows a minus sign |
| `flips` | recorded flip counts in execution order |

The bound holds because at most three flips are used per size.

A script trace for the first dataset gives:

```
start      +1 -3 -2
flip 2     +3 -1 -2
flip 1     -3 -1 -2
flip 3     +2 +1 +3
flip 1     -2 +1 +3
flip 2     -1 +2 +3
flip 1     +1 +2 +3
out        1 6 2 1 3 1 2 1
```

The final stack is sorted and burned-side down, matching the sample line.

## Code

**Input helpers.** The signed scanner accepts ASCII minus and the sample's en dash.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and int(data[pos]) != 226 and
        (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and (data[pos] == '-' or int(data[pos]) == 226):
    negative = true
    if int(data[pos]) == 226:
      pos += 3
    else:
      pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextSignedInt` reads both `+1` and signed negatives.
`appendOutput` flushes whole blocks instead of one line at a time.
The final flush ends the stream.

**Flip operation.** A flip negates the top signs and swaps their positions.

```nim
proc flipStack(stack: var seq[int], flipCount: int) =
  for topIndex in 0 .. flipCount - 1:
    stack[topIndex] = -stack[topIndex]
  var leftIndex = 0
  var rightIndex = flipCount - 1
  while leftIndex < rightIndex:
    swap stack[leftIndex], stack[rightIndex]
    leftIndex += 1
    rightIndex -= 1
```

Sign inversion and reversal happen in one pass.
No copy of the stack is allocated.
The cost is proportional to the flip size.

**Greedy sort.** Each target reaches the bottom of the active stack.

```nim
let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pancakeCount = nextSignedInt(inputData, scanPos)
  var stack = newSeq[int](pancakeCount)
  for pancakeIndex in 0 .. pancakeCount - 1:
    stack[pancakeIndex] = nextSignedInt(inputData, scanPos)
  var flips = newSeq[int](0)
  var activeSize = pancakeCount
  var targetSize = pancakeCount
  while targetSize >= 1:
    var position = -1
    for pancakeIndex in 0 .. activeSize - 1:
      if stack[pancakeIndex] == targetSize or stack[pancakeIndex] == -targetSize:
        position = pancakeIndex
        break
    if position == -1:
      targetSize -= 1
      continue
    let burnedUp = stack[position] < 0
    if position == activeSize - 1 and not burnedUp:
      activeSize -= 1
      targetSize -= 1
      continue
    if position != 0:
      flipStack(stack, position + 1)
      flips.add position + 1
    if stack[0] > 0:
      flipStack(stack, 1)
      flips.add 1
    flipStack(stack, activeSize)
    flips.add activeSize
    activeSize -= 1
    targetSize -= 1
  if stack[0] < 0:
    flipStack(stack, 1)
    flips.add 1
```

A target already at the bottom with burned side down is skipped.
Otherwise it moves to the top, turns burned-side up, then moves down.
The active stack shrinks after each fixed pancake.

**Output.** The flip list is assembled once per dataset.

```nim
  var line = $caseIndex & " " & $flips.len
  for flipCount in flips:
    line = line & " " & $flipCount
  line.add '\n'
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count precedes the flip sizes.
Each dataset contributes one line.
The buffer is flushed once at the end.

## Complexity

Each pancake is located once and flipped at most three times.

| phase | time | space |
|---|---|---|
| input read | one pass over signed sizes | one input string |
| greedy sort | one location scan per pancake | stack and flip list |
| output | one line per dataset | block buffer |

The size bound of 30 keeps every scan short.

| measure | Big O |
|---|---|
| time | O(M) per dataset |
| space | O(M) |

Searching the flip tree would be exponential; the largest-first rule fixes one pancake per step.
