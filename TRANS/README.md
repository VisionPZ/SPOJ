# TRANS — Transformation (SPOJ)

<https://www.spoj.com/problems/TRANS/>

## Problem

The input gives a source sequence, a target sequence, and rules that replace one number with two or three. Find the fewest steps that turn the source into the target, or report that it is impossible.

Input: `t` cases. Each case gives `N M U V`.

Then come sequence `X` of length `N` and sequence `Y` of length `M`. The case ends with `U` two-output rules and `V - U` three-output rules.

Output: `-1` when no transformation exists, otherwise the fewest steps.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Source length `N` | 1 to 50 |
| Target length `M` | 1 to 50 |
| Symbol values | positive, at most 30 |
| Judge limit | 1076 ms, 1536 MB |

The target length caps every interval table at 50 by 50 cells.

The sample input and output:

```
1
3 10 2 3
2 3 1
2 1 1 2 2 1 2 1 2 1
3 1 2
3 3 3
3 1 3 2
```

```
6
```

## Idea

Fill a chart of target intervals from shortest to longest, reusing each shorter result. Each rewrite rule acts as a way to cover one stretch of the target.

The program uses interval dynamic programming in the style of CYK (a chart parser over substrings). It records the cheapest way for each symbol to produce each target interval.

A final pass stitches source symbols to consecutive target prefixes. The interval stage costs `O(V × M³)` and the stitching stage `O(N × M²)`.

Rewriting the source forward explores unboundedly long sentences. Working backward over fixed target intervals keeps every state finite.

Shortest intervals first means every piece fit uses costs already computed.

## Why It Works

Five facts prove the interval recurrence.

1. Each rewrite expands one symbol, so the target sentence is the leaf list of a derivation tree.
2. A two-output rule splits one interval into two consecutive intervals. A three-output rule splits it into a pair interval and a third interval.
3. Filling intervals by increasing length puts both child costs in the table before the parent is computed.
4. `deriveCost[a, low, high]` then holds the fewest rewrites turning symbol `a` into the target stretch from `low` to `high`.
5. The last pass combines source symbols with consecutive target prefixes. `unreachableCost` marks states with no derivation, so a final value at that sentinel means `-1`.

The flat tables used by the program:

| Term | Meaning |
| --- | --- |
| `areaSize` | `M × M`, one square of interval slots |
| `spanIndex` | flat slot for interval `[lowPos, highPos]` |
| `deriveCost` | best cost for a value over every interval |
| `pairCost` | best cost for an output pair over every interval |
| `previousMatch` | best cost for a source prefix over a target prefix |

Rule outputs are numbered once, so the same pair reuses one chart.

A script trace of the sample case:

```
source [2, 3, 1]
target [2, 1, 1, 2, 2, 1, 2, 1, 2, 1]
| symbol | target span | min steps |
| 2 | [0,0] = [2] | 0 |
| 1 | [1,1] = [1] | 0 |
| 3 | [1,4] = [1, 1, 2, 2] | 2 |
| 3 | [1,8] = [1, 1, 2, 2, 1, 2, 1, 2] | 6 |
answer 6
```

The source symbol 2 covers the first target cell, symbol 3 covers eight cells in six steps, and symbol 1 covers the last cell.

## Code

**Input and helpers.** One buffer holds the stream, and a digit scanner reads every integer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSymbolValue = 30
const unreachableCost = 1 shl 25

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All values are positive, so the scanner needs no sign branch.
`unreachableCost` is `1 shl 25`, large enough to dominate any real step count.
The output helper flushes at 256 KiB.

**Case data.** The driver reads both sequences and all rewrite rules.

```nim
let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0..<caseCount:
  let sourceLength = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  let twoRuleCount = nextInt(inputData, scanPos)
  let ruleCount = nextInt(inputData, scanPos)

  var sourceSeq = newSeq[int](sourceLength)
  for sourcePos in 0..<sourceLength:
    sourceSeq[sourcePos] = nextInt(inputData, scanPos)

  var targetSeq = newSeq[int](targetLength)
  for targetPos in 0..<targetLength:
    targetSeq[targetPos] = nextInt(inputData, scanPos)

  var ruleLeft = newSeq[int](ruleCount)
  var ruleFirstOut = newSeq[int](ruleCount)
  var ruleSecondOut = newSeq[int](ruleCount)
  var ruleThirdOut = newSeq[int](ruleCount)
  for rulePos in 0..<ruleCount:
    ruleLeft[rulePos] = nextInt(inputData, scanPos)
    ruleFirstOut[rulePos] = nextInt(inputData, scanPos)
    ruleSecondOut[rulePos] = nextInt(inputData, scanPos)
    if rulePos < twoRuleCount:
      ruleThirdOut[rulePos] = 0
    else:
      ruleThirdOut[rulePos] = nextInt(inputData, scanPos)
```

The first `twoRuleCount` rules get a zero third output.
Later rules read a fourth integer.
Keeping rules in parallel arrays avoids one object per rule.

**Value range and pair ids.** The program sizes flat tables from the largest symbol seen.

