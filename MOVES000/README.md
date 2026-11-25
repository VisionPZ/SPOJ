# MOVES000 — Moves (SPOJ)
<https://www.spoj.com/problems/MOVES000/>

## Problem

A row of letters undergoes many moves. Each move cuts one consecutive block and places that block at the front of the row. Report the row after every move has been applied.

The first line holds two integers, n and m. The next line holds a string of n letters. Each of the next m lines holds two integers, L and R, the one-based ends of the block to move. Print the final string on one line.

The bounds and judge limit are:

| Constraint | Value |
| --- | --- |
| Letters n | 1 to 250000 |
| Moves m | 0 to 250000 |
| Judge limit | 1000 ms, 1536 MB |

Both bounds reach 250000, so each move must avoid copying the whole row.

The sample input and its output follow byte for byte.

```
10 3
abcdefghij
2 3
3 5
3 7
```

```
ebcfgadhij
```

## Idea

Treat the row like a row of beads on a zipper. Unclip one run of beads and clip it onto the front. An implicit treap stores the beads in order, and subtree sizes replace stored positions.

Each move performs two splits and two merges. A split or merge touches one root-to-leaf path. That path costs O(log n) expected time. An array copy would cost O(n) per move, or about 6e10 element writes at the bound. Keep the treap, and each move touches only a short path.

## Why It Works

1. In-order traversal of the treap lists the letters in row order.
2. Subtree sizes turn a position into a count of nodes to skip during a split.
3. `splitTree` with `leftIndex - 1` isolates the prefix before the chosen block.
4. A second split takes exactly `rightIndex - leftIndex + 1` nodes as the moved block.
5. Merging the moved block before the prefix puts it at the front, and the suffix keeps its order.

The main terms used in the proof are:

| Term | Meaning |
| --- | --- |
| `nodePriority` | random heap key that keeps the tree shallow |
| `subtreeSize` | node count below a tree, used to find a position |
| `prefixTree` | letters before the moved block |
| `movedTree` | letters taken from L through R |
| `suffixTree` | letters after the moved block |

These terms reduce each move to a fixed number of tree operations.

The oracle prints this trace for the sample. Each line shows the cut block and the new row.

```
start   abcdefghij
2 3     bc   + adefghij -> bcadefghij
3 5     ade  + bcfghij  -> adebcfghij
3 7     ebcfg + adij    -> ebcfgadhij
```

The last row matches the sample output exactly.

## Code

**Whole-stream input and hand scanner.** The reader stores all lines in one string, and the scanner walks it by index.

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

`nextInt` skips non-digits before reading each value. Digit folding uses `int(data[pos]) - 48`. One input string avoids a syscall per line.

**Output buffer and tree storage.** The writer flushes whole blocks, and the arrays hold one treap node per index.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let totalNodes = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var leftChild = newSeq[int](totalNodes + 1)
var rightChild = newSeq[int](totalNodes + 1)
var subtreeSize = newSeq[int](totalNodes + 1)
var nodePriority = newSeq[int](totalNodes + 1)
var nodeCharacter = newSeq[char](totalNodes + 1)

var randomState = 123456789
proc nextPriority(): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState and 0x7fffffff
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  randomState = randomState and 0x7fffffff
  return randomState

var nextNodeIndex = 0
proc createNode(character: char): int =
  nextNodeIndex += 1
  leftChild[nextNodeIndex] = 0
  rightChild[nextNodeIndex] = 0
  subtreeSize[nextNodeIndex] = 1
  nodePriority[nextNodeIndex] = nextPriority()
  nodeCharacter[nextNodeIndex] = character
  return nextNodeIndex

proc refreshSize(nodeIndex: int) =
  subtreeSize[nodeIndex] = subtreeSize[leftChild[nodeIndex]] + subtreeSize[rightChild[nodeIndex]] + 1
```

Node zero is the empty tree, with size zero. `nextPriority` uses a xorshift generator for heap keys. `refreshSize` restores the count after every structural change.

**Split and merge.** A split cuts by node count, and a merge joins two treaps by heap key.

```nim
proc splitTree(rootIndex: int, leftCount: int, leftResult: var int, rightResult: var int) =
  if rootIndex == 0:
    leftResult = 0
    rightResult = 0
    return
  if subtreeSize[leftChild[rootIndex]] >= leftCount:
    splitTree(leftChild[rootIndex], leftCount, leftResult, leftChild[rootIndex])
    rightResult = rootIndex
  else:
    splitTree(rightChild[rootIndex], leftCount - subtreeSize[leftChild[rootIndex]] - 1, rightChild[rootIndex], rightResult)
    leftResult = rootIndex
  refreshSize(rootIndex)

proc mergeTrees(leftRoot: int, rightRoot: int): int =
  if leftRoot == 0:
    return rightRoot
  if rightRoot == 0:
    return leftRoot
  if nodePriority[leftRoot] > nodePriority[rightRoot]:
    rightChild[leftRoot] = mergeTrees(rightChild[leftRoot], rightRoot)
    refreshSize(leftRoot)
    return leftRoot
  else:
    leftChild[rightRoot] = mergeTrees(leftRoot, leftChild[rightRoot])
    refreshSize(rightRoot)
    return rightRoot
```

`splitTree` keeps the first `leftCount` nodes in `leftResult`. It descends one path and restores sizes on the way back. `mergeTrees` picks the larger heap key as root, so all left nodes stay before all right nodes.

**Row rebuild and final write.** Each query reorders three treaps, and one traversal emits the answer.

```nim
proc writeTree(nodeIndex: int) =
  if nodeIndex == 0:
    return
  writeTree(leftChild[nodeIndex])
  appendOutput($nodeCharacter[nodeIndex])
  writeTree(rightChild[nodeIndex])

while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var rootIndex = 0
for characterIndex in 0 .. totalNodes - 1:
  rootIndex = mergeTrees(rootIndex, createNode(inputData[scanPos + characterIndex]))
scanPos += totalNodes

for queryIndex in 0 .. queryCount - 1:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  var prefixTree = 0
  var remainderTree = 0
  splitTree(rootIndex, leftIndex - 1, prefixTree, remainderTree)
  var movedTree = 0
  var suffixTree = 0
  splitTree(remainderTree, rightIndex - leftIndex + 1, movedTree, suffixTree)
  rootIndex = mergeTrees(mergeTrees(movedTree, prefixTree), suffixTree)

writeTree(rootIndex)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The string is read after the header, then `scanPos` advances past its n letters. Each query splits off the prefix and the moved block, then joins them in the new order. `writeTree` walks in order and appends letters through the block buffer.

## Complexity

The cost is split into input, queries, and final output.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over all bytes | one input string |
| Treap build | n merges of O(log n) | n nodes |
| Each query | two splits and two merges | O(log n) stack |
| Final write | one in-order walk | block buffer |

The build cost and q query costs dominate the runtime.

| Measure | Big O |
| --- | --- |
| Time | O((n + m) log n) expected |
| Space | O(n) |

An array-based move copies up to n letters per query, or O(nm) in total. The treap keeps that work on one path per split and merge.
