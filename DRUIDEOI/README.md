<https://www.spoj.com/problems/DRUIDEOI/>

## Problem

People stand in a circle and each person has a height. For every person, report the closest taller person when walking left and the closest taller person when walking right, using one-based indices. Unknown neighbours are reported as -1.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| people N | 1 to 100000 |
| height | 1 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

Both walks wrap around the circle and stop after N minus one steps.

Sample input:

```
3
5
172 170 168 171 169
3
172 169 172
1
172
```

Sample output:

```
-1 -1
1 4
2 4
1 1
4 1
-1 -1
1 3
-1 -1
-1 -1
```

## Idea

Walking left is like asking who blocks the view first in a hallway of people with decreasing height. A monotonic stack keeps only people who could still be that first blocker. Duplicate heights never block each other, so equal heights are popped as well. The scan runs once per direction and each person enters and leaves the stack once.

## Why It Works

1. A taller person to the right blocks every shorter person standing between them.
2. Discarding a person of smaller or equal height never removes a valid nearest taller neighbour.
3. Scanning right to left keeps a stack of strictly decreasing heights.
4. The stack top after popping shorter or equal heights is the nearest taller neighbour on the right.
5. Repeating the scan on a doubled circle covers wrap-around with the same logic.

| term | meaning |
|---|---|
| `doubledHeights` | the height list written twice to expose wrap-around |
| `monotonicStack` | indices of still useful taller candidates |
| `rightTaller` | nearest taller person on the right |
| `leftTaller` | nearest taller person on the left |

The doubled list keeps every wrapped neighbour inside one linear scan.

## Code

**Input and scanning.** The hand reader loads every test case and its height list.

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

Token parsing ignores spaces and line breaks.
The position advances once per number.
All heights fit in a signed integer.

**Right scan.** The stack is built while walking backward through the doubled circle.

```nim
  let doubledLength = 2 * personCount
  var doubledHeights = newSeq[int](doubledLength)
  for placeIndex in 0 .. doubledLength - 1:
    doubledHeights[placeIndex] = heights[placeIndex mod personCount]

  var rightTaller = newSeq[int](personCount)
  var monotonicStack = newSeq[int](doubledLength)
  var stackSize = 0
  for placeIndex in countdown(doubledLength - 1, 0):
    while stackSize > 0 and doubledHeights[monotonicStack[stackSize - 1]] <= doubledHeights[placeIndex]:
      stackSize -= 1
    if placeIndex < personCount:
      if stackSize > 0:
        rightTaller[placeIndex] = monotonicStack[stackSize - 1] mod personCount
      else:
        rightTaller[placeIndex] = -1
    monotonicStack[stackSize] = placeIndex
    stackSize += 1
```

Equal heights are popped so ties never count as taller.
A wrapped index is reduced to its original one-based person later.
Each place is pushed once and popped at most once.

**Left scan and output.** A forward scan answers the left queries and buffered writes emit the lines.

```nim
  var leftTaller = newSeq[int](personCount)
  stackSize = 0
  for placeIndex in 0 .. doubledLength - 1:
    while stackSize > 0 and doubledHeights[monotonicStack[stackSize - 1]] <= doubledHeights[placeIndex]:
      stackSize -= 1
    if placeIndex >= personCount:
      let personIndex = placeIndex - personCount
      if stackSize > 0:
        leftTaller[personIndex] = monotonicStack[stackSize - 1] mod personCount
      else:
        leftTaller[personIndex] = -1
    monotonicStack[stackSize] = placeIndex
    stackSize += 1

  for personIndex in 0 .. personCount - 1:
    if leftTaller[personIndex] < 0:
      appendOutput("-1 ")
    else:
      appendOutput($(leftTaller[personIndex] + 1))
      appendOutput(" ")
    if rightTaller[personIndex] < 0:
      appendOutput("-1\n")
    else:
      appendOutput($(rightTaller[personIndex] + 1))
      appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Reading the second copy gives left neighbours through the wrap point.
An empty stack means no taller person exists within one full turn.
The buffer flushes only after many lines accumulate.

## Complexity

The doubled circle holds two copies of the height list.

| phase | time | space |
|---|---|---|
| input read | one pass over all heights | one input string |
| right scan | one pass over twice N places | one stack |
| left scan | one pass over twice N places | one stack |
| output | one pass over N lines | block buffer |

| measure | Big O |
|---|---|
| time | O(sum of N across cases) |
| space | O(N) |

A direct walk around the circle for each person would cost O(N squared) per case.
