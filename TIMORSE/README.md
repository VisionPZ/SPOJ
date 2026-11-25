# TIMORSE — Timing Morse (SPOJ)

<https://www.spoj.com/problems/TIMORSE/>

## Problem

Compute the Morse Code length of each message, measured in dot durations. A dot lasts one unit, a dash three. Gaps inside a letter last one, between letters three, and between words seven.

Input: first line n, the number of messages. Each of the next n lines holds one message of lowercase letters and spaces; other characters are ignored. Output: n lines, each in the form original message, colon, space, length equals, space, and the number.

| item | bound |
|---|---|
| messages | given by n on the first line |
| message characters | a to z and space; other characters ignored |
| dot, dash, inner, letter, word gaps | 1, 3, 1, 3, 7 units |
| judge limit | 1000 ms, 1536 MB |

The original message text must appear again before the colon.

The sample input:

```
2
hi joe
sos
```

The sample output:

```
hi joe: length = 51
sos: length = 27
```

## Idea

Add durations like filling a timeline with blocks, like stacking tiles of length one and three. Each letter contributes its symbols plus the small gaps between them. A new letter after letters adds three; a new letter after spaces adds seven. This runs in O(m) time for a message of m characters with a fixed table lookup per letter. Simulating the whole timeline with a list costs the same time and extra space. Keep a running total instead.

## Why It Works

1. A letter with m symbols and d dashes spans 2d + 2m - 1 units.
2. Two letters in one word add a three-unit letter gap.
3. The first letter after any run of spaces adds a seven-unit word gap.
4. Repeated spaces still form one word gap, because the letter flag stays cleared.
5. Ignored characters add nothing and do not break a word.

| term | meaning |
|---|---|
| `morseCodes` | fixed code string for each letter a to z |
| `letterDuration` | units for one code, including inner gaps |
| `previousWasLetter` | true when the last kept character was a letter |
| `messageHasLetter` | true once any letter has been read |
| `totalLength` | running unit count for one message |

The two flags decide which gap, if any, comes before a letter.

A trace from the generator with visible units:

```
h = .... -> 4 dots + 3 inner gaps = 7
i = ..   -> 2 dots + 1 inner gap  = 3
gap h/i  -> 3 units -> hi = 13
joe      -> 13 + 3 + 11 + 3 + 1 = 31
hi joe   -> 13 + 7 + 31 = 51
sos      -> 3 + 3 + 3 + 3 + 3 + 3 + 3 + 3 + 3 = 27
```

The word gap of seven turns 13 plus 31 into the sample answer 51.

## Code

**Input and Morse helpers.** The fixed table and reader cover all needed characters.

```nim
const flushBlockBytes = 1 shl 17
const firstLowerLetter = 97
const morseCodes = [".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---", "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-", "..-", "...-", ".--", "-..-", "-.--", "--.."]

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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

proc letterDuration(code: string): int =
  var duration = 0
  for symbolIndex in 0 .. code.len - 1:
    if code[symbolIndex] == '-':
      duration += 3
    else:
      duration += 1
    if symbolIndex < code.len - 1:
      duration += 1
  return duration
```

The table index comes from the letter code minus the start of the lowercase range.
Raw line reads keep the message exactly as it appeared in the input.
Inner gaps are counted only between symbols, never after the last one.

**Buffered message loop.** One pass per message adds symbols and gaps to a counter.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let messageCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for messageIndex in 0 .. messageCount - 1:
  let message = nextRawLine(inputData, scanPos)
  var totalLength = 0
  var previousWasLetter = false
  var messageHasLetter = false
  for charIndex in 0 .. message.len - 1:
    let currentLetter = message[charIndex]
    if currentLetter >= 'a' and currentLetter <= 'z':
      if previousWasLetter:
        totalLength += 3
      elif messageHasLetter:
        totalLength += 7
      totalLength += letterDuration(morseCodes[int(currentLetter) - firstLowerLetter])
      previousWasLetter = true
      messageHasLetter = true
    elif currentLetter == ' ':
      previousWasLetter = false
  appendOutput(message)
  appendOutput(": length = ")
  appendOutput($totalLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A space clears the letter flag but leaves the message flag intact.
Characters outside a to z and space change neither flag nor the total.
The original message precedes the computed length on every output line.

## Complexity

Each message character takes a constant number of steps.

| phase | time | space |
|---|---|---|
| input read | one pass over all input characters | one input string |
| duration scan | one table lookup per letter | fixed code table |
| output | block writes | block buffer |

The Morse table has 26 fixed entries, independent of input size.

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(total input characters) |

Building a duration list for every symbol would use the same time but more space; one counter per message keeps the scan lean.
