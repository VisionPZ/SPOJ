# MOZSAO — Sharmeen and One (SPOJ)

<https://www.spoj.com/problems/MOZSAO/>

## Problem

For each number `n`, write the word `one` exactly `n` times, separated by single spaces, then append `n` exclamation marks. Print one such line per test case.

The first input line holds `t`, the number of cases. Each following line holds one integer `n`. Output lines must be exact, including spaces and mark counts.

| item | bound |
|---|---|
| test cases `t` | 1 to 50 |
| repeat count `n` | 1 to 50000 |
| judge limit | 1000 ms, 1536 MB |

The on-page sample collapses its line breaks. The layout below shows the two cases on separate lines.

Sample input:

```
2
1
2
```

Sample output:

```
one!
one one!!
```

For `n = 2`, two words are separated by one space and followed by two marks.

## Idea

Writing the words one by one is like laying tiles along a shelf; build the whole strip in one pass. Append each word and space to a string, then append the marks. A buffered writer sends large blocks instead of many tiny writes. Appending to a growing string costs O(n) per case, while repeated whole-string copies would cost O(n^2).

## Why It Works

1. The words occupy `3n + (n-1)` characters, since spaces sit only between words.
2. The marks add `n` characters, for `5n - 1` characters per line.
3. The loop adds a space only after the first word.
4. A second loop adds one mark per repetition.
5. The output buffer flushes by size, so large lines still leave in blocks.

| term | meaning |
|---|---|
| `repetitionCount` | `n`, the number of words and marks |
| `words` | the space-separated word strip |
| `marks` | the run of exclamation marks |
| `caseCount` | `t`, the number of test cases |

The generator checks `n = 3`. It produces `one one one!!!`, with three words, two spaces, and three marks.

| n | words | spaces | marks | line length |
|---|---|---|---|---|
| 1 | 1 | 0 | 1 | 4 |
| 2 | 2 | 1 | 2 | 9 |
| 3 | 3 | 2 | 3 | 14 |

Every length equals `5n - 1`, matching the loop structure.

## Code

**Input and scanning.** The hand reader loads every test case value.

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
```

The scanner skips the case line and reads each count.
All input is stored once before output begins.
The digit loop handles counts up to 50000.

**Line construction and buffered output.** Two loops build the words and the marks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let repetitionCount = nextInt(inputData, scanPos)
  var words = ""
  for wordIndex in 1 .. repetitionCount:
    if wordIndex > 1:
      words.add ' '
    words.add "one"
  var marks = ""
  for markIndex in 1 .. repetitionCount:
    marks.add '!'
  appendOutput(words)
  appendOutput(marks)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop inserts a space before every word except the first.
The second loop appends one mark for each word.
A single newline ends the case.

## Complexity

Each case builds one line and sends it through the buffer.

| phase | time | space |
|---|---|---|
| input read | one pass over `t` counts | one input string |
| word strip | O(n) appends | one string of `4n-1` bytes |
| marks | O(n) appends | one string of `n` bytes |
| output | block writes | one block buffer |

| measure | Big O |
|---|---|
| time per case | O(n) |
| space per case | O(n) |

Rebuilding the entire line on each word would spend O(n^2) time.

Appending each character once keeps the work linear.
