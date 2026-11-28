# MULTII — Yet Another Multiple Problem (SPOJ)

<https://www.spoj.com/problems/MULTII/>

## Problem

Find the smallest positive multiple of `N` whose decimal notation avoids every forbidden digit. Each case gives `N`, a count `m`, and `m` digits; print the case number with the answer, or `-1` when no such multiple exists.

Input consists of cases until EOF. A case starts with two integers `N` and `m` on one line. The next line holds `m` space-separated digits. Repeated digits are allowed, so `m` may exceed 9. Output one line per case in the form `Case X: answer`.

| item | bound |
|---|---|
| divisor `N` | 1 to 10000 |
| forbidden count `m` | any positive count |
| judge limit | 4000 ms, 1536 MB |

The answer can have more than 10000 digits, so it cannot be stored in a machine integer.

```
2345 3
7 8 9
100 1
0
```

```
Case 1: 2345
Case 2: -1
```

## Idea

Treat each remainder as a room: an allowed digit walks you into the next room, and the first visit to room zero gives the shortest valid number. Breadth-first search over remainders is the algorithm; each remainder has at most ten outgoing digits, so the work per state is constant. Testing successive multiples instead can scan astronomically many candidates. Use the search, then walk parent links to print the digits found.

## Why It Works

1. Appending digit `d` to a number with remainder `r` gives remainder `(10 * r + d) mod N`.
2. There are exactly `N` remainders, so a shortest path revisits none.
3. Breadth-first search visits numbers by length, and digits in increasing order break ties.
4. A leading digit comes from 1 to 9; later digits may be zero.
5. Reaching remainder zero means the constructed number is a multiple of `N`.

| term | meaning |
|---|---|
| `visitedRemainder` | marks a remainder already reached by a shorter number |
| `parentRemainder` | predecessor remainder used to rebuild the answer |
| `parentDigit` | digit appended at that predecessor step |
| `remainderQueue` | breadth-first frontier of remainders |

For the sample divisor 2345 with digits 7, 8, 9 forbidden, the search builds 2, then 23, then 234, then 2345. The last step reaches remainder zero, and every digit lies outside the forbidden set.

Parent links are walked backwards, so the collected digits are reversed before printing. The scanner skips separators, so line breaks do not affect parsing.

## Code

**Input and scanning.** The reader loads all stdin, then a hand scanner extracts integers.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer holds the whole result stream.
Large writes flush in blocks.
The loop stops only after the scanner reaches the end of input.

**Remainder search.** Breadth-first search builds one number per remainder and stops at zero.

```nim
var caseNumber = 0
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  caseNumber += 1
  let divisor = nextInt(inputData, scanPos)
  let forbiddenCount = nextInt(inputData, scanPos)
  var forbiddenDigits = newSeq[bool](10)
  for digitIndex in 0 .. forbiddenCount - 1:
    let forbiddenDigit = nextInt(inputData, scanPos)
    forbiddenDigits[forbiddenDigit] = true
  var visitedRemainder = newSeq[bool](divisor)
  var parentRemainder = newSeq[int](divisor)
  var parentDigit = newSeq[int](divisor)
  var remainderQueue = newSeq[int](divisor)
  var queueHead = 0
  var queueTail = 0
  var foundRemainder = false
  for digitValue in 1 .. 9:
    if forbiddenDigits[digitValue]:
      continue
    let startRemainder = digitValue mod divisor
    if not visitedRemainder[startRemainder]:
      visitedRemainder[startRemainder] = true
      parentRemainder[startRemainder] = -1
      parentDigit[startRemainder] = digitValue
      remainderQueue[queueTail] = startRemainder
      queueTail += 1
      if startRemainder == 0:
        foundRemainder = true
        break
  while not foundRemainder and queueHead < queueTail:
    let currentRemainder = remainderQueue[queueHead]
    queueHead += 1
    for digitValue in 0 .. 9:
      if forbiddenDigits[digitValue]:
        continue
      let nextRemainder = (currentRemainder * 10 + digitValue) mod divisor
      if not visitedRemainder[nextRemainder]:
        visitedRemainder[nextRemainder] = true
        parentRemainder[nextRemainder] = currentRemainder
        parentDigit[nextRemainder] = digitValue
        remainderQueue[queueTail] = nextRemainder
        queueTail += 1
        if nextRemainder == 0:
          foundRemainder = true
          break
  appendOutput("Case " & $caseNumber & ": ")
  if not foundRemainder:
    appendOutput("-1")
  else:
    var reversedDigits = ""
    var cursor = 0
    while parentRemainder[cursor] != -1:
      reversedDigits.add chr(parentDigit[cursor] + 48)
      cursor = parentRemainder[cursor]
    reversedDigits.add chr(parentDigit[cursor] + 48)
    for digitIndex in countdown(reversedDigits.len - 1, 0):
      outputBuffer.add reversedDigits[digitIndex]
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each state stores its parent digit for reconstruction.
The queue never exceeds `N` entries.
Digits are written as characters, so answers of any length fit.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| remainder search | at most 10 steps per remainder | four arrays of size `N` |
| digit output | one pass over the answer length | one string per answer |

| measure | Big O |
|---|---|
| time per case | O(10 * N + answer length) |
| space per case | O(N) |

Testing multiples one by one can run far longer than the remainder search on large divisors.

The search visits each remainder once, so it always finds a shortest valid number when one exists.
