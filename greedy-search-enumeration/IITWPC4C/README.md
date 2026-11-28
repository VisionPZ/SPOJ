# IITWPC4C — Maggu and Vectors (SPOJ)

<https://www.spoj.com/problems/IITWPC4C/>

## Problem

Decide whether some three of the given vectors are the three sides of a triangle.

Input starts with T. Each case gives N and then N vectors written as two coordinates. Output YES or NO on one line per case.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| vectors N | 1 to 1000 per case |
| each coordinate | -1000 to 1000 |
| judge limit | 1000 ms, 1536 MB |

The pair count reaches half a million per case, so the lookup must be constant time.

Sample input:

```
3
5
3 4 3 -4 5 0 6 0 3 5
2
4 5 -4 -5
3
1 2 3 4 -5 -6
```

Sample output:

```
YES
NO
NO
```

The first case uses vectors 3 4, 3 -4, and 6 0.

## Idea

Lay two arrows tip to tail; the third side runs from the start of the first to the tip of the second.

That third vector equals the sum of the first two, so a triangle exists when some pair sums to a vector in the set. The two addends must not be parallel, or the three segments lie on one line. The program stores every vector in a flat grid and tests each pair in constant time. Trying all triples costs O(N cubed) and is too slow for N equal to 1000.

## Why It Works

1. Place two side vectors head to tail; their sum is the closing side vector.
2. The sum belongs to the same triangle, so it must appear among the input vectors.
3. Parallel addends put all three segments on one line and give no triangle.
4. Coordinates run from -1000 to 1000, so sums stay in -2000 to 2000.
5. A two-dimensional offset grid answers each sum query in one array read.

| term | meaning |
|---|---|
| `vectorX` | first coordinate of each input vector |
| `vectorY` | second coordinate of each input vector |
| `present` | flat grid marking vectors seen in the current case |
| `gridWidth` | side length of the grid, covering -2000 through 2000 |
| `gridOffset` | shift that maps coordinate -2000 to grid index zero |

The grid is cleared after each case, so memory holds one case at a time.

A script traces the first sample case:

```
pair (3,4) + (3,-4)
cross = 3*(-4) - 4*3 = -24, not zero
sum = (6,0), present in the input
answer YES
```

The trace identifies the same three vectors as the sample explanation.

## Code

**Input, signed scan, and grid lookup.** The reader handles negative coordinates and maps sums to grid cells.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const gridWidth = 4001
const gridOffset = 2000
const gridLimit = 2000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc hasVector(present: seq[bool], xValue, yValue: int): bool =
  if xValue == 0 and yValue == 0:
    return false
  if xValue < -gridLimit or xValue > gridLimit or yValue < -gridLimit or yValue > gridLimit:
    return false
  return present[(xValue + gridOffset) * gridWidth + (yValue + gridOffset)]
```

The scanner keeps the minus sign when one is present.
The zero vector is rejected because it cannot be a side.
Out-of-grid sums are rejected before indexing.

**Buffered output.** One string collects all case answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each answer is one short line.
The tail is written once after all cases.

**Pair scan and cleanup.** Each pair produces one candidate sum vector.

```nim
let caseCount = nextSignedInt(inputData, scanPos)
var present = newSeq[bool](gridWidth * gridWidth)
for caseIndex in 0 .. caseCount - 1:
  let vectorCount = nextSignedInt(inputData, scanPos)
  var vectorX = newSeq[int](vectorCount)
  var vectorY = newSeq[int](vectorCount)
  for vectorIndex in 0 .. vectorCount - 1:
    let xValue = nextSignedInt(inputData, scanPos)
    let yValue = nextSignedInt(inputData, scanPos)
    vectorX[vectorIndex] = xValue
    vectorY[vectorIndex] = yValue
    present[(xValue + gridOffset) * gridWidth + (yValue + gridOffset)] = true
  var found = false
  for leftIndex in 0 .. vectorCount - 1:
    for rightIndex in leftIndex + 1 .. vectorCount - 1:
      let leftX = vectorX[leftIndex]
      let leftY = vectorY[leftIndex]
      let rightX = vectorX[rightIndex]
      let rightY = vectorY[rightIndex]
      if leftX * rightY - leftY * rightX == 0:
        continue
      if hasVector(present, leftX + rightX, leftY + rightY):
        found = true
        break
    if found:
      break
  for vectorIndex in 0 .. vectorCount - 1:
    present[(vectorX[vectorIndex] + gridOffset) * gridWidth + (vectorY[vectorIndex] + gridOffset)] = false
  if found:
    appendOutput "YES\n"
  else:
    appendOutput "NO\n"
stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero cross product skips parallel addends.
The scan stops at the first valid pair.
Grid cells are cleared using the stored vectors of the finished case.

## Complexity

Each case marks its vectors, scans pairs, then clears the marks.

| phase | time | space |
|---|---|---|
| input read | one pass over 2N coordinates | one input string |
| grid marking | N writes | one flat grid |
| pair scan | N squared constant-time checks | two coordinate arrays |
| cleanup | N writes | none |

The grid is reused across cases instead of reallocated.

| measure | Big O |
|---|---|
| time | O(N^2) per case |
| space | O(4001^2) for the grid |

Checking all triples costs O(N cubed) and cannot meet the limit.
Pair sums plus a flat grid are the takeaway.
