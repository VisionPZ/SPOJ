# NAPTIME — Naptime (SPOJ)
<https://www.spoj.com/problems/NAPTIME/>

## Problem

Goneril the cow wants as much sleep as her busy day allows. She may spend only B of the N periods in bed.

She chooses the periods herself. A stretch in bed pays no utility for its first period. A stretch crossing period N into period 1 pays period 1's utility. Find the largest total utility.

Input: the first integer is t, the number of cases. Each case gives N and B, then N utilities on separate lines. Output: one line per case with the maximum total utility.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases | t from the input |
| Periods N | 3 to 3830 |
| Bed periods B | 2 to N − 1 |
| Utility per period | 0 to 200000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The sample has five periods and three bed periods:

```
1
5 3
2
0
3
1
4
```

```
6
```

The answer of 6 comes from periods 4, 5, and 1 in that order.

## Idea

Try both ways around the circle and keep the better answer. Picture a string of beads laid flat, then taped into a loop.

The program uses dynamic programming (DP, a table of best answers for smaller subproblems). A state holds the period, the bed count used, and whether the previous period is in bed. Entering bed adds nothing; staying in bed adds that period's utility.

The plain run leaves period 1 unpaid. The wrapped run credits period 1 at the start and ends with period N in bed. Each run visits about N × B states, so both cost O(N × B). Listing every set of B periods costs C(N, B), which explodes near N = 3830.

Takeaway: two linear DP runs settle the circle for the price of one extra pass.

## Why It Works

Four facts prove the method.

1. A period pays utility only when the period before it is also in bed. The "inside" state captures exactly that condition.
2. Moving from outside to inside adds no utility. Moving from inside to inside adds `utilities[i]`.
3. When period 1 is outside, the plain run counts every paid period. It misses only choices where period 1 is in bed.
4. When period 1 is inside, it pays only if period N is inside. The wrapped run forces that condition and credits `utilities[1]` up front.

The two runs cover every valid choice, so the larger answer is the optimum.

These are the pieces of one DP state:

| Term | Meaning |
| --- | --- |
| `prevOutside[j]` | best utility so far with j bed periods, current period outside |
| `prevInside[j]` | best utility so far with j bed periods, current period inside |
| `utilities[i]` | utility earned by sleeping in period i |
| `previousTop` | largest bed count reachable after i − 1 periods |
| `impossibleValue` | marker for a state that cannot occur |

A script traces the winning sample choice around the circle:

```
period 4: utility 1, gain 0
period 5: utility 4, gain 4
period 1: utility 2, gain 2
total 6
```

Period 4 is the falling-asleep period, so it pays nothing. Period 1 follows period 5 across the wrap, so it pays in full.

## Code

**Input.** The whole stream goes into one buffer, and the scanner walks it by index.

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

The scanner stops at the buffer end and builds each integer from digits. No token objects are allocated. The cost is one pass over the input bytes.

**Output.** One buffer collects answers and writes them in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write happens inside the case loop. The cost is one pass over the answer text.

**DP run.** Two rows per state track the outside and inside cases.

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

The outer loop covers periods 2 through `periodCount`. The inner loop stops at `previousTop`, the largest reachable bed count. Skipping the write at `j = bedCount` keeps counts inside the budget. One run costs O(N × B) time and O(B) space.

**Driver.** Each case calls both runs and prints the winner.

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

The utility loop reads exactly `periodCount` values. Both runs execute once per case. The final write flushes the remaining bytes.

## Complexity

Input, DP, and output each add a pass.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| One DP run | O(N × B) | O(B) |
| Both runs | O(2 × N × B) | O(B) |
| Output | O(cases) | O(block size) |

The DP dominates, with O(N × B) time and O(B) extra space per case.

| Measure | Big O |
| --- | --- |
| Time per case | O(N × B) |
| Total time | O(sum of N × B over cases) |
| Working space | O(B) |

Listing all sets of B periods takes C(N, B) time, which is far larger than O(N × B).
