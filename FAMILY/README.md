# FAMILY — Family (SPOJ)
<https://www.spoj.com/problems/FAMILY/>

## Problem

A monster family shares genes, and the program estimates how much any two monsters have in common.
Every printed percentage is exact.

Read `t` cases.
Each case gives member count `n` and child count `k`, then `k` triples `a b c`.
A triple means monster `a` is a child of monsters `b` and `c`.
Other monsters are founders and are completely unrelated.
Then a query count `m` and `m` pairs of monsters follow.

Each child copies each gene from either parent with equal chance.
For each query, print the degree of relationship as a percentage.
Drop trailing zeroes and keep one digit before the decimal point.

The judge bounds follow.

| Quantity | Bound |
| --- | --- |
| Family members `n` | 2 to 300 |
| Children `k` | 0 to n - 2 |
| Queries `m` | 1 to n² |
| Time limit | 15000 ms |
| Memory limit | 1536 MB |

The small member count permits a full pairwise table.

The sample input and expected output follow verbatim.

```
1
7 4
4 1 2
5 2 3
6 4 5
7 5 6
4
1 2
2 6
7 5
3 3
```

```
0%
50%
81.25%
100%
```

The sample pair 7 and 5 shares 81.25 percent of genes.

## Idea

Store each relationship as a big integer (a number held in binary limbs), like keeping an exact recipe instead of a rounded decimal.
A memoized recurrence (caching each computed pair) expands the later-born monster into its two parents and halves their sum.
Each cache entry also stores the binary shift of the numerator.

Floating point never appears, so every printed digit is exact.
Cost per distinct pair is one recurrence step, one shift, and one decimal conversion.
Simulating every gene locus cannot finish.
Cache exact fractions by pair, then render on demand.

## Why It Works

Three cases define the recurrence.

| Case | Value |
| --- | --- |
| Same monster | R(i,i) = 1 |
| Two different founders | R(i,j) = 0 |
| Later-born i with parents p and q | R(i,j) = (R(p,j) + R(q,j)) / 2 |

Four facts prove the method.

1. A monster shares every gene with itself, and two founders share none.
2. A child takes one parent's gene at each locus, so the later-born monster contributes half from each parent.
3. The common denominator has 310 binary places.
   Each halving adds one place to the stored scale.
4. Multiplying by five to the scale moves the binary fraction into decimal digits.
   The renderer then trims surplus zeroes.

The recurrence needs only the later-born monster.

A script expands the sample family and prints the pairs leading to query 7 and 5.

```
R(4,2) = 1/2 = 50%
R(4,3) = 0 = 0%
R(4,5) = 1/4 = 25%
R(6,5) = 5/8 = 62.5%
R(5,5) = 1 = 100%
R(7,5) = 13/16 = 81.25%
```

The last line matches the sample output.

## Code

**Pragmas and constants.**

```nim
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const fractionScaleBits = 310
const limbBits = 30
const limbMask: uint64 = 1073741823'u64
const bigBase: uint64 = 1000000000'u64
const bigChunkDigits = 9

type BigNumber = seq[uint32]
```

The pragmas remove runtime checks in the hot big-integer code. fractionScaleBits fixes 310 binary places for the denominator. A BigNumber is a list of 32-bit limbs.

**Input and output helpers.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner walks one input buffer by digit. appendOutput flushes a full 256 KiB block. No output is written per digit.

**Add and halve.**

```nim
proc bigAdd(left, right: BigNumber): BigNumber =
  let longest = max(left.len, right.len)
  result = newSeq[uint32](longest + 1)
  var carry: uint32 = 0
  for chunkIdx in 0 ..< longest:
    var chunkSum: uint64 = uint64(carry)
    if chunkIdx < left.len:
      chunkSum += uint64(left[chunkIdx])
    if chunkIdx < right.len:
      chunkSum += uint64(right[chunkIdx])
    result[chunkIdx] = uint32(chunkSum and limbMask)
    carry = uint32(chunkSum shr limbBits)
  result[longest] = carry
  if carry == 0'u32:
    result.setLen(longest)
  return result

proc bigHalve(value: BigNumber): BigNumber =
  if value.len == 0:
    return @[]
  result = newSeq[uint32](value.len)
  var carry: uint32 = 0
  for chunkIdx in countdown(value.len - 1, 0):
    let current = (uint64(carry) shl limbBits) or uint64(value[chunkIdx])
    result[chunkIdx] = uint32(current shr 1'u64)
    carry = uint32(current and 1'u64)
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result
```

bigAdd carries one limb at a time. bigHalve walks from the most significant limb so the carry flows down. Both cost one pass over the limb count.

**Shift right.**

```nim
proc bigShiftRight(value: BigNumber, bits: int): BigNumber =
  if value.len == 0 or bits == 0:
    return value
  let wordShift = bits div limbBits
  let bitShift = bits mod limbBits
  if wordShift >= value.len:
    return @[]
  result = newSeq[uint32](value.len - wordShift)
  for chunkIdx in 0 ..< result.len:
    let highPart = uint64(value[chunkIdx + wordShift])
    var lowPart: uint64 = 0
    if chunkIdx + wordShift + 1 < value.len:
      lowPart = uint64(value[chunkIdx + wordShift + 1])
    let combined = highPart or (lowPart shl limbBits)
    result[chunkIdx] = uint32((combined shr bitShift) and limbMask)
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result
```

