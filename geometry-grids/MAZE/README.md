# MAZE — The Long and Narrow Maze (SPOJ)

<https://www.spoj.com/problems/MAZE/>

## Problem

A narrow maze has three rows of rotatable tiles. Decide whether any passage runs from the left edge to the right edge.

Read `t` cases. Each gives `n` columns and three tile types per column. Type 0 is empty, type 1 is straight, and type 2 is bent.

Any tile can rotate by a multiple of 90 degrees. Print `yes` when a full passage exists and `no` otherwise.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | not bounded in the statement |
| Columns per case `n` | 1 to 200000 |
| Blocks per column | 3, each of type 0, 1, or 2 |
| Time limit | 10000 ms |
| Memory limit | 1536 MB |

The column count sets the scale, so one column must cost a fixed amount.

The sample case:

```
1
6
1 0 1
1 2 2
2 2 1
2 2 1
2 2 1
1 2 2
```

```
yes
```

## Idea

Track which rows a passage can reach after each column, plus one special turn that switches sides.

Think of a baton passed down three lanes. One extra runner turns back and crosses to the opposite outer lane, which the snake flag records. Each column updates those four flags from its three tile types.

Selecting rotations for the whole maze takes exponential time; carrying four flags costs a fixed number of tests per column.

One column costs a fixed set of boolean tests, independent of `n`.

## Why It Works

Five facts prove the four flags enough.

1. A straight tile carries a passage across its row or into the adjacent row. A bent tile turns a passage by 90 degrees.
2. Two bent tiles in neighboring rows carry a passage between an outer row and the middle row.
3. Types straight, bent, bent or bent, bent, straight let a passage on an outer row reverse and reach the other outer row. The snake flag stores that chance.
4. The program starts with all three row flags set and the snake flag clear. Each column replaces all four flags from the previous ones.
5. The program computes the four new flags before replacing any old flag. One column never reads a half-updated state.

The flags and their roles:

| Term | Meaning |
| --- | --- |
| `topReach` | passage reaches the right side on the top row |
| `midReach` | passage reaches the right side on the middle row |
| `botReach` | passage reaches the right side on the bottom row |
| `snakeReach` | passage turns back and crosses to the opposite outer row |
| `nextTop` | top-row flag after the current column |
| `nextSnake` | snake flag after the current column |

These four values are the whole state between columns.

A script prints the sample state trace as four-bit words:

```
1110 1010 1101 1110 1111 1111 1111
```

The final word has all three row flags set. A passage therefore spans the maze, and the answer is `yes`.

## Code

**Scanner.** A hand scanner reads each integer from the buffer.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips separators and stops at the buffer end. It reads each integer in one pass and allocates nothing. The end guard keeps the scan inside the buffer.

**Buffers.** One input buffer and one output block handle all cases.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The first loop reads the whole input before parsing starts. `appendOutput` flushes after `flushBlockBytes` bytes, which caps memory on large test sets. Reusing the buffer avoids one allocation per answer.

**Column update.** Four flags advance through every column.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  var topReach = true
  var midReach = true
  var botReach = true
  var snakeReach = false
  for j in 0..<columnCount:
    let topType = nextInt(inputData, scanPos)
    let midType = nextInt(inputData, scanPos)
    let botType = nextInt(inputData, scanPos)
    let nextTop = (topReach and topType == 1) or
                  (midReach and topType == 2 and midType == 2) or
                  (botReach and topType == 2 and midType == 1 and botType == 2) or
                  (snakeReach and topType == 1 and midType == 2 and botType == 2)
    let nextMid = (topReach and topType == 2 and midType == 2) or
                  (midReach and midType == 1) or
                  (botReach and midType == 2 and botType == 2)
    let nextBot = (topReach and topType == 2 and midType == 1 and botType == 2) or
                  (midReach and midType == 2 and botType == 2) or
                  (botReach and botType == 1) or
                  (snakeReach and topType == 2 and midType == 2 and botType == 1)
    let nextSnake = (topReach and topType == 1 and midType == 2 and botType == 2) or
                    (botReach and topType == 2 and midType == 2 and botType == 1) or
                    (snakeReach and topType == 1 and midType == 1 and botType == 1)
    topReach = nextTop
    midReach = nextMid
    botReach = nextBot
    snakeReach = nextSnake
  if topReach or midReach or botReach:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per case and the inner loop once per column. New flags are computed before old flags are replaced. One column costs three integer reads and a fixed set of tests.

## Complexity

Every column takes the same small amount of work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(n) per case | one input buffer |
| Flag updates | O(n) per case | four boolean flags |
| Output | O(t) | one output block |

Constants keep the state tiny even at 200000 columns.

| Measure | Big O |
| --- | --- |
| Time | O(n) per case |
| Space | O(1) beyond the input buffer |

A search over every tile rotation takes exponential time in the column count.
