# TIMORSE — Timing Morse (SPOJ)

<https://www.spoj.com/problems/TIMORSE/>

## Problem

Each message is a line of letters, spaces and other characters. Print the length of that message in Morse code, measured in dot units. A dash costs 3, an intra-character gap costs 1, an inter-character gap costs 3, and a word gap costs 7.

Input starts with `n`, the number of messages, followed by `n` lines, one per message. Output holds each message line, then `: length = L`.

| Item | Bound |
|---|---|
| Messages `n` | positive integer, tests use up to 2500 |
| Message letters | `a` to `z`, space, and ignorable other characters |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
2
hi joe
sos
```

```
hi joe: length = 51
sos: length = 27
```

## Idea

Walk the message character by character and add up durations, exactly like a telegraph key being pressed. Each letter contributes its dot and dash durations plus 1-unit gaps between symbols. A letter after another letter adds a 3-unit gap, and a letter starting a new word adds a 7-unit gap. This needs no Morse string building and no second pass: one left-to-right scan gives the total.

## Why It Works

1. A letter of `k` symbols has `k` symbol durations and `k - 1` one-unit gaps, which `letterDuration` adds up directly from the code table.
2. Two letters in the same word are separated by 3 units, which the `previousWasLetter` branch adds before the next letter.
3. Words are separated by 7 units. A space turns off `previousWasLetter`, so the next letter takes the 7-unit branch instead of the 3-unit one.
4. Leading spaces, repeated spaces and trailing spaces never start a letter, so they add nothing: the 7-unit gap is charged only when a letter follows a gap and the message already contains a letter.
5. Characters outside `a` to `z` and space are skipped by both branches, matching "any other characters can be ignored".
6. The message is echoed before the number, so the output line keeps the exact spacing of the input line.

| Term | Meaning |
|---|---|
| `morseCodes` | dot and dash strings for `a` to `z` |
| `letterDuration` | symbol durations plus inner gaps for one letter |
| `totalLength` | running length of the current message |
| `previousWasLetter` | the previous character was a letter |
| `messageHasLetter` | the message has produced at least one letter |

A traced run of the first sample message:

```
h ....  -> 4 dots + 3 inner gaps = 7
i ..    -> +3 character gap, +2 dots +1 inner gap = 3   running 13
space   -> ends the word, adds nothing
j .---  -> +7 word gap, +1 dot +3 dashes +3 inner gaps = 13   running 33
o ---   -> +3 gap, +3 dashes +2 inner gaps = 11   running 47
e .     -> +3 gap, +1 dot = 1   running 51
```

## Code

**Input, scanner and line reader.** This block loads stdin and slices out whole message lines.

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
```

One readLine loop collects all input bytes.
`nextRawLine` keeps every character of a message, including spaces.
Scanning costs one pass over the consumed characters.

**Letter durations.** This block turns one Morse string into dot units.

```nim
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

A dash counts 3 and a dot counts 1.
The extra 1 is added between symbols only, never after the last one.

**Buffered output.** This block holds the finished answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Message loop.** This block scans each message and writes its line.

```nim
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

The discarded line after the count absorbs the newline that the bulk read appended.
Only letters and spaces change the state, so punctuation is ignored for free.
Each message costs one scan of its own characters.

## Complexity

The cost splits into input, one scan per message, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Timing | O(total message characters) | constant |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(total characters) |
| Space | O(input size) |

Building the Morse string first and then counting its symbols would cost the same time but store a much longer text.
