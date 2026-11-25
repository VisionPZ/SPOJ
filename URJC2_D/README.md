# URJC2_D — Keyboard Writing (SPOJ)
<https://www.spoj.com/problems/URJC2_D/>

## Problem

Each test gives the letters a typist already knows and a line to transcribe. A known letter takes 50 ms. An unknown letter takes 150 ms the first time, then 50 ms forever after. Print the total milliseconds for each test.

The first line gives the test count. Each test has two lines: known letters A, then target text B. Both lines contain lowercase letters only. Print one integer per test.

The bounds from the statement:

| Item | Bound |
|---|---|
| Known letters | 1 ≤ |A| ≤ 26 |
| Target length | 1 ≤ |B| ≤ 100000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The target length drives the work; each character costs one lookup.

The sample case:

```
2
urjc
urjccontesttwo
abcdefghijklmnopqrstuvwxyz
thequickbrownfoxjumpsoverthelazydog
```

```
1300
1750
```

## Idea

Charge 50 ms for every character, then add the extra 100 ms once per newly learned letter. Think of a cover charge at a door: everyone pays the base fee, and first-time guests pay extra. Two 26-entry tables track known and already seen letters.

## Why It Works

1. Every character needs at least the base 50 ms press.
2. A letter outside A costs 100 ms more on its first appearance only.
3. The seen table records that first appearance and prevents a second charge.
4. With 26 letters, each lookup and update takes constant time.

The main terms:

| Term | Meaning |
|---|---|
| `A` | letters the typist knows before starting |
| `B` | the line the typist must transcribe |
| `known` | table marking letters from A |
| `seen` | table marking unknown letters already met |

These terms turn the story into two table lookups per character.

A script trace of `urjccontesttwo` gives 14 characters at 50 ms, plus six new letters at 100 ms. The total is 700 + 600 = 1300, matching the sample.

## Code

**Input buffer and token scanner.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const baseLetter = 97
const alphabetSize = 26
const knownCost = 50
const unknownCost = 150

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]
```
The token scanner skips whitespace and returns one word. Both input lines become single tokens.

**Cost loop and flush.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for j in 0..<caseCount:
  let knownLetters = nextToken(inputData, scanPos)
  let textToType = nextToken(inputData, scanPos)
  var known = newSeq[bool](alphabetSize)
  var seen = newSeq[bool](alphabetSize)
  for c in knownLetters:
    known[int(c) - baseLetter] = true
  var totalCost: int64 = knownCost * int64(textToType.len)
  for c in textToType:
    let idx = int(c) - baseLetter
    if not known[idx] and not seen[idx]:
      seen[idx] = true
      totalCost += int64(unknownCost - knownCost)
  appendOutput($(totalCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
The base charge is added before the scan. The seen table adds the extra fee once per letter.

## Complexity

The cost is one pass over the target text per test.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Cost scan | one table lookup per character | two 26-entry tables |
| Output | one write per 128 KiB block | block buffer |

The scan is linear in the target length, with no per-character search.

Big O uses B as the total number of target characters.

| Measure | Big O |
|---|---|
| Time | O(B) |
| Space | O(B) for stored input |

Searching a sorted list for each letter would add a log factor. Table indexing avoids that cost.
