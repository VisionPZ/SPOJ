# DIXIE001 — Evil Overlord Cypher (SPOJ)
<https://www.spoj.com/problems/DIXIE001/>

## Problem

Replace each byte of a text with the byte at the mirrored position in a frequency-ordered list. Order distinct bytes by frequency, then by ASCII code, reverse that order, and pair the first with the last. Every byte counts, including line breaks, and the last output byte carries no added newline.

The first input line holds a count of the remaining lines. The rest of the file is the text to encode.

| item | bound |
|---|---|
| text lines | up to 593 |
| text size | about 25000 bytes |
| distinct byte values | up to 256 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
1
Aliens are dumb
```

Sample output:

```
 mn
ibAud
Aralse
```

## Idea

Sorting characters by frequency is like lining people up by height, then pairing the shortest with the tallest. Count all bytes first, order the distinct values by frequency and ASCII, and mirror the list into a substitution table. The count of at most 256 values makes insertion sorting cheap. One pass over the text writes the encoded bytes. The takeaway is to build a single lookup table before touching the text.

## Why It Works

1. Frequency is measured over the entire file before any character changes.
2. Ties in frequency break by ASCII code, so the order is unique.
3. Reversing the order pairs position p with position n − 1 − p.
4. The pairing is a bijection, so every plain byte has exactly one encoded byte.
5. Reading raw bytes keeps a final newline only when the input contains one.

| term | meaning |
|---|---|
| `frequencies` | count of each byte value in the text |
| `sortedBytes` | distinct byte values in frequency then ASCII order |
| `substitution` | encoded byte for each plain byte value |
| `inputData` | raw bytes of the whole file |

A script generated this lookup for Mississippi:

| byte | count | rank in ascending order | replacement |
|---|---|---|---|
| M | 1 | 0 | s |
| p | 2 | 1 | i |
| i | 4 | 2 | p |
| s | 4 | 3 | M |

Applying that table turns Mississippi into spMMpMMpiip.

## Code

**Raw input and ordering.** The reader keeps every byte, then insertion sort orders the distinct values.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var byteBuffer: array[65536, char]
while true:
  let bytesRead = stdin.readBuffer(addr byteBuffer[0], byteBuffer.len)
  if bytesRead == 0:
    break
  for byteIndex in 0 .. bytesRead - 1:
    inputData.add byteBuffer[byteIndex]

var textStart = 0
while textStart < inputData.len and inputData[textStart] != '\n':
  textStart += 1
if textStart < inputData.len:
  textStart += 1

var frequencies: array[256, int]
for byteIndex in textStart .. inputData.len - 1:
  frequencies[int(inputData[byteIndex])] += 1

var sortedBytes = newSeq[int](256)
var sortedLength = 0
for byteValue in 0 .. 255:
  if frequencies[byteValue] > 0:
    sortedBytes[sortedLength] = byteValue
    sortedLength += 1

for sortIndex in 1 .. sortedLength - 1:
  let currentByte = sortedBytes[sortIndex]
  var compareIndex = sortIndex - 1
  while compareIndex >= 0:
    let priorByte = sortedBytes[compareIndex]
    let priorHigher = frequencies[priorByte] > frequencies[currentByte] or
        (frequencies[priorByte] == frequencies[currentByte] and priorByte > currentByte)
    if not priorHigher:
      break
    sortedBytes[compareIndex + 1] = priorByte
    compareIndex -= 1
  sortedBytes[compareIndex + 1] = currentByte
```

The first line is skipped after its newline.
Insertion sort uses frequency first and ASCII second.
Only values present in the text enter the table.

**Substitution and output.** The mirror table encodes each byte into one buffered string.

```nim
var substitution: array[256, int]
for position in 0 .. sortedLength - 1:
  substitution[sortedBytes[position]] = sortedBytes[sortedLength - 1 - position]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for byteIndex in textStart .. inputData.len - 1:
  appendOutput($chr(substitution[int(inputData[byteIndex])]))
stdout.write outputBuffer
outputBuffer.setLen 0
```

Position zero maps to the last sorted value.
Each text byte becomes one output byte.
No newline is appended after the last byte.

## Complexity

The table holds at most 256 entries.

| phase | time | space |
|---|---|---|
| input read | one pass over the file | one raw string |
| frequency and sort | up to 256 squared comparisons | two small arrays |
| substitution | one pass over the text | block buffer |

The bounds use the text length B and the distinct count D.

| measure | Big O |
|---|---|
| time | O(B + D²) |
| space | O(B + D) |

Sorting the whole text byte by byte would cost O(B log B) comparisons.
The takeaway is that a small sorted table makes encoding a single pass.
