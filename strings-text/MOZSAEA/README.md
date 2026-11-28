# MOZSAEA — Sharmeen And English Alphabet (SPOJ)

<https://www.spoj.com/problems/MOZSAEA/>

## Problem

The lowercase letters form a circle: after `z` comes `a`. Given a start letter and an end letter, list every letter met while moving forward from start until end, including both ends. Separate consecutive letters with one space and end the line with a newline.

Two lowercase letters arrive on stdin. The first is the start, the second is the end.

| Item | Bound |
|---|---|
| Letters | lowercase `a` through `z` |
| Output length | at most 26 letters |
| Instances | one per input file |
| Judge limit | 1000 ms, 1536 MB |

The forward distance around the circle fixes the output length.

The sample case:

```
y c
```

```
y z a b c
```

## Idea

Measure the forward distance from start to end around the letter circle. Think of a clock face: moving forward from 10 to 2 covers four hours, not eight hours backwards. A modular distance gives that count, and one loop emits the letters. Restarting a search for each step costs O(26²) work. Each emitted letter costs constant time, so the run is O(26).

## Why It Works

1. Mapping `a` to 0 and `z` to 25 turns letters into positions on a 26-point circle.
2. `(endCode - startCode + 26) mod 26` is the forward distance, including wrap.
3. Adding that distance modulo 26 keeps every character in the lowercase range.
4. Equal letters give distance zero, so the answer holds one letter.

| Term | Meaning |
|---|---|
| `startCode` | numeric position of the start letter |
| `endCode` | numeric position of the end letter |
| `stepCount` | number of forward steps, including zero |
| `answerText` | the space-separated letters being built |

The distance alone drives the loop bound.

A script-traced example from `gen.py`:

```
walk from y: y z a b c
the walk stops when c is reached
```

The traced walk equals the sample output.

## Code

**Input and letter scanner.** This block loads stdin and reads two lowercase letters.

```nim
const firstLowerCode = 97
const alphabetSize = 26
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLetter(data: string, position: var int): char =
  while position < data.len and (data[position] < 'a' or data[position] > 'z'):
    position += 1
  let foundLetter = data[position]
  position += 1
  return foundLetter
```

One readLine loop stores the whole input.
The scanner skips any separator between letters.
Both reads cost one pass over the input.

**Buffered output.** This block collects answer bytes before writing.

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
Each append runs in constant time.

**Circular walk and final flush.** This block computes the distance and emits the letters.

```nim
let startLetter = nextLetter(inputData, scanPos)
let endLetter = nextLetter(inputData, scanPos)
let startCode = ord(startLetter) - firstLowerCode
let endCode = ord(endLetter) - firstLowerCode
let stepCount = (endCode - startCode + alphabetSize) mod alphabetSize
var answerText = ""
for step in 0..stepCount:
  if step > 0:
    answerText.add ' '
  answerText.add chr((startCode + step) mod alphabetSize + firstLowerCode)
answerText.add '\n'
appendOutput(answerText)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The distance wraps around `z` automatically.
Spaces are added before every letter except the first.
The loop runs at most 26 times.

## Complexity

The cost splits into reading two letters, walking the circle, and writing the line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Circular walk | at most 26 O(1) steps | answer text |
| Output | one write per 128 KiB block | block buffer |

The fixed alphabet keeps every phase tiny.

| Measure | Big O |
|---|---|
| Time | O(L + 26), where L is input bytes |
| Space | O(L + 26) |

Restarting a search for each letter costs O(26²) work.
Modular stepping avoids that repeated search.
