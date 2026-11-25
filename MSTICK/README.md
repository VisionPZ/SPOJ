# MSTICK — Wooden Sticks (SPOJ)

<https://www.spoj.com/problems/MSTICK/>

## Problem

Feed sticks to a machine that needs one setup minute whenever the next stick is smaller or lighter than the previous one. Find the fewest setup minutes for the whole pile.

Input contract: the first line gives T, then each case has n followed by the 2n length and weight values of the sticks. Output contract: print one setup count per case.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | given on the first line |
| sticks per case n | 1 to 5000 |
| length and weight | positive, at most 10000 |
| judge limit | 1000 ms, 1536 MB |

One minute starts the first chain, and every extra chain adds another minute.

Sample input:

```
3
5
4 9 5 2 2 1 3 5 1 4
3
2 2 1 1 2 2
3
1 3 2 2 3 1
```

Sample output:

```
2
1
3
```

## Idea

Sort the sticks by size, then drop each stick onto the chain whose end fits it best, like stacking plates by decreasing diameter. The algorithm keeps the last weight of every open chain and extends the chain with the largest tail that is still no heavier than the stick. Each stick costs a binary search plus a constant update, so sorting dominates at O(n log n). Trying to extend chains in arbitrary order would open more chains than necessary. The chain count is the answer.

## Why It Works

1. A zero-setup step needs both dimensions to stay nondecreasing.
2. Sorting by length makes every later stick eligible by length, so only weight matters.
3. A chain is a nondecreasing run of weights in that sorted order.
4. Extending the heaviest feasible chain leaves the smaller tails free for lighter sticks.
5. The number of chains equals the minimum number of setup minutes.

The terms used in the greedy:

| term | meaning |
|---|---|
| `Stick` | one pair of length and weight values |
| `chainTails` | last weight of each open chain, kept sorted |
| `chainCount` | number of open chains |
| `currentWeight` | weight of the stick being placed |

Binary search finds the rightmost tail no larger than the current weight.

A traced placement of the first sample case:

```
sorted pairs: (1,4) (2,1) (3,5) (4,9) (5,2)
(1,4) -> chain 1 tails [4]
(2,1) -> new chain tails [1,4]
(3,5) -> chain 1 tails [1,5]
(4,9) -> chain 1 tails [1,9]
(5,2) -> chain 2 tails [2,9]
answer = 2 chains
```

The two chains match the two setup minutes in the sample output.

## Code

**Input and comparison.** The reader collects pairs and defines the sort order.

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

type Stick = object
  lengthValue: int
  weightValue: int

proc compareSticks(leftStick: Stick, rightStick: Stick): int =
  if leftStick.lengthValue < rightStick.lengthValue:
    return -1
  if leftStick.lengthValue > rightStick.lengthValue:
    return 1
  if leftStick.weightValue < rightStick.weightValue:
    return -1
  if leftStick.weightValue > rightStick.weightValue:
    return 1
  return 0
```

Equal lengths are ordered by weight, which keeps them chainable.
The comparator returns an ordering value, as the sort routine expects.
The token reader ignores spaces and line breaks equally.

**Chain assignment.** Tails stay sorted while each stick is placed.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stickCount = nextInt(inputData, scanPos)
  var sticks = newSeq[Stick](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    sticks[stickIndex].lengthValue = nextInt(inputData, scanPos)
    sticks[stickIndex].weightValue = nextInt(inputData, scanPos)
  sticks.sort(compareSticks)
  var chainTails = newSeq[int](stickCount)
  var chainCount = 0
  for stick in sticks:
    let currentWeight = stick.weightValue
    var low = 0
    var high = chainCount
    while low < high:
      let middle = (low + high) div 2
      if chainTails[middle] <= currentWeight:
        low = middle + 1
      else:
        high = middle
    if low == 0:
      var shiftIndex = chainCount
      while shiftIndex > 0:
        chainTails[shiftIndex] = chainTails[shiftIndex - 1]
        shiftIndex -= 1
      chainTails[0] = currentWeight
      chainCount += 1
    else:
      chainTails[low - 1] = currentWeight
  appendOutput($(chainCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A new chain opens only when no tail fits the stick.
Placing on the rightmost fitting tail keeps the tail list ordered.
Each case contributes one buffered line.

## Complexity

Sorting dominates the work per case.

| phase | time | space |
|---|---|---|
| input read | one pass over 2n values per case | stick array and input string |
| sorting | n log n comparisons | stick array |
| chain assignment | one binary search per stick | tail array |
| output | one line per case | block buffer |

The tail array holds at most n entries.

| measure | Big O |
|---|---|
| time | O(n log n) per case |
| space | O(n) |

Repeated linear scans over all chains would raise the cost to O(n squared) per case.
The sorted tails keep every placement logarithmic.
