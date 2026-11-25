# TEST — Life, the Universe, and Everything (SPOJ)

<https://www.spoj.com/problems/TEST/>

## Problem

Input: one integer per line, each of one or two digits. Output: the same lines,
copied in order, and processing stops once `42` has been read.

| item | bound |
|---|---|
| numbers in the input | one or two digits |
| stop marker | `42`, not printed |
| judge limits | 1 s, 1536 MB, 50000 B source |

Sample in, sample out:

```
1
2
88
42
99
```

```
1
2
88
```

## Idea

Copy every line until the line reads `42`, then stop. Cost per line: one compare
plus one write, so O(lines read) and no memory beyond one line.
Any parsing is slower work for no gain. The stop test is an equality on text, so
converting the line to a number adds effort and cannot change the answer.

## Why It Works

The statement fixes two things, and the program relies on exactly those.

| fact | how the program uses it |
|---|---|
| one integer per line | one line read per number, so no token scanner is needed |
| numbers hold one or two digits | the text compare against `42` is exact once surrounding blanks are gone |

`line.strip` removes the trailing `CR` that a Windows input file carries, plus
leading and trailing spaces. Without it, `"42 "` and `"42"` would differ and the
program would run past the marker, which is the usual wrong answer here.

`echo numberText` writes the line and its newline, so the copied output keeps one line per
number. The `break` runs before the write, so `42` never reaches the output, and
the lines after it are never read. `99` after `42` in the sample proves this: it
is absent from the expected output.

The program also ends correctly when `42` is missing: the line loop runs out.
When `42` is the first line, no write happens at all.

## Code

```nim
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

```

`strip` comes from `std/strutils`. It is the only import, and it is used for that
one call.

```nim
let totalLen = inputData.len
while lineStart < totalLen:
  var lineEnd = lineStart
  while lineEnd < totalLen and inputData[lineEnd] != '\n':
    lineEnd += 1
  var trimStart = lineStart
  while trimStart < lineEnd and inputData[trimStart] <= ' ':
    trimStart += 1
  var trimEnd = lineEnd
  while trimEnd > trimStart and inputData[trimEnd - 1] <= ' ':
    trimEnd -= 1
  if trimEnd - trimStart == 2 and inputData[trimStart] == '4' and inputData[trimStart + 1] == '2':
    break
  for charIdx in trimStart..<trimEnd:
    outputBuffer.add inputData[charIdx]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  lineStart = lineEnd + 1

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0

```

`lines(stdin)` yields one line at a time, so memory holds a single line. `let numberText` binds the stripped text once per line. The `if numberText == "42": break` line sits above
the `echo numberText` line, which is what keeps `42` out of the output.

## Complexity

| phase | time | space |
|---|---|---|
| line read | one line at a time | one line |
| stop test | one string compare per line | none |
| output write | one write per copied line | one line |
| total | O(lines up to and including the first 42) | O(longest line) |

| measure | Big O |
|---|---|
| time | O(k), where k is the number of lines read |
| space | O(1) beyond the current line |

Per line writes cost more than a buffered writer in general. They are enough here
because the output stops at the first `42`, so the line count stays small.
