## Problem

Four dancers hold two strings at the corners of a square. Move `S` swaps the two dancers on the right side and crosses the strings once. Move `R` turns every dancer a quarter turn clockwise. Given the moves already danced, print the fewest extra moves that leave both strings straight, horizontal, parallel, and untangled.

Each input holds ten cases. One case gives `n`, then a word of `n` letters `S` and `R`. `n` ranges from 0 to 1,000,000. The judge allows 1000 ms and 1536 MB.

| Quantity | Bound |
| --- | --- |
| Cases per input | 10 |
| Moves per case `n` | 0 to 1,000,000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The answer counts moves, so it is a small integer even when the word is long.

## Idea

Record the tangle as one fraction `q`. Two strings with four fixed ends form a rational tangle, so one fraction describes every tangle the dance can reach. Straight horizontal strings give `q = 0`. Move `S` adds one crossing and sends `q` to `q + 1`. Move `R` turns the picture and sends `q` to `-1/q`.

Read the given word once and apply those two rules. Keep `q` as a continued fraction with a sign, never as a huge integer. Then undo the tangle with one rule: rotate while `q` is positive, add one while `q` is negative. Stop at zero and print the number of moves used.

Each input letter costs constant time, and the undo count is accumulated in bulk.

## Why It Works

The fraction counts signed crossings between the two strings, so a crossing added on the right is exactly `q + 1`. A quarter turn swaps the roles of numerator and denominator and flips orientation, which is exactly `-1/q`. Two turns give `q` back, so `R` is its own inverse.

The continued fraction stores the same number without growing digits without bound. Only the front digit changes on `S`, and `R` adds one front digit or removes one. Both edits touch constant memory.

The undo rule is greedy and optimal. When `q` is positive, adding one makes `q` larger and further from zero, while `R` moves it below zero in one step. When `q` is negative, adding one moves it toward zero, while `R` turns it into a positive number with a longer continued fraction. Each chosen step therefore removes one step from the only shortest route.

This example comes from a script that applies the two rules and then the undo rule to the word `SS`:

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

```
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var outputBuffer = ""
```

The flush threshold bounds the output buffer at 256 KiB. Digit conversion uses one named constant instead of a literal repeated in the scanner.

```
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

This applies `q` to `-1/q`. The front digit sits at the end of the sequence, so adding a front digit is one append. Rotating zero gives infinity, and rotating infinity gives zero.

```
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

This applies `q` to `q + 1`. The sign of `q` picks one of four branches, and each branch edits only the first two continued fraction digits. The guard before reading the second digit avoids an out-of-range write when `q` has one digit.

```
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

This counts the undo moves. A large front digit costs many identical steps, so the two batching branches add them at once instead of looping once per unit. Infinity needs one rotation, and zero ends the loop.

```
proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var i = 0
```

The whole input goes into one buffer before any parsing. One read loop replaces per-number reads and keeps the scanner independent of line endings.

```
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

A hand scanner reads `n` by walking digit by digit. Non-digit bytes are skipped, so an empty word for `n = 0` needs no special case.

```
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
```

The loop visits exactly `n` move letters. Skipping separators lets the scanner cross the newline after `n`. Each letter makes one constant-time edit to the continued fraction.

```
    let answer = countUndoSteps(cfDigits, isInfinite, isNegative)
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One call returns the answer for the case. One output buffer holds all answers and flushes in blocks, so a long run never writes per line.

```
main()
```

One call starts the program after all declarations.

## Complexity

Reading and scanning the input costs `O(n)` per case. Applying the `n` given moves costs `O(n)`. The undo loop visits continued fraction digits and adds whole blocks of equal steps at once, so it also costs `O(n)`. Total time is `O(n)` per case.

The continued fraction sequence grows by at most one digit per undo step, so it holds `O(n)` integers. Input and output buffers also hold `O(n)` bytes. Total space is `O(n)` per case.

A naive approach tracks the tangle as two arbitrary-precision integers and runs the Euclidean algorithm on them. Each step then operates on numbers with thousands of digits, which costs far more than the constant-time digit edits used here.
