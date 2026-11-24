## Problem

The program reads t, then t positive integers. Each integer is a perfect square with at most 800 decimal digits. Print the integer square root of each number on its own line.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 50 |
| Input digits per number | at most 800 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

800 digits exceed every machine integer, so the program stores numbers as decimal digit arrays.

## Idea

The program uses the schoolbook digit-by-digit method, which fixes one root digit per step. It reads the number in two-digit groups and keeps a remainder. A new digit y fits when (20R + y)y stays within that remainder. Each step tries at most ten digits with small products, so it never needs big-integer division.

Cost per two-digit group: O(P) digit work for a P-digit root, with at most ten trials.

## Why It Works

Let R be the root found so far. The groups already processed equal 100R² + remainder. Appending digit y gives root 10R + y, whose square is 100R² + 20Ry + y². The digit fits when (20R + y)y ≤ remainder. After subtracting that product, the invariant holds for the next group.

- `remOffset -= 2` shifts the remainder two decimal places; the old digits stay in place.
- `pairPos += 2` advances to the next two input digits.
- `rootOffset -= 1` makes room for the new most significant digit.

The table below comes from the generator script for the sample number 226576.

| pair | before | base | digit | product | after | root |
| --- | --- | --- | --- | --- | --- | --- |
| 22 | 22 | 0 | 4 | 16 | 6 | 4 |
| 65 | 665 | 80 | 7 | 609 | 56 | 47 |
| 76 | 5676 | 940 | 6 | 5676 | 0 | 476 |

The last row leaves a zero remainder, so 476 is the exact root.

## Code

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
  for k in start..<finish:
    value = value * digitBase + int(data[k]) - firstDigitValue
  return value
```

One readLine loop gathers all input into a single string. nextToken skips separators, so spaces and blank lines both work. parseCount handles at most two digits. The scan costs one pass over the input.

```nim
var remainderBuf: array[0..limbLimit - 1, int]
var rootBuf: array[0..rootStart, int]
var trialBuf: array[0..limbLimit - 1, int]
var productBuf: array[0..limbLimit - 1, int]
var chosenBuf: array[0..limbLimit - 1, int]

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
    for k in 0..<rootLen:
      let value = rootBuf[rootOffset + k] * trialFactor + carry
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
      for k in 0..<baseLen:
        let value = trialBuf[k] * digit + carry
        productBuf[prodLen] = value mod digitBase
        prodLen += 1
        carry = value div digitBase
      while carry > 0:
        productBuf[prodLen] = carry mod digitBase
        prodLen += 1
        carry = carry div digitBase
      var extra = digit * digit
      var k = 0
      while extra > 0:
        if k == prodLen:
          productBuf[prodLen] = 0
          prodLen += 1
        let value = productBuf[k] + extra
        productBuf[k] = value mod digitBase
        extra = value div digitBase
        k += 1
      while prodLen > 0 and productBuf[prodLen - 1] == 0:
        prodLen -= 1
      var order = 0
      if prodLen < remLen:
        order = -1
      elif prodLen > remLen:
        order = 1
      else:
        var m = prodLen - 1
        while m >= 0 and productBuf[m] == remainderBuf[remOffset + m]:
          m -= 1
        if m >= 0:
          order = (if productBuf[m] < remainderBuf[remOffset + m]: -1 else: 1)
      if order <= 0:
        chosenDigit = digit
        chosenLen = prodLen
        for k in 0..<prodLen:
          chosenBuf[k] = productBuf[k]
        break

    var borrow = 0
    for k in 0..<remLen:
      var value = remainderBuf[remOffset + k] - borrow
      if k < chosenLen:
        value -= chosenBuf[k]
      if value < 0:
        value += digitBase
        borrow = 1
      else:
        borrow = 0
      remainderBuf[remOffset + k] = value
    while remLen > 0 and remainderBuf[remOffset + remLen - 1] == 0:
      remLen -= 1

    rootOffset -= 1
    rootBuf[rootOffset] = chosenDigit
    rootLen += 1
    pairPos += 2

  result = newString(rootLen)
  for k in 0..<rootLen:
    result[rootLen - 1 - k] = char(rootBuf[rootOffset + k] + firstDigitValue)
```

Five global arrays hold the working digits, so no allocation happens inside the loop. The while pairPos < finish loop runs ceil(D/2) times for D input digits. The countdown tries digits from 9 down to 0, and the first fit wins. Comparison and subtraction work on digit arrays, not machine integers.

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
for j in 0..<caseCount:
  nextToken(inputData, scanPos, tokenStart, tokenFinish)
  appendOutput(squareRoot(inputData, tokenStart, tokenFinish))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

appendOutput flushes at 256 KiB, and the final write clears the tail. Each result gets one newline. The output stays in one buffer, so the program writes at most two blocks.

## Complexity

Let D be the input digit count and P = D/2 pairs. One pair costs O(P) digit work for the base and up to ten trials. The total per number is O(P²), or O(D²). Five arrays of 1001 digits use about 40 KB. For 50 numbers of 800 digits the program performs roughly 16 million digit operations. A binary search over 400-digit candidates would need big-integer division at every probe.
