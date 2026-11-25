# WIRED — Wired (SPOJ)

<https://www.spoj.com/problems/WIRED/>

## Problem

Four colors sit on each side of a box. Connect every left color to the right position showing the same color. Report the four target positions in left-to-right order.

The input starts with the test count. Each case has one line of four left colors and one line of four right colors. Print four positions per case.

| item | bound |
|---|---|
| tests T | not stated |
| colors | integers 1 to 4 |
| positions per side | 4 |
| judge limit | 1000 ms, 1536 MB |

Each case is tiny, so the work per case is constant.

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

Match labels like pairing socks by color: look at each left sock, then find the matching right sock. A fixed grid of four by four pairs does the job without building any map. One scan per left color finds its partner position, and four positions form the answer line.

## Why It Works

1. A wire is valid exactly when both ends show the same color.
2. The right side has four positions, numbered one through four.
3. Scanning all right positions finds the partner for a left position.
4. Repeating for all four left positions yields the required sequence.

| term | meaning |
|---|---|
| `leftColors` | the four colors on the left side |
| `rightColors` | the four colors on the right side |
| `answerPositions` | partner position for each left color |

The comparison is equality of color numbers, not of positions.

Script-generated trace for the first sample case:

```
left position | color | right position | printed
1 | 1 | 4 | 4
2 | 3 | 3 | 3
3 | 4 | 2 | 2
4 | 2 | 1 | 1
```

The printed row is 4 3 2 1, matching the sample.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed by a digit scanner.

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
```

All cases are parsed before any output is written.
The scanner skips spaces and line breaks.
Parsing costs one pass over the input bytes.

**Color matching and output.** Four by four comparisons fill the answer row.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

Fixed arrays avoid per-case allocation.
Positions are stored one-based for the output.
Spaces are written only between positions.

## Complexity

Each case does a fixed amount of work.

| phase | time | space |
|---|---|---|
| input read | one pass over 8t numbers | one input string |
| color matching | sixteen comparisons per case | four small arrays |
| output | four positions per case | block buffer |

Cost grows with the case count, not with any color value.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(1) apart from buffers |

Building a map for each case would add overhead without reducing the constant work.
