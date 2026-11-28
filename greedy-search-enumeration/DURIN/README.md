# DURIN — Durins Day (SPOJ)
<https://www.spoj.com/problems/DURIN/>

## Problem

A small key fits into a long row of keyholes wherever its letters appear in order. Count every nonempty set of fits that uses no two overlapping holes, then report that count modulo 1000000007. Print 0 when the key appears nowhere.

Input has two lines: the key, then the row of keyholes. Output has one integer on one line. Two fits overlap when their intervals share any position.

| item | bound |
|---|---|
| key length | 1 to 10000 |
| row length | 1 to 500000 |
| result | modulo 1000000007 |
| judge limit | 1000 ms, 1536 MB |

Long rows make a linear scan necessary; overlapping fits cannot be chosen together.

Sample input:

```
c
a
```

The key does not occur in the row.

Sample output:

```
0
```

Zero is the required output when no fit exists.

## Idea

Picture each fit as a tile of fixed width laid on a long strip; you may stack only tiles that do not touch. The algorithm is Knuth-Morris-Pratt matching followed by a one-pass subset count. Matching lists every fit in left-to-right order at linear cost. The count uses a moving pointer to the last fit that ends before the current fit starts. A scan of all subsets would take exponential time; the pointer reuses counts from earlier fits. One sweep after matching gives the answer.

## Why It Works

1. Knuth-Morris-Pratt reports each occurrence in increasing position order.
2. A fit at position p covers the positions p through p plus the key length minus one.
3. Two fits do not overlap when the earlier start plus the key length is at most the later start.
4. For a fit at index i, let j count fits that end before it starts; j never decreases as i grows.
5. Sets using this fit are the singleton and every valid set among those j earlier fits.
6. The new count is the old count plus the fitting count plus one, all modulo the base.
7. The count at zero fits is zero, so the empty set is never counted.

| term | meaning |
|---|---|
| `prefixTable` | longest proper border length at each key position |
| `occurrences` | start positions of every fit, in order |
| `lastFitting` | count of fits ending before the current fit starts |
| `wayCounts` | number of valid nonempty sets among the first i fits |
| `moduloBase` | 1000000007, the required modulus |

The moving pointer visits each fit at most once, so the count stays linear.

The generator script produced the second sample with key aba in row abababa. Fits start at 0, 2 and 4, and the key occupies three positions.

| fit index | start | fits ending before it | `wayCounts` after it |
|---|---|---|---|
| 0 | 0 | 0 | 1 |
| 1 | 2 | 0 | 2 |
| 2 | 4 | 1 | 4 |

The last row counts three single-fit sets and one two-fit set, so the answer is 4.

Arithmetic stays below twice the modulus before each reduction, so 64-bit integers hold every sum.

## Code

**Input and output buffer.** Read both lines once and keep a block buffer for the answer.

```nim
const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007

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
```

`inputData` holds the key line and the row line with their newlines.
`appendOutput` flushes once the buffer reaches `flushBlockBytes`.

**Line split and matching.** Extract the two strings, build the border table, and list all fits.

```nim
var firstEnd = 0
while firstEnd < inputData.len and inputData[firstEnd] != '\n':
  firstEnd += 1
let keyString = inputData[0 .. firstEnd - 1]
let secondStart = firstEnd + 1
var secondEnd = secondStart
while secondEnd < inputData.len and inputData[secondEnd] != '\n':
  secondEnd += 1
let textString = inputData[secondStart .. secondEnd - 1]
let keyLength = keyString.len

var prefixTable = newSeq[int](keyLength)
for position in 1 .. keyLength - 1:
  var backTrack = prefixTable[position - 1]
  while backTrack > 0 and keyString[position] != keyString[backTrack]:
    backTrack = prefixTable[backTrack - 1]
  if keyString[position] == keyString[backTrack]:
    backTrack += 1
  prefixTable[position] = backTrack

var occurrences = newSeq[int](0)
var matchedLength = 0
for position in 0 .. textString.len - 1:
  while matchedLength > 0 and textString[position] != keyString[matchedLength]:
    matchedLength = prefixTable[matchedLength - 1]
  if textString[position] == keyString[matchedLength]:
    matchedLength += 1
  if matchedLength == keyLength:
    occurrences.add(position - keyLength + 1)
    matchedLength = prefixTable[matchedLength - 1]
```

`prefixTable` records reusable borders inside the key.
`matchedLength` falls back through borders after a mismatch.
Each complete match appends one start position to `occurrences`.

**Subset count.** Advance the fitting pointer and add the two reuse terms per fit.

```nim
var wayCounts = newSeq[int64](occurrences.len + 1)
var lastFitting = 0
for positionIndex in 0 .. occurrences.len - 1:
  let occurrence = occurrences[positionIndex]
  while lastFitting < positionIndex and occurrences[lastFitting] + keyLength <= occurrence:
    lastFitting += 1
  wayCounts[positionIndex + 1] = (wayCounts[positionIndex] + wayCounts[lastFitting] + 1) mod moduloBase

appendOutput($wayCounts[occurrences.len])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`lastFitting` never drops, so the inner loop runs once per fit overall.
The recurrence adds the singleton and all sets using earlier nonoverlapping fits.
The final write sends the single answer line to stdout.

## Complexity

Matching and counting each scan the input a constant number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over both lines | one input string |
| border table | one pass over the key | border array of key length |
| match and count | one pass over the row | fit list and count array |

The border table costs space proportional to the key, not the row.

| measure | Big O |
|---|---|
| time | O(key length + row length) |
| space | O(key length + number of fits) |

Both bounds are linear in the input size.

Enumerating every subset instead would take exponential time in the number of fits.

The pointer reuse keeps large rows within the judge limit.
