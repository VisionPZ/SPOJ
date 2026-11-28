# ACFRAC — Another Continuous Fractions Problem (SPOJ)

<https://www.spoj.com/problems/ACFRAC/>

## Problem

Convert a fraction into a fixed ASCII picture, or rebuild the fraction from such a picture. Each case has type `A` for forward conversion or `B` for reverse conversion. The letter `C` ends the input.

A type `A` line holds `p q`. A type `B` case holds picture lines until the next standalone `A`, `B`, or `C`. Output a `Case k:` header for every case.

Type `A` prints only the picture. Type `B` prints only `p q`.

| item | bound |
|---|---|
| cases | fewer than 1000 |
| picture width | grows with the Euclidean quotients |
| judge limit | 4000 ms, 1536 MB |

The final picture term is one less than the last Euclidean remainder.

Sample input:

```
A
75 34
B
..........1......
2.+.-------------
............1....
....4.+.---------
..............1..
........1.+.-----
................1
............5.+.-
................1
C
```

Sample output:

```
Case 1:
..........1......
2.+.-------------
............1....
....4.+.---------
..............1..
........1.+.-----
................1
............5.+.-
................1
Case 2:
75 34
```

## Idea

Think of the picture as a row of signposts, like milestones that each tell you one division step. The Euclidean algorithm gives the signposts; the reverse pass folds them back into one fraction.

The algorithm is quotient extraction with a shared denominator. Each quotient costs one division step. Rebuilding scans the picture lines once and walks the terms backwards.

A naive search over possible numerators would be unbounded. The quotient chain fixes the answer directly.

## Why It Works

1. Dividing `p` by `q` gives quotient `a` and remainder `r`.
2. Repeating with `q` and `r` gives the Euclidean quotient list.
3. The last remainder is 1, and the stored final term is that remainder minus 1.
4. Reading the terms backwards rebuilds the numerator and denominator.
5. The marker column is the midpoint of the span from the current term to the picture edge.

| term | meaning |
|---|---|
| `continuedTerms` | Euclidean quotients plus the reduced final remainder |
| `pictureWidth` | three columns per term, one separator, and all digits |
| `restoreFraction` | reverse pass that folds terms into a fraction |
| `kindNeedsLineSkip` | true when a new kind came from the character scanner |

A worked example for `75 34`:

```
75 = 2 * 34 + 7
34 = 4 * 7 + 6
7 = 1 * 6 + 1
final remainder 6 -> stored term 5
terms: 2, 4, 1, 5
reverse fold: 5+1=6, 1+1/6=7/6, 4+6/7=34/7, 2+7/34=75/34
```

The reverse fold returns the original fraction, so the picture is exact.

## Code

**Input helpers and buffered output.** One read fills the input; case letters and lines are taken from it.

```nim
import strutils

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

proc nextKind(data: string, pos: var int): char =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  let kind = data[pos]
  pos += 1
  return kind

proc readTextLine(data: string, pos: var int): string =
  let start = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  if pos == start:
    if pos < data.len:
      pos += 1
    return ""
  let text = data[start .. pos - 1]
  if pos < data.len:
    pos += 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The kind reader ignores all non-letters, including digits in pictures.
Line reading keeps picture rows intact for type `B`.
The buffer flushes by byte count, not by case.

**Term extraction.** Each Euclidean step contributes one picture term.

```nim
proc greatestDivisor(first: int64, second: int64): int64 =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  if left < 0:
    return -left
  return left

proc continuedTerms(numeratorIn: int64, denominatorIn: int64): seq[int64] =
  var numerator = numeratorIn
  var denominator = denominatorIn
  var terms = newSeq[int64]()
  while true:
    let divisor = greatestDivisor(numerator, denominator)
    numerator = numerator div divisor
    denominator = denominator div divisor
    if denominator == 1:
      break
    terms.add(numerator div denominator)
    let remainder = numerator mod denominator
    numerator = denominator
    denominator = remainder
  terms.add(numerator - 1)
  return terms
```

Each step divides out the common factor before taking a quotient.
The loop stops once the denominator becomes 1.
The final stored term is the remaining numerator minus 1.

**Picture drawing.** Digits, sign markers, dashes, and midpoint ones form each picture.

```nim
proc digitCount(value: int64): int =
  var number = value
  if number < 0:
    number = -number
  var count = 1
  while number >= 10:
    number = number div 10
    count += 1
  return count

