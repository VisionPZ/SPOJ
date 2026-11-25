# PLATON — Platon and Socrates (SPOJ)

<https://www.spoj.com/problems/PLATON/>

## Problem

Two distinct whole numbers lie inside a given range. One person hears only their product and another hears only their sum. Four truthful remarks narrow the choices, and the task is to list every pair that still fits inside that range.

Write `x` and `y` for the two numbers, with `x < y`. Write `p = x*y` for their product and `s = x+y` for their sum. Write `count(p)` for how many pairs in the range give product p. Write `W` for the count of integers in the range. Both numbers lie between `l` and `r`, ends included.

Input: `t`, then `t` lines with `l r`. Output: one line `case i`, one line with the pair count, then one line `x y` per pair, ordered by increasing sum.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | at most 2000 |
| Range ends `l`, `r` | 1 ≤ l < r ≤ 5000 |
| Range width `r - l` | below 200 |
| Candidate slots `W` | at most 200 |
| Judge limit | 15 s, 1536 MB |

The width bound drives the design, since it caps a case at 19 900 pairs.

The sample case:

```
2
1 10
2 8
```

```
case 1
0
case 2
0
```

Both sample ranges are too narrow, so neither leaves a surviving pair.

## Idea

Cross off pairs the way you cross names off a list after each clue. A product that points to one pair is crossed off, because its owner would have known the answer at once.

The program makes four passes over all candidate pairs. A hash table holds product counts, and small arrays indexed by sum hold the results of each remark. Each pass touches at most 19 900 pairs once, so a case costs O(W²) time.

Recounting a product by rescanning every pair would repeat that work for each pair. The hash table counts all products in a single pass instead.

One shared hash table and three sum arrays carry the whole puzzle.

## Why It Works

1. Platon's first remark says his product occurs more than once in the range.
2. Socrates knew this before hearing Platon. Every split of his sum must have an ambiguous product, and his sum must split at least twice.
3. After that remark, Platon knows the sum is one of those surviving sums. His product points to exactly one pair with such a sum.
4. Socrates then looks at his sum. Exactly one split of that sum has a product that let Platon know.

The terms used in the four passes:

| Term | Meaning |
|---|---|
| `p = x*y` | the product Platon hears |
| `s = x+y` | the sum Socrates hears |
| `count(p)` | how many pairs in the range yield product p |
| good sum | a sum whose every split has `count(p)` above one |
| good pair | a pair with product p seen once among good-sum pairs |
| winner | a good sum with exactly one good pair |

Each term matches one sentence of the dialogue, in the same order.

A traced example for range [1, 30]:

```
range [1, 30], candidate pairs 435
product 6 count 2 representations [(1, 6), (2, 3)]
sum 5 splits [(1, 4, 4), (2, 3, 6)]
product 4 count 1 so sum 5 is rejected
sum 7 splits [(1, 6, 6), (2, 5, 10), (3, 4, 12)]
sum 7 all products ambiguous? True
good sums up to 13: [7, 9, 11, 13]
good-sum pairs with product 6: [(1, 6)]
good-sum pairs with product 10: [(1, 10), (2, 5)]
sum 7 pairs with a unique good-sum product: [(1, 6)]
final answer [(1, 6)]
```

Product 6 has two representations, yet only (1, 6) keeps a good sum.

## Code

**Input and scanner.** Everything is read once, then digits are walked by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hashBits = 17
const hashSize = 1 shl hashBits
const hashMask = hashSize - 1
const hashMultiplier = 2654435761'i64
const maxSum = 10000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The read loop appends each line to `inputData`, so odd spacing cannot desync the scanner.
`nextInt` skips separators and builds each value from digit bytes.
No token object is built, and `firstDigitValue` names the digit offset.
Cost: one pass over the input bytes.

**Product hash.** One table serves both counting passes, with stamps instead of clearing.

