## Problem

Each test case gives a Master-Mind position: P pins, C colors, and M guesses with black and white hints. Print the smallest secret sequence that fits every hint. Print "You are cheating!" when no sequence fits.

| Quantity | Range |
| --- | --- |
| Pins, P | 1 to 10 |
| Colors, C | 1 to 100 |
| Played guesses, M | 1 to 100 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The output holds one line per test case.

## Idea

Build the secret one pin at a time, trying colors from small to large. Counts per guess prune each prefix that cannot reach a hint, and the first complete secret is the smallest valid one. Each color trial costs O(M), while scoring every full sequence costs O(M * P) for each of C^P sequences.

## Why It Works

A hint comes from a matching between secret pins and guess pins with equal colors. Exact matches form the black points first. The other matched pairs equal the overlap of the two color count vectors.

- Black points B: the count of pins where secret equals guess.
- Total pairs B + W: the sum over colors of min(secretCount, guessCount).
- White points W: total pairs minus black points.

A prefix fills d pins, so P - d pins remain. One more pin raises B or B + W by at most one. A hint stays reachable only while counted B is at least required B minus the remainder, and at most required B. The same holds for counted total. The search checks these bounds after each pin and undoes the counts on failure.

The code reads a guess color at `guessIndex * pinCount + depth`. It reads that color's count at `guessIndex * colourStride + candidateColour`.

This worked example uses P = 4, C = 3, and one guess. The hint is (0, 0), so the required total is 0.

| First pin color | Black count | Counted total | Rejection reason |
| --- | --- | --- | --- |
| 1 | 1 | 1 | Black 1 exceeds 0 |
| 2 | 0 | 1 | Total 1 exceeds 0 |
| 3 | 0 | 1 | Total 1 exceeds 0 |

No color survives, so the program prints "You are cheating!".

## Code

```nim
const maxPins = 10
const maxColours = 100
const maxGuesses = 100
const colourStride = maxColours + 1
const flushBlockBytes = 1 shl 18

var inputData = ""
var scanPos = 0
var outputBuffer = ""
var pinCount = 0
var colourCount = 0
var guessCount = 0
var secretColour: array[maxPins, int]
var secretCount: array[colourStride, int]
var guessColour: array[maxGuesses * maxPins, int]
var needCount: array[maxGuesses * colourStride, int]
var requiredBlack: array[maxGuesses, int]
var requiredTotal: array[maxGuesses, int]
var blackSoFar: array[maxGuesses, int]
var totalSoFar: array[maxGuesses, int]
```

The arrays cover the largest legal case, so no case allocates memory. The stride leaves room for the unused color zero. Output flushes after 256 KiB of text.

```nim
proc readNextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    inc scanPos
  value
```

The scanner skips separators and reads one non-negative number. It never allocates a token string. The scan ends at the end of the input buffer.

```nim
proc searchSecret(depth: int): bool =
  if depth == pinCount:
    return true
  for candidateColour in 1 .. colourCount:
    secretColour[depth] = candidateColour
    inc secretCount[candidateColour]
    var checkedGuesses = 0
    var feasible = true
    while checkedGuesses < guessCount:
      let guessAtPin = guessColour[checkedGuesses * pinCount + depth]
      if guessAtPin == candidateColour:
        inc blackSoFar[checkedGuesses]
      if secretCount[candidateColour] <= needCount[checkedGuesses * colourStride + candidateColour]:
        inc totalSoFar[checkedGuesses]
      inc checkedGuesses
      let remainingPins = pinCount - depth - 1
      if blackSoFar[checkedGuesses - 1] > requiredBlack[checkedGuesses - 1] or
         requiredBlack[checkedGuesses - 1] - blackSoFar[checkedGuesses - 1] > remainingPins or
         totalSoFar[checkedGuesses - 1] > requiredTotal[checkedGuesses - 1] or
         requiredTotal[checkedGuesses - 1] - totalSoFar[checkedGuesses - 1] > remainingPins:
        feasible = false
        break
    if feasible and searchSecret(depth + 1):
      return true
    for guessIndex in 0 ..< checkedGuesses:
      let guessAtPin = guessColour[guessIndex * pinCount + depth]
      if guessAtPin == candidateColour:
        dec blackSoFar[guessIndex]
      if secretCount[candidateColour] <= needCount[guessIndex * colourStride + candidateColour]:
        dec totalSoFar[guessIndex]
    dec secretCount[candidateColour]
  false
```

The loop tries colours in increasing order, so the first full secret is the answer. The counter increments before the bound check, so rollback includes a rejected guess. Recursion ends after P pins, where the bounds force exact equality.

```nim
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

let testCount = readNextInt()
for caseIndex in 0 ..< testCount:
  pinCount = readNextInt()
  colourCount = readNextInt()
  guessCount = readNextInt()
  for colourIndex in 0 .. colourCount:
    secretCount[colourIndex] = 0
  for guessIndex in 0 ..< guessCount:
    let needBase = guessIndex * colourStride
    let colourBase = guessIndex * pinCount
    blackSoFar[guessIndex] = 0
    totalSoFar[guessIndex] = 0
    for entryIndex in 0 .. colourCount:
      needCount[needBase + entryIndex] = 0
    for pinIndex in 0 ..< pinCount:
      let guessAtPin = readNextInt()
      guessColour[colourBase + pinIndex] = guessAtPin
      inc needCount[needBase + guessAtPin]
    let blackHint = readNextInt()
    let whiteHint = readNextInt()
    requiredBlack[guessIndex] = blackHint
    requiredTotal[guessIndex] = blackHint + whiteHint
  if not searchSecret(0):
    outputBuffer.add "You are cheating!"
  else:
    for pinIndex in 0 ..< pinCount:
      if pinIndex > 0:
        outputBuffer.add ' '
      outputBuffer.add $secretColour[pinIndex]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The driver reads all input lines into one buffer before parsing. Each case rebuilds only the guess tables it uses. One output buffer collects every answer and flushes in blocks.

## Complexity

Reading costs O(total input numbers). Each color trial costs O(M), and the search visits at most C^P prefixes, so the worst case is O(C^P * M). Hints cut that count sharply in practice.

The arrays hold O(M * C) counts and O(M * P) guess colors. A full-score baseline visits the same C^P sequences but recomputes P comparisons for every guess, costing O(C^P * M * P).
