# EXPR1 — Expression (SPOJ)
<https://www.spoj.com/problems/EXPR1/>

## Problem

The input gives an arithmetic expression using `+`, `-`, and single digits, plus a target value k.
Decide whether adding parentheses can make the value equal k, and give the minimum number of pairs needed.

Read `d` data sets. Each gives expression length `n` and target `k`, then the expression string.
The string starts with an operator and alternates operator and digit.
Operators are `+` and `-`, and digits range from 0 to 9.

Add matching parentheses so the value equals `k`.
Print the smallest number of pairs, or `NO` when no placement works.

The judge bounds follow.

| item | bound |
| --- | --- |
| data sets | at most 10 |
| expression length `n` | even, 2 to 40 |
| target `k` | -180 to 180 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

A 40-character expression always fits the largest table.

The sample input and expected output follow verbatim.

```
5
6 -4
+5-4+5
2 1
+1
4 1
-1+1
4 0
-1+1
4 -2
-1+1
```

```
1
0
NO
0
1
```

The first expression needs one pair to reach -4.

## Idea

Parentheses matter only after a minus sign, like flipping the sign of every later term in a sum.
A group after `+` changes nothing.
A group after `-` flips every digit after its first inside that group.

Scan left to right with dynamic programming (a table of best costs for each state).
The state is the number of open groups and the running value.
Closing a group is free, so any group count can drop to a smaller one.
Opening a group costs one pair and needs a minus before the boundary.

Cost per digit is at most 21 group counts times 361 value slots.
Listing every parenthesization grows past a billion trees at the largest size.
Track flips with a group count instead of enumerating trees.

## Why It Works

Four facts prove the method.

1. A group after `+` leaves signs unchanged.
   A group after `-` flips every digit after its first inside the group.
2. The first digit inside a group keeps its sign, because the outside minus replaces its own operator.
3. A digit is flipped exactly when the number of open groups is odd.
4. Closing costs nothing, so a suffix minimum over open counts drops to any smaller count for free.

The table index and its parts follow.

| Term | Meaning |
| --- | --- |
| `l` | number of open groups at the current boundary |
| `k` | running value shifted by the offset |
| `valueOffset` | 180, which maps -180 to 180 onto non-negative indices |
| `i = l * valueCount + k` | index into the flat cost table |

The offset keeps every value index non-negative.

A script traces the first sample expression `+5-4+5` with target -4.

| Digit position | Sign | Digit | Open groups | Value | Pairs |
| --- | --- | --- | --- | --- | --- |
| 1 | + | 5 | 0 | 5 | 0 |
| 2 | - | 4 | 0 | 1 | 0 |
| 3 | + | 5 | 1 | -4 | 1 |

The expression becomes +5-(4+5) with value -4 and one pair.

## Code

**Constants.**

```nim
const maxTermCount = 20
const maxOpenGroups = 20
const valueOffset = 180
const valueCount = 361
const impossibleCost = 1 shl 28
const tableSize = (maxOpenGroups + 1) * valueCount
const flushBlockBytes = 1 shl 17
```

The tables hold 21 open group counts and 361 values. valueOffset shifts negative values into array indices. The output block holds 128 KiB.

**Scanners and table clear.**

```nim
proc skipWhitespace(inputData: string, i: var int) =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1

proc nextSignedInt(inputData: string, i: var int): int =
  skipWhitespace(inputData, i)
  var negative = false
  if i < inputData.len and (inputData[i] == '-' or inputData[i] == '+'):
    negative = inputData[i] == '-'
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  if negative: return -value
  return value

proc nextTokenBounds(inputData: string, i: var int): tuple[first: int, count: int] =
  skipWhitespace(inputData, i)
  let first = i
  while i < inputData.len and inputData[i] > ' ':
    i = i + 1
  result.first = first
  result.count = i - first

proc clearCosts(costs: var array[0..tableSize - 1, int]) =
  for i in 0 .. tableSize - 1:
    costs[i] = impossibleCost
```

nextSignedInt keeps a leading minus on the target. nextTokenBounds records a span without copying the expression. clearCosts fills a table with the impossible cost. Each helper costs one pass over its input span.

**Dynamic program.**

```nim
proc solveCase(termCount: int, targetValue: int, expressionStart: int, inputData: string): int =
  var termOperators: array[0..maxTermCount - 1, char]
  var termDigits: array[0..maxTermCount - 1, int]
  for i in 0 .. termCount - 1:
    termOperators[i] = inputData[expressionStart + 2 * i]
    termDigits[i] = int(inputData[expressionStart + 2 * i + 1]) - 48

  var currentCosts: array[0..tableSize - 1, int]
  var closedCosts: array[0..tableSize - 1, int]
  var openedCosts: array[0..tableSize - 1, int]
  var followingCosts: array[0..tableSize - 1, int]
  clearCosts(currentCosts)
  currentCosts[valueOffset] = 0

  for j in 0 .. termCount:
    for k in 0 .. valueCount - 1:
      var best = impossibleCost
      for l in countdown(maxOpenGroups, 0):
        let i = l * valueCount + k
        if currentCosts[i] < best: best = currentCosts[i]
        closedCosts[i] = best

    for i in 0 .. tableSize - 1:
      openedCosts[i] = closedCosts[i]
    if j >= 1 and j <= termCount - 1 and termOperators[j - 1] == '-':
      for l in 0 .. maxOpenGroups - 1:
        for k in 0 .. valueCount - 1:
          let source = closedCosts[l * valueCount + k]
          if source >= impossibleCost: continue
          let destination = (l + 1) * valueCount + k
          if source + 1 < openedCosts[destination]:
            openedCosts[destination] = source + 1

    if j == termCount:
      var answer = impossibleCost
      let wantedIndex = targetValue + valueOffset
      for l in 0 .. maxOpenGroups:
        let i = l * valueCount + wantedIndex
        if openedCosts[i] < answer: answer = openedCosts[i]
      if answer >= impossibleCost: return -1
      return answer

    clearCosts(followingCosts)
    let operatorSign = if termOperators[j] == '+': 1 else: -1
    let digitValue = termDigits[j]
    for l in 0 .. maxOpenGroups:
      let flipSign = if (l and 1) == 1: -1 else: 1
      let delta = operatorSign * flipSign * digitValue
      for k in 0 .. valueCount - 1:
        let source = openedCosts[l * valueCount + k]
        if source >= impossibleCost: continue
        let nextValue = k + delta
        if nextValue < 0 or nextValue >= valueCount: continue
        let destination = l * valueCount + nextValue
        if source < followingCosts[destination]:
          followingCosts[destination] = source

    swap currentCosts, followingCosts

  return -1
```

The loop covers all boundaries, group counts, and values. The suffix minimum closes groups at no cost. A minus sign gates the purchase of a new pair. Four tables keep the stages separate without allocation.

**Driver.**

```nim
var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var i = 0
let caseCount = nextSignedInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  let termCount = nextSignedInt(inputData, i) div 2
  let targetValue = nextSignedInt(inputData, i)
  let expressionBounds = nextTokenBounds(inputData, i)
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

The driver reads all input into one string. It halves n to get the digit count. An impossible answer prints NO. Output is flushed in 128 KiB blocks.

## Complexity

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Per case | O(m * V) | four tables of 7581 integers |
| Output | O(d) lines | one output block |

Here m is at most 20 and V is 361.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(d * m * V) |
| Space | O(m * V) |

Listing every parenthesization costs Catalan(m - 1) parses, about 1.8 billion at m = 20.
