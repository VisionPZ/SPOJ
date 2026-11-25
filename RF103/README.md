# RF103 — FEISBUC GRADO 10 (SPOJ)
<https://www.spoj.com/problems/RF103/>

## Problem

A social platform wants to flag wall messages that contain every misspelled word from a list.
Each input line gives a braced list of quoted words and a quoted wall message.
Print `true` when every listed word occurs in the message, and `false` otherwise.
A line containing only zero ends the input and produces no output.

| Item | Bound |
|---|---|
| Lines | not stated |
| Word and message length | not stated |
| Time limit | 1000 ms |
| Memory | not stated |

One substring test per listed word settles each line.

The sample from the statement:

```
{"a", "e", "i"}, "murcielago"
{"ci", "ur"}, "murcielago"
{"muri"}, "murcielago"
{"i","h", "e"}, "murcielago"
0
```

```
true
true
false
false
```

## Idea

Checking a wall message is like verifying a shopping list against a pantry shelf.
Every listed item must appear somewhere on the shelf.
The program reads the whole input once and handles one line at a time.
It locates the braces, the comma, and the two quotes that delimit the message.
Each quoted word inside the braces is compared with the message by byte scanning.
The first missing word makes the answer `false`.
When every word is found, the answer is `true`.

One pass over the words decides each line.

## Why It Works

1. The braces mark exactly the part of the line that holds the word list.
2. Every quoted pair inside the braces gives one misspelled word.
3. The quoted text after the braces is the wall message.
4. A word counts as present when its bytes appear consecutively in the message.
5. An empty word list is trivially satisfied, so the answer stays `true`.

The main terms follow.

| Term | Meaning |
|---|---|
| `braceStart` | index of the opening brace |
| `braceEnd` | index of the closing brace |
| `message` | quoted text scanned after the braces |
| `wordCursor` | index of the next quoted word inside the braces |
| `allPresent` | flag that turns false at the first missing word |

The scan stops early once a word is missing.

A trace from `gen.py --trace` for the sample:

```
a,e,i in murcielago -> true
ci,ur in murcielago -> true
muri in murcielago -> false
i,h,e in murcielago -> false
```

The trace matches all four sample answers.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds lines by index.

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

**Substring test.** This block checks one word against the message by index.

```nim
proc containsText(haystack: string, needle: string): bool =
  if needle.len == 0:
    return true
  if needle.len > haystack.len:
    return false
  for startPos in 0..(haystack.len - needle.len):
    var matches = true
    for offset in 0..<needle.len:
      if haystack[startPos + offset] != needle[offset]:
        matches = false
        break
    if matches:
      return true
  return false
```

An empty needle always matches.
A needle longer than the message cannot match.
The loop stops at the first complete match.

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

**Line scan.** This block extracts the message and tests every listed word.

```nim
while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  if lineStart == lineEnd:
    continue
  var onlyZero = true
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ' and inputData[position] != '0':
      onlyZero = false
      break
  if onlyZero:
    break

  var braceStart = lineStart
  while braceStart < lineEnd and inputData[braceStart] != '{':
    inc braceStart
  var braceEnd = braceStart
  while braceEnd < lineEnd and inputData[braceEnd] != '}':
    inc braceEnd
  var messageStart = braceEnd
  while messageStart < lineEnd and inputData[messageStart] != '"':
    inc messageStart
  var messageEnd = messageStart + 1
  while messageEnd < lineEnd and inputData[messageEnd] != '"':
    inc messageEnd

  var message = ""
  if messageStart + 1 < messageEnd:
    message = inputData[messageStart + 1 .. messageEnd - 1]

  var allPresent = true
  var wordCursor = braceStart + 1
  while wordCursor < braceEnd:
    while wordCursor < braceEnd and inputData[wordCursor] != '"':
      inc wordCursor
    if wordCursor >= braceEnd:
      break
    let wordStart = wordCursor + 1
    var wordEnd = wordStart
    while wordEnd < braceEnd and inputData[wordEnd] != '"':
      inc wordEnd
    if wordEnd > wordStart:
      let word = inputData[wordStart .. wordEnd - 1]
      if not containsText(message, word):
        allPresent = false
        break
    wordCursor = wordEnd + 1

  if allPresent:
    appendOutput("true\n")
  else:
    appendOutput("false\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A line with only zero ends the run.
The first missing word sets the answer to `false`.
The final write flushes the last partial block.

## Complexity

Cost follows the listed words and the message length.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Word scan | one substring search per word | one message string |
| Output | one write per 128 KiB block | block buffer |

The search stops early at the first missing word.

| Measure | Big O |
|---|---|
| Time | O(w · m) for w words and message length m |
| Space | O(I + B) |

Building a set of all message substrings would cost far more memory.
Direct substring scans need only the message and one word at a time.
