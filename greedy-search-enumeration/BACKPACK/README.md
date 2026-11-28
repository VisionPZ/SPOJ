# BACKPACK — Dab of Backpack (SPOJ)

<https://www.spoj.com/problems/BACKPACK/>

## Problem

Choose goods for a backpack so total volume stays within capacity and the sum of volume times importance is largest. An attachment may be chosen only when its main good is also chosen.

Input: the first line gives the test count. Each test starts with capacity V-Max and good count N. Then N lines give volume, importance, and parent index, where parent zero marks a main good. Output: print the maximum value for each test on one line.

| item | bound |
|---|---|
| capacity V-Max | 1 to 32000 |
| goods N | 1 to 60 |
| volume | multiple of 10 below 10000 |
| importance | 1 to 5 |
| judge limit | 1000 ms, 1536 MB |

Every volume is a multiple of ten, so capacity shrinks by ten before the knapsack sweep.

The sample uses five goods and capacity 1000.

| sample input lines | sample output |
|---|---|
| 800 2 0 / 400 5 1 / 300 5 1 / 400 3 0 / 500 2 0 | 2200 |

The best choice takes the two mains valued 1200 and 1000.

## Idea

Bundle each main good with its attachments, then treat each bundle as one knapsack item. This is grouped knapsack, like choosing one complete meal combo per stall instead of separate dishes. A bundle with two attachments has four options, so each group costs a constant number of transitions. Plain 0/1 knapsack would wrongly allow buying an attachment without its main. Precompute each group's options once and sweep capacity once per group.

## Why It Works

1. Each attachment belongs to exactly one main good and has no attachments of its own.
2. Any legal selection picks at most one option from each main good's bundle.
3. An option records the volume and value of the main plus any chosen attachments.
4. A descending capacity sweep adds one option without reusing the same group.
5. The final cell holds the largest value within the full capacity.

| term | meaning |
|---|---|
| `goodVolumes` | volume divided by ten for each good |
| `goodValues` | volume times importance for each good |
| `parentIndexes` | owning main good index, or zero |
| `nextKnapsack` | values after adding the current bundle |
| `knapsack` | best value for each capacity before the bundle |

Separating the two knapsack rows stops two options of one bundle from combining.

A scripted trace lists the options of each bundle in the sample.

| bundle | volume units and values |
|---|---|
| main 1 with two attachments | (80, 1600), (120, 3600), (110, 3100), (150, 5100) |
| main 4 alone | (40, 1200) |
| main 5 alone | (50, 1000) |

Capacity 100 units fits only the last two bundles and yields 2200.

All values are integers, so rounding never enters the computation.

## Code

**Input and scanning.** The reader loads every test and converts volumes into ten-unit cells.

```nim
const flushBlockBytes = 1 shl 17
const volumeUnit = 10

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

The scanner skips line breaks between goods.
The value keeps the original volume times importance.
The buffer flushes after a large block of answer lines.

**Grouped knapsack.** Each main good contributes one option from its bundle.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let maxVolume = nextInt(inputData, scanPos)
  let goodCount = nextInt(inputData, scanPos)
  var goodVolumes = newSeq[int](goodCount)
  var goodValues = newSeq[int](goodCount)
  var parentIndexes = newSeq[int](goodCount)
  for goodIndex in 0 .. goodCount - 1:
    let rawVolume = nextInt(inputData, scanPos)
    let importance = nextInt(inputData, scanPos)
    goodVolumes[goodIndex] = rawVolume div volumeUnit
    goodValues[goodIndex] = rawVolume * importance
    parentIndexes[goodIndex] = nextInt(inputData, scanPos)
  let capacityUnits = maxVolume div volumeUnit
  var knapsack = newSeq[int](capacityUnits + 1)
  for goodIndex in 0 .. goodCount - 1:
    if parentIndexes[goodIndex] != 0:
      continue
    var attachmentIndexes = newSeq[int]()
    for otherIndex in 0 .. goodCount - 1:
      if parentIndexes[otherIndex] == goodIndex + 1:
        attachmentIndexes.add otherIndex
    let choiceCount = 1 shl attachmentIndexes.len
    var nextKnapsack = knapsack
    for choiceMask in 0 .. choiceCount - 1:
      var choiceVolume = goodVolumes[goodIndex]
      var choiceValue = goodValues[goodIndex]
      for attachmentSlot in 0 .. attachmentIndexes.len - 1:
        if (choiceMask and (1 shl attachmentSlot)) != 0:
          let attachmentIndex = attachmentIndexes[attachmentSlot]
          choiceVolume += goodVolumes[attachmentIndex]
          choiceValue += goodValues[attachmentIndex]
      if choiceVolume > capacityUnits:
        continue
      for capacityLeft in countdown(capacityUnits, choiceVolume):
        let candidate = knapsack[capacityLeft - choiceVolume] + choiceValue
        if candidate > nextKnapsack[capacityLeft]:
          nextKnapsack[capacityLeft] = candidate
    knapsack = nextKnapsack
  appendOutput($(knapsack[capacityUnits]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop skips goods that are attachments.
The mask loop covers all subsets of at most two attachments.
A fresh row stops one group from contributing twice.

## Complexity

Each test builds one bundle list and sweeps capacity once per main good.

| phase | time | space |
|---|---|---|
| input read | one pass over goods | three good arrays |
| bundle sweep | groups times choices times capacity | two knapsack rows |
| output | one block per answer | output buffer |

The capacity sweep dominates the runtime for each test.

| measure | Big O |
|---|---|
| time | O(G · C · K) per test |
| space | O(V / 10 + N) |

Naive subset enumeration checks every selection of all N goods, while grouping checks only legal bundles.
