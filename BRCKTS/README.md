# BRCKTS — Brackets (SPOJ)
<https://www.spoj.com/problems/BRCKTS/>

## Problem

A word of parentheses is correct when every opening bracket finds a matching closing bracket and no prefix dips below zero. Ten words arrive with flip and check operations. Print YES or NO for each check.

Input holds ten test cases one after another. Each case starts with the word length n, then the bracket word, then the operation count m, then m integers. A zero asks for a check; a positive k flips bracket k. Output a `Test i:` header per case, then one result per check.

The stated bounds and judge limits follow.

| Quantity | Bound |
| --- | --- |
| Word length | 1 to 30,000 |
| Test cases | 10 |
| Operations per case | no stated limit |
| Time limit | 11,000 ms |
| Memory limit | 1536 MB |

The word stays modest, while the operation stream drives the running time.

The sample input and output:

```
4
()((
4
4
0
2
0
```

```
Test 1:
YES
NO
```

The first check succeeds after flipping bracket four.

## Idea

Keep a scoreboard for every interval of the word. A segment tree (an array storing one value per interval) holds each interval's bracket sum and its smallest running prefix. A flip changes one leaf and rebuilds its ancestors; a check reads the root. Think of each interval as a team whose score and worst moment are both recorded.

Each flip costs O(log n), and each check costs O(1). Rescanning the whole word on every check would cost O(n) each time and lose on a long operation stream.

Takeaway: store two numbers per interval and answer checks at the root.

## Why It Works

1. An opening bracket adds 1 to the running score; a closing bracket subtracts 1.
2. A word is correct exactly when its total is zero and its smallest prefix is non-negative.
3. The root of the tree holds both numbers, so one comparison answers a check.
4. An interval's total is the sum of its two halves.
5. Its smallest prefix is the smaller of the left prefix and the left total plus the right prefix.
6. `treeSize + j - 1` maps a 1-based bracket position to its leaf, and `i shr 1` walks to a parent.

The merge rule is the heart of the update.

| Term | Meaning |
| --- | --- |
| `segmentSum[i]` | bracket total of interval i |
| `segmentMinPrefix[i]` | smallest running prefix inside interval i |
| `leftChild = i shl 1` | left half of interval i |
| `emptyPrefixValue` | large value for unused leaves, so they never lower a minimum |

Every parent is rebuilt from its two children after a flip.

A script traced the sample word before any flip:

| Position | Bracket | Value | Prefix |
| --- | --- | --- | --- |
| 1 | ( | +1 | 1 |
| 2 | ) | -1 | 0 |
| 3 | ( | +1 | 1 |
| 4 | ( | +1 | 2 |

Flipping bracket four gives `())(` with total zero, so the first check prints YES.

## Code

**Constants, state, and readers.**
```nim
const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  treeArraySize = 1 shl 16
  emptyPrefixValue = 1 shl 25

var
  inputData = ""
  i = 0
  outputBuffer = ""
  segmentSum = newSeq[int](treeArraySize)
  segmentMinPrefix = newSeq[int](treeArraySize)
  treeSize = 1

proc loadInput() =
  var lineContents = ""
  while readLine(stdin, lineContents):
    inputData.add lineContents
    inputData.add '\n'

proc skipWhitespace() =
  while i < inputData.len and ord(inputData[i]) <= spaceCode:
    inc i

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitCode)
    inc i
```
`loadInput` gathers the stream into `inputData`. `skipWhitespace` advances past spaces and line breaks. `readInteger` builds an operation value from the buffer.

**Tree construction and queries.**
```nim
proc loadBracketWord(wordLength: int) =
  skipWhitespace()
  var j = treeSize
  while j < treeSize + wordLength:
    if inputData[i] == '(':
      segmentSum[j] = 1
      segmentMinPrefix[j] = 1
    else:
      segmentSum[j] = -1
      segmentMinPrefix[j] = -1
    inc j
    inc i
  while j < treeSize + treeSize:
    segmentSum[j] = 0
    segmentMinPrefix[j] = emptyPrefixValue
    inc j

proc rebuildParents() =
  var i = treeSize - 1
  while i >= 1:
    let leftChild = i shl 1
    let rightChild = leftChild or 1
    segmentSum[i] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[i] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    dec i

proc flipBracket(j: int) =
  var i = treeSize + j - 1
  if segmentSum[i] == 1:
    segmentSum[i] = -1
    segmentMinPrefix[i] = -1
  else:
    segmentSum[i] = 1
    segmentMinPrefix[i] = 1
  i = i shr 1
  while i >= 1:
    let leftChild = i shl 1
    let rightChild = leftChild or 1
    segmentSum[i] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[i] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    i = i shr 1

proc isBalanced(): bool =
  segmentSum[1] == 0 and segmentMinPrefix[1] >= 0
```
`loadBracketWord` fills the leaves and pads the rest with empty values. `rebuildParents` computes every parent bottom-up. `flipBracket` swaps one leaf and walks to the root, and `isBalanced` reads the root in O(1).

**Driver.**
```nim
proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

loadInput()
var testNumber = 1
while true:
  skipWhitespace()
  if i >= inputData.len: break
  let wordLength = readInteger()
  treeSize = 1
  while treeSize < wordLength:
    treeSize = treeSize shl 1
  loadBracketWord(wordLength)
  rebuildParents()
  let operationCount = readInteger()
  outputBuffer.add "Test "
  outputBuffer.add $testNumber
  outputBuffer.add ":\n"
  for j in 0 ..< operationCount:
    let operation = readInteger()
    if operation == 0:
      if isBalanced():
        outputBuffer.add "YES\n"
      else:
        outputBuffer.add "NO\n"
      flushOutput(false)
    else:
      flipBracket(operation)
  inc testNumber
flushOutput(true)
```
The loop sizes the tree as the next power of two, loads the word, then processes operations. Each zero writes YES or NO into `outputBuffer`, and `flushOutput` sends blocks to stdout.

## Complexity

Tree size is the next power of two above the word length.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Tree build | O(n) | 2 times treeSize values |
| Flip | O(log n) | O(1) extra |
| Check | O(1) | O(1) |
| Output | one write per block | flushBlockBytes |

Operations drive the total, not the word size alone.

| Measure | Big O |
| --- | --- |
| Time per flip | O(log n) |
| Time per check | O(1) |
| Space per case | O(treeSize) |

A full rescan on each check would cost O(n) every time, while the tree answers checks from two root values.
