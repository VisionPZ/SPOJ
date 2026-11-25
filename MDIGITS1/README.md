# MDIGITS1 — Different Digits (SPOJ)

<https://www.spoj.com/problems/MDIGITS1/>

## Problem

For each n, find the smallest positive multiple of n that uses the fewest different decimal digits. A number such as 1334 uses three digits: 1, 3, and 4.

Each input line holds one positive integer n. A line with 0 ends the input. Print one number per case. When several numbers use the fewest digits, print the smallest one.

| Item | Bound |
|---|---|
| Divisor n | 1 to 65535 |
| Input lines | up to 50 |
| Digits needed | at most two for every n |
| Judge limit | 104 ms, 1536 MB |

The answer can be much longer than n, so it is built as text.

Sample input:

```
7 
15 
16 
101 
0
```

Sample output:

```
7 
555 
16 
1111
```

## Idea

Picking digits works like packing a small bag: try one-digit outfits first, then two-digit outfits, and keep the smallest item that fits.

A classic pigeonhole fact guarantees that every n has a multiple written with only 0 and 1. That puts the answer at two digits at most. For each one-digit or two-digit set, run a breadth-first search over remainders modulo n. The search visits shorter numbers before longer ones and tries smaller digits first. Comparing by length, then by text, selects the smallest answer. Testing successive multiples would take far longer for large n.

## Why It Works

1. Among the numbers 1, 11, 111, and so on, two share a remainder modulo n.
2. Their difference is a multiple of n written only with 0 and 1.
3. Therefore a candidate exists using one or two distinct digits.
4. For a fixed digit set, a state is the remainder modulo n.
5. Breadth-first search reaches short numbers first, and ascending digits give the smallest text at equal length.
6. A leading digit must be nonzero, so the search starts only with valid digits.

| Term | Meaning |
|---|---|
| `singleDigitAnswer` | smallest multiple using one repeated digit |
| `pairDigitAnswer` | smallest multiple using a chosen digit pair |
| `parentRemainder` | previous remainder for each visited state |
| `parentDigit` | digit appended to reach that state |
| `bestSingle` | winning one-digit candidate |

The table names the pieces that build and compare candidates.

A script trace for n = 15:

```
single digit 5: remainders 5, 10, 0 -> number 555
one-digit candidate 555 found
two-digit search skipped because one digit wins
answer 555
```

The trace matches the second sample line.

## Code

**Input and helpers.** The scanner reads divisors, and small helpers build and compare candidates.

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

proc repeatedDigitText(digitValue: int, repeatCount: int): string =
  result = ""
  for repeatIndex in 0 .. repeatCount - 1:
    result.add chr(48 + digitValue)

proc isBetter(candidate: string, currentBest: string): bool =
  if candidate.len == 0:
    return false
  if currentBest.len == 0:
    return true
  if candidate.len != currentBest.len:
    return candidate.len < currentBest.len
  return candidate < currentBest

proc singleDigitAnswer(digitValue: int, modulusValue: int): string =
  var remainderValue = digitValue mod modulusValue
  if remainderValue == 0:
    return repeatedDigitText(digitValue, 1)
  for lengthValue in 2 .. modulusValue + 1:
    remainderValue = (remainderValue * 10 + digitValue) mod modulusValue
    if remainderValue == 0:
      return repeatedDigitText(digitValue, lengthValue)
  return ""
```

A repeated digit needs only a running remainder.
The tie-break uses text length before lexicographic order.
A zero result means no candidate was found.

**Remainder search.** Each digit pair searches states and rebuilds the winning number.

```nim
proc reconstructAnswer(parentRemainder: seq[int], parentDigit: seq[int], tailRemainder: int, lastDigit: int): string =
  var reversedDigits = newSeq[int]()
  var cursor = tailRemainder
  while cursor >= 0:
    reversedDigits.add parentDigit[cursor]
    cursor = parentRemainder[cursor]
  result = ""
  var indexValue = reversedDigits.len - 1
  while indexValue >= 0:
    result.add chr(48 + reversedDigits[indexValue])
    indexValue -= 1
  result.add chr(48 + lastDigit)

proc pairDigitAnswer(firstDigit: int, secondDigit: int, modulusValue: int, parentRemainder: var seq[int], parentDigit: var seq[int], queue: var seq[int]): string =
  for indexValue in 0 .. modulusValue - 1:
    parentRemainder[indexValue] = -2
  queue.setLen 0
  var queueHead = 0
  var lowDigit = firstDigit
  var highDigit = secondDigit
  if lowDigit > highDigit:
    let previousDigit = lowDigit
    lowDigit = highDigit
    highDigit = previousDigit
  for startDigit in [lowDigit, highDigit]:
    if startDigit == 0:
      continue
    let startRemainder = startDigit mod modulusValue
    if startRemainder == 0:
      return repeatedDigitText(startDigit, 1)
    if parentRemainder[startRemainder] == -2:
      parentRemainder[startRemainder] = -1
      parentDigit[startRemainder] = startDigit
      queue.add startRemainder
  while queueHead < queue.len:
    let currentRemainder = queue[queueHead]
    queueHead += 1
    for digitValue in [lowDigit, highDigit]:
      let nextRemainder = (currentRemainder * 10 + digitValue) mod modulusValue
      if nextRemainder == 0:
        return reconstructAnswer(parentRemainder, parentDigit, currentRemainder, digitValue)
      if parentRemainder[nextRemainder] == -2:
        parentRemainder[nextRemainder] = currentRemainder
        parentDigit[nextRemainder] = digitValue
        queue.add nextRemainder
  return ""
```

Parent arrays are reused across the 45 digit pairs.
The value -2 marks an unvisited remainder.
Digits are tried in ascending order inside the search.

**Case driver.** One-digit sets run first, then all two-digit sets when needed.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var answerLines = newSeq[string]()
while scanPos < inputData.len:
  let divisorValue = nextInt(inputData, scanPos)
  if divisorValue == 0:
    break
  var bestSingle = ""
  for digitValue in 1 .. 9:
    let candidate = singleDigitAnswer(digitValue, divisorValue)
    if isBetter(candidate, bestSingle):
      bestSingle = candidate
  if bestSingle.len > 0:
    answerLines.add bestSingle
  else:
    var parentRemainder = newSeq[int](divisorValue)
    var parentDigit = newSeq[int](divisorValue)
    var queue = newSeq[int]()
    var bestPair = ""
    for firstDigit in 0 .. 8:
      for secondDigit in firstDigit + 1 .. 9:
        let candidate = pairDigitAnswer(firstDigit, secondDigit, divisorValue, parentRemainder, parentDigit, queue)
        if isBetter(candidate, bestPair):
          bestPair = candidate
    answerLines.add bestPair
for answerIndex in 0 .. answerLines.len - 1:
  appendOutput(answerLines[answerIndex])
  if answerIndex < answerLines.len - 1:
    appendOutput " "
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Nine single-digit checks run before any pair search.
The pair loop visits all 45 digit combinations.
Buffered output handles answers longer than one line.

## Complexity

Each digit set searches at most n remainder states.

| Phase | Time | Space |
|---|---|---|
| Single digits | nine remainder scans | constant |
| Digit pairs | up to 45 scans over n states | two arrays of n |
| Output | buffered writes | block buffer |

The table shows that the pair search dominates a hard case.

| Measure | Big O |
|---|---|
| Time | O(54 n) per case |
| Space | O(n) |

Scanning every multiple of n would cost far more than one pass over remainders per digit set.
