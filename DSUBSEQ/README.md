# DSUBSEQ — Distinct Subsequences (SPOJ)

<https://www.spoj.com/problems/DSUBSEQ/>

## Problem

Given a string, count its different subsequences, including the empty one. A subsequence keeps the original left-to-right order of the chosen characters.

The first line holds the test count. Each following line holds one uppercase string. Print one count per string, reduced modulo 1000000007.

| item | bound |
|---|---|
| test count | up to 100 |
| string length | up to 100000 |
| alphabet | uppercase A to Z |
| judge limit | 1000 ms, 1536 MB |

Length drives the design, since the answer grows exponentially before reduction.

Sample input:

```
3
AAA
ABCDEFG
CODECRAFT
```

Sample output:

```
4
128
496
```

The empty subsequence and the whole string both count.

## Idea

Adding one letter doubles the pile of subsequences, like flipping a switch for every existing choice, and repeats collapse by subtracting the previous total for that same letter. The last-occurrence DP keeps one running total and one prior total per letter. Each character costs constant time and 26 counters of space. Enumerating subsequences into a set costs exponential time, so it fails on long strings. Track only the previous total per letter, and one sweep answers each string.

## Why It Works

1. Let the running total count distinct subsequences of the current prefix, empty one included.
2. A new letter appends to every old subsequence, so the doubled total represents those extended choices.
3. Old subsequences that already end with this letter also appear as bare copies, and the prior total measures exactly those copies.
4. Subtracting the prior total removes the duplicates and leaves the new distinct total.
5. Storing the previous running total per letter gives the subtraction in constant time.

| term | meaning |
|---|---|
| `distinctCount` | subsequences of the prefix processed so far |
| `lastCounts` | prior total saved for each of 26 letters |
| `letterIndex` | position of the current letter in that table |
| `extendedCount` | new total after removing repeats |

Each step reuses one saved number instead of searching the string backwards.

A trace of the string ABA:

```
start 1
A 2
B 4
A 7
```

The totals 1, 2, 4, 7 match the DP counts for the empty prefix, A, AB and ABA.

## Code

**Input and hand scanner.** One read pass fills the input string, and two small procs fetch numbers and words.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const letterCount = 26
const firstLetterValue = 65

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Letters are tokens, so the word reader skips line breaks by spacing.
The number reader handles the test count alone.
Both procs advance the same cursor.

**Buffered output and DP sweep.** One sweep per string updates the 26 saved totals.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let textValue = nextToken(inputData, scanPos)
  var lastCounts = newSeq[int64](letterCount)
  var distinctCount: int64 = 1
  for charIndex in 0 .. textValue.len - 1:
    let letterIndex = int(textValue[charIndex]) - firstLetterValue
    let previousCount = lastCounts[letterIndex]
    let extendedCount = (2 * distinctCount - previousCount + modulusValue) mod modulusValue
    lastCounts[letterIndex] = distinctCount
    distinctCount = extendedCount
  appendOutput($distinctCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Adding the modulus before taking the remainder keeps the value positive.
Each character touches one slot of the table.
One final write flushes all answers together.

## Complexity

Each string is scanned once, and each step touches one letter slot.

| phase | time | space |
|---|---|---|
| input read | one pass over the input bytes | one input string |
| DP sweep | one constant step per character | 26 counters |
| output | one buffered line per case | block buffer |

The sweep dominates, and the table stays tiny.

| measure | Big O |
|---|---|
| time | O(total string length) |
| space | O(1) per string beyond input |

Building a set of subsequences costs exponential time, while this sweep costs linear time. Keep one total and one saved value per letter.
