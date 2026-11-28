# TREEORD — Tree order (SPOJ)

<https://www.spoj.com/problems/TREEORD/>

## Problem

Decide whether three given traversals could all describe one binary tree. The preorder root fixes each subtree, the inorder split fixes its children, and the postorder must end with that root.

Each case starts with N, the node count. The next three lines hold the preorder, postorder, and inorder nodes, numbered 1 through N. Print `yes` when the three traversals agree, otherwise print `no`.

| item | bound |
|---|---|
| nodes N | between 1 and 8000 |
| node labels | 1 to N, no repeats |
| cases per file | one or more until end of input |
| judge limit | 500 ms, 1536 MB |

The sample input:

```
6
1 2 4 5 3 6
4 5 2 6 3 1
4 2 5 1 3 6
```

The sample output:

```
yes
```

## Idea

Check each subtree like verifying a family tree one branch at a time. The first preorder name is the parent; the inorder split says how many nodes sit on each side.

The algorithm walks intervals with an explicit stack. Each interval names a slice of all three traversals and one subtree size. The root must close its postorder slice, and its inorder position must lie inside the interval. The stack adds the right slice, then the left slice.

This check visits every node once and never rebuilds the tree. Rebuilding a tree would allocate child links for all N nodes before any comparison.

The interval check answers with one pass over the nodes.

## Why It Works

1. Preorder places a subtree root before both of its children.
2. Postorder places that same root after both children, at the last slot of the slice.
3. Inorder places the root between its left subtree and its right subtree.
4. The root's inorder position gives the left size and the right size directly.
5. Recursing those sizes over all nodes checks every parent-child relation, so a `yes` means one tree exists.

| term | meaning |
|---|---|
| `TraversalInterval` | one subtree slice in all three traversals |
| `preStart` | first preorder index of the slice |
| `inStart` | first inorder index of the slice |
| `postStart` | first postorder index of the slice |
| `inorderPositions` | lookup from node label to inorder index |

The stack holds intervals, so a skewed tree cannot overflow the call stack.

A script trace for the sample case:

```
preStart inStart postStart size root postEnd inPos left right
0 0 0 6 1 1 3 3 2
1 0 0 3 2 2 1 1 1
2 0 0 1 4 4 0 0 0
3 2 1 1 5 5 2 0 0
4 4 3 2 3 3 4 0 1
5 5 3 1 6 6 5 0 0
```

Every row has a matching postorder end, so the answer is `yes`.

## Code

**Input and scanner.** One scan loop loads every case and the hand scanner reads all labels.

```nim
const flushBlockBytes = 1 shl 17

type TraversalInterval = object
  preStart: int
  inStart: int
  postStart: int
  size: int

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`hasNextNumber` lets the driver stop cleanly at end of input.
The three traversal arrays are filled in statement order.
`inorderPositions` turns a label lookup into one array read.

**Interval consistency check.** Each popped interval validates one subtree root.

```nim
while hasNextNumber(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  var preorder = newSeq[int](nodeCount)
  var postorder = newSeq[int](nodeCount)
  var inorder = newSeq[int](nodeCount)
  var inorderPositions = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount - 1:
    preorder[nodeIndex] = nextInt(inputData, scanPos)
  for nodeIndex in 0 .. nodeCount - 1:
    postorder[nodeIndex] = nextInt(inputData, scanPos)
  for nodeIndex in 0 .. nodeCount - 1:
    let nodeValue = nextInt(inputData, scanPos)
    inorder[nodeIndex] = nodeValue
    inorderPositions[nodeValue] = nodeIndex
  var pendingIntervals = newSeq[TraversalInterval]()
  pendingIntervals.add(TraversalInterval(preStart: 0, inStart: 0,
      postStart: 0, size: nodeCount))
  var consistent = true
  while pendingIntervals.len > 0 and consistent:
    let current = pendingIntervals.pop()
    if current.size <= 0:
      continue
    let rootValue = preorder[current.preStart]
    if current.size == 1:
      if inorder[current.inStart] != rootValue or postorder[current.postStart] != rootValue:
        consistent = false
      continue
    if postorder[current.postStart + current.size - 1] != rootValue:
      consistent = false
      break
    let rootPosition = inorderPositions[rootValue]
    if rootPosition < current.inStart or rootPosition >= current.inStart + current.size:
      consistent = false
      break
    let leftSize = rootPosition - current.inStart
    let rightSize = current.size - 1 - leftSize
    pendingIntervals.add(TraversalInterval(
        preStart: current.preStart + 1 + leftSize,
        inStart: rootPosition + 1,
        postStart: current.postStart + leftSize,
        size: rightSize))
    pendingIntervals.add(TraversalInterval(
        preStart: current.preStart + 1,
        inStart: current.inStart,
        postStart: current.postStart,
        size: leftSize))
  if consistent:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Singletons need only three equal labels.
A wrong postorder end stops the check at once.
The heap stack keeps a chain of 8000 nodes safe.

## Complexity

Each node enters one interval and leaves it once.

| phase | time | space |
|---|---|---|
| input read | one pass over three label lists | three node arrays |
| interval check | one interval per node | heap stack of intervals |
| output | one write per block | block buffer |

The interval check dominates and stays linear in N.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(N) per case |

A rebuild would also run in linear time but would allocate child links for every node. The interval check only stores slices and stops early on a mismatch.
