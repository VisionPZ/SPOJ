# ADAFIMBR — Ada and Fimbers (SPOJ)

<https://www.spoj.com/problems/ADAFIMBR/>

## Problem

Two players take turns removing a Fibonacci number of seeds from one pile. The player with no legal move loses, and Ada moves first. Decide who wins when both play well.

The input has a single case. The first line gives the pile count `N`. The next line gives `N` pile sizes, each from zero to three million. The allowed move sizes are `1, 2, 3, 5, 8` and so on, with `1` used once. Output `Ada` when the first player wins, otherwise output `Vinit`.

| Item | Bound |
|---|---|
| Piles N | 1 to 100000 |
| Seeds per pile | 0 to 3000000 |
| Judge limit | 2000 ms, 1536 MB |

A pile of zero seeds offers no move.

The first sample case is:

```
6
3 3 1 8 3 4
```

The expected output is:

```
Ada
```

## Idea

Treat each pile as a separate game with a score, like rating a stack of coins by the best move it offers. Compute that score, called a Grundy value, for every seed count up to the largest pile. Combine piles with bitwise XOR. A nonzero total means Ada wins. A precomputed Fibonacci list supplies the legal moves, and a stamp array finds the smallest missing score quickly.

## Why It Works

1. A pile of `k` seeds can move to `k - F` seeds for every Fibonacci number `F` at most `k`.
2. The Grundy value of a position is the smallest nonnegative value absent from its options.
3. Two equal Grundy values cancel under XOR, so repeated piles cancel in pairs.
4. Sprague-Grundy theory states that a sum of piles has value equal to the XOR of pile values.
5. The next player loses exactly when that XOR is zero.

| Term | Meaning |
|---|---|
| `fibNumbers` | distinct Fibonacci move sizes, starting at one |
| `grundy` | Grundy value for each seed count |
| `seenValue` | stamp array used to collect option values |
| `nimTotal` | XOR of all pile values |

The stamp avoids clearing the option array for every seed count.

A short trace with the sample piles:

```
pile 3 -> grundy 3, pile 3 -> grundy 3, pile 1 -> grundy 1
pile 8 -> grundy 4, pile 3 -> grundy 3, pile 4 -> grundy 0
XOR: 3 xor 3 = 0, 0 xor 1 = 1, 1 xor 4 = 5, 5 xor 3 = 6, 6 xor 0 = 6
```

The nonzero total six gives the sample winner, Ada.

## Code

**Input and scanning.** The first pass finds the largest seed count and the second pass reads cases.

```nim
const flushBlockBytes = 1 shl 17
const seenSlots = 1024

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var maxSeeds = 0
while hasNextNumber(inputData, scanPos):
  let token = nextInt(inputData, scanPos)
  if token > maxSeeds:
    maxSeeds = token
scanPos = 0
```

The scan covers both pile counts and pile sizes.
Using the input maximum keeps small tests fast.
The output buffer collects winner names in blocks.

**Move list and Grundy table.** Each seed count takes the missing value from its options.

```nim
var fibNumbers = newSeq[int]()
fibNumbers.add 1
fibNumbers.add 2
while fibNumbers[fibNumbers.len - 1] <= maxSeeds:
  fibNumbers.add fibNumbers[fibNumbers.len - 1] + fibNumbers[fibNumbers.len - 2]

var grundy = newSeq[int](maxSeeds + 1)
var seenValue = newSeq[int](seenSlots)
var stamp = 0
for seeds in 1 .. maxSeeds:
  stamp += 1
  for fibonacci in fibNumbers:
    if fibonacci > seeds:
      break
    let option = grundy[seeds - fibonacci]
    if option < seenSlots:
      seenValue[option] = stamp
  var mex = 0
  while mex < seenSlots and seenValue[mex] == stamp:
    mex += 1
  grundy[seeds] = mex
```

Only distinct Fibonacci values appear in the move list.
The stamp marks values reached from the current pile.
The first unmarked value becomes the Grundy value.

**Winner decision.** All pile values are combined, then one name is written.

```nim
while hasNextNumber(inputData, scanPos):
  let pileCount = nextInt(inputData, scanPos)
  var nimTotal = 0
  for pileIndex in 0 .. pileCount - 1:
    let seeds = nextInt(inputData, scanPos)
    nimTotal = nimTotal xor grundy[seeds]
  if nimTotal != 0:
    appendOutput("Ada\n")
  else:
    appendOutput("Vinit\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero seed pile contributes zero to the XOR.
The loop also accepts extra cases in one file.
The final flush writes the buffered names.

## Complexity

The Grundy table is built once, and every pile costs one lookup.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over pile sizes | one input string |
| Grundy build | about 33 moves per seed count | one value per seed count |
| Winner decision | one XOR per pile | one output buffer |
| Output | one buffered pass over cases | block buffer |

The table limit comes from the largest seed count in the input.

| Measure | Big O |
|---|---|
| Time | O(V log V + N) |
| Space | O(V) |

`V` is the largest seed count and stays at most three million.
Replaying the game after each move would grow exponentially instead, so the table wins.
