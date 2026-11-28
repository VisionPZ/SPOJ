# AR2015PF — Jumping Joey (SPOJ)

<https://www.spoj.com/problems/AR2015PF/>

## Problem

Joey crosses a line of lily pads from the left end to the right end. He visits pads in order and either jumps a gap of at most D or swims it. Pulling a rope shortens the gap ahead and may drag later pads, so Joey minimizes the number of swims.

The first line holds the test count. A case gives n and D, then n+2 pad positions and n+1 rope lengths. Blank lines may separate cases. Print `Case x: y` with the fewest swims.

| item | bound |
|---|---|
| test cases | up to 50 |
| pads n | up to 1000 |
| jump D and all values | up to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The number of pads drives the state search design.

Sample input:

```
5
1 10
0 10 20
10 10

1 10
0 11 20
11 10

1 10
0 11 20
11 9

1 5
0 10 20
20 20

1 5
0 10 20
20 12
```

Sample output:

```
Case 1: 0
Case 2: 0
Case 3: 1
Case 4: 1
Case 5: 2
```

## Idea

Think of each rope slack as spare string that can be handed leftward, like passing a slack extension cord to the previous socket. A jump spends enough spare string to shrink its gap to D. Swimming keeps every future gap unchanged.

At each pad Joey has two useful choices: swim, or pull exactly the shortfall and jump. Partial pulls never help because they consume slack without removing a swim. A memoized search over these choices finds the minimum swim count.

## Why It Works

1. A gap before any pull equals the rope length minus the rope slack.
2. Pulling c units shortens the current gap by c and consumes c units of slack to the right.
3. Slack is consumed from the nearest rope first, then the next one, and so on.
4. The right end is fixed, so a taut chain reaching it cannot move.
5. Swimming leaves all later gaps unchanged and costs one swim.
6. Pulling exactly the shortfall makes the gap equal D, which is a legal jump.

| term | meaning |
|---|---|
| `gaps` | current distance from each pad to the next |
| `slacks` | spare rope length beyond each current gap |
| `neededPull` | shortfall between a gap and the jump distance |
| `fewestSwims` | memoized minimum swim count from a state |

Both choices at a pad are exhaustive, so the minimum is exact.

A script-generated trace of the fifth sample case:

```
gaps: 10 10    slacks: 10 2    D: 5
pad 0: shortfall 5, spare slack 2, swim
pad 1: shortfall 5, spare slack 0, swim
swims: 2
```

The trace matches the expected answer for case 5.

## Code

**Input and scanner.** All input is read once, then integers are extracted by hand.

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

Blank lines and spaces are skipped by the scanner.
Digits are accumulated one at a time.
The scan position tracks the next token.

**Buffered output.** One string collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after a large block fills.
Individual answers cause no write.
A final write flushes the remaining text.

**Memoized choices.** The search tries swimming and jumping at each pad.

```nim
var currentPadCount = 0
var currentJumpDistance = 0
var memoKeys = newSeq[string](0)
var memoValues = newSeq[int](0)

proc stateKey(stepIndex: int, gaps: seq[int], slacks: seq[int]): string =
  result = $stepIndex
  for gapValue in gaps:
    result.add '|'
    result.add $gapValue
  for slackValue in slacks:
    result.add '|'
    result.add $slackValue

proc fewestSwims(stepIndex: int, gaps: seq[int], slacks: seq[int]): int =
  if stepIndex == currentPadCount + 1:
    return 0
  let key = stateKey(stepIndex, gaps, slacks)
  for memoIndex in 0 .. memoKeys.len - 1:
    if memoKeys[memoIndex] == key:
      return memoValues[memoIndex]
  var bestCost = 1 shl 29
  let neededPull = gaps[stepIndex] - currentJumpDistance
  if neededPull <= 0:
    bestCost = fewestSwims(stepIndex + 1, gaps, slacks)
  else:
    bestCost = 1 + fewestSwims(stepIndex + 1, gaps, slacks)
    var availablePull = 0
    if stepIndex < currentPadCount:
      for slackIndex in stepIndex + 1 .. currentPadCount:
        availablePull = availablePull + slacks[slackIndex]
    if neededPull <= availablePull:
      var nextGaps = gaps
      var nextSlacks = slacks
      nextGaps[stepIndex] = nextGaps[stepIndex] - neededPull
      var remainingPull = neededPull
      var slackIndex = stepIndex + 1
      while remainingPull > 0 and slackIndex <= currentPadCount:
        let usedSlack = min(remainingPull, nextSlacks[slackIndex])
        nextSlacks[slackIndex] = nextSlacks[slackIndex] - usedSlack
        nextGaps[slackIndex] = nextGaps[slackIndex] + usedSlack
        remainingPull = remainingPull - usedSlack
        slackIndex += 1
      let jumpCost = fewestSwims(stepIndex + 1, nextGaps, nextSlacks)
      if jumpCost < bestCost:
        bestCost = jumpCost
  memoKeys.add key
  memoValues.add bestCost
  return bestCost
```

A state stores the current gaps and slacks.
A key turns that state into a string for memo lookup.
Slack consumption walks ropes from left to right.

**Case driver.** Each case builds gaps and slacks, then runs the search.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let padCount = nextInt(inputData, scanPos)
  let jumpDistance = nextInt(inputData, scanPos)
  currentPadCount = padCount
  currentJumpDistance = jumpDistance
  var positions = newSeq[int](padCount + 2)
  for positionIndex in 0 .. padCount + 1:
    positions[positionIndex] = nextInt(inputData, scanPos)
  var gaps = newSeq[int](padCount + 1)
  var slacks = newSeq[int](padCount + 1)
  for gapIndex in 0 .. padCount:
    gaps[gapIndex] = positions[gapIndex + 1] - positions[gapIndex]
  for ropeIndex in 0 .. padCount:
    let ropeLength = nextInt(inputData, scanPos)
    slacks[ropeIndex] = ropeLength - gaps[ropeIndex]

  memoKeys = newSeq[string](0)
  memoValues = newSeq[int](0)
  let answer = fewestSwims(0, gaps, slacks)
  appendOutput("Case " & $caseIndex & ": " & $answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Positions become adjacent gaps on read.
Rope lengths become initial slack values.
The memo clears between cases.

## Complexity

Each state has at most two outgoing choices, and the memo stores each state once.

| phase | time | space |
|---|---|---|
| input read | one pass over positions and ropes | one input string |
| state search | two branches per reachable state | memo keys and values |
| output | one line per case | block buffer |

The reachable state count controls the search cost.

| measure | Big O |
|---|---|
| time | O(S n), S is the number of memoized states |
| space | O(S n) for state keys |

Trying every partial pull amount would multiply the branching factor by the total slack. Restricting pulls to the exact shortfall keeps the search small.
