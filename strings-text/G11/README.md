# G11 — Binario (SPOJ)

<https://www.spoj.com/problems/G11/>

## Problem

Read one string of letters and insert the letters, in order, into a binary search tree.
Keep the tree height balanced as an AVL tree does.
Print three traversals of the finished tree.
Each traversal occupies one line.

The input holds one string of letters with no stated maximum length.

| Item | Bound |
|---|---|
| Input | one line of letters |
| Tree rule | AVL height balance at every node |
| Output | inorder, preorder, postorder |
| Judge limit | 1000 ms |

The tree shape, not the input size, decides every answer.

Sample input:

```
GKILQMT
```

Sample output:

```
GIKLMQT
LIGKQMT
GKIMTQL
```

## Idea

Think of each letter as a passenger finding a seat in a sorted row.
A new passenger moves left or right until the seat is empty.
After each arrival, a tilted subtree rotates like a seesaw finding balance.

An AVL node stores its height and two children.
Insertion walks down once, then repairs balance on the way back.
Inorder reads the sorted letters, while the other two orders expose the shape.

## Why It Works

1. Smaller letters go left and larger or equal letters go right.
2. Inorder traversal of a search tree visits keys in sorted order.
3. A height difference above one triggers a single or double rotation.
4. Rotations preserve search order and restore the height bound.
5. Preorder visits a node before its children, postorder after both.

| Term | Meaning |
|---|---|
| `nodeHeight` | longest path from a node down to a leaf |
| `rotateRight` | rebalance a left-heavy subtree |
| `rotateLeft` | rebalance a right-heavy subtree |
| `insertValue` | place a letter and repair balance on return |

Script-generated example from `gen.py`:

```
A
A
A
```

One letter produces the same single node in all three orders.

## Code

**Storage and input.** This block holds the tree in parallel index arrays.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

let capacity = inputData.len + 1
var nodeValue = newSeq[char](capacity)
var leftChild = newSeq[int](capacity)
var rightChild = newSeq[int](capacity)
var nodeHeight = newSeq[int](capacity)
var nodeCount = 0
```

Index zero means an empty child.
Every array has room for one node per input byte.
Whitespace is skipped while letters are inserted.

**Balanced insertion.** This block performs rotations and repairs the path.

```nim
proc treeHeight(index: int): int =
  if index == 0: return 0
  return nodeHeight[index]

proc refreshHeight(index: int) =
  let leftHeight = treeHeight(leftChild[index])
  let rightHeight = treeHeight(rightChild[index])
  nodeHeight[index] = 1 + (if leftHeight > rightHeight: leftHeight else: rightHeight)

proc rotateRight(index: int): int =
  let pivot = leftChild[index]
  leftChild[index] = rightChild[pivot]
  rightChild[pivot] = index
  refreshHeight(index)
  refreshHeight(pivot)
  return pivot

proc rotateLeft(index: int): int =
  let pivot = rightChild[index]
  rightChild[index] = leftChild[pivot]
  leftChild[pivot] = index
  refreshHeight(index)
  refreshHeight(pivot)
  return pivot

proc insertValue(rootIndex: int, value: char): int =
  if rootIndex == 0:
    nodeCount += 1
    nodeValue[nodeCount] = value
    leftChild[nodeCount] = 0
    rightChild[nodeCount] = 0
    nodeHeight[nodeCount] = 1
    return nodeCount
  if value < nodeValue[rootIndex]:
    leftChild[rootIndex] = insertValue(leftChild[rootIndex], value)
  else:
    rightChild[rootIndex] = insertValue(rightChild[rootIndex], value)
  refreshHeight(rootIndex)
  let balance = treeHeight(leftChild[rootIndex]) - treeHeight(rightChild[rootIndex])
  if balance > 1:
    if value > nodeValue[leftChild[rootIndex]]:
      leftChild[rootIndex] = rotateLeft(leftChild[rootIndex])
    return rotateRight(rootIndex)
  if balance < -1:
    if value < nodeValue[rightChild[rootIndex]]:
      rightChild[rootIndex] = rotateRight(rightChild[rootIndex])
    return rotateLeft(rootIndex)
  return rootIndex

var rootIndex = 0
for index in 0..<inputData.len:
  let current = inputData[index]
  if current > ' ':
    rootIndex = insertValue(rootIndex, current)
```

A single rotation fixes a straight insertion path.
A double rotation fixes a bent path.
Heights are refreshed after every structural change.

**Traversals and output.** This block walks the tree three times.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendLetter(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc walkInorder(index: int) =
  if index == 0: return
  walkInorder(leftChild[index])
  appendLetter(nodeValue[index])
  walkInorder(rightChild[index])

proc walkPreorder(index: int) =
  if index == 0: return
  appendLetter(nodeValue[index])
  walkPreorder(leftChild[index])
  walkPreorder(rightChild[index])

proc walkPostorder(index: int) =
  if index == 0: return
  walkPostorder(leftChild[index])
  walkPostorder(rightChild[index])
  appendLetter(nodeValue[index])

walkInorder(rootIndex)
outputBuffer.add '\n'
walkPreorder(rootIndex)
outputBuffer.add '\n'
walkPostorder(rootIndex)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each walk visits each node exactly once.
The buffer flush keeps memory small on long strings.
Three newline characters separate the three lines.

## Complexity

Insertion and traversal dominate the runtime.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Insertions | O(L log L) total | O(L) |
| Traversals | three walks of L nodes | recursion stack O(log L) |
| Output | one write per 128 KiB block | block buffer |

L is the number of letters in the string.

| Measure | Big O |
|---|---|
| Time | O(L log L) |
| Space | O(L) |

Repeated full rebuilds after each letter would cost O(L^2 log L).
One incremental AVL insertion keeps the tree balanced in logarithmic time.
