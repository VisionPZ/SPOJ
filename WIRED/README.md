# WIRED — Wired (SPOJ)

<https://www.spoj.com/problems/WIRED/>

## Problem

An electrical box has four sockets on the left and four on the right, each labelled with a colour number from 1 to 4. A wire from left socket `i` must go to a right socket with the same number. For each test case, print four numbers: the right-side position each left socket connects to.

| item | bound |
|---|---|
| colours | 1 to 4 |
| sockets per side | 4 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
1 3 4 2
2 4 3 1
1 2 3 4
1 2 3 4
```

Sample output:

```
4 3 2 1
1 2 3 4
```

## Idea

Read the four right-side colours and remember, for each colour, where it sits on the right. Then walk the left side and print the remembered position of each colour. That is the whole job: a tiny table of four entries, built once per case, then four lookups.

## Why It Works

1. The required output line is, position by position, "where is this left colour on the right", so a colour-to-position table answers every socket directly.
2. The program fills the table by comparing every left colour with every right colour and writing `rightIndex + 1` (positions are 1-based). Positions are visited in order, so if a colour appears several times on the right, the last one wins. The independent oracle builds the same table with a dictionary comprehension, which also keeps the last occurrence, so both agree even on repeated colours.
3. A left colour that never appears on the right has no wire. Its table entry stays 0, and the oracle's `get(color, 0)` also gives 0, so missing colours match too.
4. In the sample first case, left colour 1 sits on the right at position 4, colour 3 at position 3, colour 4 at position 2 and colour 2 at position 1, which prints `4 3 2 1` exactly as the statement explains.

| term | meaning |
|---|---|
| `leftColors` | colours on the left, in socket order |
| `rightColors` | colours on the right, in socket order |
| `answerPositions` | for each left socket, the right position of its colour |

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

```nim
const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and newlines alike, so the two-line-per-case layout never has to be tracked.

**Cases and answers.** This block builds the table per case and prints the four positions.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var leftColors: array[4, int]
  var rightColors: array[4, int]
  for colorIndex in 0 .. 3:
    leftColors[colorIndex] = nextInt(inputData, scanPos)
  for colorIndex in 0 .. 3:
    rightColors[colorIndex] = nextInt(inputData, scanPos)
  var answerPositions: array[4, int]
  for leftIndex in 0 .. 3:
    for rightIndex in 0 .. 3:
      if rightColors[rightIndex] == leftColors[leftIndex]:
        answerPositions[leftIndex] = rightIndex + 1
  for leftIndex in 0 .. 3:
    if leftIndex > 0:
      appendOutput(" ")
    appendOutput($(answerPositions[leftIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`answerPositions` starts all zero, which is the answer for a colour with no wire. The later match overwrites earlier ones, fixing the repeated-colour convention described above.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input bytes |
| per case | 16 comparisons, 4 prints | O(1) |
| output | one line per case, buffered | block buffer |

| measure | big O |
|---|---|
| time | O(T) |
| space | O(1) |

Each case is a fixed 4x4 grid, so the cost per case is a constant and the program scales only with the number of cases.
