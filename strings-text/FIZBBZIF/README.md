# FIZBBZIF — simple palindromes (SPOJ)

<https://www.spoj.com/problems/FIZBBZIF/>

## Problem

Read phrases until the input ends. For each phrase, test whether its letters and digits read alike in both directions, ignoring case and punctuation. Print the original phrase followed by the verdict.

Input: a list of words or phrases, one per line, with no count line. Output: one line per phrase, either the phrase plus ` is a palindrome` or the phrase plus ` is not a palindrome`.

| item | bound |
|---|---|
| characters per line | no more than 40, per judge note |
| number of lines | ends at EOF |
| judge limit | 1000 ms, 1536 MB |

Punctuation, spaces, and capital letters do not change the verdict.

The sample input:

```
dad
Hannah
A man, a plan, a canal, Panama!
```

The sample output:

```
dad is a palindrome
Hannah is a palindrome
A man, a plan, a canal, Panama! is a palindrome
```

## Idea

Check from both ends like two people reading the same word from opposite sides. Each side skips punctuation, lowers capitals, and compares one character per step. This is a two-pointer palindrome scan costing O(L) time for a phrase of length L. Building a cleaned copy and reversing it also costs O(L) extra space, while the two pointers use none. Compare in place and print the untouched phrase.

## Why It Works

1. Spaces and punctuation never enter the comparison.
2. Lowering uppercase letters makes case irrelevant.
3. Both pointers move inward, so every candidate pair is tested once.
4. A mismatch settles the phrase immediately; no mismatch means all pairs agreed.

| term | meaning |
|---|---|
| `isWordCharacter` | true for a letter or digit |
| `loweredCharacter` | maps A-Z to a-z, leaves other characters unchanged |
| `isPalindromePhrase` | the two-pointer test for one phrase |
| `outputBuffer` | pending answer text written in large blocks |

These names separate character rules from the comparison loop.

A trace from the generator with visible pairs:

```
dad      kept d a d       pairs d/d, a/a          palindrome
Hannah   kept h a n n a h pairs h/h, a/a, n/n    palindrome
hello    kept h e l l o   first pair h/o         not a palindrome
```

The first mismatch decides the answer for every phrase.

## Code

**Input and character helpers.** The reader keeps whole lines and the scanner remains available for numeric input.

```nim
const flushBlockBytes = 1 shl 17

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

proc isWordCharacter(letter: char): bool =
  return (letter >= 'a' and letter <= 'z') or (letter >= 'A' and letter <= 'Z') or (letter >= '0' and letter <= '9')

proc loweredCharacter(letter: char): char =
  if letter >= 'A' and letter <= 'Z':
    return chr(int(letter) + 32)
  return letter
```

Lines keep their original spacing, so the verdict can follow the exact phrase.
The hand scanner reads input without allocations per token.
Character tests use ASCII ranges and avoid ordinal conversion.

**Palindrome test.** Both pointers skip ignored characters before each comparison.

```nim
proc isPalindromePhrase(phrase: string): bool =
  var leftIndex = 0
  var rightIndex = phrase.len - 1
  while leftIndex < rightIndex:
    while leftIndex < rightIndex and not isWordCharacter(phrase[leftIndex]):
      leftIndex += 1
    while leftIndex < rightIndex and not isWordCharacter(phrase[rightIndex]):
      rightIndex -= 1
    if loweredCharacter(phrase[leftIndex]) != loweredCharacter(phrase[rightIndex]):
      return false
    leftIndex += 1
    rightIndex -= 1
  return true
```

Each loop walks at most half of one line.
A false result exits before later pairs are read.
The true result covers empty phrases and single characters.

**Buffered output loop.** Each phrase and its suffix enter one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var lineStart = 0
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  let phrase = inputData[lineStart .. lineEnd - 1]
  appendOutput(phrase)
  if isPalindromePhrase(phrase):
    appendOutput(" is a palindrome")
  else:
    appendOutput(" is not a palindrome")
  outputBuffer.add '\n'
  lineStart = lineEnd + 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final empty segment after the last newline is skipped by the loop bound.
Large outputs flush in blocks, and one final write closes the stream.
Each phrase produces exactly one output line.

## Complexity

Costs grow with the total number of input characters.

| phase | time | space |
|---|---|---|
| input read | one pass over all input characters | one input string |
| palindrome test | at most half of each line per phrase | constant |
| output | one pass over written text | block buffer |

The input string dominates space use.

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(total input characters) |

Building and reversing a cleaned copy uses the same time but extra space per phrase; the in-place scan avoids that cost. The two-pointer scan answers every phrase in one left-to-right pass over its pairs.
