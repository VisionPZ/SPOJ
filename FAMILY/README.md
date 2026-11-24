## Problem

Read a family graph and a list of monster pairs. Print the exact percentage of genes each pair shares. Founders carry unrelated genes, and a child copies one gene from either parent with equal chance. Drop trailing zeroes and keep one digit before the decimal point.

The statement fixes these bounds:

| Quantity | Bound |
| --- | --- |
| Family members n | 2 to 300 |
| Children k | 0 to n - 2 |
| Queries m | 1 to n squared |
| Time limit | 15000 ms |
| Memory limit | 1536 MB |

The small member count allows a full pairwise table, while the dense query list rewards cached exact answers.

## Idea

Store each relationship as a big integer in binary limbs over a fixed power of two. A memoized recurrence expands the later-born monster into its two parents and halves their sum. Each memo entry also stores how many binary places the numerator must be shifted. Floating point never appears, so every printed digit is exact.

Cost per distinct pair: one recurrence step, one bit shift, and one decimal conversion.

## Why It Works

A monster shares every gene with itself, giving R(i,i) = 1. Two different founders share no genes, giving R(i,j) = 0.

A child takes one parent's gene at each locus. That choice does not depend on the other monster. The later-born monster therefore contributes half from each parent.

Each row of this table gives one recurrence case:

| Case | Value |
| --- | --- |
| Same monster | R(i,i) = 1 |
| Two different founders | R(i,j) = 0 |
| Later-born monster i, parents p and q | R(i,j) = (R(p,j) + R(q,j)) / 2 |

The common denominator has 310 binary places. Each halving adds one place to the stored scale. The program shifts the numerator by 310 minus that scale, then multiplies by five to the scale. This moves the binary fraction into decimal digits without repeated division.

The generator prints this expansion for the sample pair (7, 5):

```
R(4,2) = 1/2 = 50%
R(4,3) = 0 = 0%
R(4,5) = 1/4 = 25%
R(6,5) = 5/8 = 62.5%
R(5,5) = 1 = 100%
R(7,5) = 13/16 = 81.25%
```

The last line matches the sample, so the recurrence reproduces the expected answer.

## Code

Binary limbs let a right shift move whole limbs and a few bits. This avoids hundreds of single-bit divisions per answer.

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

The loop moves one limb and part of the next into each output limb. The mask keeps every limb at 30 bits.

The recurrence stores the numerator and its scale together. The larger parent scale rises by one after the halving.

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

The rank check expands only the later-born monster. A self-pair returns one, and two founders return zero. A cache entry per unordered pair avoids repeated work.

The query loop renders the stored fraction once per unordered pair. Later queries reuse the cached text.

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
```

Multiplication by five to the scale places the decimal point. The last lines trim surplus zeroes and append the percent sign.

## Complexity

Rank computation visits each monster once and costs O(n). The memo table holds at most n squared pairs, and each pair needs two big-integer additions. Rendering one pair multiplies two big integers and writes at most 310 digits.

With L binary limbs, total time is O(n squared times L plus m times L) per case. Total space is O(n squared times L) plus the cached answer strings. Simulating every gene locus would need one pass per gene and cannot finish for large gene counts.
