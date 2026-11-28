# MDOLLS — Nested Dolls (SPOJ)

<https://www.spoj.com/problems/MDOLLS/>

## Problem

A doll fits inside another when both its width and its height are strictly smaller. Group a list of dolls into the fewest nested chains possible.

The input starts with the number of test cases. Each case starts with the doll count, followed by the width and height of every doll. The output holds one minimum chain count per case.

| item | bound |
|---|---|
| test cases `t` | 1 to 20 |
| dolls per case `m` | 1 to 20000 |
| width and height | 1 to 10000 |
| judge limit | 1000 ms, 1536 MB |

The doll count drives the design, since cases can hold twenty thousand dolls.

Sample input:

```
4
3
20 30 40 50 30 40
4
20 30 10 10 30 20 40 50
3
10 30 20 20 30 10
4
10 10 20 30 40 50 39 51
```

Sample output:

```
1
2
3
2
```

## Idea

Sort the dolls into a line, then stack them like plates in as few piles as possible. The trick is Dilworth's theorem: the fewest nested chains equals the largest set of mutually non-fitting dolls.

Sort by width ascending, then by height descending for equal widths. Greedy patience sorting places each height on the pile with the largest top below it. A Fenwick tree finds that pile in logarithmic time.

Counting sorts replace comparisons, since both dimensions stay below 10001.

## Why It Works

1. Two dolls fit exactly when both dimensions are strictly smaller.
2. Sorting by width ascending and height descending makes every chain appear in increasing height order.
3. Partitioning the height sequence into increasing subsequences gives nested chains.
4. Greedy placement on the largest smaller top keeps pile tops as large as possible.
5. By Dilworth's theorem, the pile count equals the largest antichain, which is minimal.

| term | meaning |
|---|---|
| `sortedOrder` | doll indices in width-ascending, height-descending order |
| `pileTops` | Fenwick tree of current pile-top heights |
| `smallerTops` | number of pile tops below the current height |
| `pileCount` | number of chains opened so far |

The term table names the values that drive the greedy placement.

A worked example from the generator uses the second sample case:

```
sorted heights: 10 30 20 50
tops after 10:  10          piles 1
tops after 30:  30          piles 1
tops after 20:  20 30       piles 2
tops after 50:  20 50       piles 2
```

Height 20 opens a second pile, so the answer is two nested dolls.

## Code

**Input and scanning.** One read pass loads the whole input, and the scanner skips separators.

```nim
const flushBlockBytes = 1 shl 17
const maxDimension = 10000

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

All values in this problem are non-negative.
Each call advances the scan position past one number.
The input string stays in memory, so parsing does no stream reads.

**Buffered output and Fenwick helpers.** Pile tops live in a Fenwick tree indexed by height.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc bitPrefix(bit: seq[int], index: int): int =
  var position = index
  result = 0
  while position > 0:
    result = result + bit[position]
    position = position - (position and -position)

proc bitAdd(bit: var seq[int], index: int, delta: int) =
  var position = index
  while position <= maxDimension:
    bit[position] = bit[position] + delta
    position = position + (position and -position)

proc bitFindByOrder(bit: seq[int], order: int): int =
  var position = 0
  var stepSize = 1
  while stepSize shl 1 <= maxDimension:
    stepSize = stepSize shl 1
  var remaining = order
  while stepSize > 0:
    let nextPosition = position + stepSize
    if nextPosition <= maxDimension and bit[nextPosition] < remaining:
      position = nextPosition
      remaining = remaining - bit[nextPosition]
    stepSize = stepSize shr 1
  return position + 1
```

Prefix sums count pile tops below a height.
Binary lifting locates the largest occupied height with that prefix count.
The output buffer flushes in blocks, not per case.

**Counting sorts.** Two stable counting sorts produce the required doll order.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let dollCount = nextInt(inputData, scanPos)
  var widths = newSeq[int](dollCount)
  var heights = newSeq[int](dollCount)
  var widthCount = newSeq[int](maxDimension + 1)
  var heightCount = newSeq[int](maxDimension + 1)
  var maxWidth = 0
  var maxHeight = 0
  for dollIndex in 0 .. dollCount - 1:
    let dollWidth = nextInt(inputData, scanPos)
    let dollHeight = nextInt(inputData, scanPos)
    widths[dollIndex] = dollWidth
    heights[dollIndex] = dollHeight
    widthCount[dollWidth] = widthCount[dollWidth] + 1
    heightCount[dollHeight] = heightCount[dollHeight] + 1
    if dollWidth > maxWidth:
      maxWidth = dollWidth
    if dollHeight > maxHeight:
      maxHeight = dollHeight
  var heightStart = newSeq[int](maxDimension + 2)
  var writePosition = 0
  for heightValue in countdown(maxHeight, 1):
    heightStart[heightValue] = writePosition
    writePosition = writePosition + heightCount[heightValue]
  var firstOrder = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    let dollHeight = heights[dollIndex]
    firstOrder[heightStart[dollHeight]] = dollIndex
    heightStart[dollHeight] = heightStart[dollHeight] + 1
  var widthStart = newSeq[int](maxDimension + 2)
  writePosition = 0
  for widthValue in 1 .. maxWidth:
    widthStart[widthValue] = writePosition
    writePosition = writePosition + widthCount[widthValue]
  var sortedOrder = newSeq[int](dollCount)
  for orderIndex in 0 .. dollCount - 1:
    let dollIndex = firstOrder[orderIndex]
    let dollWidth = widths[dollIndex]
    sortedOrder[widthStart[dollWidth]] = dollIndex
    widthStart[dollWidth] = widthStart[dollWidth] + 1
```

The height sort runs descending, then the width sort runs ascending.
Stable placement keeps equal dimensions in their original relative order.
Both sorts cost linear time because dimensions are small integers.

**Greedy chain count.** Each height either extends a pile or opens a new one.

```nim
  var pileTops = newSeq[int](maxDimension + 1)
  var pileCount = 0
  for orderIndex in 0 .. dollCount - 1:
    let dollIndex = sortedOrder[orderIndex]
    let dollHeight = heights[dollIndex]
    let smallerTops = bitPrefix(pileTops, dollHeight - 1)
    if smallerTops > 0:
      let oldHeight = bitFindByOrder(pileTops, smallerTops)
      bitAdd(pileTops, oldHeight, -1)
    else:
      pileCount = pileCount + 1
    bitAdd(pileTops, dollHeight, 1)
  appendOutput($pileCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal heights never extend each other, since the fit is strict.
Each replacement moves one pile top to a taller height.
The final pile count is written once per case.

## Complexity

Counting sorts and the Fenwick tree keep each case near linear time.

| phase | time | space |
|---|---|---|
| input read | one pass over 2m numbers | input string |
| counting sorts | O(m + 10000) per case | two index arrays |
| greedy chaining | O(m log 10000) per case | Fenwick tree |
| output | one block flush per 128 KiB | output buffer |

The phase table shows that no quadratic scan over dolls appears.

| measure | Big O |
|---|---|
| time | O(t * (m + 10000 + m log 10000)) |
| space | O(m + 10000) |

A direct maximum-antichain search explores subsets or pairs of dolls, while this method stays near linear and keeps the same answer.