bigShiftRight moves whole limbs and a few bits. One output limb reads two neighboring input limbs. This avoids hundreds of single-bit divisions per answer.

**Multiply and convert.**

```nim
proc bigMultiply(left, right: BigNumber): BigNumber =
  if left.len == 0 or right.len == 0:
    return @[]
  result = newSeq[uint32](left.len + right.len + 1)
  for leftIdx in 0 ..< left.len:
    var carry: uint64 = 0
    let leftChunk = uint64(left[leftIdx])
    for rightIdx in 0 ..< right.len:
      let current = uint64(result[leftIdx + rightIdx]) + leftChunk * uint64(right[rightIdx]) + carry
      result[leftIdx + rightIdx] = uint32(current and limbMask)
      carry = current shr limbBits
    var carryPos = leftIdx + right.len
    while carry > 0'u64:
      let current = uint64(result[carryPos]) + carry
      result[carryPos] = uint32(current and limbMask)
      carry = current shr limbBits
      carryPos += 1
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigMultiplySmall(value: BigNumber, factor: uint64): BigNumber =
  if value.len == 0 or factor == 0:
    return @[]
  result = newSeq[uint32](value.len + 2)
  var carry: uint64 = 0
  for chunkIdx in 0 ..< value.len:
    let current = uint64(value[chunkIdx]) * factor + carry
    result[chunkIdx] = uint32(current and limbMask)
    carry = current shr limbBits
  var carryPos = value.len
  while carry > 0'u64:
    result[carryPos] = uint32(carry and limbMask)
    carry = carry shr limbBits
    carryPos += 1
  while result.len > 0 and result[result.len - 1] == 0'u32:
    result.setLen(result.len - 1)
  return result

proc bigToDecimal(value: BigNumber): string =
  if value.len == 0:
    return "0"
  var work = value
  var chunks: seq[uint32] = @[]
  while work.len > 0:
    var remainder: uint64 = 0
    for chunkIdx in countdown(work.len - 1, 0):
      let current = (remainder shl limbBits) or uint64(work[chunkIdx])
      work[chunkIdx] = uint32(current div bigBase)
      remainder = current mod bigBase
    chunks.add uint32(remainder)
    while work.len > 0 and work[work.len - 1] == 0'u32:
      work.setLen(work.len - 1)
  result = $uint64(chunks[chunks.len - 1])
  for chunkIdx in countdown(chunks.len - 2, 0):
    let chunkText = $uint64(chunks[chunkIdx])
    for padIdx in 0 ..< (bigChunkDigits - chunkText.len):
      result.add '0'
    result.add chunkText
  return result
```

bigMultiply accumulates limb products in a 64-bit word. bigMultiplySmall handles the powers of five. bigToDecimal divides by 10^9 repeatedly and pads each chunk. The cost is O(L²) for L limbs.

**Shared tables.**

```nim
var powerOfTwo: BigNumber = newSeq[uint32](fractionScaleBits div limbBits + 1)
powerOfTwo[fractionScaleBits div limbBits] = uint32(1'u64 shl (fractionScaleBits mod limbBits))

var pow5Table = newSeq[BigNumber](fractionScaleBits + 1)
pow5Table[0] = @[1'u32]
for bitIdx in 1 .. fractionScaleBits:
  pow5Table[bitIdx] = bigMultiplySmall(pow5Table[bitIdx - 1], 5'u64)
```

powerOfTwo holds one in the 310-place scale. pow5Table holds powers of five for every possible scale. Both are built once.

**Rank computation.**

```nim
var currentParentOne: seq[int]
var currentParentTwo: seq[int]
var currentRank: seq[int]
var rankDone: seq[bool]
var currentStride = 0
var kinshipMemo: seq[BigNumber]
var kinshipDone: seq[bool]
var kinshipScale: seq[int]
var answerCache: seq[string]

proc computeRank(member: int): int =
  if rankDone[member]:
    return currentRank[member]
  if currentParentOne[member] == 0:
    currentRank[member] = 0
  else:
    let leftRank = computeRank(currentParentOne[member])
    let rightRank = computeRank(currentParentTwo[member])
    currentRank[member] = 1 + max(leftRank, rightRank)
  rankDone[member] = true
  return currentRank[member]
```

computeRank walks parent links with memoization. A founder has rank zero. A child ranks one above the higher parent rank.

**Memoized relationship.**

