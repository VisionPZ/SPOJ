# UC_OLAMUNDO — UCSAL - Olá Mundo! (SPOJ)

<https://www.spoj.com/problems/UC_OLAMUNDO/>

## Problem

A first program reads one name and greets that person in Portuguese. The greeting text is fixed; only the name changes.

The input is one line holding the name. Print the exact greeting line with that name inserted.

| item | bound |
|---|---|
| input | one name string |
| judge limit | 1000 ms, 1536 MB |

The sample fixes every character of the greeting, including accents.

Sample input:

```
Everton
```

Sample output:

```
Olá Everton, este é seu primeiro programa!
```

## Idea

Copy the fixed greeting around the name, like filling a blank on a printed form. Read the first line once, then write the greeting with that line inserted between its two fixed parts. No number parsing is needed because the input is text. One read and one buffered write settle the whole task.

## Why It Works

1. The first line of input holds the whole name.
2. The greeting has a fixed prefix and a fixed suffix.
3. Placing the name between them reproduces the required line exactly.
4. Trailing whitespace is dropped so the suffix starts at the right character.

| term | meaning |
|---|---|
| `visitorName` | text taken from the first input line |
| `outputBuffer` | single buffer holding the finished line |

One line in, one line out.

Script-generated trace for the sample name:

```
prefix: "Olá "
name:   "Everton"
suffix: ", este é seu primeiro programa!"
```

Joining the three parts gives the sample output byte for byte.

## Code

**Bulk input and output.** The stream is read once, then the first line is located by index.

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

All input lines are gathered first.
The buffer flushes only when it grows large.
Reading once avoids a syscall per line.

**Name extraction.** Two index walks isolate the name between the line breaks.

```nim
var nameStart = 0
while nameStart < inputData.len and (inputData[nameStart] == '\n' or inputData[nameStart] == '\r' or inputData[nameStart] == ' '):
  nameStart += 1
var nameEnd = nameStart
while nameEnd < inputData.len and inputData[nameEnd] != '\n' and inputData[nameEnd] != '\r':
  nameEnd += 1
let visitorName = inputData[nameStart ..< nameEnd]
appendOutput("Olá " & visitorName & ", este é seu primeiro programa!")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first walk skips leading whitespace.
The second walk stops at the first line break.
The greeting is written once from the block buffer.

## Complexity

One line of text makes the whole run constant apart from reading and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| greeting | one string join | one name slice |
| output | one buffered line | block buffer |

No parsing or search is needed beyond finding the line break.

| measure | Big O |
|---|---|
| time | O(input bytes) |
| space | O(input bytes) |

Analyzing every character for patterns would add work without changing the fixed greeting.
