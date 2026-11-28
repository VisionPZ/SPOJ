# ZAMENA — Zamena (SPOJ)

<https://www.spoj.com/problems/ZAMENA/>

## Problem

Picsel walks through a list of equal-length ID numbers and remembers one ID at a time. He may replace the remembered ID only by a later ID that differs in at most one digit, and each replacement adds the digit change to his score. Report the largest score he can reach by starting anywhere and skipping any IDs.

Input starts with the member count N. Each of the next N lines holds one integer ID. All IDs have the same digit length.

Output one line with the maximum score.

| item | bound |
|---|---|
| members N | 1 to 100000 |
| ID value | 0 to 9999999 |
| judge limit | 500 ms, 1536 MB |

The digit length of the first ID sets the common ID width.

Sample input:

```
6
8823
2145
2185
3385
4145
4445
```

Sample output:

```
5
```

## Idea

Think of each remembered ID as a rung on a ladder, like stepping only onto stones within one digit of the stone under your foot. The trick is to keep the best score for every exact ID already seen, then try all one-digit changes of the current ID. Dynamic programming over the list finds the best chain ending at each ID. A direct check of every earlier ID costs quadratic time, while trying at most 7 times 10 variants costs a fixed small number per ID. Each ID costs about 70 table lookups, so the whole list stays linear in its length.

## Why It Works

1. A valid chain is a sequence of IDs where each step changes at most one digit.
2. The score of a step is the absolute difference of the changed digits.
3. Once the current ID is fixed, only its one-digit variants can be useful predecessors.
4. Keeping the best score for each exact variant keeps every useful predecessor.
5. Processing IDs in order guarantees that every predecessor appears earlier.

| term | meaning |
|---|---|
| `memberIds` | the ID values in arrival order |
| `digitLength` | the shared number of digits in every ID |
| `placeValues` | powers of ten from the leftmost digit to the rightmost |
| `bestExactScore` | best chain score seen so far for an exact ID value |
| `chainScore` | best chain ending at the current ID |

The table holds the key invariant: one stored score per exact ID.

A script trace over the sample IDs gives these chain scores:

```
ID      best predecessor      score
8823    none                  0
2145    none                  0
2185    2145 (4 -> 8)         4
3385    none                  0
4145    2145 (2 -> 4)         2
4445    4145 (1 -> 4)         5
```

The largest score in the trace is 5, which matches the sample output.

Unreachable IDs hold the sentinel -1 in `bestExactScore`, so a real score of zero still counts as a predecessor.

## Code

**Input and table setup.** The reader loads every ID and sizes the score table from the ID width.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

The scanner skips every separator, including line breaks.
Each digit contributes through the value 48 offset.
One pass loads the whole input into `inputData`.

**Width and sentinel fill.** Place values follow the digit width, and every score starts unreachable.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let memberCount = nextInt(inputData, scanPos)
var memberIds = newSeq[int](memberCount)
for memberIndex in 0 .. memberCount - 1:
  memberIds[memberIndex] = nextInt(inputData, scanPos)

var digitLength = 1
var largestPlace = 10
while largestPlace <= memberIds[0]:
  digitLength += 1
  largestPlace = largestPlace * 10

var placeValues = newSeq[int](digitLength)
var placeMultiplier = 1
for placeIndex in countdown(digitLength - 1, 0):
  placeValues[placeIndex] = placeMultiplier
  placeMultiplier = placeMultiplier * 10

var bestExactScore = newSeq[int64](largestPlace)
for scoreIndex in 0 .. largestPlace - 1:
  bestExactScore[scoreIndex] = -1
```

The sentinel -1 separates a real zero score from an unseen ID.
`placeValues` runs from the leftmost power of ten to the rightmost.
The table has one slot for each possible ID value of that width.

**Variant scan.** Each ID probes every one-digit change and keeps the best chain.

```nim
var bestTotalScore: int64 = 0
for memberIndex in 0 .. memberCount - 1:
  let currentId = memberIds[memberIndex]
  var chainScore: int64 = 0
  for placeIndex in 0 .. digitLength - 1:
    let placeValue = placeValues[placeIndex]
    let currentDigit = (currentId div placeValue) mod 10
    let idWithoutDigit = currentId - currentDigit * placeValue
    for candidateDigit in 0 .. 9:
      let variantId = idWithoutDigit + candidateDigit * placeValue
      let priorScore = bestExactScore[variantId]
      if priorScore >= 0:
        let changeAmount = abs(candidateDigit - currentDigit)
        let candidateScore = priorScore + int64(changeAmount)
        if candidateScore > chainScore:
          chainScore = candidateScore
  if chainScore > bestTotalScore:
    bestTotalScore = chainScore
  if chainScore > bestExactScore[currentId]:
    bestExactScore[currentId] = chainScore

appendOutput($bestTotalScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The same digit gives a zero change and covers an exact ID.
Updating after the scan keeps every predecessor strictly earlier.
The answer is written once through the block buffer.

## Complexity

The work is one pass over members with a fixed-width probe per member.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| variant scan | member count times 7 times 10 lookups | score table over ID values |
| output | one line | block buffer |

The variant scan dominates and grows linearly with the member count.

| measure | Big O |
|---|---|
| time | O(N * 10 * D), D is the digit length |
| space | O(10^D) |

Checking every earlier pair would cost O(N^2) time instead.
The table turns that pair search into a fixed number of lookups per ID, which is the takeaway.
