# SMPSEQ6 — Fun with Sequences, Act 4 (SPOJ)

<https://www.spoj.com/problems/SMPSEQ6/>

## Problem

Two rows of numbers sit side by side. A position is wanted when its left value also appears near the same position in the right row.

Input: one line with `n x`, then `n` integers of S, then `n` integers of Q. Output: the wanted 1-based positions in ascending order, separated by single spaces. An empty result is a blank line.

| Item | Bound |
|---|---|
| Sequence length `n` | 2 to 100 |
| Slack `x` | 0 to n minus 1 |
| Values | -100 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The samples, verbatim:

```
5 2
-1 2 -1 1 -1
3 -2 -1 1 2
```

```
1 3 4 5
```

```
6 4
-1 2 2 2 2 -2
3 -2 3 3 3 -1
```

```
6
```

```
6 0
-1 2 10 12 6 -2
2 -2 10 21 6 -1
```

```
3 5
```

## Idea

Think of finding a name in a spreadsheet column, allowing a few rows of slack. The bounded-window search tries only the allowed positions for each index.

The statement writes `q_{i+y}` with `-x <= y <= x`. The samples confirm that this means a nearby position, not a nearby value. Each position costs one integer comparison. Scanning all `n` positions for every index would cost more comparisons.

The window keeps the search local and small.

## Why It Works

1. For index `i`, the allowed positions are `max(1, i-x)` through `min(n, i+x)`.
2. The window never leaves the right sequence, so every array access is valid.
3. The search stops at the first match, which is enough to accept the index.
4. `emittedAny` inserts a space only before a later value, so no line ends with a space.

| Term | Meaning |
|---|---|
| `sequenceLength` | the `n` of the input |
| `neighborRadius` | the `x` of the input |
| `leftSequence` | the values of S |
| `rightSequence` | the values of Q |
| `windowStart`, `windowEnd` | allowed 0-based positions in Q |
| `emittedAny` | true after the first printed position |

The window bounds decide which positions are visited.

A traced run of the first sample, produced by the generator:

```
index 1: value -1, window 1..3, match at 3, emit 1
index 2: value 2, window 1..4, no match
index 3: value -1, window 1..5, match at 3, emit 3
index 4: value 1, window 2..5, match at 4, emit 4
index 5: value -1, window 3..5, match at 3, emit 5
answer "1 3 4 5"
```

The trace matches the first sample output line.

## Code

**Constants and input read.** One string holds every input line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The digit offset is the byte of `0`. The block size bounds the output buffer.

**Digit scanner.** Each call advances the shared scan position past one signed integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

The minus sign is part of the token, not a separator. The `var` parameter keeps the position between calls.

**Output buffer.** Appends collect bytes and write one block at a time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write.

**Position loop.** One bounded window per index, then one line of output.

```nim
let sequenceLength = nextInt(inputData, scanPos)
let neighborRadius = nextInt(inputData, scanPos)
var leftSequence = newSeq[int](sequenceLength)
var rightSequence = newSeq[int](sequenceLength)
var positionIndex = 0
while positionIndex < sequenceLength:
  leftSequence[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1
positionIndex = 0
while positionIndex < sequenceLength:
  rightSequence[positionIndex] = nextInt(inputData, scanPos)
  positionIndex += 1

var emittedAny = false
positionIndex = 0
while positionIndex < sequenceLength:
  let wantedValue = leftSequence[positionIndex]
  var windowStart = positionIndex - neighborRadius
  if windowStart < 0:
    windowStart = 0
  var windowEnd = positionIndex + neighborRadius
  if windowEnd >= sequenceLength:
    windowEnd = sequenceLength - 1
  var candidateIndex = windowStart
  while candidateIndex <= windowEnd:
    if rightSequence[candidateIndex] == wantedValue:
      if emittedAny:
        appendOutput(" ")
      appendOutput($(positionIndex + 1))
      emittedAny = true
      break
    candidateIndex += 1
  positionIndex += 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The two reads fill `n` slots each. Clamping keeps the window inside the sequence. The final write covers the tail.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines | input bytes |
| Digit scan | one pass over `2n+2` integers | constant |
| Window search | at most `2x+1` comparisons per index | two sequences |
| Output | one write per block | one buffer |

The window width bounds the work per index.

| Measure | Big O |
|---|---|
| Time | O(input bytes + n times x) |
| Space | O(n) plus one output block |

Checking every position of Q for each index would cost O(n squared) comparisons instead.
