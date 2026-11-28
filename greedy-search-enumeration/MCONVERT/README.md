# MCONVERT — Convert to Decimal Base System (SPOJ)

<https://www.spoj.com/problems/MCONVERT/>

## Problem

A made-up number system lists its digit characters in increasing value, starting at zero. Each encoded number can be read in several bases, and we print the sum of all its legal decimal interpretations. Data sets are separated by blank lines, and their outputs are separated by one blank line.

A data set starts with one line defining the digit order. Every later non-empty line in that set is one number, with outer whitespace ignored. Possible bases are 2 through the number of defined digits. A base is legal for a number when every digit value in that number is smaller than the base. Print one decimal total per number line.

| item | bound |
|---|---|
| digit characters | printable ASCII above space |
| possible bases | 2 up to the number of defined digits |
| answer length | at most 1000 decimal digits |
| judge limit | 1000 ms, 1536 MB |

The 1000-digit answer forces a hand-written big integer.

Sample input:

```
0123456789
  90763  
1

.1>C
CC.
>.1
1....
```

Sample output:

```
90763
9

60
52
353
```

## Idea

Treat the digit order as a row of labeled stepping stones and each base as a stride length; walk the number once per legal stride and add the distances. For one base, Horner evaluation reads the digits left to right with one multiply and one add per digit. We keep the running values in base one billion limbs so carries stay inside 64-bit integers. Recomputing powers of the base for every digit would cost quadratic work per number.

One left-to-right walk per base gives each interpretation.

## Why It Works

1. The first line maps each character to its index in the ordering.
2. A base b is legal when b is at least two and above every digit value present.
3. The smallest legal base is the largest digit value plus one, clamped to two.
4. Horner evaluation starts from zero, then multiplies by b and adds each digit.
5. A limb holds at most 999999999, so a product with a base below 100 stays below 10^11.
6. Summing the limb arrays across all legal bases yields the required total.
7. Printing the most significant limb unpadded and the rest with nine digits gives decimal text.

| term | meaning |
|---|---|
| `digitMap` | character code to digit value lookup |
| `numberDigits` | digit values of one encoded number |
| `totalAnswer` | running big-integer sum across legal bases |
| `limbBase` | ten to the ninth power, the radix of each stored limb |
| `multiplyAdd` | one Horner step on a big integer |

Limb arithmetic keeps each carry small and local.

The second sample data set traces as follows:

```
ordering .1>C gives .=0 1=1 >=2 C=3
CC. digits 3 3 0, legal base 4 only: 3*16 + 3*4 + 0 = 60
>.1 digits 2 0 1, legal bases 3 and 4: 19 + 33 = 52
1.... digits 1 0 0 0 0, legal bases 2 3 4: 16 + 81 + 256 = 353
```

The trace reproduces all three outputs of that data set.

Blank lines mark data set boundaries, and leading or trailing spaces are trimmed before decoding. Every output digit comes from integer arithmetic, so no rounding occurs.

## Code

**Input and output buffer.** A single read loads stdin, and the buffer flushes after large blocks.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbDigits = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The limb constants fix the internal big-integer radix.
The reader preserves empty lines, which delimit data sets.
The buffer avoids a write for every answer line.

**Big integer helpers.** Limb arrays support scaling, addition, and decimal printing.

```nim
proc multiplyAdd(target: var seq[int64], multiplier: int, addend: int) =
  var carry: int64 = int64(addend)
  var limbIndex = 0
  while limbIndex < target.len:
    let product = int64(target[limbIndex]) * int64(multiplier) + carry
    target[limbIndex] = product mod limbBase
    carry = product div limbBase
    limbIndex += 1
  while carry > 0:
    target.add(carry mod limbBase)
    carry = carry div limbBase

proc addBig(target: var seq[int64], source: seq[int64]) =
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < source.len:
    if limbIndex >= target.len:
      target.add 0
    let limbTotal = int64(target[limbIndex]) + source[limbIndex] + carry
    target[limbIndex] = limbTotal mod limbBase
    carry = limbTotal div limbBase
    limbIndex += 1
  while carry > 0:
    if limbIndex >= target.len:
      target.add 0
    let limbTotal = int64(target[limbIndex]) + carry
    target[limbIndex] = limbTotal mod limbBase
    carry = limbTotal div limbBase
    limbIndex += 1

proc bigToString(digits: seq[int64]): string =
  var text = ""
  var limbIndex = digits.len
  while limbIndex > 0:
    limbIndex -= 1
    let limbValue = digits[limbIndex]
    if limbIndex == digits.len - 1:
      text.add $limbValue
    else:
      var padded = $limbValue
      while padded.len < limbDigits:
        padded = "0" & padded
      text.add padded
  return text
```

Each step multiplies one limb and propagates one carry.
Addition grows the target only when a carry needs a new limb.
Printing pads every limb except the highest one.

**Line parsing and summation.** Blank lines switch data sets, and each number visits its legal bases.

```nim
var digitMap = newSeq[int](256)
for codeValue in 0 .. 255:
  digitMap[codeValue] = -1

var lineStart = 0
var datasetCount = 0
var digitCount = 0
var inDataset = false
while lineStart < inputData.len:
  var lineEnd = lineStart
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var trimStart = lineStart
  var trimEnd = lineEnd
  while trimStart < trimEnd and inputData[trimStart] <= ' ':
    trimStart += 1
  while trimEnd > trimStart and inputData[trimEnd - 1] <= ' ':
    trimEnd -= 1
  if trimStart < trimEnd:
    if not inDataset:
      for codeValue in 0 .. 255:
        digitMap[codeValue] = -1
      digitCount = 0
      var charIndex = trimStart
      while charIndex < trimEnd:
        digitMap[int(inputData[charIndex])] = digitCount
        digitCount += 1
        charIndex += 1
      inDataset = true
      if datasetCount > 0:
        outputBuffer.add '\n'
      datasetCount += 1
    else:
      var numberDigits = newSeq[int]()
      var maxDigit = 0
      var charIndex = trimStart
      while charIndex < trimEnd:
        let digitValue = digitMap[int(inputData[charIndex])]
        numberDigits.add digitValue
        if digitValue > maxDigit:
          maxDigit = digitValue
        charIndex += 1
      var totalAnswer: seq[int64] = @[0'i64]
      var base = maxDigit + 1
      if base < 2:
        base = 2
      while base <= digitCount:
        var numberValue: seq[int64] = @[0'i64]
        for digitValue in numberDigits:
          multiplyAdd(numberValue, base, digitValue)
        addBig(totalAnswer, numberValue)
        base += 1
      appendOutput(bigToString(totalAnswer))
      outputBuffer.add '\n'
  else:
    inDataset = false
  lineStart = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first non-empty line of a set defines the digit order.
The largest digit sets the lowest legal base for each number.
A blank line goes between output sets but not after the last one.

## Complexity

Each number walks its digits once for every legal base.

| phase | time | space |
|---|---|---|
| input read | one pass over lines | one input string |
| digit mapping | one pass per ordering line | 256-entry lookup |
| base summation | one Horner walk per legal base | two limb arrays |
| output | one append per number | block buffer |

The number of legal bases is at most the ordering length minus one.

| measure | Big O |
|---|---|
| time | O(b L d) per number, with b bases, L digits, and d limbs |
| space | O(d) for the limb arrays |

Recomputing each power of the base separately would cost O(b L^2) per number.
