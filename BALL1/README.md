# BALL1 — Ball (SPOJ)
<https://www.spoj.com/problems/BALL1/>

## Problem

A ball rolls at forty-five degrees across a chessboard and bounces off each edge it meets.
Count the squares that receive an odd number of visits before the ball returns.

The first line gives the dataset count. Each next line gives board width, board height, start column, and start row. The board holds at most 10 to the ninth power squares, and the start square touches an edge. Print one odd-square count per dataset.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Datasets d | 1 to 10 |
| Board fields | at most 10 to the ninth power |
| Start field | adjacent to an edge |
| Judge time | 5 s |
| Judge memory | 1536 MB |

A closed form replaces a bounce-by-bounce simulation over a billion fields.

The sample input and its expected output follow byte for byte.

```
2
13 6 1 5
10 7 1 5
```

```
2
22
```


## Idea

Fold the bouncing path into a straight diagonal, like tracing a line through a corridor of mirrored copies of the board.
The program reduces each board dimension by one, which converts cell indices to grid lines. It swaps the axes when the start row is not on the bottom edge, so one coordinate becomes zero.
The gcd (greatest common divisor) of the two reduced dimensions gives the path period. A special case returns two, and the general case uses a closed formula for diagonal crossings.
Simulating every bounce could visit up to a billion squares, while gcd and a few products finish at once.
The geometry collapses to one divisor and one arithmetic expression.

## Why It Works

1. Subtracting one from each dimension converts cell coordinates into grid-line coordinates.
2. Swapping the axes when needed puts the start row on the bottom edge, which makes the path uniform.
3. The gcd of the reduced dimensions gives the number of repeated diagonal segments.
4. If the start column is a multiple of that gcd, exactly two squares receive an odd visit.
5. Otherwise the closed form counts crossings over one period and returns the total.

Four terms describe the reduction.

| Term | Meaning |
| --- | --- |
| reduced dimension | board side minus one |
| gcd | divisor giving the path period |
| period | repeated diagonal segment count |
| odd square | field visited an odd number of times |

They explain why no simulation loop appears in the program.

A script check of `13 6 1 5` reduces the board to 12 by 5. Swapping gives 5 by 12 with start (4,0).
The gcd is 1, and 4 is a multiple of 1, so the answer is 2.
For `10 7 1 5` the reduced board is 6 by 9 and the gcd is 3. The formula gives 36 minus 24 plus 4 plus 6, which is 22.

## Code

**Integer parser.**
```nim
proc nextInteger(sourceData: string, i: var int): int64 =
  while i < sourceData.len and sourceData[i] < '0':
    i += 1
  var parsedValue: int64 = 0
  while i < sourceData.len and sourceData[i] >= '0':
    parsedValue = parsedValue * 10 + int64(int(sourceData[i]) - zeroDigitValue)
    i += 1
  return parsedValue
```

The parser reads board sizes and start coordinates as 64-bit integers. It skips all separators between values. One pass over the input buffer supplies every dataset.

**Greatest common divisor.**
```nim
proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

The loop applies Euclid's rule with repeated remainders. It stops when the remainder becomes zero. The result sets the path period.

**Closed-form driver.**
```nim
let dataSetCount = nextInteger(inputData, i)
var j: int64 = 0
while j < dataSetCount:
  var boardWidth = nextInteger(inputData, i) - 1
  var boardHeight = nextInteger(inputData, i) - 1
  var startColumn = nextInteger(inputData, i) - 1
  var startRow = nextInteger(inputData, i) - 1
  if startRow != 0 and startRow != boardHeight:
    swap(boardWidth, boardHeight)
    swap(startColumn, startRow)
  let commonDivisor = greatestCommonDivisor(boardWidth, boardHeight)
  var oddFieldCount: int64
  if startColumn mod commonDivisor == 0:
    oddFieldCount = 2
  else:
    let widthSegments = boardWidth div commonDivisor
    let heightSegments = boardHeight div commonDivisor
    oddFieldCount = 2 * boardWidth * boardHeight div commonDivisor -
                    4 * widthSegments * heightSegments +
                    2 * widthSegments + 2 * heightSegments
  outputBuffer.add $oddFieldCount
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  j += 1

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The driver reduces dimensions and swaps axes when needed. It branches on whether the start column divides evenly. One answer line is appended per dataset.


## Complexity

Only the gcd loop depends on the board size, and it takes logarithmic steps.

| Phase | Time | Space |
| --- | --- | --- |
| input parse | O(d) | one buffer |
| gcd | O(log max dimension) | constant |
| closed form | O(1) | constant |

The output buffer flushes at a block boundary across datasets.

Big O uses dataset count d and largest board dimension M.

| Measure | Big O |
| --- | --- |
| time | O(d log M) |
| space | O(1) |

Bounce simulation would touch up to 10 to the ninth power squares per case.
