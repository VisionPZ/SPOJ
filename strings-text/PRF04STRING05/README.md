# PRF04STRING05 — String - Limit (SPOJ)

<https://www.spoj.com/problems/PRF04STRING05/>

## Problem

Read one string and print only its first ten characters. Shorter strings print in full; longer strings are cut at character ten.

The input is a single line of text with no spaces. The output is that line truncated to ten characters, followed by a newline.

| item | bound |
|---|---|
| input shape | one line of text |
| reported limit | up to 10 characters, longer input tested |
| judge limit | 1000 ms, 1536 MB |

The ten-character cut is the only limit that matters.

The sample input:

```
123456789011
```

The sample output:

```
1234567890
```

Both blocks match the statement byte for byte.

## Idea

Think of a ten-slot shelf: you load characters until the shelf is full, then ignore the rest. Find where the first line ends, copy at most ten characters from its start, and print them.

The algorithm is a bounded copy over the first line. Each copied character costs one append, so the work is constant, at most ten steps. Splitting the whole line into pieces or building a full copy would read characters that never appear in the answer.

A bounded copy finishes in ten steps no matter how long the input is.

## Why It Works

1. The first newline marks the end of the input string.
2. Characters at positions zero through nine form the required prefix.
3. The loop stops at ten characters or at the line end, whichever comes first.
4. Any character beyond position nine is never appended.
5. The output line ends with a newline, as the sample shows.

| term | meaning |
|---|---|
| `firstLineEnd` | index of the newline that ends the first line |
| `prefixText` | the characters kept for output |
| `keptCount` | number of characters copied so far |
| `keptCharacterLimit` | the fixed value ten |

The two loop bounds together handle both short and long input.

A script trace of the sample lists each position and the decision made there. The counter stops at ten, so the last two characters are ignored.

```
position:       0 1 2 3 4 5 6 7 8 9 10 11
character:      1 2 3 4 5 6 7 8 9 0  1  1
copied:         y y y y y y y y y y  n  n
prefixText:     1234567890
```

The trace ends at the same ten digits as the sample answer.

No rounding or overflow guard is needed because the program copies bytes and never computes a value.

## Code

**Input and output setup.** The reader loads stdin once and defines the block writer.

```nim
const flushBlockBytes = 1 shl 17
const keptCharacterLimit = 10

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

The reader keeps the trailing newline of every line.
The constant named `keptCharacterLimit` holds the value ten.
The writer flushes only when the block is full.

**Line boundary and bounded copy.** The code finds the line end and copies at most ten characters.

```nim
var firstLineEnd = 0
while firstLineEnd < inputData.len and inputData[firstLineEnd] != '\n':
  firstLineEnd += 1

var prefixText = ""
var keptCount = 0
while keptCount < keptCharacterLimit and keptCount < firstLineEnd:
  prefixText.add inputData[keptCount]
  keptCount += 1

appendOutput(prefixText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop stops at the first newline.
The second loop stops at ten or at the line end.
The final flush writes one answer line.

## Complexity

The scan reaches the first newline, then copies a fixed prefix.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| line scan | one pass to the first newline | no extra storage |
| prefix copy | at most ten appends | one prefix string |

The copy phase is bounded by a constant and does not grow with input size.

| measure | Big O |
|---|---|
| time | O(L) to read input of length L |
| space | O(L) for the input string |

Building a full copy of the line would use O(L) work where a ten-step copy is enough.
The fixed cap keeps the answer path constant.
