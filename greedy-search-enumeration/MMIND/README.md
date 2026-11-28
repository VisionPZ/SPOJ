# MMIND — The Game of Master-Mind (SPOJ)
<https://www.spoj.com/problems/MMIND/>

## Problem

Past Master-Mind guesses and their black and white hints are given. Output the lexicographically smallest secret code still consistent with every hint.

The input starts with the case count. Each case gives pin count, color count, and guess count, followed by each guess and its two hint numbers. Print a valid code, or `You are cheating!`.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Pins `P` | 1 to 10 |
| Colors `C` | 1 to 100 |
| Guesses `M` | 1 to 100 |
| Cases | positive, large input warning |
| Judge time | 7000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The answer must be the lexicographically smallest valid code.

Sample input and output:

Input:

```
3
4 3 2
1 2 3 2
1 1
2 1 3 2
1 1
4 6 2
3 3 3 3
3 0
4 4 4 4
2 0
8 9 3
1 2 3 4 5 6 7 8
0 0
2 3 4 5 6 7 8 9
1 0
3 4 5 6 7 8 9 9
2 0
```

Output:

```
1 1 1 3
You are cheating!
9 9 9 9 9 9 9 9
```

## Idea

Build the code one pin at a time and stop when a hint can no longer match. Think of filling pin slots one at a time, discarding each color choice that contradicts an earlier hint.

The program backtracks (tries a choice, then undoes it) over colors in increasing order. Running counters check every past guess after each pin. Each candidate costs O(M) checks. Enumerating all C^P codes would be far slower.

Takeaway: early pruning plus color order gives the smallest code.

## Why It Works

Each hint splits into two countable parts.

1. A black point means the guessed color sits on the same pin.
2. Total points count matched colors across all pins, ignoring position.
3. `needCount` stores how often a color appears in one guess.
4. `blackSoFar` and `totalSoFar` grow as pins are assigned.
5. Four checks prune a branch that overshoots or cannot reach a hint.

The terms are:

| Term | Meaning |
| --- | --- |
| `requiredBlack` | Black points demanded by a hint |
| `requiredTotal` | Black plus white points demanded |
| `remainingPins` | Pins still unassigned |
| `secretCount` | Times a color appears in the partial code |

Pruning uses only these four values.

A script checked the first sample case:

| Guess | Hint | Black in `1 1 1 3` | Total in `1 1 1 3` |
| --- | --- | --- | --- |
| `1 2 3 2` | 1 black, 1 white | 1 | 2 |
| `2 1 3 2` | 1 black, 1 white | 1 | 2 |

The smallest valid code is `1 1 1 3`.

## Code

**Constants and shared arrays.**

```nim
const maxPins = 10
const maxColours = 100
const maxGuesses = 100
const colourStride = maxColours + 1
const flushBlockBytes = 1 shl 18

var inputData = ""
var i = 0
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

Flat arrays hold every guess and counter. `colourStride` leaves slot zero unused. No case allocates memory.

**Integer scanner.**

```nim
proc readNextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    inc i
  value
```

The scanner walks the whole input buffer once. It skips separators and builds values digit by digit.

**Backtracking search.**

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
    for j in 0 ..< checkedGuesses:
      let guessAtPin = guessColour[j * pinCount + depth]
      if guessAtPin == candidateColour:
        dec blackSoFar[j]
      if secretCount[candidateColour] <= needCount[j * colourStride + candidateColour]:
        dec totalSoFar[j]
    dec secretCount[candidateColour]
  false
```

Colors are tried from 1 upward, so the first success is smallest. Counters are undone after each failed trial.

**Driver and output.**

```nim
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

let testCount = readNextInt()
for j in 0 ..< testCount:
  pinCount = readNextInt()
  colourCount = readNextInt()
  guessCount = readNextInt()
  for k in 0 .. colourCount:
    secretCount[k] = 0
  for j in 0 ..< guessCount:
    let needBase = j * colourStride
    let colourBase = j * pinCount
    blackSoFar[j] = 0
    totalSoFar[j] = 0
    for l in 0 .. colourCount:
      needCount[needBase + l] = 0
    for l in 0 ..< pinCount:
      let guessAtPin = readNextInt()
      guessColour[colourBase + l] = guessAtPin
      inc needCount[needBase + guessAtPin]
    let blackHint = readNextInt()
    let whiteHint = readNextInt()
    requiredBlack[j] = blackHint
    requiredTotal[j] = blackHint + whiteHint
  if not searchSecret(0):
    outputBuffer.add "You are cheating!"
  else:
    for l in 0 ..< pinCount:
      if l > 0:
        outputBuffer.add ' '
      outputBuffer.add $secretColour[l]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The program reads all guesses first. It fills `needCount` per case and clears only the used colors. Failure prints the cheating message.

## Complexity

The search tree and hint checks dominate.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total numbers) | O(Input size) |
| Search | O(C^P * M) worst case | O(P + C * M) |
| Output | O(T * P) | O(1) |

Pruning cuts most branches early.

| Measure | Bound |
| --- | --- |
| Time | O(C^P * M) worst case |
| Space | O(C * M) |

Ten pins and one hundred colors are reachable because hints prune.

Testing all codes without pruning would enumerate every color sequence.
