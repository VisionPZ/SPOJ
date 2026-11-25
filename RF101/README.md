# RF101 — XYBALANCE Grado 10 (SPOJ)
<https://www.spoj.com/problems/RF101/>

## Problem

Walter has strings of DNA letters and must decide whether each string balances x against y.
A string is balanced when it has at least as many y letters as x letters.
Print `True` for a balanced string and `False` otherwise, one answer per line.
Each input line holds one quoted string, and input ends at end of file.

| Item | Bound |
|---|---|
| Strings | not stated |
| String length | not stated |
| Time limit | 1000 ms |
| Memory | not stated |

Only the counts of the two letters matter, so one pass per line is enough.

The sample from the statement follows.

```
"aaxbby"
"aaxbb"
"bbbaxyb"
"jjjxjjjy"
"fefsegesxy"
"xydawdhafw"
"aaaaaxxxxxx"
"xaxwdawyx"
```

```
True
False
True
True
True
True
False
False
```

## Idea

Checking balance is like counting forks and knives in a drawer: every fork needs a knife, and extra knives are fine.
The program reads the whole input once and walks it line by line.
For each line it counts the letters x and y by index.
It prints `True` when the y count is at least the x count.
Quotes and all other letters are ignored, so no string copying is needed.
Answers leave in one buffer flushed in blocks, which keeps writes rare.

One scan of each line decides the answer.

## Why It Works

1. The statement defines balance as having a y for every x.
2. Extra y letters do not break balance, so the comparison uses at least.
3. Quotes and other letters never affect either count.
4. A line with no x and no y is balanced by the same rule.
5. Each answer ends with a newline, matching the sample's line shape.

The main terms follow.

| Term | Meaning |
|---|---|
| `lineStart` | index of the first byte of the current line |
| `lineEnd` | index after the last byte of the current line |
| `xCount` | number of x letters on the line |
| `yCount` | number of y letters on the line |
| `outputBuffer` | one buffer holding answer text |

The comparison `yCount >= xCount` implements the stated rule directly.

A trace from `gen.py --trace` for five sample lines:

```
aaxbby x=1 y=1 True
aaxbb x=1 y=0 False
jjjxjjjy x=1 y=1 True
aaaaaxxxxxx x=6 y=0 False
xaxwdawyx x=3 y=1 False
```

The trace matches the sample answers for those lines.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds each line by index.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)
```

The read loop ends at end of input.
Both carriage returns and line feeds end a line.
Empty lines are skipped by the leading scan.

**Output buffer.** This block buffers answer text and flushes it in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
`appendOutput` adds text and then checks the size.
The last partial block is written after the loop.

**Balance loop.** This block counts the two letters and prints one answer.

```nim
while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var hasContent = false
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ':
      hasContent = true
      break
  if not hasContent:
    continue
  var xCount = 0
  var yCount = 0
  for position in lineStart..<lineEnd:
    if inputData[position] == 'x':
      inc xCount
    elif inputData[position] == 'y':
      inc yCount
  if yCount >= xCount:
    appendOutput("True\n")
  else:
    appendOutput("False\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Whitespace-only lines produce no answer.
Each byte is inspected twice at most.
The final write flushes the last partial block.

## Complexity

Cost follows the number of input bytes.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Counting | one pass over each line | two counters |
| Output | one write per 128 KiB block | block buffer |

No substring or token object is created during the scan.

| Measure | Big O |
|---|---|
| Time | O(I) for I input bytes |
| Space | O(I + B) |

Counting by tokens would allocate one object per string.
Direct byte counting avoids that cost.
