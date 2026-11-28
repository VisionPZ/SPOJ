# PRMLX — Permalex (SPOJ)
<https://www.spoj.com/problems/PRMLX/>

## Problem

A lowercase word defines the sorted list of its distinct permutations. Report the 1-based position of the given word in that list, right-justified in ten columns. A blank input line represents the empty word and produces 1. A line containing `#` ends the input.

| item | bound |
|---|---|
| letters per word | 0 to 30 |
| alphabet | lowercase a to z |
| terminator | `#` |
| judge limit | 1000 ms, 1536 MB |

Every requested rank fits in 2^31 - 1, so 64-bit arithmetic holds all counted values.

Sample input:

```
bacaa
abc
cba

bacaa
abc
cba
#
```

Sample output:

```
        15
         1
         6
         1
        15
         1
         6
```

## Idea

Counting earlier permutations resembles counting ticket numbers before a chosen ticket: fix one earlier letter and count every arrangement left. The algorithm adds a multinomial count for each unused smaller letter at every position. It then fixes the actual letter and moves right. A full sorted list of permutations would grow beyond memory. Counting whole blocks avoids that list.

## Why It Works

1. Permutations are sorted by their first differing letter.
2. Fixing a smaller letter first counts one whole block of earlier words.
3. That block holds `permutationCount` arrangements of the remaining letters.
4. Adding each smaller-letter block at a position gives the rank minus one.
5. Fixing the actual letter restricts the next position to the same prefix.
6. The initial value 1 converts the count of earlier words into a rank.

| term | meaning |
|---|---|
| `frequencies` | unused copies left for each letter |
| `binomial` | precomputed choose values up to 30 |
| `permutationCount` | arrangements of the multiset left after one choice |
| `rankValue` | running position, starting at 1 |

For `bacaa`, the letter counts are a:3, b:1, c:1. Fixing a at the first position leaves a:2, b:1, c:1, giving 4!/(2!1!1!) = 12 words, so the rank reaches 13. Fixing b leaves a:3, c:1. At the third position, fixing a leaves a:1, c:1, giving 2 more words. The rank becomes 15, matching the sample.

The `rankCeiling` guard caps a growing product before it overflows. Valid inputs never reach that cap.

## Code

**Tables and helpers.** Choose values, whole-input reading, buffered output, and multiset counting.

```nim
const flushBlockBytes = 1 shl 17
const letterCount = 26
const outputFieldWidth = 10
const firstLetterCode = 97
const rankCeiling: int64 = 1 shl 40

var binomial: array[0 .. 30, array[0 .. 30, int64]]
for totalLetters in 0 .. 30:
  binomial[totalLetters][0] = 1
  binomial[totalLetters][totalLetters] = 1
  for chosenLetters in 1 .. totalLetters - 1:
    binomial[totalLetters][chosenLetters] = binomial[totalLetters - 1][chosenLetters - 1] + binomial[totalLetters - 1][chosenLetters]

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

proc permutationCount(frequencies: array[0 .. 25, int]): int64 =
  var placedLetters = 0
  result = 1
  for letterIndex in 0 .. letterCount - 1:
    placedLetters = placedLetters + frequencies[letterIndex]
    let factor = binomial[placedLetters][frequencies[letterIndex]]
    if result > rankCeiling div factor:
      return rankCeiling
    result = result * factor
```

Choose values need only one small table, built once.
The input reader keeps line breaks, so blank words survive.
Each block count multiplies choose values for letter groups.

**Rank loop.** Each line contributes one padded rank, and `#` stops the run.

```nim
var scanPos = 0
while scanPos < inputData.len:
  var lineEnd = scanPos
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var word = inputData[scanPos .. lineEnd - 1]
  if word.len > 0 and word[word.len - 1] == '\r':
    word.setLen word.len - 1
  if word == "#":
    break
  var frequencies: array[0 .. 25, int]
  for letterIndex in 0 .. letterCount - 1:
    frequencies[letterIndex] = 0
  for character in word:
    let letterIndex = int(character) - firstLetterCode
    if letterIndex >= 0 and letterIndex < letterCount:
      frequencies[letterIndex] += 1
  var rankValue: int64 = 1
  for position in 0 .. word.len - 1:
    let actualLetter = int(word[position]) - firstLetterCode
    if actualLetter >= 0 and actualLetter < letterCount:
      for smallerLetter in 0 .. actualLetter - 1:
        if frequencies[smallerLetter] == 0:
          continue
        frequencies[smallerLetter] -= 1
        rankValue = rankValue + permutationCount(frequencies)
        frequencies[smallerLetter] += 1
      frequencies[actualLetter] -= 1
  var rankText = $rankValue
  while rankText.len < outputFieldWidth:
    rankText = " " & rankText
  appendOutput(rankText)
  appendOutput("\n")
  scanPos = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

A trailing carriage return is removed before a word is scored.
Each smaller letter is tried, then restored for the next candidate.
Padding happens in the buffer, and one final write empties it.

## Complexity

| phase | time | space |
|---|---|---|
| choose table build | constant | table of 31 rows |
| one word | up to 30 positions times 26 letters | 26 counters |
| output | one padded line per word | block buffer |

| measure | Big O |
|---|---|
| per word | O(26 * L) for L letters |
| space | O(1) beyond input |

Generating and sorting every permutation would cost factorial time per word.
