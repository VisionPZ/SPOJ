# SCALE — Funny scales (SPOJ)

<https://www.spoj.com/problems/SCALE/>

## Problem

A set of weights has masses 1, 3, 9, and so on up to 3^(N-1). One scale already holds an object of mass X. Choose which weights go on each scale so both sides balance.

Input has exactly one line with two integers, N and X. If balancing is impossible, print -1. Otherwise print two lines: the indices of weights placed on the first scale, then the indices on the second scale. A line may be empty. Indices start at 1.

| item | bound |
|---|---|
| weight count N | 1 to 20 |
| object mass X | 1 to 2000000000 |
| judge limit | 1000 ms, 1536 MB |

The mass bound makes an int64 necessary, since the largest usable total is about 1.74 billion.

Sample input:

```
10 2
```

Sample output:

```
1
2
```

## Idea

Read the mass as a balanced ternary number, like writing an amount with coins that can be added or subtracted. Each weight has three choices: left scale, right scale, or unused. The method walks powers of three from largest to smallest and fixes one digit at a time. Trying all placements costs three to the N choices, while the digit walk costs N steps. Takeaway: one greedy digit decision per weight settles the whole placement.

## Why It Works

1. A weight on the object's scale reduces the imbalance by its mass; a weight on the other scale increases it.
2. The digit at power p can only be -1, 0, or 1, matching those three choices.
3. Powers above p sum to less than p, so if the imbalance exceeds half of p, the digit must be 1.
4. Subtracting p at that step keeps the remaining imbalance inside the range that lower powers can fix.
5. After the last power, a zero imbalance means a valid placement exists; any other value means none exists.

| term | meaning |
|---|---|
| `weightCount` | number of weights available |
| `imbalance` | mass still to cancel between the scales |
| `currentPower` | mass of the weight being considered |
| `halfPower` | half of that mass, the digit threshold |
| `firstWeights` | indices of weights put on the object's scale |

The generator uses an exhaustive subset search for small N, so the digit walk is checked against every reachable imbalance.

## Code

**Input and scanning.** One line is read, then both values are parsed by hand.

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

All stdin lines enter one buffer once.
The scanner ignores separators between the two numbers.
No formatted input routine is used.

**Digit decisions and output.** Powers are visited from large to small and each digit is chosen once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let weightCount = nextInt(inputData, scanPos)
var imbalance = int64(nextInt(inputData, scanPos))
var currentPower = int64(1)
for ignoredIndex in 1 .. weightCount - 1:
  currentPower = currentPower * 3

var firstWeights = newSeq[int](0)
var secondWeights = newSeq[int](0)
for weightIndex in 0 .. weightCount - 1:
  let halfPower = currentPower div 2
  if imbalance > halfPower:
    imbalance -= currentPower
    secondWeights.add(weightCount - weightIndex)
  elif imbalance < -halfPower:
    imbalance += currentPower
    firstWeights.add(weightCount - weightIndex)
  currentPower = currentPower div 3

if imbalance != 0:
  appendOutput("-1")
  outputBuffer.add '\n'
else:
  var firstPosition = firstWeights.len - 1
  while firstPosition >= 0:
    appendOutput($firstWeights[firstPosition])
    if firstPosition > 0:
      appendOutput(" ")
    firstPosition -= 1
  outputBuffer.add '\n'
  var secondPosition = secondWeights.len - 1
  while secondPosition >= 0:
    appendOutput($secondWeights[secondPosition])
    if secondPosition > 0:
      appendOutput(" ")
    secondPosition -= 1
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The largest power is built before the digit loop.
Weights are collected in reverse order and printed in ascending index order.
A blank line is emitted when a side receives no weights.

## Complexity

Work grows only with the number of weights.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| power setup | N multiplications | constant |
| digit decisions | one step per weight | two short lists |
| output | one buffered write | block buffer |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) for the index lists |

Checking every subset would cost O(3^N), while the balanced ternary walk settles each weight in one step.
