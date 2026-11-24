## Problem

Read a test count. Each case gives a matrix size n, a right shift x, and an up shift y.

A matrix of size n has 2^n rows and 2^n columns with a fractal pattern of holes. Two copies overlap after the shift. Print the number of cells where both copies have a hole.

The bounds are:

| Quantity | Bound |
| --- | --- |
| Matrix size n | 0 to 100 |
| Right shift x | 0 to 2^n |
| Up shift y | 0 to 2^n |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The grid is far too large to build, so the answer must come from the bits of x and y.

## Idea

A cell (r,c) is a hole when the bitwise OR of r and c sets all n bits. A digit DP, a scan over bits with a small state, applies that rule to both copies at once. It passes the carry of r+y and the borrow of c-x from the low bit to the high bit.

The count reaches 3^n, since each of the n bits has three choices, so the program adds big integers held in eight limbs.

Cost per bit: four states, three hole pairs, and one big-integer addition for each live state.

## Why It Works

Each matrix of size n splits into four squares. The top-left square has no holes. The other three squares are copies of size n-1.

A hole (r,c) in the lower copy meets a hole (r+y, c-x) in the upper copy. Both bit rules then hold: r OR c sets all n bits, and (r+y) OR (c-x) sets all n bits.

The update at bit i is:

- Lower hole: r_i OR c_i = 1 for every bit i.
- Added row: r'_i = (r_i + y_i + carryIn) mod 2, with carryOut = (r_i + y_i + carryIn) div 2.
- Subtracted column: c'_i = c_i - x_i - borrowIn, plus 2 and borrowOut = 1 when the result is negative.
- Upper hole: r'_i OR c'_i = 1 for every bit i.
- Valid end: carryOut = 0 and borrowOut = 0 after the last bit.

A shift of 2^n pushes a copy off the grid, so it gives zero.

gen.py enumerates the nine holes of size 2 and lists the agreements:

| Lower cell | Upper cell |
| --- | --- |
| (0,3) | (2,1) |
| (1,2) | (3,0) |
| (1,3) | (3,1) |

Three cells agree, which matches the sample output.

## Code

The big integer stores base-10^9 limbs and adds them with a carry:

```nim
const firstDigitValue = 48
const decimalBase = 1000000000
const topDigitPlace = 100000000
const limbCapacity = 8
const stateCount = 4
const flushBlockBytes = 1 shl 18

type Big = object
  limb: array[0..limbCapacity-1, int]
  used: int

proc bigAdd(dst: var Big, src: Big) =
  if src.used == 0: return
  var carry = 0
  var k = 0
  while k < src.used or carry != 0:
    var value = carry
    if k < dst.used: value += dst.limb[k]
    if k < src.used: value += src.limb[k]
    if value >= decimalBase:
      value -= decimalBase
      carry = 1
    else:
      carry = 0
    dst.limb[k] = value
    k += 1
  if k > dst.used: dst.used = k
```

The loop ends when the source limbs and the carry are both done. The used field keeps stale limbs out of each sum. One addition touches at most eight limbs.

The scanner reads decimal tokens, and the divider turns them into bits:

```nim
proc scanNumber(data: string, position: var int): seq[int] =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  result = @[0]
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    var carry = int(data[position]) - firstDigitValue
    for k in 0..<result.len:
      var value = result[k] * 10 + carry
      result[k] = value mod decimalBase
      carry = value div decimalBase
    if carry > 0: result.add carry
    position += 1

proc limbsToInt(limbs: seq[int]): int =
  if limbs.len > 0: limbs[0] else: 0

proc numberBits(limbs: seq[int], bitTotal: int): seq[int] =
  var work = limbs
  result.setLen(bitTotal)
  for i in 0..<bitTotal:
    var remainder = 0
    var k = work.len - 1
    while k >= 0:
      var value = remainder * decimalBase + work[k]
      work[k] = value div 2
      remainder = value mod 2
      k -= 1
    result[i] = remainder
```

scanNumber parses a token into base-10^9 limbs. Shifts reach 2^100, so a plain integer would overflow. numberBits halves the limbs once per bit, which costs O(n) work per shift.

The program reads all of stdin before the loops and reuses both state arrays:

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = limbsToInt(scanNumber(inputData, scanPos))

var dp: array[0..stateCount-1, Big]
var nextDp: array[0..stateCount-1, Big]
var outputBuffer = ""
var answerLine = ""
```

The read loop runs once per line and fills a single buffer. The scanner then walks that buffer once. Both state arrays survive every case.

The printer writes limbs as decimal digits and flushes in blocks:

```nim
proc appendBig(dst: var string, value: Big) =
  if value.used == 0:
    dst.add '0'
    return
  var k = value.used - 1
  dst.add $value.limb[k]
  k -= 1
  while k >= 0:
    var limbValue = value.limb[k]
    var place = topDigitPlace
    while place > 0:
      dst.add char(limbValue div place + firstDigitValue)
      limbValue = limbValue mod place
      place = place div 10
    k -= 1

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

appendBig prints the top limb without padding and each lower limb with nine digits. Its loop bound is the used limb count. appendOutput flushes once per 256 KiB block.

The main loop scans the bits and counts the agreements:

```nim
for caseIndex in 0..<caseCount:
  let sizeLimbs = scanNumber(inputData, scanPos)
  let matrixSize = limbsToInt(sizeLimbs)
  let shiftDownBits = numberBits(scanNumber(inputData, scanPos), matrixSize + 1)
  let shiftRightBits = numberBits(scanNumber(inputData, scanPos), matrixSize + 1)
  var answer: Big
  if shiftRightBits[matrixSize] == 1 or shiftDownBits[matrixSize] == 1:
    answer.used = 0
  else:
    for j in 0..<stateCount:
      dp[j].used = 0
    dp[0].limb[0] = 1
    dp[0].used = 1
    for i in 0..<matrixSize:
      for j in 0..<stateCount: nextDp[j].used = 0
      let downBit = shiftDownBits[i]
      let rightBit = shiftRightBits[i]
      for j in 0..<stateCount:
        if dp[j].used == 0: continue
        let carryIn = j div 2
        let borrowIn = j mod 2
        for l in 0..2:
          let rowBit = if l == 0: 0 else: 1
          let colBit = if l == 1: 0 else: 1
          let sumValue = rowBit + downBit + carryIn
          let primeRowBit = sumValue mod 2
          let carryOut = sumValue div 2
          let diffValue = colBit - rightBit - borrowIn
          var primeColBit: int
          var borrowOut: int
          if diffValue >= 0:
            primeColBit = diffValue
            borrowOut = 0
          else:
            primeColBit = diffValue + 2
            borrowOut = 1
          if primeRowBit == 0 and primeColBit == 0: continue
          bigAdd(nextDp[carryOut * 2 + borrowOut], dp[j])
      dp = nextDp
    answer = dp[0]
  answerLine.setLen 0
  appendBig(answerLine, answer)
  answerLine.add '\n'
  appendOutput(answerLine)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The case loop runs once per case and the bit loop runs n times. The state loop visits four carry and borrow pairs, and the inner loop visits three hole pairs.

Skipping zero states avoids needless additions. The final write flushes the remaining bytes.

## Complexity

Input parsing reads each token once and converts each shift to bits in O(n) time. Each case runs 4n transitions and at most 12 big-integer additions.

A big integer holds eight limbs, so one case costs O(n) time and O(1) space. Total time is O(t*n) for t cases, and total space is O(1) besides the input and output buffers.

The naive form builds 3^n holes and tests each one, which costs O(3^n) time and cannot run at n=100.
