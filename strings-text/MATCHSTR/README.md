# MATCHSTR — Tìm xâu 01 (SPOJ)

<https://www.spoj.com/problems/MATCHSTR/>

## Problem

Count how many times a short digit string appears inside a long digit string. Overlapping appearances each count, so a pattern can start again before the previous match ends.

Input has two lines: the text `S` and the pattern `T`, both made of digits. Output one integer: the number of appearances of `T` in `S`.

| item | bound |
|---|---|
| pattern length | 1 to 1000000 |
| text length | pattern length to 1000000 |
| alphabet | digits 0 through 9 |
| judge limit | 1000 ms, 1536 MB |

Both length bounds reach a million, so the scan must be linear.

Sample input:

```
123123
12
```

Sample output:

```
2
```

## Idea

Slide a window over the text and reuse what already matched, like a zipper that backs up only as far as needed. The Knuth–Morris–Pratt algorithm builds a prefix table for the pattern, then walks the text once. Each text digit moves the matched length forward by at most one step after backing up, so the scan is linear. A naive check would restart at every position and cost O(|S|·|T|) in the worst case. The takeaway is to precompute fallback positions once and never reread the pattern blindly.

## Why It Works

1. The prefix table stores the longest proper prefix of the pattern that is also a suffix ending at each position.
2. On a mismatch, the matched length falls to the prefix value of the already matched part.
3. Backing up never rechecks text digits, so the text pointer only moves forward.
4. Reaching the full pattern length records one appearance and falls back for overlaps.
5. A pattern longer than the text cannot appear and yields zero without building the table.

| term | meaning |
|---|---|
| `textLength` | number of digits in the text |
| `patternLength` | number of digits in the pattern |
| `prefixValue` | fallback length for each pattern position |
| `matchedLength` | digits matched at the current text position |
| `occurrenceCount` | number of appearances found so far |

The prefix table makes every fallback a constant-time jump.

A script-generated example:

```
text 123123 pattern 12
match starts [0, 3] count 2
```

The two starts at 0 and 3 give the sample answer 2.

## Code

**Input location.** The first two digit runs in the input become the text and the pattern.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1
let textStart = scanPos
while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
  scanPos += 1
let textLength = scanPos - textStart
while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
  scanPos += 1
let patternStart = scanPos
while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
  scanPos += 1
let patternLength = scanPos - patternStart
```

Line breaks are skipped as plain separators between the two digit runs.
Both lengths are measured before any table is allocated.
A missing pattern leaves `patternLength` at zero and leads to an early answer.

**Prefix and scan.** The prefix table drives one linear walk over the text.

```nim
if patternLength == 0 or patternLength > textLength:
  appendOutput("0\n")
else:
  var prefixValue = newSeq[int](patternLength)
  var matchedLength = 0
  for prefixIndex in 1 .. patternLength - 1:
    while matchedLength > 0 and inputData[patternStart + prefixIndex] != inputData[patternStart + matchedLength]:
      matchedLength = prefixValue[matchedLength - 1]
    if inputData[patternStart + prefixIndex] == inputData[patternStart + matchedLength]:
      matchedLength += 1
    prefixValue[prefixIndex] = matchedLength
  var occurrenceCount: int64 = 0
  matchedLength = 0
  for textIndex in 0 .. textLength - 1:
    while matchedLength > 0 and inputData[textStart + textIndex] != inputData[patternStart + matchedLength]:
      matchedLength = prefixValue[matchedLength - 1]
    if inputData[textStart + textIndex] == inputData[patternStart + matchedLength]:
      matchedLength += 1
    if matchedLength == patternLength:
      occurrenceCount += 1
      matchedLength = prefixValue[matchedLength - 1]
  appendOutput($occurrenceCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The prefix loop visits positions 1 through `patternLength - 1` exactly once.
After a full match, the fallback keeps overlapping appearances visible.
The occurrence counter uses `int64` for million-digit texts.

## Complexity

The prefix table and the text scan are both single passes.

| phase | time | space |
|---|---|---|
| input read | one pass over both digit strings | input string |
| prefix table | one visit per pattern digit | table of pattern digits |
| text scan | one visit per text digit | matched length scalar |
| output | one line | block buffer |

The two passes add up to a cost set by the combined string lengths.

| measure | Big O |
|---|---|
| time | O(|S| + |T|) |
| space | O(|T|) |

Restarting the pattern at every text position would cost O(|S|·|T|); the prefix table removes that blow-up.
