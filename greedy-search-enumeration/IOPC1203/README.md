# IOPC1203 — Crazy texting (SPOJ)
<https://www.spoj.com/problems/IOPC1203/>

## Problem

A phone prints a key's letters in cycles, and arbitrary gaps between presses change the typed word. Count the distinct words that one key sequence can print, modulo 100000007.

The first line gives the test count. Each following line holds one lowercase string of length at most 100000.

Print one count per line modulo 100000007.

The table lists the input and judge limits.

| item | bound |
|---|---|
| test cases | 1 to 10 |
| string length | 1 to 100000 |
| key cycle length | 3 or 4 |
| answer modulus | 100000007 |
| judge limit | 1000 ms, 1536 MB |

Only two cycle lengths occur in the T9 letter mapping.

The sample below is verbatim from the statement.

```
2
mod
iopc
```

```
8
64
```

The word `mod` produces eight different outputs.

## Idea

A run of keypresses is a row of beads, and each gap cuts the row into shorter words.

The algorithm counts bounded compositions of each run. Only cycle lengths 3 and 4 occur, so two precomputed tables cover every case.

Each press position costs a constant number of additions. Placing gaps one by one would take two to the length of the run, which is exponential.

The tables answer each run in one lookup.

## Why It Works

1. Different keys already separate letters, so only runs of one key matter.
2. A part of `pressCount` presses prints letter number (pressCount - 1) mod c in that key's cycle.
3. Equal letter sequences come from equal residue sequences of the parts.
4. A residue sequence is possible when its sum is at most `runPresses` and matches it modulo `cycleLength`.
5. `waysThree` and `waysFour` add the composition counts for sums `pressCount`, `pressCount - c`, and so on.

The table names the counts in the DP.

| term | meaning |
|---|---|
| `counts` | bounded compositions of a given press total |
| `ways` | distinct strings for one run length |
| `letterPresses` | presses needed for one letter |
| `letterCycles` | cycle length of that letter's key |

The bounded composition rule is a sliding sum of the last `cycleLength` counts.

For `mod`, the key 6 run has four presses and cycle length 3. There are seven compositions of 4 with parts at most 3, plus one composition of 1.

The run gives 8 strings, and the letter `d` gives one more factor, so the answer is 8.

The precomputation uses `maximumPresses` equal to four times 100000. This covers the longest possible run of one key.

## Code

**Input and word scanning.** The reader takes whole lowercase words after the test count.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 100000007
const maximumPresses = 400000

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word
```

The word scanner skips line breaks and separators. It collects letters into one string per case.

No whitespace token parser is needed.

**Composition tables.** Sliding sums build the bounded compositions once.

```nim
proc buildCounts(cycleLength: int): seq[int] =
  var counts = newSeq[int](maximumPresses + 1)
  counts[0] = 1
  for pressCount in 1 .. maximumPresses:
    var windowTotal = 0
    for partSize in 1 .. cycleLength:
      if pressCount - partSize >= 0:
        windowTotal = (windowTotal + counts[pressCount - partSize]) mod answerModulus
    counts[pressCount] = windowTotal
  return counts

proc buildWays(counts: seq[int], cycleLength: int): seq[int] =
  var ways = newSeq[int](maximumPresses + 1)
  for pressCount in 1 .. maximumPresses:
    var earlier = 0
    if pressCount > cycleLength:
      earlier = ways[pressCount - cycleLength]
    ways[pressCount] = (earlier + counts[pressCount]) mod answerModulus
  return ways

let countsThree = buildCounts(3)
let countsFour = buildCounts(4)
let waysThree = buildWays(countsThree, 3)
let waysFour = buildWays(countsFour, 4)
```

Each count sums the previous three or four counts. The ways table accumulates counts at the same residue.

All values stay reduced modulo `answerModulus`.

**Run multiplication.** Consecutive letters on one key form a single run.

```nim
var letterKeys = newSeq[int](26)
var letterPresses = newSeq[int](26)
var letterCycles = newSeq[int](26)
var letterIndex = 0
for keyValue in [2, 3, 4, 5, 6, 7, 8, 9]:
  let cycleLength = if keyValue == 7 or keyValue == 9: 4 else: 3
  for offsetValue in 0 .. cycleLength - 1:
    letterKeys[letterIndex] = keyValue
    letterPresses[letterIndex] = offsetValue + 1
    letterCycles[letterIndex] = cycleLength
    letterIndex += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let word = nextWord(inputData, scanPos)
  var currentKey = -1
  var currentCycle = 0
  var runPresses = 0
  var answerValue: int64 = 1
  for character in word:
    let alphabetIndex = int(character) - 97
    let keyValue = letterKeys[alphabetIndex]
    if runPresses > 0 and keyValue != currentKey:
      let ways = if currentCycle == 3: waysThree[runPresses] else: waysFour[runPresses]
      answerValue = answerValue * int64(ways) mod answerModulus
      runPresses = 0
    currentKey = keyValue
    currentCycle = letterCycles[alphabetIndex]
    runPresses += letterPresses[alphabetIndex]
  if runPresses > 0:
    let ways = if currentCycle == 3: waysThree[runPresses] else: waysFour[runPresses]
    answerValue = answerValue * int64(ways) mod answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A key change flushes the current run. The letter tables give cycle and press count.

The last run flushes after the loop.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| table build | four times `maximumPresses` additions | four arrays |
| letter tables | 26 assignments | three arrays |
| per string | one step per character | one word |
| output | one line per case | block buffer |

The measures use N for total input length.

| measure | Big O |
|---|---|
| time | O(maximumPresses + N) |
| space | O(maximumPresses) |

Enumerating gaps would grow as two to the length of each run. The residue DP turns that growth into one table build.
