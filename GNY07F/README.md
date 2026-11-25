# GNY07F — Monkey Vines (SPOJ)

<https://www.spoj.com/problems/GNY07F/>

## Problem

Count the fewest monkeys that can hang from a balanced vine built from nested bracket junctions. Each junction has two sides, both sides must carry the same number of monkeys, and an empty vine needs one monkey. Junctions may nest up to 25 levels deep.

Input starts with the dataset count. Each following line holds one bracket string, possibly empty. Output one line per dataset: the dataset number, a space, and the minimum monkey count.

| item | bound |
|---|---|
| datasets N | 1 to 1000 |
| vine length | 0 to 150 |
| nesting depth | at most 25 |
| judge limit | 12850 ms, 1536 MB |

Nesting depth sets the largest answer, so a recursive count fits the input.

Sample input:

```
3
[]

[[][[]]]
```

Sample output:

```
1 2
2 1
3 8
```

## Idea

Treat each bracket pair like a two-pan balance: the heavier pan decides how many monkeys both pans need. A vine with several junctions in a row needs the largest count among them, because all monkeys jump at once. Walk the string once per level, double the largest child count at each junction, and keep the maximum along a side.

## Why It Works

1. An empty vine needs one monkey.
2. A junction doubles the count needed by its heavier side.
3. Junctions in series share monkeys, so their side needs only the largest count.
4. Splitting the content into two sides cannot change that maximum.
5. Therefore a junction contributes twice the maximum count of the junctions inside it.

| term | meaning |
|---|---|
| `bestCount` | largest monkey count among junctions in the current side |
| `openPos` | position of the bracket that opens the current junction |
| `innerCount` | count needed by the junctions inside one bracket pair |
| `junctionCount` | doubled count for the current bracket pair |

The maximum combines any split of the content into two sides.

A script trace for the third dataset gives:

```
vine        [[][[]]]
inner       [][[]]
left        []          -> 2 * 1 = 2
right       [[]]        -> inner [] = 2, then 2 * 2 = 4
inner max   4
outer       2 * 4 = 8
out         3 8
```

The trace reaches the sample answer without listing where the two sides split.

## Code

**Input and output helpers.** The header and each vine line are read as raw text.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLine(data: string, pos: var int): string =
  var line = ""
  while pos < data.len and data[pos] != '\n':
    if data[pos] != '\r':
      line.add data[pos]
    pos += 1
  if pos < data.len:
    pos += 1
  return line

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

`nextLine` keeps an empty dataset line intact.
`nextInt` reads only the dataset count from the header.
`appendOutput` writes complete blocks, then one final flush ends the stream.

**Recursive count.** Each bracket pair contributes twice the largest count inside it.

```nim
proc vineMonkeys(data: string, startPos: int, endPos: int): int64 =
  var bestCount: int64 = 1
  var pos = startPos
  while pos < endPos:
    if data[pos] == '[':
      let openPos = pos
      var depth = 0
      var closePos = -1
      while pos < endPos:
        if data[pos] == '[':
          depth += 1
        elif data[pos] == ']':
          depth -= 1
          if depth == 0:
            closePos = pos
            break
        pos += 1
      let innerCount = vineMonkeys(data, openPos + 1, closePos)
      let junctionCount = 2 * innerCount
      if junctionCount > bestCount:
        bestCount = junctionCount
      pos = closePos + 1
    else:
      pos += 1
  return bestCount
```

The depth counter finds the matching closing bracket.
`bestCount` starts at one for the empty side.
The call visits every bracket at most twice per nesting level.

**Driver.** Lines are processed in order and results are buffered.

```nim
var headerPos = 0
let header = nextLine(inputData, headerPos)
scanPos = headerPos
var numberPos = 0
let caseCount = nextInt(header, numberPos)
for caseIndex in 1 .. caseCount:
  let vine = nextLine(inputData, scanPos)
  let monkeyCount = vineMonkeys(vine, 0, vine.len)
  var line = $caseIndex & " " & $monkeyCount & "\n"
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
```

`scanPos` advances to the first dataset after the header.
An empty vine line yields one monkey.
Each line is appended to the output buffer once.

## Complexity

Each character is scanned once per nesting level that contains it.

| phase | time | space |
|---|---|---|
| input read | one pass over input lines | one input string |
| bracket matching | one pass per nesting level | recursion stack |
| output | one line per dataset | block buffer |

Depth, not total length, drives the largest count and the stack use.

| measure | Big O |
|---|---|
| time | O(L * D) worst case |
| space | O(D) |

A parser that copied each substring before recursing would add quadratic work on deep vines; the position range avoids those copies.
