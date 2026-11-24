## Problem

Each test case gives a preorder string of digits 0, 1 and 2 that describes a binary tree. Digit 0 marks a leaf, digit 1 marks one child and digit 2 marks two children. Print the largest and smallest number of green vertices over all legal colorings. A vertex differs from each child, and the two children of a vertex differ from each other.

The statement sets these bounds:

| Quantity | Bound |
| --- | --- |
| Word length | at most 10000 digits |
| Test cases | no upper bound in the statement |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The word length sets the array size, and the missing case bound shapes the buffered input and output.

## Idea

This program numbers nodes in preorder, stores both children of each node, then walks the numbers backwards. Red and blue play the same role when counting green vertices, so one other state covers both. Four values per node record the most and fewest green vertices when the node is green or other.

Each node costs constant work in the child-building pass and constant work in the reverse pass.

## Why It Works

Three colors leave two choices for a child and two colors for a pair of children. A node with two children hands those two colors to its children in either order. The other state treats red and blue as one case because neither color adds a green vertex. Preorder places every parent before its descendants, so a reverse walk sees all children before their parent.

Let index i name a node. The four stored values use green and other as the node state.

- `maxGreen[i] = 1` and `maxOther[i] = 0` for a leaf.
- `maxGreen[i] = 1 + maxOther[childIndex]` with one child.
- `maxOther[i] = max(maxGreen[childIndex], maxOther[childIndex])` with one child.
- `maxGreen[i] = 1 + maxOther[leftIndex] + maxOther[rightIndex]` with two children.
- `maxOther[i] = max(maxGreen[leftIndex] + maxOther[rightIndex],` plus `maxOther[leftIndex] + maxGreen[rightIndex])` with two children.

The minimum forms replace `max` with `min` and use the same child values.

A brute-force enumeration of the sample string gives these counts by root color:

| Root color | Most green | Fewest green |
| --- | --- | --- |
| red | 4 | 2 |
| green | 5 | 3 |
| blue | 4 | 2 |

The program reports 5 from the green root and 2 from a red or blue root.

## Code

The program reads every line into one string. The scanner walks that string by index, and the output buffer flushes in large blocks.

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

The read loop runs once per input line, not once per digit. The scanner skips separators, so blank lines cause no error. Buffering keeps write calls rare.

One case owns one word. The arrays are allocated once and reused across cases.

```nim
var childLeft: array[maxSpecLen, int]
var childRight: array[maxSpecLen, int]
var childNeed: array[maxSpecLen, int]
var maxGreen: array[maxSpecLen, int]
var minGreen: array[maxSpecLen, int]
var maxOther: array[maxSpecLen, int]
var minOther: array[maxSpecLen, int]
var nodeStack: array[maxSpecLen, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  while scanPos < inputData.len and inputData[scanPos] < '0':
    scanPos += 1
  let wordStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    scanPos += 1
  let wordLen = scanPos - wordStart
```

The loop runs exactly `caseCount` times. The two inner loops find one word and never copy it. Fixed arrays avoid per-case allocation.

The stack holds nodes that still await children. Each digit becomes a node before its own subtree is read.

```nim
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

The loop runs `wordLen` times. Resetting `childLeft[i]` prevents a stale child from an earlier case. One push and one pop per node keep the stack balanced.

The reverse walk fills the four values for the node at index i.

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
```

The loop covers indices from `wordLen - 1` down to zero. Reverse order makes every child value ready before its parent needs it. Each branch touches at most four other nodes.

The answer takes the best root state, and the last write empties the buffer.

```nim
  let answerMax = max(maxGreen[0], maxOther[0])
  let answerMin = min(minGreen[0], minOther[0])
  appendOutput($(answerMax) & " " & $(answerMin) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Node zero is the root because the string starts at the root. The single space and trailing newline match the required output shape. The final write flushes any remaining bytes.

## Complexity

Reading input costs O(total digits), and parsing each word costs O(word length). Building children costs O(word length), and the reverse pass costs O(word length). Output costs O(test cases).

The arrays hold O(10000) integers, and the output buffer holds at most 256 KiB. Total time is O(total digits + test cases), and total space is O(10000) plus the buffer. A naive search tries one coloring per three-color assignment and grows as 3 to the node count.
