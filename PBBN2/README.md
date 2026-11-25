# PBBN2 — Print Big Binary Numbers (SPOJ)

<https://www.spoj.com/problems/PBBN2/>

## Problem

Compute `(A^B) XOR (C^D)` and print the sum of its digits when the number is read in base `2^16384`. Each digit is a block of 16384 bits, so the sum is itself a large decimal number.

Input starts with the test count `T`. Each following line holds four base-10 integers `A B C D`. Print one decimal line per test case.

| item | bound |
|---|---|
| test cases `T` | up to 321 |
| bases and exponents | 2 to 10000 |
| digit sum size | about 4933 decimal digits |
| judge limit | 1500 ms, 1536 MB |

For base `B = 2^8`, the number 12345678 splits into digits 78, 97, and 188, whose sum is 363. This problem uses a much larger base.

```
2
7 3 5 4
1234 5678 9012 4444
```

```
806
1194204158794232147799<...snip...>9938532444216215551948305
```

The statement elides the middle of the second answer; the full answer has 4933 digits.

## Idea

Think of a huge number as a row of equal boxes: XOR changes bits inside boxes, and the answer adds the box values. Store each power in 32-bit limbs, XOR limb by limb, then add 512-limb groups into one accumulator. A direct decimal big-integer library would repeat allocations per test; fixed limbs keep the work predictable.

## Why It Works

1. A limb holds 32 bits, so 16384 bits occupy exactly 512 limbs.
2. Repeated multiplication by a base below 10000 keeps each product inside 64 bits.
3. XOR acts independently on each limb because both operands use the same radix.
4. Adding every 512-limb block into one accumulator forms the base-`2^16384` digit sum.
5. Repeated division by `10^9` converts that accumulator into decimal groups of nine digits.

| term | meaning |
|---|---|
| `powerLimbs` | builds a power by repeated small multiplication |
| `limbBase` | radix `2^32` of each stored word |
| `chunkLimbs` | 512 limbs, one base-`2^16384` digit |
| `decimalGroupBase` | divisor that yields nine decimal digits per step |

For the first sample case, `7^3` is 343 and `5^4` is 625. Their XOR is 806, which fits in one chunk, so the digit sum is 806.

Each conversion group is padded to nine digits before being prepended. Leading zeros are removed from the final string, and a zero result prints `0`.

## Code

**Input and scanning.** The hand reader loads stdin and extracts integers.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1 shl 32
const limbMask = limbBase - 1
const chunkLimbs = 512
const decimalGroupBase = 1000000000

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
```

Constants fix the limb and chunk sizes.
The buffer flushes only after large blocks accumulate.
One input string serves every test case.

**Power construction.** Each exponent step multiplies the whole limb array by its small base.

```nim
proc powerLimbs(baseValue: int, exponent: int): seq[int] =
  result = @[1]
  for exponentStep in 0 .. exponent - 1:
    var carry: int64 = 0
    for limbIndex in 0 .. result.len - 1:
      let product = int64(result[limbIndex]) * int64(baseValue) + carry
      result[limbIndex] = int(product and int64(limbMask))
      carry = product shr 32
    while carry > 0:
      result.add(int(carry and int64(limbMask)))
      carry = carry shr 32
```

Products and carries stay within signed 64-bit arithmetic.
A new limb is appended whenever a carry survives the last word.
The result is little-endian, so index zero holds the lowest bits.

**XOR and decimal conversion.** Chunks are summed, then divided into nine-digit groups.

```nim
proc digitSumDecimal(firstPower: seq[int], secondPower: seq[int]): string =
  let combinedLength = max(firstPower.len, secondPower.len)
  var combined = newSeq[int](combinedLength)
  for limbIndex in 0 .. combinedLength - 1:
    var firstLimb = 0
    var secondLimb = 0
    if limbIndex < firstPower.len:
      firstLimb = firstPower[limbIndex]
    if limbIndex < secondPower.len:
      secondLimb = secondPower[limbIndex]
    combined[limbIndex] = firstLimb xor secondLimb
  let chunkCount = (combinedLength + chunkLimbs - 1) div chunkLimbs
  var sumLimbs = newSeq[int](chunkCount * chunkLimbs + 2)
  for chunkIndex in 0 .. chunkCount - 1:
    var carry: int64 = 0
    for limbIndex in 0 .. chunkLimbs - 1:
      let limbPosition = chunkIndex * chunkLimbs + limbIndex
      var addend = 0
      if limbPosition < combinedLength:
        addend = combined[limbPosition]
      let partial = int64(sumLimbs[limbIndex]) + int64(addend) + carry
      sumLimbs[limbIndex] = int(partial and int64(limbMask))
      carry = partial shr 32
    var carryIndex = chunkLimbs
    while carry > 0:
      let partial = int64(sumLimbs[carryIndex]) + carry
      sumLimbs[carryIndex] = int(partial and int64(limbMask))
      carry = partial shr 32
      carryIndex += 1
  var highestLimb = sumLimbs.len - 1
  while highestLimb > 0 and sumLimbs[highestLimb] == 0:
    highestLimb -= 1
  var decimalText = ""
  while highestLimb > 0 or sumLimbs[0] != 0:
    var remainder: int64 = 0
    for limbIndex in countdown(highestLimb, 0):
      let current = remainder * int64(limbBase) + int64(sumLimbs[limbIndex])
      sumLimbs[limbIndex] = int(current div int64(decimalGroupBase))
      remainder = current mod int64(decimalGroupBase)
    while highestLimb > 0 and sumLimbs[highestLimb] == 0:
      highestLimb -= 1
    if remainder == 0 and highestLimb == 0 and sumLimbs[0] == 0:
      break
    var groupText = $remainder
    while groupText.len < 9:
      groupText = "0" & groupText
    decimalText = groupText & decimalText
  var firstNonZero = 0
  while firstNonZero < decimalText.len and decimalText[firstNonZero] == '0':
    firstNonZero += 1
  if firstNonZero > 0:
    decimalText = decimalText[firstNonZero .. decimalText.len - 1]
  if decimalText == "":
    decimalText = "0"
  return decimalText
```

XOR needs no carry propagation between limbs.
Every chunk is added at limb zero of the accumulator.
The final string is trimmed before printing.

**Case loop.** Two powers are built and converted for every case.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let firstBase = nextInt(inputData, scanPos)
  let firstExponent = nextInt(inputData, scanPos)
  let secondBase = nextInt(inputData, scanPos)
  let secondExponent = nextInt(inputData, scanPos)
  let firstPower = powerLimbs(firstBase, firstExponent)
  let secondPower = powerLimbs(secondBase, secondExponent)
  appendOutput(digitSumDecimal(firstPower, secondPower))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case reads exactly four integers.
The two powers are independent until XOR.
Final output flushes the shared buffer once.

## Complexity

| phase | time | space |
|---|---|---|
| power build | exponent times the current limb count | one limb array per power |
| XOR and chunk sum | one pass over all limbs | one accumulator |
| decimal conversion | nine digits per division pass | one output string |

| measure | Big O |
|---|---|
| time | O((B + C) * L + D) |
| space | O(L + D) |

Here `L` is the limb count of the larger power and `D` is the decimal output length.

Using a decimal big integer for each chunk would add repeated parsing work; limb blocks avoid it.

The fixed radix keeps every intermediate exact and within 64-bit arithmetic.
