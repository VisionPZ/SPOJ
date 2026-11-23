## Problem

Each data set gives an arithmetic expression and a target value. Operators `+` and `-` sit at odd positions, and digits from 0 to 9 sit at even positions. Add matching parentheses so the expression equals the target with the fewest pairs, or print `NO`. Print one line per data set.

The bounds fix the size of every table.

| item | bound |
|---|---|
| data sets | at most 10 |
| expression length `n` | even, 2 to 40 |
| digit count `m` | 1 to 20 |
| target `k` | -180 to 180 |
| judge limits | 5 s, 1536 MB |

A 40-character expression always fits the largest table.

## Idea

Parentheses change a value only when a minus sign stands before them. Such a group flips every later digit inside it, so a left-to-right scan tracks flips with the count of open groups. Listing every parenthesization grows past a billion trees at the largest size, while the scan visits one digit at a time.

Cost per digit: at most 21 group counts times 361 value slots, about 7 600 state updates.

## Why It Works

A group after `+` leaves all signs unchanged. A group after `-` flips every digit after its first digit. The first digit inside a group keeps its sign, because the minus outside replaces its own operator. Only one operator precedes a digit, so at most one group starts at each boundary. A digit is flipped exactly when the number of open groups is odd. Closing a group costs nothing, so any group count can drop to any smaller count. Starting a group needs a minus sign before the boundary and adds one pair.

The table index combines the group count and the running value.

The value index adds the offset of 180 to the running value.

`slot = depth * valueCount + valueIndex`

The offset of 180 maps every value from -180 to 180 onto a non-negative index.

The scan for +5-4+5 and target -4 reaches the answer in three digit steps.

| digit position | sign | digit | open groups | value | pairs |
|---|---|---|---|---|---|
| 1 | + | 5 | 0 | 5 | 0 |
| 2 | - | 4 | 0 | 1 | 0 |
| 3 | + | 5 | 1 | -4 | 1 |

The start at position 3 builds the expression +5-(4+5) with value -4 and one pair.

## Code

```
const maxTermCount = 20
const maxOpenGroups = 20
const valueOffset = 180
const valueCount = 361
const impossibleCost = 1 shl 28
const tableSize = (maxOpenGroups + 1) * valueCount
const flushBlockBytes = 1 shl 17
```

Seven constants bound the tables. The state space has (20 + 1) times 361 slots. The offset turns a negative value into an array index.

```
proc nextSignedInt(inputData: string, scanPos: var int): int =
  skipWhitespace(inputData, scanPos)
  var negative = false
  if scanPos < inputData.len and (inputData[scanPos] == '-' or inputData[scanPos] == '+'):
    negative = inputData[scanPos] == '-'
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  if negative: return -value
  return value

proc nextTokenBounds(inputData: string, scanPos: var int): tuple[first: int, count: int] =
  skipWhitespace(inputData, scanPos)
  let first = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos = scanPos + 1
  result.first = first
  result.count = scanPos - first```

The driver reads the whole stream once, and these procs walk that buffer. The sign branch keeps negative targets. Token bounds point into the same buffer without copying. Scanning costs one pass over the input characters.

```
proc solveCase(termCount: int, targetValue: int, expressionStart: int, inputData: string): int =
  var termOperators: array[0..maxTermCount - 1, char]
  var termDigits: array[0..maxTermCount - 1, int]
  for termIndex in 0 .. termCount - 1:
    termOperators[termIndex] = inputData[expressionStart + 2 * termIndex]
    termDigits[termIndex] = int(inputData[expressionStart + 2 * termIndex + 1]) - 48

  var currentCosts: array[0..tableSize - 1, int]
  var closedCosts: array[0..tableSize - 1, int]
  var openedCosts: array[0..tableSize - 1, int]
  var followingCosts: array[0..tableSize - 1, int]
  clearCosts(currentCosts)
  currentCosts[valueOffset] = 0

  for boundary in 0 .. termCount:
    for valueIndex in 0 .. valueCount - 1:
      var best = impossibleCost
      for depth in countdown(maxOpenGroups, 0):
        let slot = depth * valueCount + valueIndex
        if currentCosts[slot] < best: best = currentCosts[slot]
        closedCosts[slot] = best

    for slot in 0 .. tableSize - 1:
      openedCosts[slot] = closedCosts[slot]
    if boundary >= 1 and boundary <= termCount - 1 and termOperators[boundary - 1] == '-':
      for depth in 0 .. maxOpenGroups - 1:
        for valueIndex in 0 .. valueCount - 1:
          let source = closedCosts[depth * valueCount + valueIndex]
          if source >= impossibleCost: continue
          let destination = (depth + 1) * valueCount + valueIndex
          if source + 1 < openedCosts[destination]:
            openedCosts[destination] = source + 1

    if boundary == termCount:
      var answer = impossibleCost
      let wantedIndex = targetValue + valueOffset
      for depth in 0 .. maxOpenGroups:
        let slot = depth * valueCount + wantedIndex
        if openedCosts[slot] < answer: answer = openedCosts[slot]
      if answer >= impossibleCost: return -1
      return answer

    clearCosts(followingCosts)
    let operatorSign = if termOperators[boundary] == '+': 1 else: -1
    let digitValue = termDigits[boundary]
    for depth in 0 .. maxOpenGroups:
      let flipSign = if (depth and 1) == 1: -1 else: 1
      let delta = operatorSign * flipSign * digitValue
      for valueIndex in 0 .. valueCount - 1:
        let source = openedCosts[depth * valueCount + valueIndex]
        if source >= impossibleCost: continue
        let nextValue = valueIndex + delta
        if nextValue < 0 or nextValue >= valueCount: continue
        let destination = depth * valueCount + nextValue
        if source < followingCosts[destination]:
          followingCosts[destination] = source

    swap currentCosts, followingCosts

  return -1
```

The loops cover 21 boundaries, 21 group counts, and 361 values. The suffix minimum closes groups at no cost. The minus check gates the purchase of a new pair. Four tables keep the stages separate, so processing a digit needs no allocation.

```
var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
let caseCount = nextSignedInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  let termCount = nextSignedInt(inputData, scanPos) div 2
  let targetValue = nextSignedInt(inputData, scanPos)
  let expressionBounds = nextTokenBounds(inputData, scanPos)
  let answer = solveCase(termCount, targetValue, expressionBounds.first, inputData)
  if answer < 0:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add $answer
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The driver reads all input lines into one string. It flushes the output buffer in 128 KiB blocks. Output cost stays proportional to the number of answers.

## Complexity

Input costs one pass over at most 400 expression characters and ten targets. Each case updates about 159 000 states and clears four small tables. The program stores four tables of 7 581 integers, about 243 KB. Total time is O(d times m squared times V), with m at most 20 and V equal to 361. Listing every parenthesization costs Catalan(m - 1) parses, about 1.8 billion at m = 20.
