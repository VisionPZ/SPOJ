# HELP — Help the problem setter (SPOJ)

<https://www.spoj.com/problems/HELP/>

## Problem

Given the shape of an optimal binary search tree on keys 1 to n, find access frequencies that make this exact tree the only optimum.

Each case starts with n. The next n lines give the left and right child labels of nodes 1 to n, with -1 for an empty child. A zero ends the input. Print one line per case with n positive integer frequencies in key order. The judge computes each probability as one frequency divided by the sum of all frequencies. Any set that makes the given tree the unique optimum is accepted.

| Item | Bound |
|---|---|
| Nodes per case | 1 to 50 |
| Child label | -1 or a key from 1 to 50 |
| Frequency | positive integer, at most 2^63 - 1 |
| Cases | until a zero line |
| Judge limit | 1000 ms, 1536 MB |

The 50-node cap and the 64-bit ceiling keep every weight in a small integer.

Sample in, sample out:

```
3
-1 -1
1 3
-1 -1
10
-1 2
-1 3
-1 4
-1 5
-1 6
-1 7
-1 8
-1 9
-1 10
-1 -1
0
```

```
1 1 1
512 256 128 64 32 16 8 4 2 1
```

The statement output is one valid set; the program prints another valid set.

## Idea

Give each node more weight than every node below it, like a manager whose budget outweighs the whole team beneath them. That one rule forces the tree shape.

The program walks the tree bottom-up and assigns one weight per node. Each node gets 1 plus the totals of its two child subtrees. A subtree total is twice its root weight minus 1. This post-order weight assignment visits each node once, so the cost is O(n) per case.

A dynamic program that tests every possible root for every key interval costs O(n^3) per case. It still needs a search over integer weights. The post-order rule writes the answer directly. One visit per node settles both the root choice and uniqueness.

## Why It Works

The construction works because a heavy node cannot stay below another node in an optimal tree.

1. Suppose a node weighs more than all other nodes in its key interval combined. Any tree with that node below the root keeps it on some path. Rotating it up past its parent lowers the cost, since it outweighs the nodes pushed down.
2. The cost drop is strict, so no tree with that node below the root is optimal. It must be the root, and it is the only possible root.
3. After fixing that root, the keys on its left and on its right form independent subproblems. The same argument applies at every node.
4. Setting each weight to 1 plus the child subtree totals makes it exceed all descendants by exactly 1.

The recurrence uses these terms:

| Term | Meaning |
|---|---|
| `leftTotal` | sum of frequencies in the left subtree |
| `rightTotal` | sum of frequencies in the right subtree |
| `nodeWeight[node]` | `1 + leftTotal + rightTotal` |
| `2 * nodeWeight[node] - 1` | sum of frequencies in this subtree |

Every node wins its own interval by a margin of one.

A script-generated trace shows both sample trees:

```
tree 1: root 2
  node 1: totals 0 0 -> weight 1
  node 3: totals 0 0 -> weight 1
  node 2: totals 1 1 -> weight 3
  output: 1 3 1
tree 2: root 1
  node 10: totals 0 0 -> weight 1
  node 9: totals 0 1 -> weight 2
  node 8: totals 0 3 -> weight 4
  node 7: totals 0 7 -> weight 8
  node 6: totals 0 15 -> weight 16
  node 5: totals 0 31 -> weight 32
  node 4: totals 0 63 -> weight 64
  node 3: totals 0 127 -> weight 128
  node 2: totals 0 255 -> weight 256
  node 1: totals 0 511 -> weight 512
  output: 512 256 128 64 32 16 8 4 2 1
```

The chain needs powers of two; the balanced tree needs only small integers.

## Code

**Constants and arrays.** The fixed sizes cover the largest legal case.

```nim
const firstDigitValue = 48
const emptyChild = -1
const maxNodes = 50
const flushBlockBytes = 1 shl 18

var leftChild: array[maxNodes + 1, int]
var rightChild: array[maxNodes + 1, int]
var nodeWeight: array[maxNodes + 1, int]
```

`emptyChild` is the -1 marker from the statement. Each array holds 51 slots, one more than the 50-node cap. All three arrays are reused for every case, so no case allocates a tree.

**Token scanner.** One pass converts digits straight from the input buffer.

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] <= ' ': position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var digitValue = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    digitValue = digitValue * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * digitValue
```

The minus branch handles the -1 child marker. Each byte becomes a digit value without a substring or a parse call. The `position` parameter keeps its value between calls.

**Weight builder.** A post-order walk assigns the frequency of every node.

```nim
proc subtreeTotal(node: int): int =
  if node == emptyChild: return 0
  let leftTotal = subtreeTotal(leftChild[node])
  let rightTotal = subtreeTotal(rightChild[node])
  nodeWeight[node] = 1 + leftTotal + rightTotal
  return 2 * nodeWeight[node] - 1
```

The walk visits at most 50 nodes. An empty child returns 0 and adds nothing. The return value is the total frequency of the subtree rooted at `node`.

**Driver.** One input buffer, one output buffer, and one case loop.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

while true:
  let nodeCount = nextInt(inputData, scanPos)
  if nodeCount == 0: break
  var isChild: array[maxNodes + 1, bool]
  for node in 1 .. nodeCount:
    let leftValue = nextInt(inputData, scanPos)
    let rightValue = nextInt(inputData, scanPos)
    leftChild[node] = leftValue
    rightChild[node] = rightValue
    if leftValue != emptyChild: isChild[leftValue] = true
    if rightValue != emptyChild: isChild[rightValue] = true
  var rootNode = 1
  while rootNode <= nodeCount and isChild[rootNode]: rootNode += 1
  discard subtreeTotal(rootNode)
  for node in 1 .. nodeCount:
    if node > 1: outputBuffer.add ' '
    outputBuffer.add $nodeWeight[node]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The root is the only label that never appears as a child. Each case appends one line to `outputBuffer`, which flushes every 256 KiB. The final `stdout.write` emits the tail.

## Complexity

The work splits into one input pass, one tree walk per case, and one output pass.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| Weight build | one post-order visit per node, at most 50 | three 51-slot arrays |
| Output | one write per 256 KiB block | block buffer |
| Total per case | linear in the node count | constant within the cap |

Every phase stays linear in the case size and the output bytes.

| Measure | Big O |
|---|---|
| Time | O(total input tokens plus total output digits) |
| Space | O(50) for arrays plus one output block |

The input and output passes dominate the run at large case counts. A root-by-root dynamic program costs O(n^3) per case and still cannot name the frequencies directly. The bottom-up rule finishes in one visit per node.
