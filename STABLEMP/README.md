## Problem

Read several stable-marriage instances. Each instance gives n women and n men, and every person ranks all members of the other group. Print n pairs "m w" per instance so no man and woman prefer each other to their own partners. Any stable matching is accepted.

| Quantity | Bound |
| --- | --- |
| Test cases t | at most 100 |
| Couples per case n | at most 500 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Each case reads 2n ranked lists of n numbers, so input parsing drives the design.

## Idea

Use man-proposing Gale–Shapley. Each free man proposes to the next woman on his list. A woman keeps the best proposal so far and rejects the rest. A rejected man proposes again, and a displaced husband returns to the free pool. The process stops when every man has a wife.

Cost per proposal: O(1), because a rank matrix answers each woman comparison.

Searching all matchings would take factorial time. Each proposal here settles one comparison and never repeats a pair.

## Why It Works

A woman only trades up, since she replaces her husband solely with a man she ranks higher. A man only moves down his list, since each proposal advances one position. A woman rejects a man only while she holds someone better, so each of the n women rejects each man at most once. The process therefore ends with all men married.

In the final matching no blocking pair exists. If a man prefers a woman to his wife, that woman already rejected him or holds a man she ranks higher.

The flat arrays use these offsets:

- rowWidth equals pairCount, the length of one ranked list.
- womanId * rowWidth + manId finds a man's rank inside a woman's row.
- manId * rowWidth + proposalIndex finds the next woman inside a man's row.
- nextProposal[manId] counts proposals already made, so no pair repeats.

The generator prints the proposal trace for the first sample case.

| Man | Woman | Result |
| --- | --- | --- |
| 1 | 3 | accept |
| 2 | 2 | accept |
| 3 | 3 | reject, keeps man 1 |
| 3 | 1 | accept |
| 4 | 3 | reject, keeps man 1 |
| 4 | 2 | reject, keeps man 2 |
| 4 | 4 | accept |

Every rejection points at a woman holding a better man, so no pair is tried twice.

The resulting couples are:

| Man | Woman |
| --- | --- |
| 1 | 3 |
| 2 | 2 |
| 3 | 1 |
| 4 | 4 |

These four couples match the first sample case.

## Code

Input is read once into inputData. The digit scanner skips separators, and appendOutput flushes at 64 KiB.

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

The two loops read pairCount women and then pairCount men. The leading number on each row names the person and sets the row offset. Flat arrays keep each rank lookup to one index operation.

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

The outer loop ends when the free-men queue is empty. The inner loop ends when the current man has a wife. A displaced husband re-enters the queue, so freeMen holds pairCount squared plus pairCount slots.

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

Men are printed in increasing order, which matches the sample. The remaining output buffer is flushed once after all cases.

```nim
  for manId in 0..<pairCount:
    appendOutput($(manId + 1) & " " & $(wifeOfMan[manId] + 1) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0

{.pop.}
```

## Complexity

Reading and parsing take O(t n^2) time for all cases. Gale–Shapley takes at most n squared proposals per case, and each proposal costs O(1). Printing takes O(t n) time.

Total time is O(t n^2). Per-case space is O(n^2) for the rank tables and the free-men queue. The input buffer holds the whole stream, so its size is O(t n^2).

A naive search enumerates all perfect matchings in O(n!) time before any stability test.