proc drawFraction(numerator: int64, denominator: int64): string =
  let terms = continuedTerms(numerator, denominator)
  var pictureWidth = 3 * terms.len + 1
  for term in terms:
    pictureWidth += digitCount(term)
  var picture = newSeq[string](2 * terms.len + 1)
  for lineIndex in 0 .. picture.len - 1:
    picture[lineIndex] = repeat('.', pictureWidth)
  var column = 0
  for termIndex in 0 .. terms.len - 1:
    let lineIndex = 2 * termIndex + 1
    let digits = $terms[termIndex]
    for digitIndex in 0 .. digits.len - 1:
      picture[lineIndex][column] = digits[digitIndex]
      column += 1
    picture[lineIndex][column] = '.'
    picture[lineIndex][column + 1] = '+'
    picture[lineIndex][column + 2] = '.'
    column += 3
    var dashColumn = column
    while dashColumn < pictureWidth:
      picture[lineIndex][dashColumn] = '-'
      dashColumn += 1
    let markerColumn = (column + pictureWidth - 1) div 2
    picture[lineIndex - 1][markerColumn] = '1'
  picture[picture.len - 1][pictureWidth - 1] = '1'
  return picture.join("\n") & "\n"
```

Every term occupies one odd line and one marker row above it.
Dashes fill from the sign marker to the right edge.
Width counts digits so terms wider than one character still align.

**Reverse folding.** Walking terms backwards reconstructs the original pair.

```nim
proc restoreFraction(terms: seq[int64]): tuple[numerator: int64, denominator: int64] =
  var numerator: int64 = 1
  var denominator: int64 = 1
  var termIndex = terms.len - 1
  while termIndex >= 0:
    let previousNumerator = numerator
    let previousDenominator = denominator
    numerator = previousDenominator + terms[termIndex] * previousNumerator
    denominator = previousNumerator
    termIndex -= 1
  return (numerator, denominator)
```

The fold stores the old numerator as the new denominator.
Each term contributes its coefficient to the new numerator.
All arithmetic stays in 64-bit integers.

**Case driver.** The loop handles both directions and keeps the line cursor aligned.

```nim
var currentKind = nextKind(inputData, scanPos)
var kindNeedsLineSkip = true
var caseNumber = 0

while currentKind != 'C':
  caseNumber += 1
  appendOutput("Case " & $caseNumber & ":\n")
  if currentKind == 'A':
    let numerator = int64(nextInt(inputData, scanPos))
    let denominator = int64(nextInt(inputData, scanPos))
    appendOutput(drawFraction(numerator, denominator))
    currentKind = nextKind(inputData, scanPos)
    kindNeedsLineSkip = true
  else:
    if kindNeedsLineSkip:
      while scanPos < inputData.len and inputData[scanPos] != '\n':
        scanPos += 1
      if scanPos < inputData.len:
        scanPos += 1
    kindNeedsLineSkip = false
    var coefficients = newSeq[int64]()
    var artLineIndex = 0
    while true:
      let artLine = readTextLine(inputData, scanPos)
      if artLine == "A" or artLine == "B" or artLine == "C":
        currentKind = artLine[0]
        break
      if artLineIndex mod 2 == 1:
        var coefficientPos = 0
        coefficients.add(int64(nextInt(artLine, coefficientPos)))
      artLineIndex += 1
    let restored = restoreFraction(coefficients)
    appendOutput($restored.numerator)
    appendOutput(" ")
    appendOutput($restored.denominator)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Only odd picture lines carry coefficients.
The skip flag prevents losing the first picture line after a case break.
The last write flushes all answer text at once.

## Complexity

Each case depends on the number of Euclidean quotients.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| forward case | one Euclidean step per term | picture rows |
| reverse case | one pass over picture lines | term list |
| output | one block flush per threshold | block buffer |

The number of terms stays small for 32-bit inputs, so drawing dominates only by picture width.

| measure | Big O |
|---|---|
| time | O(total output characters) |
| space | O(picture width times picture height) |

Guessing the fraction from a picture by enumeration would be unbounded, while reverse folding takes one pass.
