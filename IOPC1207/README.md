# IOPC1207 — GM plants (SPOJ)

<https://www.spoj.com/problems/IOPC1207/>

## Problem

Track red plants in a 3D box after range flips along one axis at a time. A flip toggles every plant whose chosen coordinate lies in the given range, and a query counts red plants inside a sub-box.

Input starts with T, the number of cases, where T ≤ 10. Each case begins with Nx, Ny, Nz and Q, with dimensions up to 100000 and Q ≤ 5000. Flip queries give an axis and a coordinate range; report queries give six corners of a box. Print one line per report query.

| item | bound |
|---|---|
| cases T | up to 10 |
| dimensions Nx, Ny, Nz | 1 to 100000 |
| queries Q | up to 5000 |
| judge limit | 1000 ms, 1536 MB |

The large dimensions force a logarithmic structure, while the small query count keeps each case cheap.

The sample case has one case, five queries, and two replies.

```
1
3 4 5 5
0 1 2
1 2 3
3 0 0 0 1 2 3
2 3 4
3 1 1 1 2 2 2
```

```
12
4
```

The first report query finds twelve red plants.

## Idea

The trick is to store one parity per coordinate, not one color per plant. Think of a three-way switch circuit. A lamp is on when an odd number of switches are on. Each plant is red when its three coordinate parities add to one.

The algorithm keeps one lazy segment tree per axis. A range flip toggles counts in one tree in logarithmic time. A report query reads three range counts. It combines them with a signed product. Directly storing the full 3D grid would cost Nx times Ny times Nz space.

Track three axes, then turn three counts into one red count.

## Why It Works

1. Every laser operation changes only one coordinate, so parity can be tracked separately for x, y, and z.
2. A plant at (x, y, z) is red exactly when the three parities have odd sum.
3. In a range of length L with p on positions, the sum of minus-one to the parity is L-2p.
4. Multiplying those sums over the three axes gives the sum over every triple in the queried box.
5. Red triples have sign minus one, so the red count is (total triples minus the product) divided by two.
6. A lazy segment tree flips a whole covered node by replacing its count with its length minus the count.

| term | meaning |
|---|---|
| `xTree` | ones counts for x coordinates in a segment tree |
| `lazyFlags` | pending flip markers for tree nodes |
| `xOnes` | number of x coordinates set to one in a query range |
| `spanX` | length of the queried x range |
| `signedSum` | product of the three signed axis sums |

The three signed sums give the exact red count with one division.

The generator compares the formula against a full grid simulation on small cases.

```
x range 0..1: ones 1, zeros 1 -> signed 0
y range 0..2: ones 1, zeros 2 -> signed 1
z range 0..3: ones 0, zeros 4 -> signed 4
total 2 * 3 * 4 = 24, product 0, red (24 - 0) / 2 = 12
```

The twelve red plants match the first sample answer.

## Code

**Input and lazy push.** The reader loads all tokens, and a helper spreads pending flips.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner reads flip and report tokens alike.

`appendOutput` flushes large report blocks.

A pending flip is passed down before visiting either child.

**Range flip.** A covered node swaps its ones count with its zeros count.

```nim
proc pushDown(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
              leftBound: int, middle: int, rightBound: int) =
  if lazyFlags[nodeIndex] == 1:
    let leftChild = nodeIndex * 2
    let rightChild = leftChild + 1
    tree[leftChild] = (middle - leftBound + 1) - tree[leftChild]
    lazyFlags[leftChild] = lazyFlags[leftChild] xor 1
    tree[rightChild] = (rightBound - middle) - tree[rightChild]
    lazyFlags[rightChild] = lazyFlags[rightChild] xor 1
    lazyFlags[nodeIndex] = 0

proc flipRange(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
               leftBound: int, rightBound: int, flipLeft: int, flipRight: int) =
  if flipRight < leftBound or rightBound < flipLeft:
    return
  if flipLeft <= leftBound and rightBound <= flipRight:
    tree[nodeIndex] = (rightBound - leftBound + 1) - tree[nodeIndex]
    lazyFlags[nodeIndex] = lazyFlags[nodeIndex] xor 1
    return
  let middle = (leftBound + rightBound) div 2
  pushDown(tree, lazyFlags, nodeIndex, leftBound, middle, rightBound)
  let leftChild = nodeIndex * 2
  let rightChild = leftChild + 1
  flipRange(tree, lazyFlags, leftChild, leftBound, middle, flipLeft, flipRight)
  flipRange(tree, lazyFlags, rightChild, middle + 1, rightBound, flipLeft, flipRight)
  tree[nodeIndex] = tree[leftChild] + tree[rightChild]
```

