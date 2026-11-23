## Problem

Read ten bracket words and their lists of operations. Each operation flips one bracket or checks whether the current word is a correct bracket expression. A word is correct when its brackets pair up and every prefix holds at least as many opening brackets as closing brackets. Print one `Test i:` header per word, then `YES` or `NO` for each check operation.

The stated bounds and judge limits follow.

| Quantity | Bound |
| --- | --- |
| Word length | 1 to 30,000 |
| Test cases | 10 |
| Operations per case | No limit stated |
| Time limit | 11,000 ms |
| Memory limit | 1,536 MB |

The word stays small, while the operation stream drives the running time.

## Idea

A segment tree is an array that holds one value per interval of the word. Here it stores two values per interval: the interval total and its smallest running prefix. A flip changes one leaf and rebuilds the ancestors. A check reads the root.
Each flip costs O(log n) time, and each check costs O(1) time.

## Why It Works

An opening bracket adds 1 to the running prefix, and a closing bracket subtracts 1. A word is correct exactly when its total is zero and its smallest prefix is non-negative. The root of the tree holds both numbers, so one comparison answers a check.

Each formula below maps one part of the tree to a value.

- `segmentSum[nodeIndex] = segmentSum[leftChild] + segmentSum[rightChild]` adds the totals of the two halves.
- `segmentMinPrefix[nodeIndex] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])` compares prefixes inside the left half with prefixes that continue into the right half.
- `treeSize + bracketPosition - 1` maps a 1-based bracket position to its leaf.
- `nodeIndex shr 1` moves from a child to its parent, so a flip visits one node per level.
- `segmentSum[1] == 0 and segmentMinPrefix[1] >= 0` is the final check at the root.

This trace of the sample word lists each bracket, its value, and the running prefix.

| Position | Bracket | Value | Prefix |
| --- | --- | --- | --- |
| 1 | ( | +1 | 1 |
| 2 | ) | -1 | 0 |
| 3 | ( | +1 | 1 |
| 4 | ( | +1 | 2 |

The total is 2, so the first check prints NO. After flipping bracket 4, the word becomes ()() and the second check prints YES.

## Code

```
const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  treeArraySize = 1 shl 16
  emptyPrefixValue = 1 shl 25

var
  inputData = ""
  inputPosition = 0
  outputBuffer = ""
  segmentSum = newSeq[int](treeArraySize)
  segmentMinPrefix = newSeq[int](treeArraySize)
  treeSize = 1
```

The arrays hold 65,536 slots, twice the smallest power of two above 30,000. Padding gets a large empty-prefix value so empty leaves never lower a parent minimum. This block costs one allocation.

```
proc loadInput() =
  var lineContents = ""
  while readLine(stdin, lineContents):
    inputData.add lineContents
    inputData.add '\n'

proc skipWhitespace() =
  while inputPosition < inputData.len and ord(inputData[inputPosition]) <= spaceCode:
    inc inputPosition

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while inputPosition < inputData.len and inputData[inputPosition] >= '0' and inputData[inputPosition] <= '9':
    result = result * 10 + (ord(inputData[inputPosition]) - firstDigitCode)
    inc inputPosition
```

The read loop runs once per input line, and the scanner walks the buffer by index. Whitespace skipping also absorbs carriage returns. This costs one pass over the input bytes.

```
proc loadBracketWord(wordLength: int) =
  skipWhitespace()
  var leafIndex = treeSize
  while leafIndex < treeSize + wordLength:
    if inputData[inputPosition] == '(':
      segmentSum[leafIndex] = 1
      segmentMinPrefix[leafIndex] = 1
    else:
      segmentSum[leafIndex] = -1
      segmentMinPrefix[leafIndex] = -1
    inc leafIndex
    inc inputPosition
  while leafIndex < treeSize + treeSize:
    segmentSum[leafIndex] = 0
    segmentMinPrefix[leafIndex] = emptyPrefixValue
    inc leafIndex
```

The first loop runs exactly wordLength times, and the second runs treeSize minus wordLength times. Padding cannot change a parent result. This costs O(treeSize) per test case.

```
proc rebuildParents() =
  var nodeIndex = treeSize - 1
  while nodeIndex >= 1:
    let leftChild = nodeIndex shl 1
    let rightChild = leftChild or 1
    segmentSum[nodeIndex] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[nodeIndex] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    dec nodeIndex
```

The loop visits each internal node once, from treeSize minus 1 down to 1. The merge keeps the prefix that stops at the left boundary, because that prefix is already inside the left half. This costs O(treeSize) per test case.

```
proc flipBracket(bracketPosition: int) =
  var nodeIndex = treeSize + bracketPosition - 1
  if segmentSum[nodeIndex] == 1:
    segmentSum[nodeIndex] = -1
    segmentMinPrefix[nodeIndex] = -1
  else:
    segmentSum[nodeIndex] = 1
    segmentMinPrefix[nodeIndex] = 1
  nodeIndex = nodeIndex shr 1
  while nodeIndex >= 1:
    let leftChild = nodeIndex shl 1
    let rightChild = leftChild or 1
    segmentSum[nodeIndex] = segmentSum[leftChild] + segmentSum[rightChild]
    segmentMinPrefix[nodeIndex] = min(segmentMinPrefix[leftChild], segmentSum[leftChild] + segmentMinPrefix[rightChild])
    nodeIndex = nodeIndex shr 1
```

The upward loop runs once per tree level, at most 15 steps here. The leaf flips sign, and the parent merge matches the build. This costs O(log n) per replacement.

```
proc isBalanced(): bool =
  segmentSum[1] == 0 and segmentMinPrefix[1] >= 0

proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The check reads two root values and does no scanning. The buffer flushes after 256 KiB or at the end. This keeps write calls rare.

```
loadInput()
var testNumber = 1
while true:
  skipWhitespace()
  if inputPosition >= inputData.len: break
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
  for operationIndex in 0 ..< operationCount:
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

The size loop doubles treeSize until it reaches wordLength, giving at most 32,768 leaves. End of input stops the case loop, so ten cases need no hard-coded count. This costs one pass over all operations.

## Complexity

Phase costs use a word of length n, q operations, and p checks.

| Phase | Time | Space |
| --- | --- | --- |
| Input load | O(total input bytes) | O(total input bytes) |
| Tree build | O(n) | O(n) |
| Replacement | O(log n) each | O(1) extra |
| Check | O(1) each | O(1) extra |
| Output | O(p) bytes | O(1) beyond the block |

Total time is O(input + n + q log n + output), and total space is O(input + n). A naive check rescans all n brackets, which costs O(n × p) for p checks. The tree replaces that rescan with one root read.
