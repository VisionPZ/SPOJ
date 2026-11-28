# KPARCH — Archiver (SPOJ)

<https://www.spoj.com/problems/KPARCH/>

## Problem

Count every substring of the input text that is two identical parts written one after the other. Such a substring has the form AA and is called a square.

The input file holds only upper-case and lower-case Latin letters. Letter case matters, so X and x differ. Newlines separate lines of text and are not letters. Print one integer: the number of square substrings.

| item | bound |
|---|---|
| text length | at most 200000 letters |
| alphabet | 52 case-sensitive Latin letters |
| answer size | up to about 10^10 |
| judge limit | 1000 ms, 1536 MB |

The length bound rules out checking every substring by hand.

Sample input:

```
abcdefg
```

Sample output:

```
0
```

## Idea

Treat the middle of the text like the seam of a folded strip: count folds whose two halves match, then fold the strip in half and repeat. The Main–Lorentz divide-and-conquer algorithm counts squares that straddle a seam in linear time using four Z-functions. Squaring both halves of the recursion costs O(n log n) overall.

Trying every start and every half-length costs O(n^3) comparisons and cannot pass. Grouping matching splits into one counted interval removes that cost.

## Why It Works

1. A crossing square has a fixed half-length once its middle character is chosen.
2. Two match lengths bound the possible splits into a leading and trailing piece.
3. Every split inside those bounds gives one valid square.
4. The Z-function returns those two bounds in constant time after one linear pass.
5. Recursion on left and right halves counts the squares that do not cross.
6. A 64-bit integer holds the answer because a string of 200000 equal letters has about 10^10 squares.

| term | meaning |
|---|---|
| `textData` | the input letters, with whitespace removed |
| `halfLength` | length of one half of a candidate square |
| `firstMatch` | number of matching letters before the seam |
| `secondMatch` | number of matching letters after the seam |
| `foundCount` | squares counted at one center |

The split count is high minus low plus one, with one removed when the left-side split would be empty.

A script listed every square in the third sample string.

```
text = aCacaacaa length = 9
start 2 half 3 -> acaaca
start 3 half 3 -> caacaa
start 4 half 1 -> aa
start 7 half 1 -> aa
count = 4
```

Two overlapping long squares and two short doubles give the expected answer four.

The separator character `#` never appears in the input, so Z-functions cannot match across it. The left-side break avoids counting a square that lies wholly inside the left half.

## Code

**Hand reader and Z-function.** The reader keeps letters only. The Z-function gives match lengths in linear time.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var textData = ""
for inputChar in inputData:
  if (inputChar >= 'A' and inputChar <= 'Z') or (inputChar >= 'a' and inputChar <= 'z'):
    textData.add inputChar

proc zFunction(source: string): seq[int] =
  let sourceLength = source.len
  var zValues = newSeq[int](sourceLength)
  var matchLeft = 0
  var matchRight = 0
  var position = 1
  while position < sourceLength:
    if position <= matchRight:
      var candidate = matchRight - position + 1
      if zValues[position - matchLeft] < candidate:
        candidate = zValues[position - matchLeft]
      zValues[position] = candidate
    while position + zValues[position] < sourceLength and
          source[zValues[position]] == source[position + zValues[position]]:
      zValues[position] += 1
    if position + zValues[position] - 1 > matchRight:
      matchLeft = position
      matchRight = position + zValues[position] - 1
    position += 1
  return zValues

proc zValueAt(zValues: seq[int], index: int): int =
  if index >= 0 and index < zValues.len:
    return zValues[index]
  return 0
```

Each input line contributes its letters to `textData`.
The sliding match window keeps total comparisons linear.
Out-of-range Z queries return zero, which handles the short seam cases.

**Divide-and-conquer count.** Each recursion counts crossing squares with four Z-arrays and one center sweep.

```nim
proc countAtCenter(isLeftSide: bool, halfLength: int, firstMatch: int,
                   secondMatch: int): int64 =
  var lowSplit = halfLength - secondMatch
  if lowSplit < 1:
    lowSplit = 1
  var highSplit = firstMatch
  if highSplit > halfLength:
    highSplit = halfLength
  if highSplit < lowSplit:
    return 0
  var foundCount = highSplit - lowSplit + 1
  if isLeftSide and highSplit == halfLength:
    foundCount -= 1
  return int64(foundCount)

proc countCrossing(text: string, shiftValue: int): int64 =
  let textLength = text.len
  if textLength <= 1:
    return 0
  let leftLength = textLength div 2
  let rightLength = textLength - leftLength
  let leftPart = text[0 ..< leftLength]
  let rightPart = text[leftLength ..< textLength]
  var reversedLeft = ""
  var reversedRight = ""
  var reverseIndex = leftLength - 1
  while reverseIndex >= 0:
    reversedLeft.add leftPart[reverseIndex]
    reverseIndex -= 1
  reverseIndex = rightLength - 1
  while reverseIndex >= 0:
    reversedRight.add rightPart[reverseIndex]
    reverseIndex -= 1

  var total = countCrossing(leftPart, shiftValue) +
              countCrossing(rightPart, shiftValue + leftLength)

  let zReversedLeft = zFunction(reversedLeft)
  let zAcross = zFunction(rightPart & "#" & leftPart)
  let zBothReversed = zFunction(reversedLeft & "#" & reversedRight)
  let zRight = zFunction(rightPart)

  var centerIndex = 0
  while centerIndex < textLength:
    var halfLength: int
    var firstMatch: int
    var secondMatch: int
    if centerIndex < leftLength:
      halfLength = leftLength - centerIndex
      firstMatch = zValueAt(zReversedLeft, leftLength - centerIndex)
      secondMatch = zValueAt(zAcross, rightLength + 1 + centerIndex)
    else:
      halfLength = centerIndex - leftLength + 1
      firstMatch = zValueAt(zBothReversed, leftLength + rightLength -
                            (centerIndex - leftLength))
      secondMatch = zValueAt(zRight, centerIndex - leftLength + 1)
    if firstMatch + secondMatch >= halfLength:
      total += countAtCenter(centerIndex < leftLength, halfLength,
                             firstMatch, secondMatch)
    centerIndex += 1
  return total
```

The two recursive calls run before the crossing work.
Each Z-array has total length at most twice the current segment.
The split count uses arithmetic, so repetitive input stays fast.

**Buffered output.** One number and one newline close the run.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let squareCount = countCrossing(textData, 0)
appendOutput($squareCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The count is written once as a decimal integer.
The buffer flush keeps the write path uniform with the other solutions.

## Complexity

Each recursion level visits disjoint segments whose lengths sum to n.

| phase | time | space |
|---|---|---|
| input read | one pass over letters | one input string |
| crossing scan | four Z-arrays per segment | segment copies |
| output | one buffered write | block buffer |

The split counts are computed without a per-square loop.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n log n) across recursion levels |

Checking every start and half-length would take O(n^3) comparisons, while the Z-based count stays near-linear per level. The divide-and-conquer sweep settles all square substrings at once.
