# PAINTTMP — Paint Templates (SPOJ)
<https://www.spoj.com/problems/PAINTTMP/>

## Problem

Two hole-pattern matrices are overlaid with one shifted by x columns and y rows. Count the holes that coincide, which become yellow stains.

The input starts with the case count. Each case gives matrix size `n` and two shifts `x` and `y`. Print the number of yellow stains.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Cases | separated by blank lines |
| Matrix size `n` | 0 to 100 |
| Shifts `x`, `y` | 0 to 2^n |
| Judge time | 3000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The answer can reach 3^100, so it needs big integers.

Sample input and output:

Input:

```
1
2
2
2
```

Output:

```
3
```

## Idea

Decide the hole pattern one bit at a time. Think of laying two hole-punched matrices over each other and counting holes that land on holes.

The program runs a digit dynamic program (state-by-state counting) over the `n` bits of each coordinate. A state holds a carry and a borrow from binary arithmetic. Four states cover every choice. Counts use big integers held in base-10^9 limbs (fixed-size digit blocks). Listing all 2^n cells would be impossible at `n = 100`.

Takeaway: bitwise structure replaces a huge grid.

## Why It Works

The fractal hole rule depends only on coordinate bits.

1. A cell is a hole when its column index is a submask (bitwise subset) of its row index.
2. Shifting the upper template adds `x` to columns and `y` to rows.
3. Each bit then produces a sum bit and a difference bit.
4. `carryIn` and `borrowIn` carry those effects to the next bit.
5. A state with both prime bits zero cannot form a hole pair and is dropped.

The terms are:

| Term | Meaning |
| --- | --- |
| `Big` | Integer stored in base-10^9 limbs |
| `carryIn` | Carry from the previous bit |
| `borrowIn` | Borrow from the previous bit |
| `dp` | Counts for the four bit states |

Eight limbs hold the largest answer.

A script enumerated holes for small sizes:

| Size | Holes | Shift (0, 0) | Shift (2, 2) |
| --- | --- | --- | --- |
| 0 | 1 | 1 | 0 |
| 1 | 3 | 3 | 0 |
| 2 | 9 | 9 | 3 |
| 3 | 27 | 27 | 12 |

The sample case gives three stains.

## Code

**Big integer type and constants.**

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
```

A limb stores nine decimal digits. Eight limbs cover the maximum count. Four states cover carry and borrow.

**Big addition and number scan.**

```nim
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

`bigAdd` adds one big value into another with a carry. `scanNumber` converts decimal text into limbs.

**Bit extraction.**

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

`numberBits` halves a big value repeatedly and records each remainder. The top bit detects an impossible shift.

**Input and formatting helpers.**

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

The program joins input lines into one buffer. `appendBig` writes limbs from high to low with zero padding.

**Bit dynamic program.**

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

Each case expands the count across `matrixSize` bits. Three choices update each state. The final state zero holds the answer.

## Complexity

Bits and limbs set the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total digits) | O(Input size) |
| Bit conversion | O(n * limbs) | O(n) |
| Digit DP | O(n * 4 * 3 * limbs) | O(4 * limbs) |
| Output | O(limbs) per case | O(1) |

The limb count stays at eight or fewer.

| Measure | Bound |
| --- | --- |
| Time | O(n) per case with a fixed limb count |
| Space | O(n + limbs) |

One hundred bits take a few hundred operations.

Enumerating 2^n template cells would be impossible for large sizes.
