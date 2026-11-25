# G11182 — CRUZ Grado 11 (SPOJ)

<https://www.spoj.com/problems/G11182/>

## Problem

Draw double leading word crosses from lines holding four uppercase words. Each pair crosses at its earliest shared letter, with the two horizontal words on one line.

Each input line contains four space-separated words, and a line holding a single # ends the input. Each output set repeats the input line, then draws the two vertical words around one shared line. Three spaces separate the horizontal words, and a blank line separates output sets. An impossible pair prints Unable to make two crosses.

The bounds that shape the drawing:

| item | bound |
|---|---|
| words per line | 4 |
| letters per word | 1 to 10 uppercase |
| input lines | until a line holding a single # |
| judge limit | 1000 ms, 1536 MB |

The ten-letter word length bounds every printed row.

Sample input:

```
MATCHES CHEESECAKE PICNIC EXCUSES
PEANUT BANANA VACUUM GREEDY
#
```

Sample output:

```
MATCHES CHEESECAKE PICNIC EXCUSES
 C
 H
 E
 E
 S
 E          E
 C          X
MATCHES   PICNIC
 K          U
 E          S
            E
            S

PEANUT BANANA VACUUM GREEDY
Unable to make two crosses
```

## Idea

Picture each vertical word as a ribbon hanging from a hook, with the shared letter at hook height. Two hooks share one horizontal baseline. The leading cross is the earliest horizontal letter found in the vertical word, paired with its earliest position there. A nested scan finds that pair, then the drawing prints letters above, on, and below the baseline. Trying every alignment would draw many invalid crosses. Find two leading pairs, then paint two letter columns on one baseline.

## Why It Works

1. The outer scan picks the earliest horizontal letter that occurs in the vertical word.
2. The inner scan picks that letter's earliest position in the vertical word.
3. The second column starts after the first horizontal word plus three spaces.
4. Letters before the shared index sit above the baseline, and later letters sit below.
5. A missing shared letter makes the crosses impossible, so the message replaces the drawing.

The names below drive the cross search and painting:

| term | meaning |
|---|---|
| `findCrossIndex` | returns the leading shared position pair |
| `firstColumn` | column of the first vertical word |
| `rightColumn` | column of the second vertical word |
| `aboveCount` | rows painted above the baseline |
| `belowCount` | rows painted below the baseline |

These values fix both vertical columns and the row counts.

A script trace from the generator:

```
cross 1: (1, 7) letter A
cross 2: (2, 2) letter C
line row: 'MATCHES   PICNIC'
hang 1 above (top to line): CHEESEC
hang 1 below the line: KE
hang 2 above: EX  below: USES
```

The trace places CHEESEC above and KE below at column 1, matching the sample drawing.

## Code

**Input and drawing helpers.** The reader joins lines, and two helpers find and paint columns.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const rowCells = 128

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc findCrossIndex(horizontalWord: string, verticalWord: string): (int, int) =
  var horizontalIndex = 0
  while horizontalIndex < horizontalWord.len:
    var verticalIndex = 0
    while verticalIndex < verticalWord.len:
      if horizontalWord[horizontalIndex] == verticalWord[verticalIndex]:
        return (horizontalIndex, verticalIndex)
      verticalIndex += 1
    horizontalIndex += 1
  return (-1, -1)

proc appendCrossRow(leftColumn: int, leftCharacter: char, rightColumn: int, rightCharacter: char) =
  var row = repeat(' ', rowCells)
  var lastColumn = -1
  if leftCharacter != chr(0):
    row[leftColumn] = leftCharacter
    lastColumn = leftColumn
  if rightCharacter != chr(0):
    row[rightColumn] = rightCharacter
    if rightColumn > lastColumn:
      lastColumn = rightColumn
  if lastColumn >= 0:
    appendOutput(row[0 .. lastColumn])
  appendOutput("\n")
