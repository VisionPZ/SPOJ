# JARJAR — Helping Jar Jar Binks (SPOJ)

<https://www.spoj.com/problems/JARJAR/>

## Problem

Given part weights, list every number of parts that can be selected to reach a target weight exactly. Each part is used at most once, and answers are printed in ascending order.

Several cases follow one another; a case starts with N and Q, then N weights and Q target weights. The line 0 0 ends the input. When no selection works, print "That's impossible!".

| item | bound |
|---|---|
| parts N | 1 to 60 |
| queries Q | 0 to 10000 |
| weight per part | 1 to 1000 |
| target weight | any integer, possibly negative |
| judge limit | 1000 ms, 1536 MB |

The largest possible total is 60000, which bounds the DP table.

Sample input:

```
5 4
1 2 3 1 1
3
5
1
9
0 0
```

Sample output:

```
1 2 3
2 3 4
1
That's impossible!
```

## Idea

Treat each possible piece count as a row of checkboxes, one box per reachable weight, like a chart that lights up when a new part is tried. Adding a part shifts the previous row's boxes forward by that part's weight and ORs them into the new row.

The algorithm stores each row as a bitset of 60001 bits. One update shifts about 940 machine words, and Q queries each test one bit per row. A set-of-pairs DP would store millions of tuples and cost far more per part.

Bit positions give weights directly, so answering a query needs no search.

## Why It Works

1. Row k holds a 1 at weight w exactly when some k parts sum to w.
2. Row zero holds only weight zero, the empty selection.
3. Adding a part of weight p makes row k include row k - 1 shifted by p.
4. Processing piece counts downward prevents the same part from being used twice.
5. Testing bit W in rows 1 through N gives every valid piece count in order.

| term | meaning |
|---|---|
| `reachable` | rows of bitsets, one row per piece count |
| `shiftInto` | ORs a shifted source row into a destination row |
| `wordShift` | whole 64-bit words moved by one part |
| `bitShift` | remaining bit offset inside a word |
| `targetMask` | single-bit mask for a queried weight |

Rows are processed from high piece count to low so each part is counted once.

A script-generated trace for the sample weights 1 2 3 1 1:

```
W=1 -> counts {1}
W=3 -> counts {1,2,3}
W=5 -> counts {2,3,4}
W=9 -> counts {}
```

The first three rows match the sample, and the last row gives the impossible line.

## Code

**Input and word shift.** The scanner handles minus signs, and the helper shifts one row by a part weight.

```nim
const flushBlockBytes = 1 shl 17
const wordBits = 64
const maxParts = 60
const maxTotalWeight = 60000
const wordCount = 940

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc shiftInto(destination: var seq[uint64], source: seq[uint64], wordShift: int, bitShift: int, lastWord: int) =
  if bitShift == 0:
    for wordIndex in countdown(lastWord, wordShift):
      destination[wordIndex] = destination[wordIndex] or source[wordIndex - wordShift]
  else:
    if lastWord > wordShift:
      for wordIndex in countdown(lastWord, wordShift + 1):
        let lowerWord = source[wordIndex - wordShift - 1]
        let upperWord = source[wordIndex - wordShift]
        destination[wordIndex] = destination[wordIndex] or ((upperWord shl bitShift) or (lowerWord shr (wordBits - bitShift)))
    destination[wordShift] = destination[wordShift] or (source[0] shl bitShift)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A minus sign lets the reader accept negative targets.
The helper crosses a word boundary with two source words.
A var parameter writes into the row directly.

**Bitset DP and queries.** Every part updates all rows, then each target reads one bit per row.

```nim
while true:
  let partCount = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  if partCount == 0 and queryCount == 0:
    break
  var reachable = newSeq[seq[uint64]](maxParts + 1)
  for pieceCount in 0 .. maxParts:
    reachable[pieceCount] = newSeq[uint64](wordCount)
  reachable[0][0] = 1'u64
  var activeParts = 0
  var currentLimit = 0
  for partIndex in 0 ..< partCount:
    let partWeight = nextInt(inputData, scanPos)
    let wordShift = partWeight div wordBits
    let bitShift = partWeight mod wordBits
    let lastWord = min(wordCount - 1, (currentLimit + partWeight) div wordBits)
    let nextParts = activeParts + 1
    if nextParts > 0:
      for pieceCount in countdown(nextParts, 1):
        shiftInto(reachable[pieceCount], reachable[pieceCount - 1], wordShift, bitShift, lastWord)
    activeParts = nextParts
    currentLimit = min(maxTotalWeight, currentLimit + partWeight)
  for queryIndex in 0 ..< queryCount:
    let targetWeight = nextInt(inputData, scanPos)
    if targetWeight < 0 or targetWeight > maxTotalWeight:
      appendOutput("That's impossible!\n")
    else:
      let targetWord = targetWeight div wordBits
      let targetMask = 1'u64 shl (targetWeight mod wordBits)
      var hasPieceCount = false
      for pieceCount in 1 .. activeParts:
        if (reachable[pieceCount][targetWord] and targetMask) != 0'u64:
          if hasPieceCount:
            appendOutput(" ")
          appendOutput($pieceCount)
          hasPieceCount = true
      if not hasPieceCount:
        appendOutput("That's impossible!")
      appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`currentLimit` stops shift work past the reachable total.
Descending piece counts keep each part single-use.
A query with no set bit prints the fixed failure line.

## Complexity

Each part shifts N rows, and each query checks N rows at one bit.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| bitset DP | N shifts of about 940 words | 61 rows of 940 words |
| queries | N bit tests per target | block buffer |

The DP cost depends on N and the word count, not on Q.

| measure | Big O |
|---|---|
| time | O(N^2 * 60000 / 64 + Q * N) |
| space | O(N * 60000 / 64) |

A tuple-based subset DP would pay far more per transition than a word-wise OR.
