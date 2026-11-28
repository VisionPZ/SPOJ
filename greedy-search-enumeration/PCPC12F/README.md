# PCPC12F — Snakes and Ladders Again (SPOJ)

<https://www.spoj.com/problems/PCPC12F/>

## Problem

Find the expected number of die throws to travel from square 0 to the last square of a numbered board. Each throw rolls one to six, and landing on a snake head or ladder bottom moves the token again until it rests on a stable square. Overshooting the top leaves the token where it was.

Input holds test cases until end of file. Each case gives rows, columns, snake count, and ladder count, then the snake and ladder lines. Output one expected value per case with exactly three decimal places. The top is always reachable as a stable square.

The statement gives these bounds.

| item | bound |
|---|---|
| rows N | 1 to 10 |
| columns M | 1 to 10 |
| board squares | up to 100 |
| decimal places | exactly 3 |
| judge limit | 409 ms, 1536 MB |

The small board keeps a full linear system affordable.

Sample input:

```
5 10 3 5
16 6
47 26
49 11
1 38
4 14
9 31
40 42
36 44
```

Sample output:

```
30.198
```

## Idea

Treat every square as an equation whose value is one throw plus the average of the next values, like balancing a set of scales.

The algorithm resolves snake and ladder chains, builds one linear equation per non-final square, and solves the system with Gaussian elimination. Each square contributes six terms and one pivot step. A direct simulation would need many rolls to estimate the same average. Solving the equations gives the exact value at once.

## Why It Works

1. Landing on an unstable square starts a chain that ends at one stable square.
2. An overshooting roll leaves the token on the same square and still costs a throw.
3. For a square s, the expected value is one plus the mean value of the six outcomes.
4. The final square has value zero, so its column drops out of the system.
5. Multiplying each equation by six removes fractions and keeps the matrix simple.

The main terms are listed below.

| term | meaning |
|---|---|
| `destination` | the snake or ladder target for a square |
| `finalSquare` | the stable square reached after following a chain |
| `matrix` | the linear system, with the right side in the last column |
| `formatFixed3` | rounds a value to three decimal places |

Resolving chains first makes each equation depend only on stable squares.

A script trace on small boards shows the equations and the sample value.

```
board 1x1 top=1
  E0=6.000
board 1x2 top=2
  E1=6.000
  E0=6.000
sample board 5x10 top=50 E0=30.198
```

Overshoot rolls explain the value six on tiny boards, and the sample value matches the statement.

Rounding uses half up on the scaled value, so the printed digits agree at the third place.

## Code

**Input and helpers.** The reader loads input, and the helpers handle floats and formatting.

```nim
const flushBlockBytes = 1 shl 17
const dieFaces = 6
const equationScale = 6.0
const decimalPlaces = 1000

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

proc hasMoreData(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

proc floatAbs(value: float): float =
  if value < 0.0:
    return -value
  return value

proc formatFixed3(value: float): string =
  let scaled = int(value * float(decimalPlaces) + 0.5)
  let wholePart = scaled div decimalPlaces
  let fractionPart = scaled mod decimalPlaces
  var fractionText = "000"
  fractionText[0] = char(48 + fractionPart div 100)
  fractionText[1] = char(48 + (fractionPart div 10) mod 10)
  fractionText[2] = char(48 + fractionPart mod 10)
  return $wholePart & "." & fractionText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The lookahead ends the input loop at end of file.
The formatter builds three digits without relying on locale settings.
Buffered output writes once per block instead of once per case.

**Chain resolution.** The code reduces each square to the stable square where it rests.

```nim
while hasMoreData(inputData, scanPos):
  let boardRows = nextInt(inputData, scanPos)
  let boardColumns = nextInt(inputData, scanPos)
  let snakeCount = nextInt(inputData, scanPos)
  let ladderCount = nextInt(inputData, scanPos)
  let topSquare = boardRows * boardColumns
  var destination = newSeq[int](topSquare + 1)
  for snakeIndex in 0 ..< snakeCount:
    let snakeHead = nextInt(inputData, scanPos)
    let snakeTail = nextInt(inputData, scanPos)
    destination[snakeHead] = snakeTail
  for ladderIndex in 0 ..< ladderCount:
    let ladderBottom = nextInt(inputData, scanPos)
    let ladderTop = nextInt(inputData, scanPos)
    destination[ladderBottom] = ladderTop
  var finalSquare = newSeq[int](topSquare + 1)
  for square in 1 .. topSquare:
    if finalSquare[square] != 0:
      continue
    var path: seq[int] = @[]
    var current = square
    var steps = 0
    while steps <= topSquare:
      if finalSquare[current] != 0 or destination[current] == 0:
        break
      path.add current
      current = destination[current]
      steps += 1
    var baseSquare = current
    if finalSquare[current] != 0:
      baseSquare = finalSquare[current]
    for node in path:
      finalSquare[node] = baseSquare
    finalSquare[square] = baseSquare
```

A later ladder overwrites an earlier snake on the same square.
The path list lets each chain resolve once and reuse the result.
The step guard prevents a malformed cycle from stalling the run.

**Linear system.** Each square gets one equation, and Gaussian elimination solves them.

```nim
  let stateCount = topSquare
  var matrix = newSeq[seq[float]](stateCount)
  for row in 0 ..< stateCount:
    matrix[row] = newSeq[float](stateCount + 1)
    for col in 0 .. stateCount:
      matrix[row][col] = 0.0
  for state in 0 ..< stateCount:
    matrix[state][stateCount] = equationScale
    var overshootCount = 0
    for dieFace in 1 .. dieFaces:
      let rawSquare = state + dieFace
      if rawSquare > topSquare:
        overshootCount += 1
      else:
        let landing = finalSquare[rawSquare]
        if landing < topSquare:
          matrix[state][landing] -= 1.0
    matrix[state][state] += equationScale - float(overshootCount)
  for pivotCol in 0 ..< stateCount:
    var pivotRow = pivotCol
    for row in pivotCol + 1 ..< stateCount:
      if floatAbs(matrix[row][pivotCol]) > floatAbs(matrix[pivotRow][pivotCol]):
        pivotRow = row
    if pivotRow != pivotCol:
      for col in pivotCol .. stateCount:
        swap matrix[pivotCol][col], matrix[pivotRow][col]
    let pivotValue = matrix[pivotCol][pivotCol]
    if floatAbs(pivotValue) < 1e-12:
      continue
    for col in pivotCol .. stateCount:
      matrix[pivotCol][col] /= pivotValue
    for row in 0 ..< stateCount:
      if row == pivotCol:
        continue
      let factor = matrix[row][pivotCol]
      if floatAbs(factor) < 1e-12:
        continue
      for col in pivotCol .. stateCount:
        matrix[row][col] -= factor * matrix[pivotCol][col]
  appendOutput(formatFixed3(matrix[0][stateCount]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Overshooting rolls add to the diagonal instead of another column.
The final square is absent from the matrix because its value is zero.
Partial pivoting keeps the elimination stable on small systems.

## Complexity

Board size drives both the equation build and the elimination.

| phase | time | space |
|---|---|---|
| input read | one pass over the case data | one input string |
| chain resolution | one pass with memoized paths | two arrays of squares |
| equation build | six terms per square | one square matrix |
| elimination | cubic in the square count | one square matrix |

Building equations is linear, and elimination is the dominant step.

| measure | Big O |
|---|---|
| time | O((N M)^3) per case |
| space | O((N M)^2) per case |

Simulation would need many rolls per case, while elimination returns the exact value directly.

Resolving chains and solving once keeps each small board fast.