```nim
var hashKeys = newSeq[int](hashSize)
var hashValues = newSeq[int](hashSize)
var hashStamps = newSeq[int](hashSize)
var currentStamp = 0

proc hashSlot(value: int): int =
  return int((int64(value) * hashMultiplier shr 32) and int64(hashMask))

proc bumpCount(value: int, stamp: int): int =
  var at = hashSlot(value)
  while true:
    if hashStamps[at] != stamp:
      hashStamps[at] = stamp
      hashKeys[at] = value
      hashValues[at] = 1
      return 1
    if hashKeys[at] == value:
      hashValues[at] += 1
      return hashValues[at]
    at = (at + 1) and hashMask

proc lookupCount(value: int, stamp: int): int =
  var at = hashSlot(value)
  while true:
    if hashStamps[at] != stamp: return 0
    if hashKeys[at] == value: return hashValues[at]
    at = (at + 1) and hashMask
```

`hashSize` is 131 072 slots, well above the 19 900 products in a widest case.
`currentStamp` gives each pass a fresh view, so the arrays are never cleared.
`bumpCount` returns the running count, and `lookupCount` returns zero for a missing product.
Linear probing stops at the first free slot, so a call costs a few probes.

**Sum arrays and output block.** Sums index flat arrays; output leaves in blocks.

```nim
var sumSplitCount = newSeq[int](maxSum + 1)
var sumBadCount = newSeq[int](maxSum + 1)
var sumWinnerCount = newSeq[int](maxSum + 1)
var winnerLow = newSeq[int](maxSum + 1)
var winnerHigh = newSeq[int](maxSum + 1)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`maxSum` covers the largest possible sum, so no map is needed for sums.
The main loop clears only the sums that the current range can reach.
`appendOutput` flushes at `flushBlockBytes` and reuses the same buffer with `setLen 0`.
Cost: one array write per pair and one stream write per block.

**Driver.** Four pair passes implement the four remarks, then sums are printed in order.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let rangeLow = nextInt(inputData, scanPos)
  let rangeHigh = nextInt(inputData, scanPos)
  let sumLow = 2 * rangeLow + 1
  let sumHigh = 2 * rangeHigh - 1
  for s in sumLow..sumHigh:
    sumSplitCount[s] = 0
    sumBadCount[s] = 0
    sumWinnerCount[s] = 0
  currentStamp += 1
  let productStamp = currentStamp
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      discard bumpCount(x * y, productStamp)
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      sumSplitCount[total] += 1
      if lookupCount(x * y, productStamp) == 1:
        sumBadCount[total] += 1
  currentStamp += 1
  let winnerStamp = currentStamp
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      if sumSplitCount[total] > 1 and sumBadCount[total] == 0:
        discard bumpCount(x * y, winnerStamp)
  for x in rangeLow..rangeHigh:
    for y in x + 1..rangeHigh:
      let total = x + y
      if sumSplitCount[total] > 1 and sumBadCount[total] == 0 and lookupCount(x * y, winnerStamp) == 1:
        sumWinnerCount[total] += 1
        winnerLow[total] = x
        winnerHigh[total] = y
  var pairCount = 0
  for s in sumLow..sumHigh:
    if sumSplitCount[s] > 1 and sumBadCount[s] == 0 and sumWinnerCount[s] == 1:
      pairCount += 1
  appendOutput("case " & $caseIndex)
  outputBuffer.add '\n'
  appendOutput($pairCount)
  outputBuffer.add '\n'
  for s in sumLow..sumHigh:
    if sumSplitCount[s] > 1 and sumBadCount[s] == 0 and sumWinnerCount[s] == 1:
      appendOutput($(winnerLow[s]) & " " & $(winnerHigh[s]))
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each nested loop stops at `rangeHigh`, so a case touches at most 19 900 pairs.
`productStamp` counts representations; a count of one rules out a sum at once.
`winnerStamp` counts only pairs whose sum survived the second remark.
`winnerLow` and `winnerHigh` store the sole winner, and the last loop walks sums upward.

## Complexity

The work splits into input, four counting passes, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Product count pass | about W² / 2 hash bumps | 1.5 MB hash arrays |
| Sum and winner passes | three scans of W² / 2 pairs | sum arrays under 100 KB |
| Output | one stream write per block | 256 KiB block |

The hash arrays dominate space, while the sum arrays stay small.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(t * W²) |
| Space | O(W + hashSize) |

Recounting each product by rescanning every pair would grow much faster, while this program stays quadratic in the width.
