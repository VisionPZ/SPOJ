# CARDFLIP — Dolan and Nephews (SPOJ)

<https://www.spoj.com/problems/CARDFLIP/>

## Problem

A stack holds cards numbered 1 through n from top to bottom. nephews reverse a consecutive block of positions or ask which card sits at a position or where a given card sits. Answer every question after all earlier reversals.

The first line holds n and q. Each of the next q lines holds an operation number, then one or two positions. Operation 1 takes i and j and reverses that position range. Operation 2 takes a position and asks for its card. Operation 3 takes a card and asks for its position.

Output one line per question.

| item | bound |
|---|---|
| cards n | 1 to 100000 |
| operations q | 1 to 100000 |
| judge limit | 500 ms, 1536 MB |

Positions and card labels both stay within 1 through n.

Sample input:

```
10 5
1 2 6
2 5
1 4 9
3 4
2 4
```

Sample output:

```
3
9
9
```

## Idea

Picture the deck as a row of beads on a string, where cutting and rejoining segments is cheaper than sliding every bead. An implicit treap stores the deck in position order without storing positions. Each node keeps its subtree size, so splitting and merging move whole segments in logarithmic time. A naive list reversal touches every card in the range, while the treap reverses a block by swapping two child pointers. Position queries walk down by subtree size, and card queries walk up through parent links. Each operation costs logarithmic time, so the long input stays manageable.

## Why It Works

1. An implicit treap orders nodes by their position in the sequence, not by a stored key.
2. Splitting after k nodes separates the first k cards from the rest.
3. Reversing a middle treap swaps its children and marks a pending flag.
4. Pushing that flag reverses the children, so every descendant stays correct.
5. A node index equals its card number, so a card query starts at a known node.

| term | meaning |
|---|---|
| `subtreeSize` | number of cards in a node subtree |
| `reverseFlag` | marks children already swapped but not yet pushed down |
| `mergeTrees` | joins two treaps whose cards are in sequence order |
| `splitTree` | cuts a treap after a given number of positions |
| `rankOfNode` | position of a card, using parent links and pending flags |

The flag rule keeps reversal lazy without changing subtree sizes.

A script trace over the sample operations gives these decks and answers:

```
operation        deck after operation                     question
1 2 6            1 6 5 4 3 2 7 8 9 10                   -
2 5              1 6 5 4 3 2 7 8 9 10                   3
1 4 9            1 6 5 9 8 7 2 3 4 10                   -
3 4              1 6 5 9 8 7 2 3 4 10                   9
2 4              1 6 5 9 8 7 2 3 4 10                   9
```

The three answers match the sample output exactly.

A card query must flip its rank when an ancestor has a pending flag, since that ancestor reverses the segment containing the card.

## Code

**Input and node arrays.** The reader loads all operations, and node indices double as card labels.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

let cardCount = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)

var leftChild = newSeq[int](cardCount + 1)
var rightChild = newSeq[int](cardCount + 1)
var parentNode = newSeq[int](cardCount + 1)
var subtreeSize = newSeq[int](cardCount + 1)
var nodePriority = newSeq[int](cardCount + 1)
var reverseFlag = newSeq[bool](cardCount + 1)
```

Card number k uses node k, so no separate card map is needed.
The priority values come from a fixed xorshift stream.
Every subtree size starts as one for a freshly created node.

**Treap updates.** Pull refreshes sizes, and push spreads pending reversal to children.

```nim
var randomState: uint32 = 2463534242'u32
proc nextPriority(): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  return int(randomState)

proc pullNode(nodeIndex: int) =
  subtreeSize[nodeIndex] = subtreeSize[leftChild[nodeIndex]] + subtreeSize[rightChild[nodeIndex]] + 1
  if leftChild[nodeIndex] != 0:
    parentNode[leftChild[nodeIndex]] = nodeIndex
  if rightChild[nodeIndex] != 0:
    parentNode[rightChild[nodeIndex]] = nodeIndex

proc pushNode(nodeIndex: int) =
  if reverseFlag[nodeIndex]:
    let firstChild = leftChild[nodeIndex]
    let secondChild = rightChild[nodeIndex]
    if firstChild != 0:
      let firstLeft = leftChild[firstChild]
      leftChild[firstChild] = rightChild[firstChild]
      rightChild[firstChild] = firstLeft
      reverseFlag[firstChild] = not reverseFlag[firstChild]
    if secondChild != 0:
      let secondLeft = leftChild[secondChild]
      leftChild[secondChild] = rightChild[secondChild]
      rightChild[secondChild] = secondLeft
      reverseFlag[secondChild] = not reverseFlag[secondChild]
    reverseFlag[nodeIndex] = false
