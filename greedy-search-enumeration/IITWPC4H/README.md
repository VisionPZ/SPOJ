# IITWPC4H — Maggu and Cuteness of Strings (SPOJ)

<https://www.spoj.com/problems/IITWPC4H/>

## Problem

Merge two strings into one by interleaving their characters, then find the longest run of equal letters in any merge. A merge keeps the letters of each source string in their original order and uses every letter exactly once.

Input starts with T. Each following line holds two space-separated strings s and t made of lowercase letters. Output one integer per case: the largest cuteness value over all valid merges.

| item | bound |
|---|---|
| string lengths | 1 to 100000 each |
| total input length | below 5000000 |
| judge limit | 1000 ms, 1536 MB |

A long repeated letter in either string can be combined with a matching run in the other string.

Sample input:

```
1
ab ab
```

Sample output:

```
2
```

## Idea

Treat each letter separately, like snapping two identical train cars together at the same station. A run of one letter from s can join a run of the same letter from t, so their lengths add.

The algorithm scans runs in both strings and keeps the best run length per letter. Each scan touches every character once, giving linear cost. Trying every interleaving would enumerate exponentially many merges. The answer is the largest sum of a run from s and a run from t over all letters.

Run merging turns an exponential search into two linear scans.

## Why It Works

1. A valid merge is an interleaving of s and t, so each string keeps its own letter order.
2. Letters of one string that lie between two equal letters must stay between them in every merge.
3. Therefore a run of c in any merge uses letters from one run of c in s and one run of c in t.
4. Any chosen run from s and chosen run from t can be placed together: put earlier letters first, then the two runs, then later letters.
5. The best cuteness for letter c is the sum of the longest c-run in s and the longest c-run in t.

| term | meaning |
|---|---|
| `longestFirstRuns` | longest run of each letter in s |
| `currentRun` | run length at the current position of a scan |
| `combinedRun` | a run from s added to a run from t |
| `cuteness` | best combined run seen so far |

Each table term maps to one variable in the main loop.

The worked trace uses s = ab and t = ab:

```
scan s: run of a = 1, run of b = 1
scan t: run of a = 1, combined run = 1 + 1 = 2
scan t: run of b = 1, combined run = 1 + 1 = 2
best cuteness = 2
```

The trace reaches 2, which matches the sample output.

Letters absent from s have a stored run of zero. The initial pass over `longestFirstRuns` covers letters that appear only in s.

## Code

**Input and token scanning.** The reader loads all lines, then extracts integers and space-separated strings.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const firstLetterCode = 97

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

The token scanner stops at the first whitespace byte.
Letter codes use `firstLetterCode` as the base index.
Both scanners share one cursor into `inputData`.

**Run scan.** The first pass records runs in s, and the second pass combines them with runs in t.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let firstString = nextToken(inputData, scanPos)
  let secondString = nextToken(inputData, scanPos)
  var longestFirstRuns: array[alphabetSize, int]
  var previousLetter = -1
  var currentRun = 0
  for letter in firstString:
    let letterIndex = int(letter) - firstLetterCode
    if letterIndex == previousLetter:
      currentRun += 1
    else:
      currentRun = 1
      previousLetter = letterIndex
    if currentRun > longestFirstRuns[letterIndex]:
      longestFirstRuns[letterIndex] = currentRun
  var cuteness = 0
  for letterIndex in 0 .. alphabetSize - 1:
    if longestFirstRuns[letterIndex] > cuteness:
      cuteness = longestFirstRuns[letterIndex]
  previousLetter = -1
  currentRun = 0
  for letter in secondString:
    let letterIndex = int(letter) - firstLetterCode
    if letterIndex == previousLetter:
      currentRun += 1
    else:
      currentRun = 1
      previousLetter = letterIndex
    let combinedRun = longestFirstRuns[letterIndex] + currentRun
    if combinedRun > cuteness:
      cuteness = combinedRun
  appendOutput($cuteness)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The array of 26 slots covers the whole lowercase alphabet.
Each scan advances once per character.
The buffer emits one answer per case.

## Complexity

Each case reads both strings once and updates a fixed-size letter table.

| phase | time | space |
|---|---|---|
| input read | one pass over all input bytes | one input string |
| run scans | one pass over s and t | 26 integer slots |
| output | one buffered line per case | block buffer |

Run scanning dominates, and its cost scales with the two string lengths.

| measure | Big O |
|---|---|
| time | O(n + m) per case |
| space | O(1) beyond input and output storage |

Enumerating interleavings grows exponentially, while run scanning touches each character exactly once.