```nim
proc kinship(first, second: int): BigNumber =
  let memoIndex = first * currentStride + second
  if kinshipDone[memoIndex]:
    return kinshipMemo[memoIndex]
  var value: BigNumber = @[]
  var scaleValue = 0
  if first == second:
    value = powerOfTwo
    scaleValue = 0
  elif currentRank[first] < currentRank[second]:
    value = kinship(second, first)
    scaleValue = kinshipScale[second * currentStride + first]
  else:
    let olderMember = first
    let youngerMember = second
    let firstParent = currentParentOne[olderMember]
    if firstParent == 0:
      value = @[]
      scaleValue = 0
    else:
      let secondParent = currentParentTwo[olderMember]
      let leftValue = kinship(firstParent, youngerMember)
      let leftScale = kinshipScale[firstParent * currentStride + youngerMember]
      let rightValue = kinship(secondParent, youngerMember)
      let rightScale = kinshipScale[secondParent * currentStride + youngerMember]
      value = bigAdd(leftValue, rightValue)
      value = bigHalve(value)
      scaleValue = max(leftScale, rightScale) + 1
  kinshipDone[memoIndex] = true
  kinshipMemo[memoIndex] = value
  kinshipScale[memoIndex] = scaleValue
  return value
```

kinship expands only the later-born monster. A self-pair returns one and two founders return zero. Each unordered pair is computed once. The scale grows by one after every halving.

**Read one case.**

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let memberCount = nextInt(inputData, scanPos)
  let childCount = nextInt(inputData, scanPos)
  currentStride = memberCount + 1
  currentParentOne = newSeq[int](memberCount + 1)
  currentParentTwo = newSeq[int](memberCount + 1)
  for childIdx in 0 ..< childCount:
    let childMember = nextInt(inputData, scanPos)
    currentParentOne[childMember] = nextInt(inputData, scanPos)
    currentParentTwo[childMember] = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var queryFirst = newSeq[int](queryCount)
  var querySecond = newSeq[int](queryCount)
  for queryIdx in 0 ..< queryCount:
    queryFirst[queryIdx] = nextInt(inputData, scanPos)
    querySecond[queryIdx] = nextInt(inputData, scanPos)

  currentRank = newSeq[int](memberCount + 1)
  rankDone = newSeq[bool](memberCount + 1)
  for member in 1 .. memberCount:
    discard computeRank(member)

  let tableSize = currentStride * currentStride
  kinshipMemo = newSeq[BigNumber](tableSize)
  kinshipDone = newSeq[bool](tableSize)
  kinshipScale = newSeq[int](tableSize)
  answerCache = newSeq[string](tableSize)
```

The case loop reads parents and queries into flat arrays. Ranks are computed before any relationship. The memo and answer cache are sized for the member count.

**Render and write answers.**

```nim
  for queryIdx in 0 ..< queryCount:
    let firstMember = queryFirst[queryIdx]
    let secondMember = querySecond[queryIdx]
    let lowMember = min(firstMember, secondMember)
    let highMember = max(firstMember, secondMember)
    let cacheKey = lowMember * currentStride + highMember
    let cachedAnswer = answerCache[cacheKey]
    if cachedAnswer.len > 0:
      appendOutput(cachedAnswer)
      outputBuffer.add '\n'
      continue
    let ratio = kinship(firstMember, secondMember)
    var rendered: string = ""
    if ratio.len == 0:
      rendered = "0%"
    else:
      let scaleBits = kinshipScale[firstMember * currentStride + secondMember]
      var shiftBits = fractionScaleBits - scaleBits
      if shiftBits > fractionScaleBits:
        shiftBits = fractionScaleBits
      let oddNumerator = bigShiftRight(ratio, shiftBits)
      let numerator = bigMultiply(oddNumerator, pow5Table[scaleBits])
      let total = bigMultiplySmall(numerator, 100'u64)
      let decimalText = bigToDecimal(total)
      if scaleBits == 0:
        rendered = decimalText & "%"
      else:
        var padded = ""
        let paddingCount = scaleBits + 1 - decimalText.len
        if paddingCount > 0:
          for padIdx in 0 ..< paddingCount:
            padded.add '0'
        padded.add decimalText
        let cutPos = padded.len - scaleBits
        var wholePart = padded[0 .. cutPos - 1]
        var fractionPart = padded[cutPos .. padded.len - 1]
        while fractionPart.len > 0 and fractionPart[fractionPart.len - 1] == '0':
          fractionPart.setLen(fractionPart.len - 1)
        var leading = 0
        while leading < wholePart.len - 1 and wholePart[leading] == '0':
          leading += 1
        wholePart = wholePart[leading .. wholePart.len - 1]
        if fractionPart.len == 0:
          rendered = wholePart & "%"
        else:
          rendered = wholePart & "." & fractionPart & "%"
    answerCache[cacheKey] = rendered
    appendOutput(rendered)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each query uses the cached text when available. The numerator is shifted, scaled by five, and printed as decimal. Trailing zeroes and leading zeroes are trimmed. The final write emits the remaining bytes.

## Complexity

The phases and their costs for one case follow.

| Phase | Time | Space |
| --- | --- | --- |
| Rank computation | O(n) | O(n) |
| Memoized pairs | O(n² * L) | O(n² * L) |
| Render queries | O(m * L) | cached strings |
| Output | O(m) lines | one output block |

Here L is the limb count of a 310-bit number.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(n² * L + m * L) per case |
| Space | O(n² * L) per case |

Simulating every gene locus needs one pass per gene and cannot finish for large gene counts.
