# RETO6 — Hulk Grado 10 (SPOJ)

<https://www.spoj.com/problems/RETO6/>

## Problem

Dr. Banner wants a sentence for each layer of a feeling. The layers alternate between hate and love.

The input holds one integer, the number of layers. Print the matching sentence on one line.

| Item | Bound |
|---|---|
| Layers | 1 to 100 |
| Judge limit | 1000 ms, 1536 MB |

Each layer adds one phrase, and the final layer ends the sentence.

The statement shows one sample:

```
1
```

```
I hate it
```

One layer gives "I hate it".

## Idea

Think of peeling nested gift wrap, with two labels alternating from the outside inward. Each wrap says "I hate that" or "I love that".

Odd layers say hate and even layers say love. For the first n - 1 layers, print the label followed by "that ". The last layer prints the same label followed by "it".

Writing each phrase costs constant time, so the whole sentence costs O(n) time. Building the sentence through repeated copying would do extra work. One pass appends each phrase directly.

## Why It Works

1. Layer one says hate, and every later layer flips the label.
2. The phrase "that" links a layer to the next one.
3. Only the final layer changes "that" into "it".
4. An odd layer count ends with hate; an even one ends with love.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `layerCount` | number of feeling layers |
| `layerIndex` | zero-based counter over the first n - 1 layers |
| `appendOutput` | adds a phrase to the output buffer |

The terms match the loop in the program.

A trace from `gen.py` on the first four layer counts:

```
layers 1: I hate it
layers 2: I hate that I love it
layers 3: I hate that I love that I hate it
layers 4: I hate that I love that I hate that I love it
```

The three-layer sentence ends with hate, matching the alternating labels.

## Code

**Input and output helpers.** The whole input becomes one string before scanning.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 128 KiB, although this sentence is short. The scanner reads the one input integer.

**Sentence driver.** The loop writes n - 1 phrases, then the final phrase.

```nim
let layerCount = int(nextInteger(inputData, scanPos))
for layerIndex in 0 ..< layerCount - 1:
  if (layerIndex + 1) mod 2 == 1:
    appendOutput("I hate that ")
  else:
    appendOutput("I love that ")
if layerCount mod 2 == 1:
  appendOutput("I hate it")
else:
  appendOutput("I love it")
outputBuffer.add '\n'
stdout.write outputBuffer
```

The loop runs n - 1 times. The parity test chooses the label for both phrase forms.

## Complexity

The output length sets the work.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Sentence build | one phrase per layer | output buffer |
| Output | one write at the end | output buffer |

At most 100 layers occur, so the sentence stays short.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) for the printed sentence |

Repeatedly concatenating whole sentences would rewrite earlier phrases. Appending each phrase once avoids that work.
