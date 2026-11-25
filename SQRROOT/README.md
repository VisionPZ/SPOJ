# SQRROOT — Square Root (SPOJ)

<https://www.spoj.com/problems/SQRROOT/>

## Problem

A librarian reads labels with up to 800 digits and must find the shelf number whose square each label shows. Ordinary machine integers hold about 19 digits, so the librarian works on paper.

Input: `t` test cases, then `t` positive integers. Each integer is a perfect square with at most 800 digits. Output: exactly `t` lines, each holding the integer square root of one input number.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Test cases `t` | at most 50 |
| Digits per number | at most 800 |
| Value | guaranteed perfect square |
| Judge limit | 1000 ms, 1536 MB |

Eight hundred digits rule out every built-in integer type.

The sample input and output:

```
3
36
81
226576
```

```
6
9
476
```

## Idea

Fix one root digit at a time, the way long division fixes one quotient digit. Think of reading a long number two digits at a time and asking which digit fits.

The program uses the schoolbook digit-by-digit method on decimal limbs. Each two-digit group tries at most ten digits and compares small products. A number with `D` digits needs `D / 2` groups and `O(D)` work per group, so `O(D²)` overall.

Repeated big-integer division would multiply and divide full 800-digit values at every step. That costs far more than comparing a few short products.

Fixed digits never get revised, so one left-to-right pass finds the whole root.

## Why It Works

Four facts prove the digit rule.

1. Group the input digits in pairs from the left. An odd digit count gets a virtual leading zero, which changes no value.
2. After some groups, the processed prefix equals `100R² + remainder`, where `R` is the root found so far.
3. Appending digit `y` gives the root `10R + y`. Its square is `100R² + (20R + y)y`, so `y` fits when `(20R + y)y` stays at most the remainder.
4. Subtracting that product restores the invariant for the next group. The input is a perfect square, so the final remainder is zero.

The buffers used for the arithmetic:

| Term | Meaning |
| --- | --- |
| `pairValue` | next two input digits as a number |
| `remainderBuf` | current remainder, stored low digit first |
| `trialBuf` | the value `20R` as decimal limbs |
| `productBuf` | candidate value `(20R + y)y` |
| `chosenDigit` | largest fitting digit `y` |

Limb arrays let the program compare products without any big-integer library.

A generator trace for `226576`:

```
| pair | before | base | digit | product | after | root |
| --- | --- | --- | --- | --- | --- | --- |
| 22 | 22 | 0 | 4 | 16 | 6 | 4 |
| 65 | 665 | 80 | 7 | 609 | 56 | 47 |
| 76 | 5676 | 940 | 6 | 5676 | 0 | 476 |
```

The last row leaves a zero remainder, so 476 is the exact root.

The odd-length case uses `pairPos -= 1`, which supplies the virtual leading zero. Trailing zero limbs are dropped after each subtraction, so the remainder keeps its true length.

## Code

**Constants, input, and scanner.** The case count is parsed digit by digit from one buffer.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitBase = 10
const trialFactor = 20
const maxTrialDigit = 9
const rootStart = 500
const remainderStart = 1000
const limbLimit = 1001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int, start: var int, finish: var int) =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  start = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  finish = pos

proc parseCount(data: string, start: int, finish: int): int =
  var value = 0
  for idx in start..<finish:
    value = value * digitBase + int(data[idx]) - firstDigitValue
  return value
