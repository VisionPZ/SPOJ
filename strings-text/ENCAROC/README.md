# ENCAROC — Occurrences of a Character (SPOJ)
<https://www.spoj.com/problems/ENCAROC/>

## Problem

A line of text and a single character are given. Print how many times that character appears in the text.

The first input line is the text, and the second line holds the character. Spaces may occur inside the text.

| Item | Value |
|---|---|
| Input | one text line, then one character line |
| Output | one integer, the occurrence count |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The whole text is available at once, so one scan is enough.

The statement sample follows verbatim.

```
hello world
o
```

```
2
```

## Idea

Think of a turnstile clicked once for every matching letter in a line.
The program reads the whole input, finds the second line, and clicks once per match.
A fresh count starts at zero and grows only when characters are equal.
Repeated searching would rescan the text for every position and cost far more.

The final count is the answer.

## Why It Works

1. The first line break marks the end of the text exactly.
2. The first nonspace character after that break is the target.
3. Comparing each text character once counts every occurrence.
4. Characters that differ leave the count unchanged.
5. An empty text yields zero because the loop has no iterations.

| Term | Meaning |
|---|---|
| text line | all characters before the first line break |
| target | the character on the second line |
| occurrence | a position where the character equals the target |

These facts make a single left-to-right pass complete.

A script trace of the sample marks the matching positions.

```
string: hello world
character: o
positions (zero based): [4, 7]
count: 2
```

Two marked positions give the sample answer 2.

## Code

**Locate the target.**
```nim
var lineBreak = 0
while lineBreak < inputData.len and inputData[lineBreak] != '\n':
  lineBreak += 1

var scanPos = lineBreak + 1
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
```

The scan stops at the first line break. Whitespace after it is skipped. The target is one character.

**Count matches.**
```nim
var occurrenceCount = 0
if scanPos < inputData.len:
  let targetChar = inputData[scanPos]
  for index in 0..<lineBreak:
    if inputData[index] == targetChar:
      occurrenceCount += 1
```

Only the text range is visited. Equality adds one to the running count.

**Emit the count.**
```nim
appendOutput($(occurrenceCount))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The answer is converted to text and buffered. A newline ends the single output line.

## Complexity

The scan over the text is the only substantive work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Counting | one pass over the text | constant |
| Output | one buffered write | buffer block |

Every text character is compared exactly once.

| Measure | Big O |
|---|---|
| Time | O(input bytes) |
| Space | O(input bytes) |

Searching the text once per position would cost O(n squared), so one pass wins.
