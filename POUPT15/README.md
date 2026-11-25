# POUPT15 — É uma AVL? (SPOJ)

<https://www.spoj.com/problems/POUPT15/>

## Problem

Insert the given keys into an ordinary binary search tree, then decide whether every node has balanced subtree heights. Print `sim` for a balanced tree and `nao` for an unbalanced tree.

The first line holds the test case count. Each case holds positive keys in the range 0 to 64000, read until the sentinel -1. Print one answer line per case.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| keys | 0 to 64000, terminated by -1 |
| judge limit | 5000 ms, 1536 MB |

The sentinel is not part of the tree.

Sample input:

```
3
40 30 25 50 35 60 45 -1
25 36 20 22 30 40 38 28 10 5 12 48 -1
25 36 20 22 30 40 38 28 10 5 12 1 8 15 48 50 45   -1
```

Sample output:

```
sim
sim
nao
```

## Idea

Treat each node like a shelf that must hold two side stacks of nearly equal height. Build the tree by plain insertion, then measure both subtrees at every node. A node fails when its Child heights differ by more than one. A single bottom-up pass computes all heights, because parents are always created before their children.

The real algorithm is a bottom-up height computation over an array of nodes. Each node costs constant work, so the whole case costs linear time in the number of keys. Rescanning the tree from the root for each node would cost quadratic time instead. The takeaway is that creation order gives a ready-made bottom-up order.

## Why It Works

1. Insertion into a binary search tree places each key at one new leaf.
2. A parent node always gets a smaller array index than its children.
3. Scanning node indices in reverse therefore visits children before parents.
4. A missing child contributes height zero, and a present child contributes its stored height.
5. An AVL tree requires the two Child heights to differ by at most one at every node.

| term | meaning |
|---|---|
| `nodeKeys` | key stored at each tree node |
| `leftChildren` | index of the left child, or -1 when absent |
| `rightChildren` | index of the right child, or -1 when absent |
| `nodeHeights` | height of the subtree rooted at each node |
| `balancedTree` | false once any node fails the height test |

The reverse scan reads each stored child height exactly once.

For the first sample the root 40 has a left subtree of height 3 and a right subtree of height 2. The difference is one, so that node passes. Every other node also passes, which yields `sim`.

## Code

**Input and scanner.** The reader captures all lines and the scanner handles the negative sentinel.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The minus branch reads the sentinel correctly.
Buffered output flushes once after all cases.
Each parsed number advances the scan position.

**Tree construction.** Each key extends the array and attaches to the first empty child slot.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var nodeKeys = newSeq[int]()
  var leftChildren = newSeq[int]()
  var rightChildren = newSeq[int]()
  var rootNode = -1
  while scanPos < inputData.len:
    let keyValue = nextInt(inputData, scanPos)
    if keyValue == -1:
      break
    let newNode = nodeKeys.len
    nodeKeys.add keyValue
    leftChildren.add -1
    rightChildren.add -1
    if rootNode == -1:
      rootNode = newNode
    else:
      var currentNode = rootNode
      while true:
        if keyValue < nodeKeys[currentNode]:
          if leftChildren[currentNode] == -1:
            leftChildren[currentNode] = newNode
            break
          currentNode = leftChildren[currentNode]
        else:
          if rightChildren[currentNode] == -1:
            rightChildren[currentNode] = newNode
            break
          currentNode = rightChildren[currentNode]
```

Smaller keys go left and other keys go right.
The sentinel ends the current case only.

**Balance check.** A reverse pass fills heights and flags any uneven node.

```nim
  let nodeTotal = nodeKeys.len
  var nodeHeights = newSeq[int](nodeTotal)
  var balancedTree = true
  var nodeIndex = nodeTotal - 1
  while nodeIndex >= 0:
    var leftHeight = 0
    var rightHeight = 0
    if leftChildren[nodeIndex] != -1:
      leftHeight = nodeHeights[leftChildren[nodeIndex]]
    if rightChildren[nodeIndex] != -1:
      rightHeight = nodeHeights[rightChildren[nodeIndex]]
    nodeHeights[nodeIndex] = 1 + (if leftHeight > rightHeight: leftHeight else: rightHeight)
    if leftHeight - rightHeight > 1 or rightHeight - leftHeight > 1:
      balancedTree = false
    nodeIndex -= 1
  if balancedTree:
    appendOutput("sim")
  else:
    appendOutput("nao")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Children are always ready before their parent.
A height gap of two fails the AVL rule.
The final write empties the block buffer.

## Complexity

Each key walks down the tree once, and each node is visited once during the height pass.

| phase | time | space |
|---|---|---|
| input read | one pass over all keys | one input string |
| tree build | one root-to-leaf walk per key | three node arrays |
| height pass | one visit per node | one height array |

| measure | Big O |
|---|---|
| time | O(k) per case, for k keys |
| space | O(k) per case |

Checking balance by rescanning subtrees from every node would cost O(k^2) time.
The reverse height pass keeps each case linear.
