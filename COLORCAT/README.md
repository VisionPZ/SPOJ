# COLORCAT — Magical colorful cats (easy) (SPOJ)

<https://www.spoj.com/problems/COLORCAT/>

## Problem

Cats sit in a circle, and each step makes neighboring pairs talk in order around the ring. A pair with different colors both become the third color; a pair with equal colors stays unchanged. Report all colors after k steps.

Input gives n and k, then a string of n color letters. Output one string of n letters in the final order.

| item | bound |
|---|---|
| cats n | 1 to 20000 |
| steps k | 1 to 30000 |
| judge limit | 1000 ms, 1536 MB |

The product n times k reaches 600 million pair updates.

Sample input:

```
3 1
GRR
```

Sample output:

```
RGR
```

Cats 1 and 2 become W, then cats 2 and 3 become G, then cats 3 and 1 become R.

## Idea

Think of three-way switches that snap to the missing setting: when two differ, both take the third setting, and when they match nothing moves. Number the colors 0, 1 and 2, and the missing color is the negative sum modulo 3. That same formula also leaves equal pairs unchanged, so one small lookup table handles every pair. The algorithm simulates pairs in place in O(n) per step. Testing color names by branches per pair adds avoidable work. One table lookup per pair keeps the sweep tight.

## Why It Works

1. Map W, R and G to 0, 1 and 2; these residues sum to 3, which is 0 modulo 3.
2. For different colors x and y, the third color has residue minus x minus y modulo 3.
3. For equal colors, twice x is minus x modulo 3, so the same formula returns x.
4. Pairs are handled in order, and each pair sees the already updated left cat.
5. After pair i is processed, cat i never changes again, so writing it at once is safe.
6. The closing pair uses the newly written colors of the first and last cats.

The main terms:

| term | meaning |
|---|---|
| `colorValues` | numeric colors of the cats |
| `combineTable` | precomputed result for every ordered color pair |
| `leftColor` | color carried from the previous pair |
| `newColor` | color assigned to both cats in a pair |
| `resultText` | final string of color letters |

The table removes all branching from the hot loop.

A script trace of the sample in letter form:

```
colors: G R R
pair 1-2: G and R become W
pair 2-3: W and R become G
pair 3-1: G and W become R
result: R G R
```

Each pair uses the updated left cat, which gives RGR after one step.

## Code

**Input and helpers.** Colors arrive as one letter string after the two counts.

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

proc skipSpace(data: string, pos: var int) =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner and the string reader share one buffer position.
The output helper flushes whole blocks, not single letters.
A single trailing newline ends the output.

**Color parsing and table setup.** Each letter becomes a small integer code.

```nim
let catCount = nextInt(inputData, scanPos)
let stepCount = nextInt(inputData, scanPos)
skipSpace(inputData, scanPos)
var colorValues = newSeq[uint8](catCount)
for catIndex in 0 .. catCount - 1:
  let symbol = inputData[scanPos]
  scanPos += 1
  if symbol == 'W':
    colorValues[catIndex] = 0'u8
  elif symbol == 'R':
    colorValues[catIndex] = 1'u8
  else:
    colorValues[catIndex] = 2'u8
var combineTable: array[9, uint8]
for leftColor in 0 .. 2:
  for rightColor in 0 .. 2:
    combineTable[leftColor * 3 + rightColor] = uint8((3 - ((leftColor + rightColor) mod 3)) mod 3)
```

Codes fit in one byte, which keeps the array small.
The nine table entries cover every ordered pair of colors.
The same entry rule handles both equal and different pairs.

**Step simulation.** Each pass advances every pair once around the ring.

```nim
for stepIndex in 0 .. stepCount - 1:
  var leftColor = colorValues[0]
  for pairIndex in 0 .. catCount - 2:
    let rightColor = colorValues[pairIndex + 1]
    let newColor = combineTable[int(leftColor) * 3 + int(rightColor)]
    colorValues[pairIndex] = newColor
    leftColor = newColor
  let finalColor = combineTable[int(leftColor) * 3 + int(colorValues[0])]
  colorValues[catCount - 1] = finalColor
  colorValues[0] = finalColor
const colorLetters = "WRG"
var resultText = newString(catCount)
for catIndex in 0 .. catCount - 1:
  resultText[catIndex] = colorLetters[int(colorValues[catIndex])]
appendOutput(resultText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The carried left color avoids rereading the cat written by the previous pair.
The closing pair updates the last cat and the first cat together.
Mapping codes back to letters produces the required output string.

## Complexity

The simulation visits every pair in every step.

| phase | time | space |
|---|---|---|
| input read | one pass over the color string | one input string |
| simulation | O(k) passes over n cats | one byte per cat |
| output | one string of n letters | block buffer |

The color array is reused across all steps.

| measure | Big O |
|---|---|
| time | O(n * k) |
| space | O(n) |

Searching over colorings would be exponential, while each pair is updated exactly once per step.
The table keeps the constant factor low for the largest inputs.
