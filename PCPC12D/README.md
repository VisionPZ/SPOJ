# PCPC12D — New Strategy (SPOJ)

<https://www.spoj.com/problems/PCPC12D/>

## Problem

Sort problem names by the letters they contain after removing whitespace and case. A name with more of the first differing letter comes first, counting from a to z. Print the original names, unchanged, in that order.

Input begins with the number of test cases. Each case gives a count n, then n name lines. Each case prints a header and the sorted original names.

The statement gives these bounds.

| item | bound |
|---|---|
| problems per case | 1 to 999 |
| name length | under 200 characters |
| test cases | not stated |
| judge limit | 2000 ms, 1536 MB |

The count vector has only 26 entries, so comparison cost stays small.

Sample input:

```
2
2
abc
ab
4
bcsaasd
dbasaaaa
azzz
bayy
```

Sample output:

```
case: 1
abc
ab
case: 2
dbasaaaa
bcsaasd
bayy
azzz
```

## Idea

Compare names by their letter counts, like comparing scores one category at a time from a to z.

The algorithm builds a count vector for each name, then sorts with an explicit comparator. Each comparison checks at most 26 letters. A naive sort that recounts letters on every comparison would multiply that work by log n. Counting once per name removes the repeated scans.

## Why It Works

1. Removing whitespace and case leaves only lowercase letters to count.
2. A count vector stores how often each of the 26 letters appears.
3. Comparing vectors from a to z matches the required ordering rule.
4. The comparator uses input order to break exact ties, so the sort stays stable.
5. Sorting the entries moves the original names, not the cleaned text.

The main terms are listed below.

| term | meaning |
|---|---|
| `ProblemEntry` | one original name, its count vector, and its input position |
| `letterCounts` | the 26 counts used by the comparator |
| `compareEntries` | returns the order of two entries |
| `mergeSortEntries` | a stable merge sort over the entries |

The comparator decides the order, and the merge sort preserves input order on ties.

A script trace on sample case 2 shows the deciding counts.

```
bcsaasd a=2 b=1 z=0
dbasaaaa a=5 b=1 z=0
azzz a=1 b=0 z=3
bayy a=1 b=1 y=2
order=dbasaaaa,bcsaasd,bayy,azzz
```

The a count separates the first three names, and the b count places bayy before azzz.

Names with identical count vectors keep their input order.

## Code

**Types and input helpers.** The reader keeps raw lines and the scanner reads counts.

```nim
const flushBlockBytes = 1 shl 17
const firstLetterCode = 97
const upperLetterCode = 65
const lowerLetterCode = 97
const letterKinds = 26

type ProblemEntry = object
  originalName: string
  letterCounts: array[letterKinds, int]
  inputOrder: int

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

Each name line is kept exactly as it appeared.
The scanner skips separators before each integer.
The letter array holds 26 slots, one per lowercase letter.

**Line access and sorting.** The helpers read raw lines and order the entries.

```nim
proc skipToNextLine(data: string, pos: var int) =
  while pos < data.len and data[pos] != '\n':
    pos += 1
  if pos < data.len:
    pos += 1

proc nextRawLine(data: string, pos: var int): string =
  let startPos = pos
  while pos < data.len and data[pos] != '\n':
    pos += 1
  let rawText = data[startPos ..< pos]
  if pos < data.len:
    pos += 1
  return rawText

proc compareEntries(left, right: ProblemEntry): int =
  for letterIndex in 0 ..< letterKinds:
    if left.letterCounts[letterIndex] != right.letterCounts[letterIndex]:
      if left.letterCounts[letterIndex] > right.letterCounts[letterIndex]:
        return -1
      return 1
  if left.inputOrder < right.inputOrder:
    return -1
  if left.inputOrder > right.inputOrder:
    return 1
  return 0

proc mergeSortEntries(entries: var seq[ProblemEntry], low, high: int) =
  if high - low <= 1:
    return
  let middle = (low + high) div 2
  mergeSortEntries(entries, low, middle)
  mergeSortEntries(entries, middle, high)
  var merged = newSeq[ProblemEntry](high - low)
  var leftPos = low
  var rightPos = middle
  var mergePos = 0
  while leftPos < middle and rightPos < high:
    if compareEntries(entries[leftPos], entries[rightPos]) <= 0:
      merged[mergePos] = entries[leftPos]
      leftPos += 1
    else:
      merged[mergePos] = entries[rightPos]
      rightPos += 1
    mergePos += 1
  while leftPos < middle:
    merged[mergePos] = entries[leftPos]
    leftPos += 1
    mergePos += 1
  while rightPos < high:
    merged[mergePos] = entries[rightPos]
    rightPos += 1
    mergePos += 1
  for index in 0 ..< (high - low):
    entries[low + index] = merged[index]
```

Whitespace inside a name survives the raw line read.
The comparator scans letters from a to z and favors larger counts.
Input order breaks exact ties, so equal vectors keep their original sequence.

**Output buffering and main loop.** Each case is counted, sorted, and written.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  let problemCount = nextInt(inputData, scanPos)
  skipToNextLine(inputData, scanPos)
  var entries = newSeq[ProblemEntry](problemCount)
  for problemIndex in 0 ..< problemCount:
    let rawName = nextRawLine(inputData, scanPos)
    entries[problemIndex].originalName = rawName
    entries[problemIndex].inputOrder = problemIndex
    for character in rawName:
      let characterCode = int(character)
      var lowerCode = characterCode
      if characterCode >= upperLetterCode and characterCode <= upperLetterCode + letterKinds - 1:
        lowerCode = characterCode + lowerLetterCode - upperLetterCode
      if lowerCode >= lowerLetterCode and lowerCode <= lowerLetterCode + letterKinds - 1:
        entries[problemIndex].letterCounts[lowerCode - firstLetterCode] += 1
  mergeSortEntries(entries, 0, problemCount)
  appendOutput("case: " & $caseNumber)
  outputBuffer.add '\n'
  for problemIndex in 0 ..< problemCount:
    appendOutput(entries[problemIndex].originalName)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Uppercase codes fold into lowercase codes before counting.
Whitespace falls outside the letter range and is ignored for sorting.
Buffered writes keep the output path to one call per block.

## Complexity

Counting runs once per name, and sorting uses short comparisons.

| phase | time | space |
|---|---|---|
| input read | one pass over the lines | one input string |
| count vectors | one pass over each name | 26 counts per name |
| merge sort | O(n log n) comparisons | one merged copy |
| output | one line per name | block buffer |

Counting once per name keeps sorting cheap.

| measure | Big O |
|---|---|
| time | O(total name length + n log n) per case |
| space | O(n) per case |

Recounting letters inside every comparison would add a factor of 26 log n to each case.

Counting once, then sorting, keeps each case fast and stable.
