# G10182 — Criptoanálisis (SPOJ)

<https://www.spoj.com/problems/G10182/>

## Problem

Count how often each letter appears in a passage and rank the letters by frequency. Case is ignored, and letters that never appear are omitted.

The first line gives the number of text lines that follow. Print one line per present letter: the uppercase letter, a space, and its count. Sort by count from highest to lowest, breaking ties by later letter first.

| Item | Bound |
|---|---|
| Text lines | given by the header number |
| Characters per line | about 200 |
| Output lines | at most 26 |
| Judge limit | 1000 ms, 1536 MB |

The line count fixes how much text enters the tally.

Sample input:

```
3
Esta es una prueba,
Cuentame 1 2 3 4 5,
¡ ¡oohh!! ¿Esta es pregunta facil?
```

Sample output:

```
E 8
A 7
U 4
T 4
S 4
N 3
R 2
P 2
O 2
H 2
C 2
M 1
L 1
I 1
G 1
F 1
B 1
```

## Idea

Tally letters into 26 slots, then rank them like a hand of Scrabble tiles sorted by how many of each you hold. One pass over the bytes fills the slots. Each byte costs two range checks and one increment. Rebuilding a count map per line would repeat work across the passage. A single array and one short ranking settle the answer.

## Why It Works

1. Uppercase codes run from 65 to 90 and lowercase codes from 97 to 122, so both map onto 26 slots.
2. The header is parsed from its own slice before the first newline, so text digits cannot change the count.
3. Tallying stops after the requested number of newlines, so trailing lines are ignored.
4. The comparator favors a larger count first and then a larger letter index.
5. Slots with a zero tally never enter the ranking, so absent letters print nothing.

The terms used by the tally and ranking:

| Term | Meaning |
|---|---|
| `lineCount` | the number of text lines named in the header |
| `headerEnd` | the byte position of the first newline |
| `newlineCode` | 10, the code that ends one text line |
| `letterCounts` | the 26 tallies, index zero holding A |
| `presentLetters` | indexes whose tally is greater than zero |
| `compareLetters` | the count-then-letter ranking rule |

Each term covers one step from header parse to final line.

A script-traced example:

```
input: 1 then abcabc
tallies: a=2, b=2, c=2
ranking by count then letter: C 2, B 2, A 2
```

Ties fall to the later letter, exactly as the statement asks.

## Code

**Input and buffered output.** These declarations load stdin and provide the hand scanner.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const firstUpperValue = 65
const firstLowerValue = 97
const alphabetSize = 26
const firstDigitValue = 48
const newlineCode = 10

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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
```

The scanner skips non-digits before reading the header. Output text leaves in 131072-byte blocks.

**Header slice and tally pass.** This block isolates the header and counts letters in the text.

```nim
var headerEnd = 0
while headerEnd < inputData.len and inputData[headerEnd] != '\n':
  headerEnd += 1
var headerPos = 0
let lineCount = nextInt(inputData[0 .. headerEnd - 1], headerPos)

var letterCounts = newSeq[int](alphabetSize)
var linesConsumed = 0
var bytePos = headerEnd + 1
while bytePos < inputData.len and linesConsumed < lineCount:
  let byteCode = ord(inputData[bytePos])
  if byteCode == newlineCode:
    linesConsumed += 1
  elif byteCode >= firstUpperValue and byteCode <= firstUpperValue + alphabetSize - 1:
    letterCounts[byteCode - firstUpperValue] += 1
  elif byteCode >= firstLowerValue and byteCode <= firstLowerValue + alphabetSize - 1:
    letterCounts[byteCode - firstLowerValue] += 1
  bytePos += 1
```

The loop stops at the requested line count. Non-letters cost two comparisons and no increment.

**Ranking and output.** This block sorts the present letters and writes their lines.

```nim
var presentLetters: seq[int] = @[]
for letterIndex in 0 .. alphabetSize - 1:
  if letterCounts[letterIndex] > 0:
    presentLetters.add letterIndex

proc compareLetters(leftIndex: int, rightIndex: int): int =
  if letterCounts[leftIndex] > letterCounts[rightIndex]:
    return -1
  if letterCounts[leftIndex] < letterCounts[rightIndex]:
    return 1
  if leftIndex > rightIndex:
    return -1
  if leftIndex < rightIndex:
    return 1
  return 0

sort(presentLetters, compareLetters)

for letterIndex in presentLetters:
  appendOutput($chr(firstUpperValue + letterIndex))
  appendOutput(" ")
  appendOutput($letterCounts[letterIndex])
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

At most 26 indexes enter the sort. The final flush releases any buffered text.

## Complexity

Counting and ranking determine the cost.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input string |
| Tally | one check per text byte | 26 counters |
| Ranking | one sort of at most 26 indexes | index list |
| Output | one line per present letter | block buffer |

The tally grows with the text; the ranking stays bounded by the alphabet.

| Measure | Big O |
|---|---|
| Time | O(N) in input bytes |
| Space | O(N) for the input string |

Rescanning the text once per letter would cost 26 passes, so one tally wins.
