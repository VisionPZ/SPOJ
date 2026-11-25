# STABLEMP — Stable Marriage Problem (SPOJ)

<https://www.spoj.com/problems/STABLEMP/>

## Problem

A dance organizer pairs `n` men with `n` women. Everyone ranks the other side, and no couple should prefer a different partner to the one assigned. The organizer needs any pairing with that property.

Input: `t` test cases. Each case starts with `n`, followed by `n` lines of women's rankings and `n` lines of men's rankings.

Each line names the person and lists partners from best to worst. Output: `n` lines `m w` per case, with one line for each man.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Test cases `t` | at most 100 |
| Couples per case `n` | at most 500 |
| Input size | large, so buffered reading matters |
| Judge limit | 1000 ms, 1536 MB |

Each case holds `2n` ranked lists, so parsing runs alongside the matching.

The sample input and output:

```
2
4
1 4 3 1 2
2 2 1 3 4
3 1 3 4 2
4 4 3 1 2
1 3 2 4 1
2 2 3 1 4
3 3 1 2 4
4 3 2 4 1
7
1 3 4 2 1 6 7 5
2 6 4 2 3 5 1 7
3 6 3 5 7 2 4 1
4 1 6 3 2 4 7 5
5 1 6 5 3 4 7 2
6 1 7 3 4 5 6 2
7 5 6 2 4 3 7 1
1 4 5 3 7 2 6 1
2 5 6 4 7 3 2 1
3 1 6 5 4 3 7 2
4 3 5 6 7 2 4 1
5 1 7 6 4 3 5 2
6 6 3 7 5 2 4 1
7 1 7 4 2 6 5 3
```

```
1 3
2 2
3 1
4 4
1 4
2 5
3 1
4 3
5 7
6 6
7 2
```

## Idea

Let each free man ask the next woman on his list, like an applicant knocking on doors. A woman keeps the best offer so far and sends the rest away.

The program runs the man-proposing Gale–Shapley algorithm. A rank matrix answers each woman comparison in `O(1)` time. At most `n²` proposals occur, so a case costs `O(n²)`.

Scanning all `n!` matchings would explode long before `n = 500`. Each proposal here settles one comparison and never repeats a pair.

Keeping only the current best offer per woman makes stability automatic.

## Why It Works

Four facts prove stability.

1. A woman only trades up, since she replaces her husband with a man she ranks higher.
2. A man only moves down his list, because `nextProposal` advances after each offer.
3. A rejected man returns to the free queue. Each ordered pair is tried once, so the loop makes at most `n²` offers.
4. In the final matching, a man who prefers another woman was rejected by her or lost to a better husband. No blocking pair remains.

The flat arrays and their offsets:

| Term | Meaning |
| --- | --- |
| `rowWidth` | length of one ranked list, equal to `n` |
| `womanRank[womanId * rowWidth + manId]` | where a woman ranks one man |
| `manChoice[manId * rowWidth + rankIndex]` | a man's next woman |
| `wifeOfMan`, `husbandOfWoman` | current partners, or `-1` when free |
| `freeMen` | queue of men waiting to propose |

The rank matrix turns each acceptance test into one array lookup.

A generator trace of the proposals in the first sample case:

```
| Man | Woman | Result |
| --- | --- | --- |
| 1 | 3 | accept |
| 2 | 2 | accept |
| 3 | 3 | reject, keeps man 1 |
| 3 | 1 | accept |
| 4 | 3 | reject, keeps man 1 |
| 4 | 2 | reject, keeps man 2 |
| 4 | 4 | accept |

Final matching

| Man | Woman |
| --- | --- |
| 1 | 3 |
| 2 | 2 |
| 3 | 1 |
| 4 | 4 |
```

Each rejection points to a woman holding a better man, so no pair is tried twice.

## Code

**Input and parsing.** One buffer holds the whole stream, and a scanner reads integers.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips all non-digits, so blank lines between cases cause no trouble.
The output helper flushes at 64 KiB, which suits many short lines.

**Rank matrices.** The program stores each woman's ranks and each man's choices in flat arrays.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pairCount = nextInt(inputData, scanPos)
  let rowWidth = pairCount
  var manChoice = newSeq[int](pairCount * rowWidth)
  var womanRank = newSeq[int](pairCount * rowWidth)

  for womanIndex in 0..<pairCount:
    let womanId = nextInt(inputData, scanPos) - 1
    for rankIndex in 0..<rowWidth:
      let manId = nextInt(inputData, scanPos) - 1
      womanRank[womanId * rowWidth + manId] = rankIndex + 1

  for manIndex in 0..<pairCount:
    let manId = nextInt(inputData, scanPos) - 1
    for rankIndex in 0..<rowWidth:
      manChoice[manId * rowWidth + rankIndex] = nextInt(inputData, scanPos) - 1
```

`rowWidth` equals `pairCount`.
Index `womanId * rowWidth + manId` finds one rank; index `manId * rowWidth + rankIndex` finds one choice.
Both loops read exactly `n` numbers per line.

**Proposal loop.** Free men propose until every man has a wife.

```nim
  var nextProposal = newSeq[int](pairCount)
  var wifeOfMan = newSeq[int](pairCount)
  var husbandOfWoman = newSeq[int](pairCount)
  var freeMen = newSeq[int](pairCount * pairCount + pairCount)
  var queueHead = 0
  var queueTail = 0
  for manId in 0..<pairCount:
    wifeOfMan[manId] = -1
    husbandOfWoman[manId] = -1
    freeMen[queueTail] = manId
    queueTail += 1

  while queueHead < queueTail:
    let manId = freeMen[queueHead]
    queueHead += 1
    while wifeOfMan[manId] == -1:
      let proposalIndex = nextProposal[manId]
      let womanId = manChoice[manId * rowWidth + proposalIndex]
      nextProposal[manId] = proposalIndex + 1
      let heldHusband = husbandOfWoman[womanId]
      if heldHusband == -1:
        husbandOfWoman[womanId] = manId
        wifeOfMan[manId] = womanId
      elif womanRank[womanId * rowWidth + manId] < womanRank[womanId * rowWidth + heldHusband]:
        husbandOfWoman[womanId] = manId
        wifeOfMan[manId] = womanId
        wifeOfMan[heldHusband] = -1
        freeMen[queueTail] = heldHusband
        queueTail += 1
```

The queue is sized `n² + n`, which covers every possible proposal.
The inner `while` ends when the man is married; a rejected husband re-enters the queue.
The rank comparison is one lookup, so an offer costs `O(1)`.

**Output and tail.** One line per man closes each case.

```nim
  for manId in 0..<pairCount:
    appendOutput($(manId + 1) & " " & $(wifeOfMan[manId] + 1) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

{.pop.}
```

Both indices are incremented before printing, since the arrays use zero-based ids.
The final write flushes the remaining buffer.
`{.pop.}` closes the check suppression at file end.

## Complexity

Parsing and matching both scale with the number of ranked entries.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Preference matrices | O(n²) per case | O(n²) for two arrays |
| Proposal loop | at most n² offers | O(n²) for the queue |
| Output | one write per 64 KiB block | 64 KiB |
| Total per case | O(n²) | O(n²) |

At `n = 500` the matrices hold 250,000 integers each.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n²) per case, O(t × n²) overall |
| Space | O(n²) per case, plus buffers |

Checking all `n!` matchings for stability is infeasible. Gale–Shapley reaches a stable matching after at most `n²` offers.
