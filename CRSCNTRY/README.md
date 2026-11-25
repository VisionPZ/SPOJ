# CRSCNTRY — Cross-country (SPOJ)

<https://www.spoj.com/problems/CRSCNTRY/>

## Problem

Each dataset gives a reference route card and several candidate cards, each a list of checkpoints. Count how many checkpoints a candidate shares with the reference in order, and print the largest count.

Read `d` datasets. Each dataset holds Agnes' route card, then one or more cards for Tom. A card is a list of checkpoints ending in `0`; a `0` alone on a line ends the dataset. Tom picks one card and scores a point each time he meets Agnes in order. Print his highest score for each dataset.

| item | bound |
|---|---|
| datasets `d` | 1 to 10 |
| checkpoints per card | 2 to 2000 |
| checkpoint values | 1 to 1000 |
| Tom's cards per dataset | at least 1 |
| judge limits | 5 s, 1536 MB |

The score bound follows from the card length, so the output holds at most 10 lines.

Sample input and sample output use these exact bytes.

```
3
1 2 3 4 5 6 7 8 9 0
1 3 8 2 0
2 5 7 8 9 0
1 1 1 1 1 1 2 3 0
1 3 1 3 5 7 8 9 3 4 0
1 2 35 0
0
1 3 5 7 0
3 7 5 1 0
0
1 2 1 1 0
1 1 1 0
0
```

```
6
2
3
```

The first dataset has five Tom cards, and the fourth card scores 6.

## Idea

A meeting is a checkpoint both cards visit in order, so the score is the longest common subsequence (LCS) length of the two cards. Tom picks his best card, so the answer is the largest LCS over his cards. One bit mask per value packs the matches, so each checkpoint costs `m / 64` word operations, not `m` cell updates.

## Why It Works

The DP row `L[j]` holds the LCS of Agnes' processed prefix and the first `j` checkpoints of Tom's card. Bit `j` of the working state `S` is 1 exactly when `L[j]` exceeds `L[j - 1]`. The popcount of `S` is therefore `L[m]`, the score.

Three bitwise steps replace the whole row update. The table shows what each term does.

| term | meaning |
|---|---|
| `mask[value]` | bits at positions where Tom's card holds `value` |
| `x = S or mask[value]` | positions that can grow in this row |
| `y = (S shl 1) or 1` | earlier growth moved one slot to the right |
| `x - y` | borrow chain that resolves every growth at once |
| `S = x and not (x - y)` | positions that truly grew |

Each borrow travels from low bit to high bit, the same direction as the DP recurrence. The popcount step needs no row array.

Checkpoint values run from 1 to 1000, so the masks are small and fixed. Each value owns `maxWords` consecutive words. A position maps to word `position div wordBits` and bit `position mod wordBits`. With 32 words, 2000 checkpoints always fit.

A generated trace for Agnes `1 2 1` and Tom `1 1 2` shows the arithmetic. The masks are `011` for value 1 and `100` for value 2; bit `j` is position `j`.

```
step  Agnes  x     y     x - y  S     popcount(S)
start   -      -     -     -      000       0
1       1      011   001   010    001       1
2       2      101   011   010    101       2
3       1      111   011   100    011       2
```

The final popcount is 2, the same length a table DP returns for these cards.

## Code

`maxWords` covers the longest legal card. The other constants set the value range, the word size, the output block, and the digit base.

```nim
const valueRange = 1000
const wordBits = 64
const maxWords = 32
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
```

`i` advances by one digit, so no token object is built. The loop stops at the first non-digit byte. Card values stay positive, so no sign branch is needed.

```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  return value
```

This SWAR popcount sums bit groups without testing 64 bits one by one. One call costs a fixed handful of word operations. It runs at most 32 times per card.

```nim
proc countSetBits(value: uint64): int =
  var bits = value
  bits = bits - ((bits shr 1) and 0x5555555555555555'u64)
  bits = (bits and 0x3333333333333333'u64) + ((bits shr 2) and 0x3333333333333333'u64)
  bits = (bits + (bits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((bits * 0x0101010101010101'u64) shr 56)
```

