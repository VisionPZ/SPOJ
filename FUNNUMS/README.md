# FUNNUMS — FUN WITH LETTERS (SPOJ)

<https://www.spoj.com/problems/FUNNUMS/>

## Problem

A string holds each letter from `a` up to its length exactly once. Report the string that appears N permutations later in lexicographic order. The input promises that this string exists.

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| word length | 2 to 15 |
| letters | `a` through `a + length - 1`, all distinct |
| judge limit | 2000 ms, 1536 MB |

Input starts with the test count. Each later line holds a word and the shift N. Output has one transformed word per line.

Sample input:

```
3
abdc 2
adcb 3
badc 7
```

Sample output:

```
acdb
bcad
cbad
```

## Idea

Treat every permutation as a page number on an odometer, like turning a car's trip meter forward. The factorial number system gives each word its page number directly. Add N to that number, then rebuild the word from the new page number. A naive program applies the next-permutation step N times; this method finishes in one pass over the word.

Two passes over at most 15 letters suffice, one to rank and one to unrank. The precomputed factorial table makes each pass cheap.

## Why It Works

1. A permutation's rank counts the smaller permutations that come before it.
2. At position `posIndex`, the number of unused letters smaller than the current letter gives a Lehmer digit.
3. That digit contributes `smallerCount` times `factorials[wordLength - 1 - posIndex]` to the rank.
4. Adding the shift advances the rank by exactly N pages.
5. Unranking divides the new rank by each descending factorial to recover every Lehmer digit.
6. The chosen digit selects one letter from the still-unused letters, which rebuilds the word.

| term | meaning |
|---|---|
| `factorials` | precomputed factorials up to 15 |
| `rankValue` | zero-based page number of the word |
| `shiftCount` | number of permutations to advance |
| `availableLetters` | flags for letters not yet consumed |

The table lists each value that the two passes maintain.

A trace from the generator for `abdc 2` uses repeated next-permutation steps. The rank method reaches the same page in two arithmetic passes.

```
letters a b d c: Lehmer digits 0 0 1 0
rank = 0*6 + 0*2 + 1*1 + 0*1 = 1
new rank = 1 + 2 = 3 -> digits 0 1 0 0 -> acdb
```

The generated answer matches the sample line `acdb`.

## Code

**Input and scanning.** The hand reader loads words and shifts into one buffer.

```nim
const flushBlockBytes = 1 shl 17
const letterBase = 97
const maxWordLength = 15

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var word = ""
  while pos < data.len and data[pos] > ' ':
    word.add data[pos]
    pos += 1
  return word
```

The word reader stops at the first space.
The integer reader skips any separator.
Both readers share one scan position.

**Output buffer and factorials.** One buffer collects all answers while the table is built once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var factorials = newSeq[int64](maxWordLength + 1)
factorials[0] = 1
for sizeIndex in 1 .. maxWordLength:
  factorials[sizeIndex] = factorials[sizeIndex - 1] * int64(sizeIndex)
```

The buffer flushes after 128 KiB.
Factorials fit in 64 bits because 15! is below 2 to the 41.
The table is shared by every test case.

**Ranking.** Each position contributes one Lehmer digit.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let permutationText = nextWord(inputData, scanPos)
  let shiftCount = int64(nextInt(inputData, scanPos))
  let wordLength = permutationText.len
  var availableLetters = newSeq[bool](wordLength)
  for letterIndex in 0 .. wordLength - 1:
    availableLetters[letterIndex] = true
  var rankValue: int64 = 0
  for posIndex in 0 .. wordLength - 1:
    let letterIndex = int(permutationText[posIndex]) - letterBase
    var smallerCount = 0
    for candidate in 0 .. letterIndex - 1:
      if availableLetters[candidate]:
        smallerCount += 1
    rankValue = rankValue + int64(smallerCount) * factorials[wordLength - 1 - posIndex]
    availableLetters[letterIndex] = false
```

The scanner consumes a word and its shift.
Each counted letter is removed from the pool.
The rank stays under 15! plus the allowed shift.

**Unranking.** The advanced rank selects one letter at a time.

```nim
  rankValue = rankValue + shiftCount
  for letterIndex in 0 .. wordLength - 1:
    availableLetters[letterIndex] = true
  var answerText = ""
  for posIndex in 0 .. wordLength - 1:
    let blockSize = factorials[wordLength - 1 - posIndex]
    let chosenIndex = int(rankValue div blockSize)
    rankValue = rankValue mod blockSize
    var seenCount = 0
    for candidate in 0 .. wordLength - 1:
      if availableLetters[candidate]:
        if seenCount == chosenIndex:
          answerText.add char(candidate + letterBase)
          availableLetters[candidate] = false
          break
        seenCount += 1
  appendOutput(answerText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Division recovers the next Lehmer digit.
The digit indexes the remaining unused letters.
One final flush writes the buffered lines.

## Complexity

The factorial table is built once, and each case costs two short passes.

| phase | time | space |
|---|---|---|
| factorial table | 15 steps | 16 integers |
| ranking | up to 15 positions times 15 letters | one flag array |
| unranking | up to 15 positions times 15 letters | one output word |
| output | one write per block | one output string |

The table shows that every phase is bounded by the word length.

| measure | Big O |
|---|---|
| time per case | O(L^2) for word length L |
| space per case | O(L) |

Repeating next-permutation would cost O(N * L) and grows with the shift. Ranking and unranking depend only on the word length.
