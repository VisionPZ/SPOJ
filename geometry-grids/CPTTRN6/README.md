# CPTTRN6 — Character Patterns (Act 6) (SPOJ)

<https://www.spoj.com/problems/CPTTRN6/>

## Problem

Print a grid of `l` horizontal elements and `c` vertical elements. Each rectangle is `h` rows tall and `w` columns wide. Pipes mark vertical rules, dashes mark horizontal rules, plus signs mark crossings, and dots fill the rest.

The input starts with a test count. Each case gives four positive integers: `l`, `c`, `h`, and `w`. Vertical rows precede the first horizontal rule and follow the last. A blank line follows each case, including the last.

| Item | Bound |
|---|---|
| Test cases | fewer than 100 |
| Elements `l` and `c` | positive integers, below 100 |
| Size `h` and `w` | positive integers, below 100 |
| Judge limit | 1000 ms, 1536 MB |

The sample from the statement:

```
3
3 1 2 1
4 4 1 2
2 5 3 2
```

```
.|.
.|.
-+-
.|.
.|.
-+-
.|.
.|.
-+-
.|.
.|.

..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..
--+--+--+--+--
..|..|..|..|..

..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..
--+--+--+--+--+--
..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..
--+--+--+--+--+--
..|..|..|..|..|..
..|..|..|..|..|..
..|..|..|..|..|..

```

## Idea

Picture graph paper: upright rules are pipes, flat rules are dashes, and their intersections are plus signs.

The program prints `h` vertical rows and then one horizontal row, repeated `l` times, followed by `h` more vertical rows. A rule column sits wherever `columnIndex + 1` is a multiple of `w + 1`. A vertical row writes `|` there and `.` elsewhere. A horizontal row writes `+` there and `-` elsewhere.

Every printed character needs one comparison, so the cost tracks the output size.

## Why It Works

1. Rule columns at multiples of `w + 1` are shared by neighboring rectangles.
2. The printed width is `c * (w + 1) + w`, so `w` dot columns follow the final rule.
3. `h` vertical rows precede the first rule row and follow the last, giving `l * (h + 1) + h` rows.
4. A rule row writes plus signs where a vertical row writes pipes, which reproduces the crossings.
5. The blank line after each case matches the sample byte shape, including the final case.

| Term | Meaning |
|---|---|
| `cellHeight` | the number of vertical rows in one rectangle |
| `cellWidth` | the number of dot columns in one rectangle |
| `totalColumns` | the printed width of the whole pattern |
| `outputBuffer` | the single string that collects all pattern bytes |

A traced run of the sample case `2 5 3 2` from `gen.py`:

```
total columns 17
row 0: ..|..|..|..|..|..
row 3: --+--+--+--+--+--
row 7: --+--+--+--+--+--
row 10: ..|..|..|..|..|..
then a blank line after the case
```

The traced rows match the last pattern of the sample.

## Code

**Element-row loop.** One character decision per printed position.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let lineCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let cellHeight = nextInt(inputData, scanPos)
  let cellWidth = nextInt(inputData, scanPos)
  let totalColumns = columnCount * (cellWidth + 1) + cellWidth
  for elementRow in 0 ..< lineCount:
    for insideRow in 0 ..< cellHeight:
      for columnIndex in 0 ..< totalColumns:
        if (columnIndex + 1) mod (cellWidth + 1) == 0:
          appendOutput("|")
        else:
          appendOutput(".")
      outputBuffer.add '\n'
    for columnIndex in 0 ..< totalColumns:
      if (columnIndex + 1) mod (cellWidth + 1) == 0:
        appendOutput("+")
      else:
        appendOutput("-")
    outputBuffer.add '\n'
  for insideRow in 0 ..< cellHeight:
    for columnIndex in 0 ..< totalColumns:
      if (columnIndex + 1) mod (cellWidth + 1) == 0:
        appendOutput("|")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case prints `l * (h + 1) + h` rows. Nim 0.19.4 has no `%` operator, so the code uses `mod`. One buffer collects the bytes before a block write.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| Pattern build | one decision per printed character | one output buffer |
| Output | one write per full block | one block |

The printed character count bounds the middle phase.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

A separate string for each row would add copying to the same character work. One buffer keeps the cost on the pattern itself.
