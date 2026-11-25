# FINGP — Fingerprints (SPOJ)

<https://www.spoj.com/problems/FINGP/>

## Problem

Keep the fingerprints whose final characters match a given pattern, then print those fingerprints in lexicographic order. If none match, print a fixed failure line.

The first input line holds the pattern, made of letters only. The next line holds the fingerprint count. Each following line is one fingerprint made of letters and spaces, and spaces count as characters. Print the count, then each matching fingerprint on its own line, or the failure line when the count is zero.

| Item | Bound |
|---|---|
| Pattern length | 1 to 50 |
| Fingerprint count | 1 to 10 |
| Fingerprint length | 1 to 50 |
| Judge limit | 1000 ms, 1536 MB |

Short lines keep the scan cheap; exact character order makes the sort matter.

Sample input:

```
On
5
Pattern recognatiOn
CommOn patterN
game
organizatiOn
lion
```

The sample mixes matching suffixes, lowercase letters, and a wrong final letter.

Sample output:

```
2
Pattern recognatiOn
organizatiOn
```

The two matching fingerprints appear in lexicographic order.

## Idea

Checking the tail of a fingerprint is like checking the last word on a page: compare only the ending characters. Read each line whole and compare its final pattern-length slice.

The algorithm is a suffix check on every fingerprint followed by an insertion sort of the matches. A suffix check costs pattern length steps, and sorting at most ten short strings costs little. Building all substrings or searching every position would waste work, because only the line ending matters.

Takeaway: keep whole lines, compare only the tail, then sort the matches.

## Why It Works

1. A fingerprint belongs when its last pattern-length characters equal the pattern exactly.
2. Comparison is case sensitive, so uppercase and lowercase letters never match each other.
3. Spaces are ordinary characters, so a trailing space prevents a match with a letter pattern.
4. Lexicographic order compares the first differing character by character value.
5. Uppercase letters have smaller character values than lowercase letters, so they come first.
6. Reading whole lines preserves leading and trailing spaces for both matching and printing.

| Term | Meaning |
|---|---|
| `specialPattern` | the pattern line read from the input |
| `fingerprint` | one full fingerprint line, spaces included |
| `matchedFingerprints` | fingerprints whose final slice matches |
| suffix | the last pattern-length characters of a line |

The table ties the suffix test to the exact strings printed in the answer.

A script-generated trace of the first sample:

```
'Pattern recognatiOn': last 2 chars 'On' -> True
'CommOn patterN': last 2 chars 'rN' -> False
'game': last 2 chars 'me' -> False
'organizatiOn': last 2 chars 'On' -> True
'lion': last 2 chars 'on' -> False
sorted matches: ['Pattern recognatiOn', 'organizatiOn']
```

The trace names the two fingerprints printed by the sample.

When no line matches, the count is zero and the program prints the failure line. An empty match list never enters the sort loop.

## Code

**Input, scanner, and scanner helper.** Lines are stored whole, and the count comes from a hand scanner.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
var inputLines = newSeq[string]()
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
  inputLines.add inputLine

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`inputLines` keeps spaces that a token scanner would drop. `fingerprintCount` is read from `inputData`. This block runs once.

**Suffix check, sort, and output.** Each line is tested at its end, then matches are ordered and written.

```nim
proc endsWithPattern(text: string, pattern: string): bool =
  if pattern.len > text.len:
    return false
  let startPos = text.len - pattern.len
  for patternIndex in 0 .. pattern.len - 1:
    if text[startPos + patternIndex] != pattern[patternIndex]:
      return false
  return true

let specialPattern = inputLines[0]
let fingerprintCount = nextInt(inputData, scanPos)
var matchedFingerprints = newSeq[string]()
for fingerprintIndex in 0 .. fingerprintCount - 1:
  let fingerprint = inputLines[fingerprintIndex + 2]
  if endsWithPattern(fingerprint, specialPattern):
    matchedFingerprints.add fingerprint

for sortIndex in 1 .. matchedFingerprints.len - 1:
  var cursor = sortIndex
  while cursor > 0 and matchedFingerprints[cursor] < matchedFingerprints[cursor - 1]:
    swap matchedFingerprints[cursor], matchedFingerprints[cursor - 1]
    cursor -= 1

if matchedFingerprints.len == 0:
  appendOutput("Wrong fingerprints!\n")
else:
  appendOutput($matchedFingerprints.len)
  outputBuffer.add '\n'
  for matchedFingerprint in matchedFingerprints:
    appendOutput(matchedFingerprint)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The check skips lines shorter than the pattern. Insertion sort compares strings by character value. One final flush writes every line together.

## Complexity

Each fingerprint costs one suffix comparison, and sorting touches only the matches.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all lines | one line per input row |
| Suffix check | pattern length steps per fingerprint | list of matches |
| Sort and output | quadratic in the match count | block buffer |

The phase table shows that the ten-line cap keeps every phase small.

| Measure | Big O |
|---|---|
| Time | O(total characters plus k squared) for k matches |
| Space | O(input size) |

Searching every position of every fingerprint would cost more than comparing the final slice alone. The suffix check and the small sort keep the work proportional to the input.
