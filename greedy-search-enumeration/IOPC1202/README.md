# IOPC1202 — Quadrilaterals (SPOJ)
<https://www.spoj.com/problems/IOPC1202/>

## Problem

A square supplies the four edge midpoints of a convex lattice quadrilateral. Sum the areas of every such quadrilateral and give the total modulo 100000007.

The first line gives the case count `testCount`. Each case then has four lines of two integers: the x and y coordinates of one square vertex.

Vertices are distinct and may appear in any order. Print one line per case with the area total modulo 100000007.

The table lists the input and judge limits.

| item | bound |
|---|---|
| test cases | 1 to 25000 |
| vertex coordinate | -1000000000 to 1000000000 |
| answer modulus | 100000007 |
| judge limit | 1000 ms, 1536 MB |

Integers stay exact when we use 64-bit products.

The sample below is verbatim from the statement.

```
2
0 0
1 1
1 0
0 1
0 1
1 0
0 -1
-1 0
```

```
0
4
```

The second square is a diamond, and its total is 4.

## Idea

One lattice corner slides inside a fixed parallelogram, like a loose pin in a hinged frame.

The algorithm combines Varignon's theorem with Pick's theorem. Varignon makes every valid quadrilateral have area twice the square's area.

Pick counts the lattice corners that keep the quadrilateral convex. Each case costs one gcd pair and a few products after reading eight numbers.

Scanning every lattice point in the coordinate box would cost billions of steps. The parallelogram count finishes each case at once.

## Why It Works

1. Varignon's theorem makes the midpoint parallelogram half the quadrilateral's area.
2. Every valid quadrilateral therefore has area `sideSquared` times two.
3. Fix the square vertices in cyclic order and choose one corner freely.
4. Convexity holds exactly when that corner lies inside an open fundamental parallelogram.
5. Pick's theorem gives `interiorPoints` as `sideSquared - sideSteps - otherSideSteps + 1`.

The table names the values used in the formula.

| term | meaning |
|---|---|
| `sideSquared` | squared side length of the square |
| `sideX` | x part of one side vector |
| `otherSideX` | x part of the adjacent side vector |
| `sideSteps` | lattice steps along one side vector |
| `interiorPoints` | number of convex choices for the free corner |

The gcd of each side vector counts its boundary lattice intervals.

For the second sample square, `sideX` is 1 and `sideY` is -1. The adjacent side is (-1, -1), so `sideSquared` is 2.

Both gcd values are 1. Pick gives 2 - 1 - 1 + 1 = 1 convex corner.

Its area is twice 2, so the answer is 4.

Reduce both factors modulo `answerModulus` before multiplying them. A squared coordinate difference can reach 4 times 10 to the 18th power, which fits in `int64`.

## Code

**Input and signed scanning.** The reader accepts the minus signs in vertex coordinates.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 100000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

The scanner stops at each separator and keeps the minus branch. It builds the value one digit at a time.

No library parser touches the input.

**Integer geometry.** Side vectors and their gcds drive the closed formula.

```nim
proc absoluteValue(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc greatestCommonDivisor(first: int64, second: int64): int64 =
  var larger = absoluteValue(first)
  var smaller = absoluteValue(second)
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc squaredDistance(firstX: int64, firstY: int64, secondX: int64, secondY: int64): int64 =
  let deltaX = secondX - firstX
  let deltaY = secondY - firstY
  return deltaX * deltaX + deltaY * deltaY
```

The shortest vertex pair fixes the side length. The two neighbors of the first corner give the side vectors.

Products stay in `int64` to avoid overflow.

**Output.** One reduced area total goes to the block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  var cornerX = newSeq[int64](4)
  var cornerY = newSeq[int64](4)
  for cornerIndex in 0 .. 3:
    cornerX[cornerIndex] = int64(nextInt(inputData, scanPos))
    cornerY[cornerIndex] = int64(nextInt(inputData, scanPos))
  var sideSquared = high(int64)
  for firstCorner in 0 .. 3:
    for secondCorner in firstCorner + 1 .. 3:
      let distanceSquared = squaredDistance(cornerX[firstCorner], cornerY[firstCorner], cornerX[secondCorner], cornerY[secondCorner])
      if distanceSquared < sideSquared:
        sideSquared = distanceSquared
  var sideX = 0.int64
  var sideY = 0.int64
  var otherSideX = 0.int64
  var otherSideY = 0.int64
  var neighboursFound = 0
  for neighbourCorner in 1 .. 3:
    if squaredDistance(cornerX[0], cornerY[0], cornerX[neighbourCorner], cornerY[neighbourCorner]) == sideSquared:
      if neighboursFound == 0:
        sideX = cornerX[neighbourCorner] - cornerX[0]
        sideY = cornerY[neighbourCorner] - cornerY[0]
      else:
        otherSideX = cornerX[neighbourCorner] - cornerX[0]
        otherSideY = cornerY[neighbourCorner] - cornerY[0]
      neighboursFound += 1
  let sideSteps = greatestCommonDivisor(sideX, sideY)
  let otherSideSteps = greatestCommonDivisor(otherSideX, otherSideY)
  let interiorPoints = sideSquared - sideSteps - otherSideSteps + 1
  let answerValue = (interiorPoints mod answerModulus) * ((2 * (sideSquared mod answerModulus)) mod answerModulus) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The buffer flushes by block, not by case. A final write clears any remaining text.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| input read | one pass over 8 numbers per case | one input string |
| side scan | six squared distances | four vertex pairs |
| answer | two gcd calls and products | constant |
| output | one line per case | block buffer |

Both moduli below apply to `testCount` cases.

| measure | Big O |
|---|---|
| time | O(testCount) |
| space | O(testCount) for input; O(1) per case |

A box scan over all lattice coordinates would cost O(coordinate squared) per case. The closed parallelogram count replaces that scan with constant work.
