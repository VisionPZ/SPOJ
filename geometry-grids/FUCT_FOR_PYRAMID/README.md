# FUCT_FOR_PYRAMID — Star pyramid (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_PYRAMID/>

## Problem

The input gives the height of a star pyramid. The task is to print the pyramid: row i has (n − i) pairs of leading spaces, then 2i − 1 stars separated by single spaces.

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
        *
      * * *
    * * * * *
  * * * * * * *
* * * * * * * * *
```

## Idea

Each row is a fixed indent plus a fixed star run: the indent shrinks by two spaces each row and the star run grows by two stars. Analogy: a party garland hung from the center, one longer strand per row. The program writes the indent with `repeat`, then alternates star and space, costing one buffer append per character. Storing the whole pyramid first would keep thousands of characters that are printed once and never read.

## Why It Works

1. Row i needs 2(n − i) leading spaces, so the pyramid tip sits centered.
2. Row i holds 2i − 1 stars, giving odd widths 1, 3, 5, ...
3. Spaces go between stars only, so no row ends with a space.
4. The program answers one pyramid per integer in the input, matching the single-number spec.

| Term | Meaning |
|---|---|
| `height` | pyramid height read from input |
| `rowIndex` | current row number, 1..height |
| `starCount` | stars in the row, 2 × rowIndex − 1 |
| `appendOutput` | adds text to the block buffer |

The loops touch each printed character once.

A script-traced example from `gen.py`:

```
height 5 row 3:     * * * * *
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

**Pyramid loop.** This block writes the indent, then the star run.

```nim
while scanPos < inputData.len:
  let savedPos = scanPos
  let height = nextInt(inputData, scanPos)
  if scanPos == savedPos:
    break
  for rowIndex in 1..height:
    appendOutput(repeat(' ', 2 * (height - rowIndex)))
    let starCount = 2 * rowIndex - 1
    for starIndex in 1..starCount:
      if starIndex != 1:
        appendOutput(" ")
      appendOutput("*")
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The saved position detects exhausted input and stops the loop.
`repeat(' ', 2 * (height - rowIndex))` builds the shrinking indent in one call.
Each row costs starCount + 1 appends.

## Complexity

The cost is the input pass plus the printed characters.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Printing | O(n²) spaces, stars, and newlines | block buffer |

At n = 100 the whole pyramid is about 30 KB of text.

| Measure | Big O |
|---|---|
| Time | O(n²) |
| Space | O(N) for the input buffer |

Building each row by repeated string concatenation would copy the row many times; buffer appends write each character once.
