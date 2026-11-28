# THREECOL — Three-coloring of binary trees (SPOJ)

<https://www.spoj.com/problems/THREECOL/>

## Problem

The input gives binary trees as digit strings: 0 is a leaf, 1 a node with one child, and 2 a node with two. Color nodes red, green, or blue so a node differs from its children and two children differ; report the fewest and most green nodes.

Input: `t` test cases, one specification word per line. A digit `0` means a leaf, `1` means one child follows, and `2` means two children follow. Output: two integers per case, the maximum and minimum green count.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Specification length | at most 10,000 characters |
| Children per node | 0, 1, or 2 |
| Judge limit | 7000 ms, 1536 MB |

A specification can describe thousands of nodes, so parsing and coloring must stay linear.

The sample input and output:

```
1
1122002010
```

```
5 2
```

## Idea

Color each subtree from its leaves upward, keeping only two numbers for each node. Remember the most and fewest green nodes when the root is green, and the same two counts when it is not.

The program builds child links from the preorder specification, then applies dynamic programming (reusing each subtree's best answer) in reverse order. Each node needs a constant number of comparisons, so a case costs `O(n)`.

Trying all three colors at every node visits `3^n` colorings. The two-state summary keeps one best maximum and one best minimum per node.

The symmetry between red and blue lets one "other color" state stand for both.

## Why It Works

Five facts prove the two-state recurrence.

1. The specification is preorder, so a node's children are the next nodes in the word. A stack tracks how many children each open node still needs.
2. A green node forces every child to be non-green. A non-green node allows a child to be green or the other non-green color.
3. A leaf has one green count when green and zero when not.
4. With one child, a green parent adds one plus the child's best non-green value. A non-green parent takes the better of the child's green and non-green values.
5. With two children, a non-green parent must give the children different colors. The program takes the better of green-left and other-right versus other-left and green-right.

The four values stored for each node:

| Term | Meaning |
| --- | --- |
| `maxGreen[i]`, `minGreen[i]` | green extremes when node `i` is green |
| `maxOther[i]`, `minOther[i]` | extremes when node `i` uses red or blue |
| `childLeft[i]`, `childRight[i]` | child node slots of node `i` |
| `childNeed[i]` | children still expected while parsing |
| `nodeStack` | open nodes during the preorder walk |

The reverse loop visits children before parents, so every lookup is ready.

A script scan of the sample specification:

```
spec 1122002010, root color grouped by green/not-green
| root color | max greens | min greens |
| 0 | 4 | 2 |
| 1 | 5 | 3 |
| 2 | 4 | 2 |
answer max 5, min 2
```

Red and blue give the same pair, so the maximum comes from a green root.

## Code

**Input and helpers.** One buffer holds the stream, and a digit scanner reads the case count.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxSpecLen = 10010

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextInt` skips non-digits, so it stops at the specification word.
`appendOutput` flushes at 256 KiB.
The output helper writes one line per case.

**Fixed tables.** Arrays cover the longest permitted specification.

```nim
var childLeft: array[maxSpecLen, int]
var childRight: array[maxSpecLen, int]
var childNeed: array[maxSpecLen, int]
var maxGreen: array[maxSpecLen, int]
var minGreen: array[maxSpecLen, int]
var maxOther: array[maxSpecLen, int]
var minOther: array[maxSpecLen, int]
var nodeStack: array[maxSpecLen, int]
```

`maxSpecLen = 10010` leaves room for the word plus a margin.
Each node gets four extreme values and two child links.
All arrays are reused across cases.

**Child links.** A stack connects each digit to its parent during the preorder walk.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and inputData[scanPos] < '0':
    scanPos += 1
  let wordStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    scanPos += 1
  let wordLen = scanPos - wordStart

  var stackTop = -1
  for i in 0..<wordLen:
    let digit = int(inputData[wordStart + i]) - firstDigitValue
    childLeft[i] = -1
    childRight[i] = -1
    childNeed[i] = digit
    if stackTop >= 0:
      let parentIndex = nodeStack[stackTop]
      if childLeft[parentIndex] == -1:
        childLeft[parentIndex] = i
      else:
        childRight[parentIndex] = i
      childNeed[parentIndex] -= 1
      if childNeed[parentIndex] == 0:
        stackTop -= 1
    if digit > 0:
      stackTop += 1
      nodeStack[stackTop] = i
```

`childNeed` counts children still expected at an open node.
The first child fills `childLeft`, and the second fills `childRight`.
Digits larger than zero push a new open node onto `nodeStack`.

**Bottom-up coloring.** The reverse loop computes the four extremes for every node.

```nim
  for i in countdown(wordLen - 1, 0):
    let digit = int(inputData[wordStart + i]) - firstDigitValue
    if digit == 0:
      maxGreen[i] = 1
      minGreen[i] = 1
      maxOther[i] = 0
      minOther[i] = 0
    elif digit == 1:
      let childIndex = childLeft[i]
      maxGreen[i] = 1 + maxOther[childIndex]
      minGreen[i] = 1 + minOther[childIndex]
      maxOther[i] = max(maxGreen[childIndex], maxOther[childIndex])
      minOther[i] = min(minGreen[childIndex], minOther[childIndex])
    else:
      let leftIndex = childLeft[i]
      let rightIndex = childRight[i]
      maxGreen[i] = 1 + maxOther[leftIndex] + maxOther[rightIndex]
      minGreen[i] = 1 + minOther[leftIndex] + minOther[rightIndex]
      maxOther[i] = max(maxGreen[leftIndex] + maxOther[rightIndex],
                        maxOther[leftIndex] + maxGreen[rightIndex])
      minOther[i] = min(minGreen[leftIndex] + minOther[rightIndex],
                        minOther[leftIndex] + minGreen[rightIndex])

  let answerMax = max(maxGreen[0], maxOther[0])
  let answerMin = min(minGreen[0], minOther[0])
  appendOutput($(answerMax) & " " & $(answerMin) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`countdown(wordLen - 1, 0)` visits children before parents.
The two-child branch takes the better of the two allowed color assignments.
The final answer compares the green and non-green states at the root.

## Complexity

Parsing and coloring each visit every node a constant number of times.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Child links | O(n) digits | O(n) for links and stack |
| Bottom-up coloring | O(n) nodes | O(n) for four value arrays |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n) | O(n) |

At `n = 10,000` the reverse loop fills 40,000 extreme values.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n) per case, O(total specification length) overall |
| Space | O(n) per case, plus buffers |

Enumerating `3^n` colorings grows exponentially. Two best values per subtree settle each case in linear time.
