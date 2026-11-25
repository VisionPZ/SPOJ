# GCJ1C09C — Bribe the Prisoners (SPOJ)

<https://www.spoj.com/problems/GCJ1C09C/>

## Problem

Prisoners sit in a row of P cells. Releasing one prisoner empties that cell and forces every still-occupied cell out to the nearest empty cell or end of the row to be bribed. Choose the release order that minimises the total coins paid.

Input starts with N cases. Each case gives P and Q on one line, then Q distinct ascending cell numbers on the next line. Output `Case #X: C` per line, where X starts at one and C is the minimum coin count.

| item | bound |
|---|---|
| test cases N | 1 to 100 |
| cells P | 1 to 10000 |
| releases Q | 1 to 100 |
| judge limit | 20000 ms, 1536 MB |

Q drives the search size; P only sets the width of one interval.

The sample input:

```
2
8 1
3
20 3
3 6 14
```

The sample output:

```
Case #1: 7
Case #2: 35
```

## Idea

Releasing a prisoner splits its current block of occupied cells into two smaller blocks, like cutting a rope at a chosen point. Treat released cells and both row ends as fixed boundaries, then solve each interval between boundaries by trying every prisoner inside as the next cut. A bottom-up interval dynamic program fills all short intervals first and combines them for longer ones. Trying every release order would take factorial time. Each subproblem tries at most Q choices, so the whole case finishes in cubic time.

## Why It Works

1. Add two artificial boundaries at cells zero and P + 1, which are always empty.
2. Inside one interval, releasing cell x bribes every occupied cell between the two boundaries, which is rightEdge - leftEdge - 2 prisoners.
3. That release creates two independent intervals, one on each side of x.
4. The optimal cost for an interval is the minimum over x of the two subinterval costs plus the bribe paid now.
5. Filling intervals by increasing length makes both subinterval costs available before they are used.

| term | meaning |
|---|---|
| `boundaries` | released cells plus the two artificial ends |
| `bestCosts` | minimum bribe cost for each interval of release indices |
| `bribeCost` | coins paid for one release inside its current interval |
| `totalCost` | candidate cost for one chosen release |

The table names the values stored during the interval fill.

A script trace of the second sample case with release order 14, 6, 3:

```
release 14: edges 0 and 21 -> 21 - 0 - 2 = 19
release 6:  edges 0 and 14 -> 14 - 0 - 2 = 12
release 3:  edges 0 and 6  -> 6 - 0 - 2 = 4
total 19 + 12 + 4 = 35
```

The trace totals 35, which matches the second sample answer.

No rounding applies. The sentinel `impossibleCost` exceeds any real total, so an unfinished candidate never wins.

## Code

**Input and scanner.** The reader loads the whole input and parses case numbers by hand.

```nim
const flushBlockBytes = 1 shl 17
const maxReleaseCount = 100
const dpStride = maxReleaseCount + 2
const impossibleCost = 1000000000000

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

The stride keeps the triangular table in one flat sequence.
The sentinel sits far above the largest possible bribe total.
The scanner advances once per integer.

**Output helper.** One buffer holds every case answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after crossing `flushBlockBytes`.
A final flush writes the remaining lines.
No write happens per case.

**Interval fill.** Each interval tries every prisoner inside as the next release.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let cellCount = nextInt(inputData, scanPos)
  let releaseCount = nextInt(inputData, scanPos)
  var boundaries = newSeq[int](releaseCount + 2)
  boundaries[0] = 0
  for releaseIndex in 1 .. releaseCount:
    boundaries[releaseIndex] = nextInt(inputData, scanPos)
  boundaries[releaseCount + 1] = cellCount + 1
  var bestCosts = newSeq[int64](dpStride * dpStride)
  for spanLength in 1 .. releaseCount:
    for leftRelease in 1 .. releaseCount - spanLength + 1:
      let rightRelease = leftRelease + spanLength - 1
      let leftEdge = boundaries[leftRelease - 1]
      let rightEdge = boundaries[rightRelease + 1]
      var bestCost: int64 = impossibleCost
      for midRelease in leftRelease .. rightRelease:
        let leftCost = bestCosts[leftRelease * dpStride + midRelease - 1]
        let rightCost = bestCosts[(midRelease + 1) * dpStride + rightRelease]
        let bribeCost = int64(rightEdge - leftEdge - 2)
        let totalCost = leftCost + rightCost + bribeCost
        if totalCost < bestCost:
          bestCost = totalCost
      bestCosts[leftRelease * dpStride + rightRelease] = bestCost
  var answer: int64 = 0
  if releaseCount >= 1:
    answer = bestCosts[dpStride + releaseCount]
  appendOutput("Case #" & $caseNumber & ": " & $answer & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Empty intervals keep their initial zero cost.
Increasing span length guarantees both halves exist when needed.
The answer is the full interval from the first release to the last.

## Complexity

Each case fills one triangular table of intervals.

| phase | time | space |
|---|---|---|
| input read | one pass over Q release cells | one input string |
| interval fill | Q intervals per length, Q choices each | Q squared cost cells |
| output | one line per case | block buffer |

The interval fill dominates every other phase.

| measure | Big O |
|---|---|
| time | O(Q^3) per case |
| space | O(Q^2) |

Q never exceeds 100, so a case needs at most about one million candidate costs.

Trying every permutation of the release order costs Q factorial time. Dynamic programming reuses each interval result and finishes in cubic time instead.
