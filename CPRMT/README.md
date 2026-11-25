# CPRMT — Common Permutation (SPOJ)

<https://www.spoj.com/problems/CPRMT/>

## Problem

Two lowercase strings are given. Build the longest word using letters found in both strings, counting each letter no more often than in either string. Print the alphabetically first word among all valid answers.

The input has no case count. Each pair of consecutive lines forms one case. Each line holds a lowercase string of at most 1000 letters. Print one answer line per pair.

| item | bound |
|---|---|
| string length | at most 1000 lowercase letters |
| pair count | until end of input |
| answer order | alphabetical |
| judge limit | 1000 ms |

The longest common word uses the smaller supply of every letter.

Sample input:

```
pretty
women
walking
down
the
street
```

Sample output:

```
e
nw
et
```

## Idea

Think of two boxes of letter tiles and keep the smaller stack of each letter, like making one sandwich from whatever both kitchens have.

The algorithm counts letters in each string, then writes each letter in alphabetical order as many times as the smaller count. Counting costs one pass over each string and 26 checks per pair. Trying all permutations or all subsequences would take exponential time.

Counting letters turns the permutation rule into a simple minimum per letter.

## Why It Works

1. A permutation of the answer is a subsequence of a string exactly when that string contains enough copies of every letter.
2. The order of letters inside the answer does not matter, since any permutation may be chosen.
3. The longest valid answer uses min(count in first, count in second) copies of each letter.
4. Writing those letters from a to z gives the alphabetically first answer.

| term | meaning |
|---|---|
| `firstLetterCounts` | how many times each letter appears in the first string |
| `secondLetterCounts` | how many times each letter appears in the second string |
| `sharedCount` | the smaller of the two counts for one letter |
| `commonLetters` | the answer built for one pair |

The table shows that one array entry per letter decides each output character.

A trace for the first sample pair:

```
letter a_count b_count shared
e      1        1       1
```

The shared count for e is one, so the answer for that pair is e.

## Code

**Input and buffering.** All lines are read once, and output is held in one string.

```nim
const flushBlockBytes = 1 shl 17

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

The reader stops at end of input because no case count exists.
Letters are taken only from runs of lowercase characters.
The buffer flushes after 128 KiB, then once more at the end.

**Pair processing.** Each pair builds its answer from the two count arrays.

```nim
var firstLetterCounts = newSeq[int](26)
var secondLetterCounts = newSeq[int](26)
var scanPos = 0
var pairPosition = 0

while scanPos < inputData.len:
  var nextWord = ""
  while scanPos < inputData.len and inputData[scanPos] >= 'a' and inputData[scanPos] <= 'z':
    nextWord.add inputData[scanPos]
    scanPos += 1
  if nextWord.len == 0:
    scanPos += 1
    continue
  if pairPosition == 0:
    for letterChar in nextWord:
      firstLetterCounts[int(letterChar) - 97] += 1
    pairPosition = 1
  else:
    for letterChar in nextWord:
      secondLetterCounts[int(letterChar) - 97] += 1
    var commonLetters = ""
    for letterIndex in 0 .. 25:
      let sharedCount = min(firstLetterCounts[letterIndex], secondLetterCounts[letterIndex])
      for repeatIndex in 0 ..< sharedCount:
        commonLetters.add chr(97 + letterIndex)
    appendOutput(commonLetters)
    outputBuffer.add '\n'
    for letterIndex in 0 .. 25:
      firstLetterCounts[letterIndex] = 0
      secondLetterCounts[letterIndex] = 0
    pairPosition = 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan groups consecutive lowercase letters into one word.
Whitespace-only lines are skipped, so the trailing blank in the sample is harmless.
Both arrays are cleared before the next pair starts.
Each pair costs one pass over its letters plus 26 checks.

## Complexity

The work is one pass over the input letters plus one short scan per pair.

| phase | time | space |
|---|---|---|
| input read | one pass over all letters | one input string |
| pair answer | 26 checks per pair | two arrays of 26 counts |
| output | one line per pair | block buffer |

The phase table shows that output size sets the total cost for long inputs.

| measure | Big O |
|---|---|
| time | O(total letters + 26 times pairs) |
| space | O(total letters) |

Trying permutations would take factorial time, while counting letters stays linear.
