# AFS2 — Amazing Factor Sequence (medium) (SPOJ)
<https://www.spoj.com/problems/AFS2/>

## Problem

For each queried n, print a[n], where a[0] and a[1] are zero and each later term adds the sum of the proper divisors of n. Answers can exceed a 64-bit integer, so print the exact decimal value.

Input starts with t, followed by t lines each holding one integer n. Print one exact integer per line.

| item | bound |
|---|---|
| test cases t | 1 to 100 |
| query n | 1 to 12148001999 |
| answer size | about 4.8 × 10¹⁹ at the largest n |
| judge limit | 6400 ms, 1536 MB |

Sample input:

```
3
3
4
5
```

Sample output:

```
2
5
6
```

## Idea

Every divisor contributes once to each later multiple, like counting bricks that each appear in several walls. Rewrite a[n] as a sum over divisors x of x times (floor(n/x) − 1). Equal quotients form one block, so a sweep jumps between block edges in about 2√n steps. The accumulator uses base-one-billion limbs because the answer needs twenty digits. The takeaway is to trade a linear divisor scan for a short quotient sweep.

## Why It Works

1. The recurrence sums every proper divisor of every value from two through n.
2. A fixed divisor x appears in that sum once for each multiple from 2x up to n.
3. That gives x times (floor(n/x) − 1) as the total contribution of x.
4. Divisors sharing the same quotient fill a consecutive block with a known arithmetic sum.
5. Base-one-billion limbs hold the exact total, which can pass 2⁶⁴.

| term | meaning |
|---|---|
| `queryValue` | the queried index n |
| `quotientValue` | floor of `queryValue` divided by `leftValue` |
| `addChunkProduct` | adds one block contribution to the limb array |
| `answerLimbs` | decimal-friendly base-one-billion limbs |

A script generated these values by direct divisor summation:

| n | proper divisor sum | a[n] |
|---|---|---|
| 3 | 1 | 2 |
| 4 | 3 | 5 |
| 5 | 1 | 6 |
| 6 | 6 | 12 |

For n equals five, the divisor one contributes four and the divisor two contributes two.

## Code

**Input and limb arithmetic.** The scanner reads every query, and the helper adds a block product into the big accumulator.

```nim
const flushBlockBytes = 1 shl 17
const limbBase: uint64 = 1000000000'u64

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

var answerLimbs: array[6, uint32]
var answerLength = 0

proc addChunkProduct(primaryValue: uint64, multiplierValue: uint64) =
  var remainingValue = primaryValue
  var carryValue: uint64 = 0
  var limbIndex = 0
  while remainingValue > 0'u64 or carryValue > 0'u64:
    if limbIndex >= answerLength:
      answerLength = limbIndex + 1
      answerLimbs[limbIndex] = 0
    let digitValue = remainingValue mod limbBase
    let productValue = uint64(answerLimbs[limbIndex]) + digitValue * multiplierValue + carryValue
    answerLimbs[limbIndex] = uint32(productValue mod limbBase)
    carryValue = productValue div limbBase
    remainingValue = remainingValue div limbBase
    limbIndex += 1
```

Each limb stays below one billion.
Unsigned arithmetic keeps the intermediate products exact.
Carries move to the next limb until they vanish.

**Decimal output.** The printer writes the top limb, then pads every lower limb to nine digits.

```nim
proc appendBigAnswer() =
  if answerLength == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    return
  var topIndex = answerLength - 1
  appendOutput($answerLimbs[topIndex])
  topIndex -= 1
  while topIndex >= 0:
    var limbText = $answerLimbs[topIndex]
    while limbText.len < 9:
      limbText = "0" & limbText
    appendOutput(limbText)
    topIndex -= 1
  outputBuffer.add '\n'
```

Zero uses a single digit.
Padding restores the missing leading zeros.
One newline closes each answer line.

**Quotient sweep.** The driver jumps between block edges and skips the final quotient of one.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let queryValue = int64(nextInt(inputData, scanPos))
  answerLength = 0
  var leftValue: int64 = 1
  while leftValue <= queryValue:
    let quotientValue = queryValue div leftValue
    if quotientValue > 1:
      let rightValue = queryValue div quotientValue
      let countValue = rightValue - leftValue + 1
      let pairSum = leftValue + rightValue
      var firstFactor: int64
      var secondFactor: int64
      if (pairSum and 1'i64) == 0'i64:
        firstFactor = pairSum div 2
        secondFactor = countValue
      else:
        firstFactor = pairSum
        secondFactor = countValue div 2
      addChunkProduct(uint64(firstFactor) * uint64(secondFactor), uint64(quotientValue - 1))
      leftValue = rightValue + 1
    else:
      leftValue = queryValue + 1
  appendBigAnswer()
stdout.write outputBuffer
outputBuffer.setLen 0
```

Halving an even factor keeps the block sum exact.
A quotient of one contributes nothing and ends the sweep.
The buffer flushes once after all answers.

## Complexity

The sweep touches one block per distinct quotient.

| phase | time | space |
|---|---|---|
| input read | one pass over all queries | one input string |
| quotient sweep | about 2√n blocks per query | two 64-bit values |
| limb output | one line per query | six limbs |

The bound counts operations for one query.

| measure | Big O |
|---|---|
| time per query | O(√n) |
| space | O(1) |

Visiting each divisor up to n would take O(n) steps per query.
The takeaway is that grouping equal quotients removes the long scan.
