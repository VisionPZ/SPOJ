# NJEG1 — Maths is Magic (SPOJ)

<https://www.spoj.com/problems/NJEG1/>

## Problem

A card trick predicts one card from a pile of 26 cards. Three friends remove cards from the remaining 26 cards and borrow from the pile when needed.

Each test case gives the 26 plate1 cards, then cards A, B, and C. Jack counts 1, Queen 2, King 3, Ace 4, and other cards count their number. Print the predicted card value for each case. Cards A, B, and C are never Queen, King, or Ace.

| Item | Bound |
|---|---|
| Test cases | first input integer, no numeric bound stated |
| Plate1 cards | 26 card symbols per case |
| Chosen cards | three symbols, each with value 1 or 5 to 10 |
| Card values | 1 to 10 |
| Judge limit | 500 ms, 1536 MB |

The index is the sum of the three chosen card values.

The statement shows one sample:

```
1
A 4 2 3 6 5 7 8 9 10 J K Q 2 3 4 5 6 7 8 J Q 8 9 5 4
7 2 4
```

```
7
```

The seventh plate1 card has value 7.

## Idea

Think of a marked page that a bookmark always finds. However many cards move, the trick lands on the same plate1 position.

A friend taking a card of value v removes 11 - v cards in total. The three friends remove 33 minus the index altogether. The deck starts with 26 cards, so the leftover pile has index - 7 cards. Those leftovers go on top of plate1. Position index in the combined pile becomes position seven in the original plate1 order. Borrowing removes the same number of top cards, so the result stays the same.

Reading the seventh plate1 card costs a fixed number of token scans per case. Simulating the unknown deck would need information the input never gives.

## Why It Works

1. Each friend takes one chosen card and adds 10 minus its value.
2. Three friends therefore consume 33 minus the index cards.
3. The deck holds 26 cards, leaving index - 7 cards when nothing is borrowed.
4. Those leftovers shift position index back to position seven of plate1.
5. Borrowing removes top cards and shifts the plate by the same amount.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `predictionToken` | symbol of the seventh plate1 card |
| `cardValue` | numeric value of one card symbol |
| `nextToken` | reader that returns one whitespace-delimited symbol |
| `skipToken` | reader that passes over unwanted symbols |

These names match the scanning code in the program.

A trace from `gen.py` on two cases:

```
chosen values [7, 2, 4], index 13
deck leftovers 6, borrowed 0, plate position 7, value 7
chosen values [1, 1, 1], index 3
deck leftovers 0, borrowed 4, plate position 3, value 10
```

Both cases point at the original seventh plate1 card.

## Code

**Input helpers.** The program scans tokens directly from one input string.

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

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  if tokenStart == scanPos:
    return ""
  return inputData[tokenStart .. scanPos - 1]

proc skipToken(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1

proc cardValue(cardToken: string): int =
  if cardToken.len == 1:
    if cardToken[0] == 'A':
      return 4
    if cardToken[0] == 'J':
      return 1
    if cardToken[0] == 'Q':
      return 2
    if cardToken[0] == 'K':
      return 3
    return int(cardToken[0]) - firstDigitValue
  return 10
```

`nextToken` builds only the seven needed symbols. `skipToken` moves past the rest without allocating.

**Output buffer.** Results are written in blocks.

```nim
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

The buffer flushes every 128 KiB. A final write emits any remainder.

**Prediction loop.** Seven tokens give the answer; 22 tokens end the case.

```nim
let caseCount = int(nextInteger(inputData, scanPos))
for caseIndex in 0 ..< caseCount:
  var predictionToken = ""
  for tokenIndex in 0 .. 6:
    predictionToken = nextToken(inputData, scanPos)
  appendOutput($(cardValue(predictionToken)))
  outputBuffer.add '\n'
  for skippedIndex in 0 ..< 22:
    skipToken(inputData, scanPos)

stdout.write outputBuffer
```

Each case consumes 29 cards and symbols in total. The chosen three symbols only need skipping.

## Complexity

The token count sets the work per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input lines | input buffer |
| Token scan | 29 symbols per case | one symbol at a time |
| Output | one write per 128 KiB block | output buffer |

The work stays fixed no matter which cards are chosen.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(29 times caseCount) |
| Space | O(input bytes) |

Tracking every removed card would add work for cards the input never describes. Reading one fixed position keeps the program small and quick.
