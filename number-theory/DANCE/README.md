# DANCE — The Gordian Dance (SPOJ)
<https://www.spoj.com/problems/DANCE/>

## Problem

The input gives a sequence of moves already performed by two pairs of dancers holding strings.
Moves `S` and `R` tangle the strings; find the fewest extra moves that leave both straight, horizontal, and parallel.

Four dancers hold two strings at the corners of a square.
Move `S` swaps the two dancers on the right side and adds one crossing.
Move `R` turns every dancer a quarter turn clockwise.
Given the moves already danced, print the fewest extra moves that leave both strings straight, horizontal, parallel, and untangled.

Each input holds ten cases.
A case gives `n`, then a word of `n` letters `S` and `R`.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Cases per input | 10 |
| Moves per case `n` | 0 to 1000000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The answer counts moves, so it stays small even for a long word.

The sample input and expected output follow verbatim.

```
2
SS
```

```
5
```

The word SS needs five extra moves.

## Idea

Track the tangle as one fraction, like a subtraction you can undo from either end.
Two strings with four fixed ends form a rational tangle (a fraction that records crossings).
Straight horizontal strings give `q = 0`.
Move `S` sends `q` to `q + 1`.
Move `R` sends `q` to `-1/q`.

Keep `q` as a continued fraction (a list of integers for a fraction) with an explicit sign.
Undo greedily: rotate while `q` is positive, add one while `q` is negative, and stop at zero.
Batching repeated unit steps keeps the undo count cheap.

Each input letter costs constant time.
One fraction and a greedy undo give the answer in one pass.

## Why It Works

Four facts prove the method.

1. The fraction counts signed crossings, so adding a crossing on the right gives `q + 1`.
2. A quarter turn swaps numerator and denominator and flips orientation, which gives `-1/q`.
   Two turns give `q` back.
3. A positive `q` moves below zero after one rotation.
   A negative `q` moves toward zero after adding one.
4. Batching a large front digit replaces many identical steps with one counter update.

The values used by the program follow.

| Term | Meaning |
| --- | --- |
| `cfDigits` | continued fraction digits, front digit at the end |
| `isNegative` | sign of the current fraction |
| `isInfinite` | special state reached by rotating zero |
| `countUndoSteps` | greedy counter with batching |

Each undo step removes one step from the only shortest route.

A script applies the two rules to the word `SS` and then runs the undo rule.

| Step | Action | Fraction |
| --- | --- | --- |
| 0 | start | 0 |
| 1 | S | 1 |
| 2 | S | 2 |
| 3 | undo R | -1/2 |
| 4 | undo S | 1/2 |
| 5 | undo R | -2 |
| 6 | undo S | -1 |
| 7 | undo S | 0 |

The five undo steps give the answer 5 and spell `RSRSS`.

## Code

**Constants and output buffer.**

```nim
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var outputBuffer = ""
```

flushBlockBytes sets the 256 KiB output block. firstDigitValue converts a digit byte into its value. All answer lines share one buffer.

**Rotation.**

```nim
proc rotateFraction(cfDigits: var seq[int], isInfinite: var bool, isNegative: var bool) =
  if isInfinite:
    isInfinite = false
    isNegative = false
    cfDigits[0] = 0
    cfDigits.setLen(1)
    return
  let digitCount = cfDigits.len
  let front = cfDigits[digitCount - 1]
  if digitCount == 1 and front == 0:
    isInfinite = true
  elif front == 0:
    cfDigits.setLen(digitCount - 1)
  else:
    cfDigits.add 0
  isNegative = not isNegative
```

This applies `q` to `-1/q`. The front digit sits at the end of the list, so a new front digit is one append. Rotating zero gives infinity, and rotating infinity gives zero. The sign flips on every call.

**Add one.**