The outer loop runs once per Agnes checkpoint, at most 2000 times. Each inner loop runs `wordCount` times, where `wordCount` is `ceil(m / 64)`. The two borrow flags carry across words in the right order. Clearing `stateBits` at entry prevents a previous card from leaking into this one.

```nim
proc lcsLength(agnesRoute: seq[int], matchMask: seq[uint64], wordCount: int, stateBits: var seq[uint64], shiftedBits: var seq[uint64], differenceBits: var seq[uint64]): int =
  for l in 0 ..< wordCount:
    stateBits[l] = 0'u64
  for checkpoint in agnesRoute:
    let maskBase = checkpoint * maxWords
    var shiftCarry = 0'u64
    for l in 0 ..< wordCount:
      let stateWord = stateBits[l]
      shiftedBits[l] = (stateWord shl 1) or shiftCarry
      shiftCarry = stateWord shr (wordBits - 1)
    shiftedBits[0] = shiftedBits[0] or 1'u64
    var borrow = 0'u64
    for l in 0 ..< wordCount:
      let leftWord = stateBits[l] or matchMask[maskBase + l]
      let shiftedWord = shiftedBits[l]
      let partial = leftWord - borrow
      let firstBorrow = leftWord < borrow
      let differenceWord = partial - shiftedWord
      let secondBorrow = partial < shiftedWord
      borrow = (if firstBorrow or secondBorrow: 1'u64 else: 0'u64)
      stateBits[l] = leftWord and (not differenceWord)
  var total = 0
  for l in 0 ..< wordCount:
    total = total + countSetBits(stateBits[l])
  return total
```

Lines append to one input buffer, so odd spacing cannot desync the reader. A `0` right after a route's own `0` ends the dataset. Masks are cleared only over `wordCount` words, so each card costs `1000 * wordCount` writes. The output buffer flushes at 128 KiB and writes the tail once.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
let caseCount = nextInt(inputData, i)

var stateBits = newSeq[uint64](maxWords)
var shiftedBits = newSeq[uint64](maxWords)
var differenceBits = newSeq[uint64](maxWords)
var matchMask = newSeq[uint64]((valueRange + 1) * maxWords)
var agnesRoute: seq[int] = @[]
var tomRoute: seq[int] = @[]
var outputBuffer: string

for j in 1 .. caseCount:
  agnesRoute.setLen 0
  while true:
    let checkpoint = nextInt(inputData, i)
    if checkpoint == 0: break
    agnesRoute.add checkpoint
  var bestScore = 0
  while true:
    let firstValue = nextInt(inputData, i)
    if firstValue == 0: break
    tomRoute.setLen 0
    tomRoute.add firstValue
    while true:
      let checkpoint = nextInt(inputData, i)
      if checkpoint == 0: break
      tomRoute.add checkpoint
    let checkpointCount = tomRoute.len
    let wordCount = (checkpointCount + wordBits - 1) div wordBits
    for k in 0 .. valueRange:
      let maskBase = k * maxWords
      for l in 0 ..< wordCount:
        matchMask[maskBase + l] = 0'u64
    for k in 0 ..< checkpointCount:
      let maskBase = tomRoute[k] * maxWords
      let l = k div wordBits
      matchMask[maskBase + l] = matchMask[maskBase + l] or (1'u64 shl (k mod wordBits))
    let score = lcsLength(agnesRoute, matchMask, wordCount, stateBits, shiftedBits, differenceBits)
    if score > bestScore: bestScore = score
  outputBuffer.add $bestScore
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input bytes |
| mask build | `1000 * wordCount` writes per card | 1001 * 32 words |
| LCS | `n * wordCount` word steps per card | 3 * 32 words |
| output | one write per 128 KiB block | 128 KiB |

`n` is Agnes' card length and `wordCount` is `ceil(m / 64)` for Tom's card.

| measure | Big O |
|---|---|
| time per card | O(`n * m / 64`) plus O(`1000 * m / 64`) for masks |
| space | O(1000 * 32) words, independent of route lengths |

A table DP costs O(`n * m`) cell updates per card, about 64 times more work at full length.
