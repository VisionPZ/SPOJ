# SEGSI — Segsi Substrings (SPOJ)

<https://www.spoj.com/problems/SEGSI/>

## Problem

Take a string and join k copies of it into one long string. Count the substrings equal to the five-letter word segsi in that joined string.

Input: line one holds s, with length at most 100000. Line two holds k, at most 1000000000. Output: one integer, the number of matching substrings.

| item | bound |
|---|---|
| string length | up to 100000 |
| copy count k | up to 1000000000 |
| pattern length | 5 |
| judge limit | 1000 ms, 1536 MB |

The huge copy count rules out building the joined string.

The sample input:

```
siseg
10
```

The sample output:

```
9
```

## Idea

Count matches in one copy, like counting windows on one repeating strip of wallpaper. A window that fits inside a copy appears k times; one that crosses a seam appears k minus one times. Scan the starts inside one copy against a short extended string. This costs O(5n) time and O(5n + n) space, while building all k copies costs O(kn) time and memory. Scan one period and multiply the two match classes.

## Why It Works

1. Every substring of the joined string starts at some position inside one copy.
2. A start at most n minus 5 fits wholly inside its copy, so it repeats k times.
3. A later start reaches into the next copy, which exists after only k minus 1 seams.
4. Two extended copies give every possible five-character window a real suffix.

| term | meaning |
|---|---|
| `sourceString` | the input string s of length n |
| `repeatCount` | the copy count k |
| `extendedString` | source repeated enough times to finish every window |
| `interiorMatches` | starts at most n minus 5, counted k times |
| `wrapMatches` | later starts, counted k minus 1 times |

The split by start position removes all dependence on the size of k.

A trace from the generator with visible starts:

```
s = siseg, n = 5, k = 10, n - 5 = 0
start 0: siseg no      start 1: isegs no
start 2: segsi yes     n - 5 = 0, so this start wraps
start 3: egssi no      start 4: gsise no
answer = 1 * (10 - 1) = 9
```

The wrapped match at start 2 explains the sample answer nine.

## Code

**Input and buffered output.** The source line is read before the numeric copy count.

```nim
const flushBlockBytes = 1 shl 17
const searchPattern = "segsi"
const patternLength = 5

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner skips the newline after the source string.
The pattern and its length stay as constants, so the scan never reallocates.

**One-period scan.** Each start position in the source gets exactly five checks.

```nim
var sourceEnd = 0
while sourceEnd < inputData.len and inputData[sourceEnd] != '\n':
  sourceEnd += 1
let sourceString = inputData[0 .. sourceEnd - 1]
scanPos = sourceEnd + 1
let repeatCount = nextInt(inputData, scanPos)

var extendedString = ""
let copiesNeeded = patternLength div sourceString.len + 2
for copyIndex in 0 .. copiesNeeded - 1:
  extendedString.add sourceString

var interiorMatches: int64 = 0
var wrapMatches: int64 = 0
let lastInteriorStart = sourceString.len - patternLength
for startIndex in 0 .. sourceString.len - 1:
  var foundMatch = true
  for patternOffset in 0 .. patternLength - 1:
    if extendedString[startIndex + patternOffset] != searchPattern[patternOffset]:
      foundMatch = false
      break
  if foundMatch:
    if startIndex <= lastInteriorStart:
      interiorMatches += 1
    else:
      wrapMatches += 1
```

Multiplication by k uses int64 to hold answers near 5 times 10 to the 14th.
The innermost loop stops at the first mismatched character.
Only starts inside one period are visited, even for a billion copies.

**Final count.** The two classes use different multipliers.

```nim
let totalMatches = interiorMatches * int64(repeatCount) + wrapMatches * int64(repeatCount - 1)
appendOutput($totalMatches)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Interior windows occur once per copy, and seam windows once per seam.
A single line carries the answer after the buffer is flushed.

## Complexity

Each candidate start takes a fixed five character checks.

| phase | time | space |
|---|---|---|
| input read | one pass over s and k | one input string |
| window scan | five checks per start in s | two strings of size s |
| output | one integer | block buffer |

The scan length depends on the string size, not the copy count.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

Building all k copies uses O(kn) time and space, while one period keeps both bounds linear in n. The constant five makes the scan cheap for the full 100000 character input.