```

Push swaps each child internally and clears the parent flag.
Pull reconnects parent links after any child change.
Neither update changes a subtree size.

**Split, merge, and queries.** Splits isolate a range, queries use sizes and parent links.

```nim
proc mergeTrees(firstRoot: int, secondRoot: int): int =
  if firstRoot == 0:
    if secondRoot != 0:
      parentNode[secondRoot] = 0
    return secondRoot
  if secondRoot == 0:
    parentNode[firstRoot] = 0
    return firstRoot
  if nodePriority[firstRoot] > nodePriority[secondRoot]:
    pushNode(firstRoot)
    let mergedRight = mergeTrees(rightChild[firstRoot], secondRoot)
    rightChild[firstRoot] = mergedRight
    pullNode(firstRoot)
    parentNode[firstRoot] = 0
    return firstRoot
  pushNode(secondRoot)
  let mergedLeft = mergeTrees(firstRoot, leftChild[secondRoot])
  leftChild[secondRoot] = mergedLeft
  pullNode(secondRoot)
  parentNode[secondRoot] = 0
  return secondRoot

proc splitTree(rootIndex: int, prefixSize: int, leftRoot: var int, rightRoot: var int) =
  if rootIndex == 0:
    leftRoot = 0
    rightRoot = 0
    return
  pushNode(rootIndex)
  if subtreeSize[leftChild[rootIndex]] >= prefixSize:
    var newLeft = 0
    splitTree(leftChild[rootIndex], prefixSize, leftRoot, newLeft)
    leftChild[rootIndex] = newLeft
    pullNode(rootIndex)
    parentNode[rootIndex] = 0
    rightRoot = rootIndex
  else:
    var newRight = 0
    splitTree(rightChild[rootIndex], prefixSize - subtreeSize[leftChild[rootIndex]] - 1, newRight, rightRoot)
    rightChild[rootIndex] = newRight
    pullNode(rootIndex)
    parentNode[rootIndex] = 0
    leftRoot = rootIndex
```

Merge keeps the higher priority node as the local root.
Split pushes before descending so sizes reflect the current order.
Both procedures reset the new root parent to zero.

```nim
proc nodeAtPosition(rootIndex: int, position: int): int =
  var current = rootIndex
  var remaining = position
  while true:
    pushNode(current)
    let leftSize = subtreeSize[leftChild[current]]
    if remaining <= leftSize:
      current = leftChild[current]
    elif remaining == leftSize + 1:
      return current
    else:
      remaining = remaining - leftSize - 1
      current = rightChild[current]

proc rankOfNode(nodeIndex: int): int =
  var current = nodeIndex
  var answer = subtreeSize[leftChild[current]] + 1
  while parentNode[current] != 0:
    let ancestor = parentNode[current]
    let leftSize = subtreeSize[leftChild[ancestor]]
    let rightSize = subtreeSize[rightChild[ancestor]]
    if reverseFlag[ancestor]:
      if current == leftChild[ancestor]:
        answer = leftSize + 1 - answer
      else:
        answer = leftSize + rightSize + 2 - answer
    elif current == rightChild[ancestor]:
      answer = answer + leftSize + 1
    current = ancestor
  return answer
```

A position query walks down using subtree sizes.
A card query walks up and flips ranks across flagged ancestors.
The returned node index is the card number.

**Driver.** The main loop applies each nephew operation and flushes the buffer once.

```nim
var treapRoot = 0
for cardNumber in 1 .. cardCount:
  subtreeSize[cardNumber] = 1
  nodePriority[cardNumber] = nextPriority()
  treapRoot = mergeTrees(treapRoot, cardNumber)

for operationIndex in 0 .. operationCount - 1:
  let nephewNumber = nextInt(inputData, scanPos)
  if nephewNumber == 1:
    let leftPosition = nextInt(inputData, scanPos)
    let rightPosition = nextInt(inputData, scanPos)
    var middleTree = 0
    var tailTree = 0
    splitTree(treapRoot, rightPosition, middleTree, tailTree)
    var headTree = 0
    splitTree(middleTree, leftPosition - 1, headTree, middleTree)
    if middleTree != 0:
      let firstChild = leftChild[middleTree]
      leftChild[middleTree] = rightChild[middleTree]
      rightChild[middleTree] = firstChild
      reverseFlag[middleTree] = not reverseFlag[middleTree]
      parentNode[middleTree] = 0
    treapRoot = mergeTrees(mergeTrees(headTree, middleTree), tailTree)
  elif nephewNumber == 2:
    let askedPosition = nextInt(inputData, scanPos)
    appendOutput($(nodeAtPosition(treapRoot, askedPosition)))
    outputBuffer.add '\n'
  else:
    let askedCard = nextInt(inputData, scanPos)
    appendOutput($(rankOfNode(askedCard)))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Two splits isolate the reversed range.
Swapping children marks the reversal without touching the range.
All answers leave through the single block buffer.

## Complexity

Each operation performs a constant number of treap traversals.

| phase | time | space |
|---|---|---|
| build | merge each card once | one node per card |
| reverse | two splits and two merges | recursion stack |
| query | one tree traversal | recursion stack |
| output | one flush per block | block buffer |

Treap height drives every operation cost.

| measure | Big O |
|---|---|
| time | O(q log n) expected |
| space | O(n) |

Reversing a list directly would cost O(n) per operation, which is slower.
The treap turns range reversal into pointer swaps, which is the takeaway.