```

`limbLimit = 1001` covers 800 input digits and their 400 root digits.
`nextToken` returns the start and finish of a number without copying it.
`parseCount` handles the small case count.

**Working buffers.** Five fixed arrays hold every intermediate value.

```nim
var remainderBuf: array[0..limbLimit - 1, int]
var rootBuf: array[0..rootStart, int]
var trialBuf: array[0..limbLimit - 1, int]
var productBuf: array[0..limbLimit - 1, int]
var chosenBuf: array[0..limbLimit - 1, int]
```

Each array has static size, so no case allocates new memory.
Limb zero holds the least significant digit.
Offsets leave room to prepend digits by decrementing.

**Digit-by-digit root.** One pass over two-digit groups builds the answer.

```nim
proc squareRoot(data: string, start: int, finish: int): string =
  var remOffset = remainderStart
  var remLen = 0
  var rootOffset = rootStart
  var rootLen = 0
  var pairPos = start
  if (finish - start) mod 2 == 1:
    pairPos -= 1
  while pairPos < finish:
    var pairValue = 0
    if pairPos >= start:
      pairValue = int(data[pairPos]) - firstDigitValue
    if pairPos + 1 < finish:
      pairValue = pairValue * digitBase + int(data[pairPos + 1]) - firstDigitValue
    remOffset -= 2
    remainderBuf[remOffset] = pairValue mod digitBase
    remainderBuf[remOffset + 1] = pairValue div digitBase
    remLen += 2
    while remLen > 0 and remainderBuf[remOffset + remLen - 1] == 0:
      remLen -= 1

    var baseLen = 0
    var carry = 0
    for limbIdx in 0..<rootLen:
      let value = rootBuf[rootOffset + limbIdx] * trialFactor + carry
      trialBuf[baseLen] = value mod digitBase
      baseLen += 1
      carry = value div digitBase
    while carry > 0:
      trialBuf[baseLen] = carry mod digitBase
      baseLen += 1
      carry = carry div digitBase

    var chosenDigit = 0
    var chosenLen = 0
    for digit in countdown(maxTrialDigit, 0):
      var prodLen = 0
      carry = 0
      for limbIdx in 0..<baseLen:
        let value = trialBuf[limbIdx] * digit + carry
        productBuf[prodLen] = value mod digitBase
        prodLen += 1
        carry = value div digitBase
      while carry > 0:
        productBuf[prodLen] = carry mod digitBase
        prodLen += 1
        carry = carry div digitBase
      var extra = digit * digit
      var addIdx = 0
      while extra > 0:
        if addIdx == prodLen:
          productBuf[prodLen] = 0
          prodLen += 1
        let value = productBuf[addIdx] + extra
        productBuf[addIdx] = value mod digitBase
        extra = value div digitBase
        addIdx += 1
      while prodLen > 0 and productBuf[prodLen - 1] == 0:
        prodLen -= 1
      var order = 0
      if prodLen < remLen:
        order = -1
      elif prodLen > remLen:
        order = 1
      else:
        var cmpIdx = prodLen - 1
        while cmpIdx >= 0 and productBuf[cmpIdx] == remainderBuf[remOffset + cmpIdx]:
          cmpIdx -= 1
        if cmpIdx >= 0:
          order = (if productBuf[cmpIdx] < remainderBuf[remOffset + cmpIdx]: -1 else: 1)
      if order <= 0:
        chosenDigit = digit
        chosenLen = prodLen
        for limbIdx in 0..<prodLen:
          chosenBuf[limbIdx] = productBuf[limbIdx]
        break

    var borrow = 0
    for limbIdx in 0..<remLen:
      var value = remainderBuf[remOffset + limbIdx] - borrow
      if limbIdx < chosenLen:
        value -= chosenBuf[limbIdx]
      if value < 0:
        value += digitBase
        borrow = 1
      else:
        borrow = 0
      remainderBuf[remOffset + limbIdx] = value
    while remLen > 0 and remainderBuf[remOffset + remLen - 1] == 0:
      remLen -= 1

    rootOffset -= 1
    rootBuf[rootOffset] = chosenDigit
    rootLen += 1
    pairPos += 2

  result = newString(rootLen)
  for limbIdx in 0..<rootLen:
    result[rootLen - 1 - limbIdx] = char(rootBuf[rootOffset + limbIdx] + firstDigitValue)
```

The outer loop advances `pairPos` by two until it reaches `finish`.
The candidate loop runs `digit` from 9 down to 0 and stops at the first fit.
The borrow loop subtracts the chosen product limb by limb, and the root digit is stored at the new front offset.

**Buffered output.** Each root becomes one line in a shared buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var tokenStart = 0
var tokenFinish = 0
nextToken(inputData, scanPos, tokenStart, tokenFinish)
let caseCount = parseCount(inputData, tokenStart, tokenFinish)
for caseIdx in 0..<caseCount:
  nextToken(inputData, scanPos, tokenStart, tokenFinish)
  appendOutput(squareRoot(inputData, tokenStart, tokenFinish))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes at 256 KiB, which bounds memory for 50 long answers.
The final write covers the tail.
`parseCount` reads the header before the case loop begins.

## Complexity

Each two-digit group compares at most ten candidates over short limb arrays.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| One two-digit group | O(10 × D) limb steps | O(D) limb arrays |
| One number | O(D²) for `D / 2` groups | O(D) |
| Output | one write per 256 KiB block | 256 KiB |
| Total, 50 cases | O(50 × D²) | O(D) plus buffers |

At `D = 800` the program handles 400 groups per case.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(D²) per number, O(t × D²) overall |
| Space | O(D) for limbs, plus input and output buffers |

Full-width big-integer division at every digit would cost more than these short limb comparisons.
