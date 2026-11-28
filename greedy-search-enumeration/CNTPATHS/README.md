# CNTPATHS — Count weighted paths (SPOJ)
<https://www.spoj.com/problems/CNTPATHS/>

## Problem

Count walks from vertex 0 to vertex 1 whose total road time stays within T, modulo 1000000007. A walk may revisit vertices, and each visit changes the walk.

Input starts with the case count. Each case gives N and T, then N strings of N characters. Character j on row i is '-' for no road or a digit 1 to 3 for travel time. Print `Case #i: R` on one line per case.

| Constraint | Value |
| --- | --- |
| Cases | up to 10 |
| Vertices N | 2 to 5 |
| Time limit T | 1 to 1000000000 |
| Road time | 1, 2, or 3 |
| Modulus | 1000000007 |
| Judge time | 100 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
3
2 9
-3
3-
5 4
--123
--123
11---
22---
33---
3 100
-21
2-3
13-
```

```
Case #1: 2
Case #2: 4
Case #3: 924247768
```

## Idea

Keep the last three time layers, like a sliding window that remembers every road length still in flight.

Each step builds the next time layer from the previous three layers, because road times are at most three. A running total adds every arrival at vertex 1. The program packs those layers and the total into one vector, then applies its transition matrix T times by repeated squaring. Simulating T steps one by one would take a billion steps. Matrix squaring takes about 30 steps for this vector size. Remember three layers, then jump through time.

## Why It Works

1. A road of weight w ending at time t+1 starts from a walk ending at time t+1-w.
2. Since w is at most three, only layers t, t-1, and t-2 are ever needed.
3. The transition matrix copies old layers down and writes the new layer from all roads.
4. The total cell adds the new arrival count at vertex 1 on every step.
5. Repeated squaring applies the same transition T times in O(log T) matrix products.

| Term | Meaning |
| --- | --- |
| `stateSize` | three layers of vertices plus one running total |
| `transitionMatrix` | one-step rewrite of the state vector |
| `stateVector` | counts for the current time window |
| `prefixIndex` | index of the running total cell |

A script-generated check uses two vertices, T of 9, and a single road of weight 3. Arrivals at vertex 1 happen at times 3 and 9. The running total is therefore 2. Each longer walk needs at least 15 seconds, so no other walk qualifies.

## Code

**Input and scanner.** The reader loads all lines and parses counts and widths with hand scanners.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxWeight = 3

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

proc nextAdjacencyRow(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  result = ""
  var taken = 0
  while taken < width and pos < data.len:
    result.add data[pos]
    pos += 1
    taken += 1
```

The row reader keeps '-' in place.
Each row has exactly N characters.
The integer scanner handles the case counts.

**Output writer and matrix product.** All entries are modular integers held in 64-bit words.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMatrices(leftMatrix: seq[int64], rightMatrix: seq[int64], dimension: int): seq[int64] =
  var productMatrix = newSeq[int64](dimension * dimension)
  var rowIndex = 0
  while rowIndex < dimension:
    var columnIndex = 0
    while columnIndex < dimension:
      var total = int64(0)
      var middleIndex = 0
      while middleIndex < dimension:
        total = (total + leftMatrix[rowIndex * dimension + middleIndex] * rightMatrix[middleIndex * dimension + columnIndex]) mod answerModulus
        middleIndex += 1
      productMatrix[rowIndex * dimension + columnIndex] = total
      columnIndex += 1
    rowIndex += 1
  return productMatrix
```

The dimension is at most sixteen.
Every product fits in a signed 64-bit value.
The output buffer flushes only when full.

**Case solver.** Roads build one transition matrix, and repeated squaring applies it T times.

```nim
let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let timeLimit = int64(nextInt(inputData, scanPos))
  let stateSize = vertexCount * maxWeight + 1
  let prefixIndex = stateSize - 1
  var transitionMatrix = newSeq[int64](stateSize * stateSize)
  var sourceVertex = 0
  while sourceVertex < vertexCount:
    let adjacencyRow = nextAdjacencyRow(inputData, scanPos, vertexCount)
    var targetVertex = 0
    while targetVertex < vertexCount:
      let roadCharacter = adjacencyRow[targetVertex]
      if roadCharacter >= '1' and roadCharacter <= '3':
        let roadWeight = int(roadCharacter) - 48
        let historyRow = (roadWeight - 1) * vertexCount + sourceVertex
        transitionMatrix[targetVertex * stateSize + historyRow] = (transitionMatrix[targetVertex * stateSize + historyRow] + 1) mod answerModulus
        if targetVertex == 1:
          transitionMatrix[prefixIndex * stateSize + historyRow] = (transitionMatrix[prefixIndex * stateSize + historyRow] + 1) mod answerModulus
      targetVertex += 1
    sourceVertex += 1
  var previousVertex = 0
  while previousVertex < vertexCount:
    let firstShiftRow = vertexCount + previousVertex
    let secondShiftRow = 2 * vertexCount + previousVertex
    transitionMatrix[firstShiftRow * stateSize + previousVertex] = 1
    transitionMatrix[secondShiftRow * stateSize + vertexCount + previousVertex] = 1
    previousVertex += 1
  transitionMatrix[prefixIndex * stateSize + prefixIndex] = 1
  var stateVector = newSeq[int64](stateSize)
  stateVector[0] = 1
  var remainingTime = timeLimit
  while remainingTime > 0:
    if (remainingTime and 1) == 1:
      var nextVector = newSeq[int64](stateSize)
      var rowIndex = 0
      while rowIndex < stateSize:
        var total = int64(0)
        var columnIndex = 0
        while columnIndex < stateSize:
          total = (total + transitionMatrix[rowIndex * stateSize + columnIndex] * stateVector[columnIndex]) mod answerModulus
          columnIndex += 1
        nextVector[rowIndex] = total
        rowIndex += 1
      stateVector = nextVector
    transitionMatrix = multiplyMatrices(transitionMatrix, transitionMatrix, stateSize)
    remainingTime = remainingTime shr 1
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $stateVector[prefixIndex] & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Layer shifts move today's counts into yesterday's slot.
The start vector has one walk at vertex 0 and time zero.
The total cell holds the required answer.

## Complexity

The matrix has at most sixteen rows, so each product is small and fixed.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over N squared characters | one input string |
| Matrix build | one entry per road | 16 by 16 matrix |
| Exponentiation | O(log T) matrix products | 16 by 16 matrix |
| Output | one line per case | one output buffer |

| Measure | Big O |
| --- | --- |
| Time per case | O(log T) |
| Space | O(N squared) |

Walking through T seconds one at a time would need up to 10 to the 9 steps.

A small state vector and repeated squaring reduce a billion steps to about thirty.