```nim
  var valueLimit = maxSymbolValue
  for sourcePos in 0..<sourceLength:
    valueLimit = max(valueLimit, sourceSeq[sourcePos])
  for targetPos in 0..<targetLength:
    valueLimit = max(valueLimit, targetSeq[targetPos])
  for rulePos in 0..<ruleCount:
    valueLimit = max(valueLimit, ruleLeft[rulePos])
    valueLimit = max(valueLimit, ruleFirstOut[rulePos])
    valueLimit = max(valueLimit, ruleSecondOut[rulePos])
    valueLimit = max(valueLimit, ruleThirdOut[rulePos])

  let areaSize = targetLength * targetLength
  let slotWidth = valueLimit + 1
  var pairSlot = newSeq[int](slotWidth * slotWidth)
  for slotPos in 0..<pairSlot.len:
    pairSlot[slotPos] = -1

  var pairFirst = newSeq[int](ruleCount)
  var pairSecond = newSeq[int](ruleCount)
  var rulePair = newSeq[int](ruleCount)
  var pairCount = 0
  for rulePos in 0..<ruleCount:
    let slotKey = ruleFirstOut[rulePos] * slotWidth + ruleSecondOut[rulePos]
    if pairSlot[slotKey] == -1:
      pairSlot[slotKey] = pairCount
      pairFirst[pairCount] = ruleFirstOut[rulePos]
      pairSecond[pairCount] = ruleSecondOut[rulePos]
      pairCount += 1
    rulePair[rulePos] = pairSlot[slotKey]

  var deriveCost = newSeq[int](slotWidth * areaSize)
  for costPos in 0..<deriveCost.len:
    deriveCost[costPos] = unreachableCost
  var pairCost = newSeq[int](pairCount * areaSize)
  for costPos in 0..<pairCost.len:
    pairCost[costPos] = unreachableCost
```

`valueLimit` covers symbols in the sequences and in the rules.
`pairSlot` maps an ordered output pair to one compact id.
Both cost tables start at `unreachableCost`.

**Interval chart.** Spans grow from length one up to the full target.

```nim
  for spanLength in 1..targetLength:
    for lowPos in 0..(targetLength - spanLength):
      let highPos = lowPos + spanLength - 1
      let spanIndex = lowPos * targetLength + highPos
      if spanLength == 1:
        for symbolValue in 1..valueLimit:
          if targetSeq[lowPos] == symbolValue:
            deriveCost[symbolValue * areaSize + spanIndex] = 0
      else:
        for pairPos in 0..<pairCount:
          let leftBase = pairFirst[pairPos] * areaSize
          let rightBase = pairSecond[pairPos] * areaSize
          let pairBase = pairPos * areaSize
          var bestCost = unreachableCost
          for splitPos in lowPos..<highPos:
            let leftCost = deriveCost[leftBase + lowPos * targetLength + splitPos]
            let rightCost = deriveCost[rightBase + (splitPos + 1) * targetLength + highPos]
            let candidate = leftCost + rightCost
            if candidate < bestCost:
              bestCost = candidate
          pairCost[pairBase + spanIndex] = bestCost

        for rulePos in 0..<ruleCount:
          let symbolBase = ruleLeft[rulePos] * areaSize
          let pairBase = rulePair[rulePos] * areaSize
          var bestCost = deriveCost[symbolBase + spanIndex]
          if ruleThirdOut[rulePos] == 0:
            let candidate = pairCost[pairBase + spanIndex] + 1
            if candidate < bestCost:
              bestCost = candidate
          else:
            let tailBase = ruleThirdOut[rulePos] * areaSize
            for splitPos in (lowPos + 1)..<highPos:
              let headCost = pairCost[pairBase + lowPos * targetLength + splitPos]
              let tailCost = deriveCost[tailBase + (splitPos + 1) * targetLength + highPos]
              let candidate = headCost + tailCost + 1
              if candidate < bestCost:
                bestCost = candidate
          deriveCost[symbolBase + spanIndex] = bestCost
```

A length-one span costs zero only when the target symbol matches.
Each longer span tries every split position.
Two-output rules add one step to the pair cost; three-output rules add one step to a pair plus tail cost.

**Source stitching and output.** The last pass walks source symbols against target prefixes.

```nim
  var previousMatch = newSeq[int](targetLength + 1)
  var currentMatch = newSeq[int](targetLength + 1)
  for matchPos in 0..targetLength:
    previousMatch[matchPos] = unreachableCost
  previousMatch[0] = 0

  for sourcePos in 1..sourceLength:
    for matchPos in 0..targetLength:
      currentMatch[matchPos] = unreachableCost
    let symbolBase = sourceSeq[sourcePos - 1] * areaSize
    for matchedCount in 1..targetLength:
      var bestCost = unreachableCost
      for splitPos in 0..<matchedCount:
        let headCost = previousMatch[splitPos]
        if headCost >= unreachableCost:
          continue
        let tailCost = deriveCost[symbolBase + splitPos * targetLength + matchedCount - 1]
        let candidate = headCost + tailCost
        if candidate < bestCost:
          bestCost = candidate
      currentMatch[matchedCount] = bestCost
    let swapBuffer = previousMatch
    previousMatch = currentMatch
    currentMatch = swapBuffer

  let answer = previousMatch[targetLength]
  if answer >= unreachableCost:
    appendOutput("-1")
  else:
    appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`previousMatch[0]` starts at zero and all other slots at the sentinel.
Each source symbol splits the target prefix into a head and a derived tail.
The final value at `targetLength` is the answer.

## Complexity

The interval chart dominates the cost for each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Pair numbering | O(V + valueLimit²) | O(valueLimit²) |
| Interval chart | O(V × M³) | O(valueLimit × M² + V × M²) |
| Source stitching | O(N × M²) | O(M) for two rows |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(V × M³ + N × M²) | O(valueLimit × M²) |

At `M = 50` the chart holds 2,500 interval slots per value.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(V × M³ + N × M²) per case |
| Space | O(valueLimit × M²) per case, plus buffers |

Forward rewriting has no bound on sentence length. Interval dynamic programming fixes the work to a polynomial in `M`.
