## Problem

A maze has three rows and n columns of square blocks. Each block is empty, straight, or bent, and the program can rotate any block by a multiple of 90 degrees. Decide whether the patterns form a passage from the left edge to the right edge. Print yes when a passage exists and no otherwise.

The bounds and judge limits are:

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded in the statement |
| Columns per case | 1 to 200000 |
| Blocks per column | 3, each of type 0, 1 or 2 |
| Time limit | 10000 ms |
| Memory limit | 1536 MB |

The column count sets the scale, so one column must cost a small fixed amount.

## Idea

Keep four flags after each column. Three flags say which rows have a passage reaching the right side of that column. The fourth flag records a snake passage, which turns back and crosses to the opposite outer row. The program reads one column, updates the four flags, and repeats. Trying every rotation of the whole maze grows exponentially with n.

One column costs a fixed set of boolean tests.

## Why It Works

A straight tile carries a passage across its row or into the adjacent row. A bent tile turns a passage by 90 degrees. Two bent tiles in neighboring rows carry a passage between an outer row and the middle row. A column with types straight, bent, bent, or bent, bent, straight, lets a passage on an outer row reverse and reach the other outer row. The snake flag stores this chance while later all-straight columns keep it alive.

The program starts with all three row flags set and the snake flag clear. Each column updates all four flags from the previous flags and its three tile types. After the last column, a set row flag means a passage spans the maze.

These rules drive the updates:

- A straight top tile keeps a passage on the top row.
- Two bent tiles in the top and middle rows move a passage between those rows.
- Bent, straight, bent tiles in the three rows move a passage between the top and bottom rows.
- The snake flag survives only across columns of three straight tiles.

The generator prints the sample state trace 1110 1010 1101 1110 1111 1111 1111. The final row flags are all set, so the answer is yes.

## Code

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

The scanner skips separators and stops at the buffer end. It reads each integer in one pass and allocates nothing. Checking the end guard keeps the scan inside the buffer. The cost is one pass per input digit.

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

The first loop reads the whole input into one buffer before parsing starts. appendOutput flushes after flushBlockBytes bytes, which caps memory on large test sets. Reusing the buffer avoids one allocation per answer. The cost is one write per 256 KiB of output.

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

The outer loop runs once per case and the inner loop once per column. The four new flags are computed before any old flag is replaced, so one column never reads a half-updated state. The final write flushes the partial block. One column costs three integer reads and a fixed set of tests.

## Complexity

Reading the input costs time linear in the number of integers and space for one buffer. Each column costs fixed time and four boolean flags. Writing costs time linear in the number of cases and space for one output block.

Total time is O(n) per case and total space is O(1) besides the input buffer. A search over all rotations takes exponential time in n.