```

The nested scan checks horizontal letters in order.
The pair (-1, -1) signals a missing shared letter.
Each painted row stops at its last occupied cell.

**Line parsing.** Trimming and tokenising yield the four words or end the input.

```nim
var scanPos = 0
var setNumber = 0
while scanPos < inputData.len:
  var lineStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  var lineEnd = scanPos
  if scanPos < inputData.len:
    scanPos += 1
  while lineEnd > lineStart and (inputData[lineEnd - 1] == '\r' or inputData[lineEnd - 1] == ' ' or inputData[lineEnd - 1] == '\t'):
    lineEnd -= 1
  if lineEnd == lineStart:
    continue
  if lineEnd - lineStart == 1 and inputData[lineStart] == '#':
    break

  var words = newSeq[string](0)
  var tokenStart = lineStart
  while tokenStart < lineEnd and words.len < 4:
    while tokenStart < lineEnd and (inputData[tokenStart] == ' ' or inputData[tokenStart] == '\t'):
      tokenStart += 1
    var tokenEnd = tokenStart
    while tokenEnd < lineEnd and inputData[tokenEnd] != ' ' and inputData[tokenEnd] != '\t':
      tokenEnd += 1
    if tokenEnd > tokenStart:
      words.add inputData[tokenStart ..< tokenEnd]
    tokenStart = tokenEnd
  if words.len != 4:
    continue

  if setNumber > 0:
    appendOutput("\n")
  setNumber += 1
  appendOutput(inputData[lineStart ..< lineEnd])
  appendOutput("\n")
```

Trailing carriage returns and spaces are trimmed.
A single # stops the whole input.
Sets after the first get one leading blank line.

**Cross placement.** Two leading pairs set the columns, and rows fill both sides.

```nim
  let firstCross = findCrossIndex(words[0], words[1])
  let secondCross = findCrossIndex(words[2], words[3])
  if firstCross[0] < 0 or secondCross[0] < 0:
    appendOutput("Unable to make two crosses\n")
    continue

  let firstColumn = firstCross[0]
  let firstVerticalIndex = firstCross[1]
  let secondColumn = secondCross[0]
  let secondVerticalIndex = secondCross[1]
  let rightColumn = words[0].len + 3 + secondColumn

  let aboveCount = max(firstVerticalIndex, secondVerticalIndex)
  var rowOffset = 0
  while rowOffset < aboveCount:
    let firstIndex = rowOffset - (aboveCount - firstVerticalIndex)
    let secondIndex = rowOffset - (aboveCount - secondVerticalIndex)
    let leftCharacter = if firstIndex >= 0: words[1][firstIndex] else: chr(0)
    let rightCharacter = if secondIndex >= 0: words[3][secondIndex] else: chr(0)
    appendCrossRow(firstColumn, leftCharacter, rightColumn, rightCharacter)
    rowOffset += 1

  appendOutput(words[0])
  appendOutput("   ")
  appendOutput(words[2])
  appendOutput("\n")

  let belowFirst = words[1].len - firstVerticalIndex - 1
  let belowSecond = words[3].len - secondVerticalIndex - 1
  let belowCount = max(belowFirst, belowSecond)
  rowOffset = 0
  while rowOffset < belowCount:
    let firstIndex = firstVerticalIndex + 1 + rowOffset
    let secondIndex = secondVerticalIndex + 1 + rowOffset
    let leftCharacter = if firstIndex < words[1].len: words[1][firstIndex] else: chr(0)
    let rightCharacter = if secondIndex < words[3].len: words[3][secondIndex] else: chr(0)
    appendCrossRow(firstColumn, leftCharacter, rightColumn, rightCharacter)
    rowOffset += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The second column starts three cells past the first word.
Above rows and below rows use the same column positions.
The final write drains the remaining buffer.

## Complexity

Each line pays one bounded search and one bounded painting pass.

| phase | time | space |
|---|---|---|
| input read | one pass over the input text | one input string |
| cross search | at most 100 letter comparisons per pair | four word slices |
| painting | at most ten rows per set | one fixed row template |

The word length keeps both the search and the painted rows small.

| measure | Big O |
|---|---|
| time | O(L) per line for L input characters |
| space | O(L) for one line and one row |

Trying every alignment for each pair would multiply work by word length.
