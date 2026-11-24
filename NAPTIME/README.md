## Problem

Each case gives N periods in a circle and a bed budget B. Every period has a utility. Choose exactly B periods to maximize the total utility, and print that total for each case.

A stay in bed pays no utility for its first period. A stay that runs from period N into period 1 pays period 1's utility.

| Quantity | Bound |
| --- | --- |
| Periods per case | 3 to 3830 |
| Periods in bed | 2 to N − 1 |
| Utility per period | 0 to 200000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The two size bounds set the work for each case.

## Idea

Dynamic programming over periods and the bed budget finds the best choice. A state records whether the previous period is in bed, because that fact decides whether the current period pays utility. Two runs cover the circle. One run pays no utility for period 1. The other run pays that utility and ends with period N in bed. The larger answer wins.

Each state takes constant work. The two runs visit about 2 × N × B states per case.

## Why It Works

Utility at period i arrives only when both i − 1 and i are in bed. Utility at period 1 arrives only when both N and 1 are in bed. The plain run leaves period 1 unpaid, so it covers every choice that earns no wrap utility. The wrapped run adds period 1's utility at the start and ends with period N in bed, which makes the wrap real. Every valid choice belongs to one of the two runs.

The update has three parts:

- `bestOutside` takes the larger previous value, since staying out pays nothing.
- `bestInside` compares falling asleep from outside, which adds nothing, with staying asleep from inside, which adds `utilities[i]`.
- `previousTop` caps the bed count at the number of periods already seen.

The script prints the winning sample choice period by period:

```
period 4: utility 1, gain 0
period 5: utility 4, gain 4
period 1: utility 2, gain 2
total 6
```

Period 4 is the falling-asleep period, so its gain is zero.

## Code

The program reads all input into one buffer. The scanner walks it once and builds integers from digits.

```nim
{.push optimization: speed.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const impossibleValue = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scan stops at the end of the buffer. No token objects are built. The cost is one pass over the input bytes.

One output buffer collects answers and writes them in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush happens every `flushBlockBytes` bytes. No write occurs inside the case loop. The cost is one pass over the answer text.

The DP keeps two rows for each run and swaps them after every period.

```nim
proc solveRun(utilities: seq[int], periodCount: int, bedCount: int,
              wrapFirst: bool): int =
  var prevOutside = newSeq[int](bedCount + 1)
  var prevInside = newSeq[int](bedCount + 1)
  var nextOutside = newSeq[int](bedCount + 1)
  var nextInside = newSeq[int](bedCount + 1)
  for j in 0..bedCount:
    prevOutside[j] = impossibleValue
    prevInside[j] = impossibleValue
  if wrapFirst:
    prevInside[1] = utilities[1]
  else:
    prevOutside[0] = 0
    prevInside[1] = 0
  for i in 2..periodCount:
    let previousTop = if i - 1 < bedCount: i - 1 else: bedCount
    for j in 0..previousTop:
      var bestOutside = impossibleValue
      var bestInside = impossibleValue
      let outsideValue = prevOutside[j]
      let insideValue = prevInside[j]
      if outsideValue >= 0:
        bestOutside = outsideValue
        bestInside = outsideValue
      if insideValue >= 0:
        if insideValue > bestOutside:
          bestOutside = insideValue
        let stayValue = insideValue + utilities[i]
        if stayValue > bestInside:
          bestInside = stayValue
      nextOutside[j] = bestOutside
      if j < bedCount:
        nextInside[j + 1] = bestInside
    if previousTop < bedCount:
      nextOutside[previousTop + 1] = impossibleValue
    nextInside[0] = impossibleValue
    swap(prevOutside, nextOutside)
    swap(prevInside, nextInside)
  if wrapFirst:
    return prevInside[bedCount]
  let outsideAnswer = prevOutside[bedCount]
  let insideAnswer = prevInside[bedCount]
  return if outsideAnswer > insideAnswer: outsideAnswer else: insideAnswer
```

The outer loop runs from period 2 to `periodCount`. The inner loop stops at `previousTop`, the largest reachable bed count. The skipped write at `j = bedCount` keeps counts inside the budget. One run updates about N × B states.

The driver reads each case and calls both runs.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let periodCount = nextInt(inputData, scanPos)
  let bedCount = nextInt(inputData, scanPos)
  var utilities = newSeq[int](periodCount + 1)
  for i in 1..periodCount:
    utilities[i] = nextInt(inputData, scanPos)
  let plainAnswer = solveRun(utilities, periodCount, bedCount, false)
  let wrappedAnswer = solveRun(utilities, periodCount, bedCount, true)
  let bestAnswer = if plainAnswer > wrappedAnswer: plainAnswer else: wrappedAnswer
  appendOutput($(bestAnswer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The utility loop reads exactly `periodCount` values. Both runs are called once per case. The final flush writes the remaining buffer bytes.

## Complexity

Input reading scans each token once. The DP keeps four rows of length `bedCount + 1` and swaps them each period. Output appends one line per case.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(total tokens) | O(input size) |
| DP per case | O(N × B) | O(B) |
| Output | O(cases) | O(block size) |

The DP dominates, and each case costs O(N × B) time with O(B) extra space. Trying every set of B periods would take exponential time.