Each flip touches logarithmic nodes.

The parent count is rebuilt from both children after recursion.

A single-bit flag records an even number of flips as zero.

**Range count.** A query returns the number of on coordinates in a range.

```nim
proc countOnes(tree: var seq[int], lazyFlags: var seq[int], nodeIndex: int,
               leftBound: int, rightBound: int, queryLeft: int, queryRight: int): int =
  if queryRight < leftBound or rightBound < queryLeft:
    return 0
  if queryLeft <= leftBound and rightBound <= queryRight:
    return tree[nodeIndex]
  let middle = (leftBound + rightBound) div 2
  pushDown(tree, lazyFlags, nodeIndex, leftBound, middle, rightBound)
  let leftChild = nodeIndex * 2
  let rightChild = leftChild + 1
  return countOnes(tree, lazyFlags, leftChild, leftBound, middle, queryLeft, queryRight) +
      countOnes(tree, lazyFlags, rightChild, middle + 1, rightBound, queryLeft, queryRight)
```

Disjoint nodes contribute zero to the count.

Covered nodes return their stored ones count directly.

The push keeps child counts correct before a partial descent.

**Case loop.** Three trees answer every query in one case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let xExtent = nextInt(inputData, scanPos)
  let yExtent = nextInt(inputData, scanPos)
  let zExtent = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var xTree = newSeq[int](4 * xExtent + 5)
  var xLazy = newSeq[int](4 * xExtent + 5)
  var yTree = newSeq[int](4 * yExtent + 5)
  var yLazy = newSeq[int](4 * yExtent + 5)
  var zTree = newSeq[int](4 * zExtent + 5)
  var zLazy = newSeq[int](4 * zExtent + 5)
  for queryIndex in 1 .. queryCount:
    let queryType = nextInt(inputData, scanPos)
    if queryType <= 2:
      let flipLeft = nextInt(inputData, scanPos)
      let flipRight = nextInt(inputData, scanPos)
      if queryType == 0:
        flipRange(xTree, xLazy, 1, 0, xExtent - 1, flipLeft, flipRight)
      elif queryType == 1:
        flipRange(yTree, yLazy, 1, 0, yExtent - 1, flipLeft, flipRight)
      else:
        flipRange(zTree, zLazy, 1, 0, zExtent - 1, flipLeft, flipRight)
    else:
      let xLow = nextInt(inputData, scanPos)
      let yLow = nextInt(inputData, scanPos)
      let zLow = nextInt(inputData, scanPos)
      let xHigh = nextInt(inputData, scanPos)
      let yHigh = nextInt(inputData, scanPos)
      let zHigh = nextInt(inputData, scanPos)
      let xOnes = countOnes(xTree, xLazy, 1, 0, xExtent - 1, xLow, xHigh)
      let yOnes = countOnes(yTree, yLazy, 1, 0, yExtent - 1, yLow, yHigh)
      let zOnes = countOnes(zTree, zLazy, 1, 0, zExtent - 1, zLow, zHigh)
      let spanX = int64(xHigh - xLow + 1)
      let spanY = int64(yHigh - yLow + 1)
      let spanZ = int64(zHigh - zLow + 1)
      let signedSum = (spanX - 2 * int64(xOnes)) * (spanY - 2 * int64(yOnes)) *
          (spanZ - 2 * int64(zOnes))
      let answer = (spanX * spanY * spanZ - signedSum) div 2
      appendOutput($answer)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Tree indices run from zero to one less than each extent.

`int64` holds products up to one quadrillion.

The difference is even because both terms count the same triples.

## Complexity

Each query costs a logarithmic number of tree steps.

| phase | time | space |
|---|---|---|
| input read | one pass over query tokens | one input string |
| flips | O(log N) per flip | three lazy trees |
| reports | three range counts per report | three range results |
| output | one line per report | one output block |

Space grows with the sum of the three extents, not their product.

| measure | Big O |
|---|---|
| time | O(Q * log(max dimension)) |
| space | O(Nx + Ny + Nz) |

Storing every plant would cost Nx times Ny times Nz space, so three axis trees are the decisive gain.
