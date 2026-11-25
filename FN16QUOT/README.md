# FN16QUOT — String Theory (SPOJ)

<https://www.spoj.com/problems/FN16QUOT/>

## Problem

A string is described only by the lengths of its consecutive quote runs, with some non-quote characters between runs. Find the deepest nesting level k that such a string can reach, or report that no quotation is possible.

Input holds several test cases until end of file. Each case gives a run count n, then one line with n run lengths. Output one line per case: the largest k, or `no quotation`.

| item | bound |
|---|---|
| runs per case | 1 to 100 |
| quotes in a run | 1 to 100 |
| total quotes | at most 10000 |
| judge limit | 1000 ms, 1536 MB |

The quote count drives the search, since a level k quotation needs at least k(k+1) quotes.

The exact sample input is:

    5
    2 1 1 1 3
    1
    22
    1
    1

The exact sample output is:

    2
    4
    no quotation

## Idea

Peel a quotation like unwrapping nested gift boxes: take k quotes, then k-1, down to one, from each end. The judge sketch gives a greedy test that always works. Each peel needs quotes from a single run, since only non-quote text may separate the layers. Trying levels from high to low finds the answer after at most 100 checks.

The takeaway is that one deterministic peeling pass decides each candidate level.

## Why It Works

1. A level k quotation opens with k quotes and closes with k quotes.
2. Its nested sequence begins with k-1 quotes, then k-2, and so on.
3. The same descending pattern holds at the opposite end.
4. The quotes left between the two peels must form 1-quotations, so their count is even.
5. Each peel takes the next available quotes, so the pattern is forced and greedy is complete.

| term | meaning |
|---|---|
| `runOfQuote` | run number stored for each quote position |
| `totalQuotes` | number of quote characters in the string |
| `frontPos` | quote position reached by peeling from the left |
| `backPos` | quote position reached by peeling from the right |
| `bestLevel` | deepest level that passed the peel test |

The table shows that positions, not non-quote counts, drive the test.

A script trace of the run of 22 quotes follows:

    level 4 peels 4+3+2+1 = 10 quotes on the left
    level 4 peels 4+3+2+1 = 10 quotes on the right
    leftover quotes 22-20 = 2, which is even
    level 5 would need 30 quotes, so it fails

The trace explains why the sample answer is 4.

## Code

**Input and scanning.** The reader consumes cases until no digits remain.

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

proc hasMoreData(data: string, pos: var int): bool =
  var probe = pos
  while probe < data.len and (data[probe] < '0' or data[probe] > '9'):
    probe += 1
  if probe < data.len:
    pos = probe
    return true
  return false
```

The scanner skips every space and line break.
The end of file check uses a separate probe position.
No negative values appear in this problem.

**Buffered output.** One string collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 131072 bytes.
A single final flush finishes the run.
Many small test cases stay cheap this way.

**Peeling test.** Candidate levels shrink until one passes.

```nim
while hasMoreData(inputData, scanPos):
  let runCount = nextInt(inputData, scanPos)
  var quoteRuns = newSeq[int](runCount)
  var totalQuotes = 0
  for runIndex in 0 .. runCount - 1:
    quoteRuns[runIndex] = nextInt(inputData, scanPos)
    totalQuotes += quoteRuns[runIndex]
  var runOfQuote = newSeq[int](totalQuotes)
  var quoteIndex = 0
  for runIndex in 0 .. runCount - 1:
    for quoteInRun in 0 .. quoteRuns[runIndex] - 1:
      runOfQuote[quoteIndex] = runIndex
      quoteIndex += 1
  var maxLevelValue = 1
  while (maxLevelValue + 1) * (maxLevelValue + 2) <= totalQuotes:
    maxLevelValue += 1
  var bestLevel = 0
  var candidateLevel = maxLevelValue
  while candidateLevel >= 2 and bestLevel == 0:
    var feasible = true
    var frontPos = 0
    var frontSize = candidateLevel
    while frontSize >= 1:
      if frontPos + frontSize > totalQuotes:
        feasible = false
        break
      if runOfQuote[frontPos] != runOfQuote[frontPos + frontSize - 1]:
        feasible = false
        break
      frontPos += frontSize
      frontSize -= 1
    if feasible:
      var backPos = totalQuotes
      var backSize = candidateLevel
      while backSize >= 1:
        if backPos - backSize < frontPos:
          feasible = false
          break
        if runOfQuote[backPos - backSize] != runOfQuote[backPos - 1]:
          feasible = false
          break
        backPos -= backSize
        backSize -= 1
      if feasible and (backPos - frontPos) mod 2 == 0:
        bestLevel = candidateLevel
    candidateLevel -= 1
  if bestLevel == 0 and totalQuotes == 2:
    bestLevel = 1
  if bestLevel == 0:
    appendOutput("no quotation")
  else:
    appendOutput($bestLevel)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The run map marks which run owns each quote slot.
Each peel checks that its quotes share one run.
The level 1 case needs exactly two quotes.
The first passing level is written before moving on.

## Complexity

Each case builds a run map once and then tries levels.

| phase | time | space |
|---|---|---|
| input read | one pass over all numbers | one input string |
| run map | one entry per quote | array of total quotes |
| level search | up to 100 peels of at most 100 steps | constant extra space |
| output | one write per full block | block buffer |

The level search stays small because a level needs k(k+1) quotes.

| measure | Big O |
|---|---|
| time | O(total quotes · square root of total quotes) |
| space | O(total quotes) |

A recursive enumeration of all nestings would explore far more states.
The takeaway is that forced peeling gives the answer with a short scan.