```nim
proc addOneToFraction(cfDigits: var seq[int], isNegative: var bool) =
  let digitCount = cfDigits.len
  let front = cfDigits[digitCount - 1]
  if not isNegative:
    cfDigits[digitCount - 1] = front + 1
  elif front >= 2:
    cfDigits[digitCount - 1] = front - 1
  elif front == 1:
    if digitCount == 1:
      isNegative = false
      cfDigits[0] = 0
    else:
      cfDigits[digitCount - 1] = 0
  else:
    let second = cfDigits[digitCount - 2]
    if second >= 2:
      cfDigits[digitCount - 2] = second - 1
      cfDigits[digitCount - 1] = 1
      cfDigits.add 0
    elif digitCount >= 3:
      cfDigits[digitCount - 3] = cfDigits[digitCount - 3] + 1
      cfDigits[digitCount - 2] = 0
      cfDigits.setLen(digitCount - 1)
    else:
      cfDigits[0] = 0
      cfDigits.setLen(1)
    isNegative = false
```

This applies `q` to `q + 1`. The sign selects one of four branches. Each branch edits only the first two continued fraction digits. Guards before the second digit avoid an out-of-range write.

**Greedy undo with batching.**

```nim
proc countUndoSteps(cfDigits: var seq[int], isInfinite: var bool, isNegative: var bool): int =
  if isInfinite:
    return 1
  var answer = 0
  while true:
    if not isInfinite and cfDigits.len == 1 and cfDigits[0] == 0:
      return answer
    if isNegative:
      let digitCount = cfDigits.len
      let front = cfDigits[digitCount - 1]
      if front >= 2:
        answer += front - 1
        cfDigits[digitCount - 1] = 1
      elif front == 0 and digitCount >= 2 and cfDigits[digitCount - 2] >= 2:
        answer += 3 * (cfDigits[digitCount - 2] - 1)
        cfDigits[digitCount - 2] = 1
      else:
        addOneToFraction(cfDigits, isNegative)
        answer += 1
    else:
      rotateFraction(cfDigits, isInfinite, isNegative)
      answer += 1
```

The loop ends when the fraction reaches zero. A large front digit costs many identical steps, so two branches add them in bulk. Infinity needs one rotation. The counter holds the minimal number of extra moves.

**Read one case.**

```nim
proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var i = 0
  while i < dataLength:
    while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
      i += 1
    if i >= dataLength:
      break
    var moveCount = 0
    while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
      moveCount = moveCount * 10 + (ord(inputData[i]) - firstDigitValue)
      i += 1
    var cfDigits: seq[int] = @[0]
    var isInfinite = false
    var isNegative = false
```

The whole input goes into one buffer before parsing. A hand scanner reads `n` digit by digit. Skipping non-digits lets `n = 0` need no special case. The fraction starts at zero.

**Apply the given moves.**

```nim
    for j in 0 ..< moveCount:
      while i < dataLength and inputData[i] != 'S' and inputData[i] != 'R':
        i += 1
      if i >= dataLength:
        break
      let moveLetter = inputData[i]
      i += 1
      if moveLetter == 'R':
        rotateFraction(cfDigits, isInfinite, isNegative)
      elif not isInfinite:
        addOneToFraction(cfDigits, isNegative)
    let answer = countUndoSteps(cfDigits, isInfinite, isNegative)
```

The loop visits exactly `n` move letters. Skipping separators crosses the newline after `n`. Each letter makes one constant-time edit to the fraction. The final call returns the undo count.

**Write answers and start.**

```nim
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()
```

One buffer holds all answers and flushes in blocks. A long run never writes per line. One call starts the program after all declarations.

## Complexity

The phases and their costs for one case follow.

| Phase | Time | Space |
| --- | --- | --- |
| Read and parse | O(n) | one input buffer |
| Apply the given moves | O(n) | O(n) fraction digits |
| Greedy undo | O(n) | O(n) fraction digits |
| Output | O(1) per case | one output block |

The undo loop batches repeated steps, so it also costs O(n).

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(n) per case |
| Space | O(n) per case |

A naive approach tracks the tangle as two arbitrary-precision integers and runs Euclid on them.
Each step then handles thousands of digits instead of constant-time digit edits.
