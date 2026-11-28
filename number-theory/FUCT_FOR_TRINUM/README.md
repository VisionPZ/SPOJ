# FUCT_FOR_TRINUM — Number triangular (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_TRINUM/>

## Problem

The input gives the height of a number triangle. The task is to print the triangle: row i lists the numbers from i down to 1, separated by single spaces.

Input holds one integer, the height. Output holds one row per line.

| Item | Bound |
|---|---|
| Height | 1 ≤ n ≤ 100 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
```

```
1
2 1
3 2 1
4 3 2 1
5 4 3 2 1
```

## Idea

Each row is its row number counted down to 1, like reading the marks on a ruler backwards. Two nested loops print the rows directly: the outer loop walks the rows, the inner loop walks the values. Printing costs one digit write per printed number, about 15,000 characters at n = 100. Building the triangle from a stored grid first would keep numbers that are never needed again.

## Why It Works

1. Row i holds exactly the values i, i-1, ..., 1, so the inner loop is a countdown from i.
2. A space is written before every value except the first, so no line ends with a space.
3. The program answers one triangle per integer found in the input, which matches the single-number spec.
4. `countdown(rowIndex, 1)` stops after writing the value 1.

| Term | Meaning |
|---|---|
| `height` | triangle height read from input |
| `rowIndex` | current row number, 1..height |
| `columnValue` | value printed in a cell, counting down |
| `appendOutput` | adds text to the block buffer |

The loops touch each printed character once.

A script-traced example from `gen.py`:

```
height 5 row 3: 3 2 1
```

The trace matches the third row of the sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block collects finished rows.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Triangle loop.** This block prints every row as a countdown.

```nim
while scanPos < inputData.len:
  let savedPos = scanPos
  let height = nextInt(inputData, scanPos)
  if scanPos == savedPos:
    break
  for rowIndex in 1..height:
    for columnValue in countdown(rowIndex, 1):
      if columnValue != rowIndex:
        appendOutput(" ")
      appendOutput($(columnValue))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The saved position detects exhausted input and stops the loop.
The row loop runs height times, the inner loop rowIndex times.
Each cell costs one or two buffer appends.

## Complexity

The cost is the input pass plus the printed characters.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Printing | O(n²) digits and spaces | block buffer |

At n = 100 the whole triangle is about 14 KB of text.

| Measure | Big O |
|---|---|
| Time | O(n²) |
| Space | O(N) for the input buffer |

Storing the triangle in a grid first would cost the same O(n²) plus unused memory; direct printing skips it.
