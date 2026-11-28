# BASECONV — Base Conversion (SPOJ)

<https://www.spoj.com/problems/BASECONV/>

## Problem

Convert a number from base B1 to base B2. The input digits are least significant first. Output the number of base-B2 digits, then the digits, also least significant first.

| item | bound |
|---|---|
| test cases T | 1 to 50 |
| bases B1, B2 | 2 to 1000000000 |
| digit count k | 2 to 10000 |
| digit ai | 0 to B1 − 1, top digit positive |
| judge limit | 2483 ms, 1536 MB |

The value N can have thousands of digits, so no built-in integer type holds it.

Sample input:

```
1 10 100
5
5 4 3 2 1
```

Sample output:

```
3
45 23 1
```

## Idea

Store the number in base 2³² limbs, like writing a long sum on many small slips of paper. Read the source digits from the top down, multiplying the whole limb array by B1 and adding one digit each time. Write the result by dividing the limb array by B2 repeatedly and keeping each remainder.

Group several output digits per division when B2 is small. One division by a power of B2 then yields a whole chunk of digits.

## Why It Works

1. A limb holds 32 bits, and each product of a limb by a base below 2³⁰ fits in 64 bits.
2. Reading digits from most significant to least keeps the invariant N = N × B1 + digit.
3. Long division by a small divisor scans limbs from high to low and keeps a 64-bit remainder.
4. The remainder after dividing by B2 is the next output digit, least significant first.
5. Dividing by B2^g yields g output digits at once when B2^g fits in 32 bits.
6. Removing high zero digits at the end keeps only the true digits of N.

| term | meaning |
|---|---|
| magnitude | limb array holding the current value |
| multiplier | B1 during input, or a power of B2 during output |
| groupDivisor | largest power of B2 that fits in 32 bits |
| targetDigits | output digits, least significant first |

For the sample, 12345 divided by 100 leaves 45, then 123 divided by 100 leaves 23, then 1 remains. The output is 3, then 45 23 1.

## Code

**Input and scanning.** The reader takes the shared bases and the digit list of each case.

```nim
const flushBlockBytes = 1 shl 17
const limbMask: uint64 = 0xffffffff'u64

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
```

All bases and digits arrive through one hand scanner.
The scanner ignores spacing and line breaks.

**Big integer helpers.** Multiply-add builds the value; long division extracts chunks.

```nim
proc multiplyAdd(magnitude: var seq[uint32], multiplier: uint64, addend: uint64) =
  var carry = addend
  if magnitude.len > 0:
    for limbIndex in 0 .. magnitude.len - 1:
      let product = uint64(magnitude[limbIndex]) * multiplier + carry
      magnitude[limbIndex] = uint32(product and limbMask)
      carry = product shr 32
  while carry != 0'u64:
    magnitude.add uint32(carry and limbMask)
    carry = carry shr 32

proc divideSmall(magnitude: var seq[uint32], divisor: uint64): uint64 =
  var remainder: uint64 = 0
  var limbIndex = magnitude.len - 1
  while limbIndex >= 0:
    let current = (remainder shl 32) + uint64(magnitude[limbIndex])
    magnitude[limbIndex] = uint32(current div divisor)
    remainder = current mod divisor
    limbIndex -= 1
  while magnitude.len > 0 and magnitude[magnitude.len - 1] == 0:
    magnitude.setLen(magnitude.len - 1)
  return remainder
```

Carry propagation never exceeds one extra limb.
Division trims high zero limbs so the next pass starts clean.

**Conversion and output.** Input digits build the value, then grouped divisions emit digits.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
let firstBase = nextInt(inputData, scanPos)
let secondBase = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  var sourceDigits = newSeq[int](sourceCount)
  for digitIndex in 0 .. sourceCount - 1:
    sourceDigits[digitIndex] = nextInt(inputData, scanPos)
  var magnitude = newSeq[uint32]()
  var sourcePosition = sourceCount - 1
  while sourcePosition >= 0:
    multiplyAdd(magnitude, uint64(firstBase), uint64(sourceDigits[sourcePosition]))
    sourcePosition -= 1
  var groupDivisor: uint64 = 1
  var groupSize = 0
  while groupDivisor * uint64(secondBase) <= limbMask:
    groupDivisor = groupDivisor * uint64(secondBase)
    groupSize += 1
  var targetDigits = newSeq[int]()
  while magnitude.len > 0:
    var chunk = divideSmall(magnitude, groupDivisor)
    for groupIndex in 0 .. groupSize - 1:
      targetDigits.add(int(chunk mod uint64(secondBase)))
      chunk = chunk div uint64(secondBase)
  while targetDigits.len > 1 and targetDigits[targetDigits.len - 1] == 0:
    targetDigits.setLen(targetDigits.len - 1)
  appendOutput($targetDigits.len)
  outputBuffer.add '\n'
  for targetIndex in 0 .. targetDigits.len - 1:
    if targetIndex > 0:
      outputBuffer.add ' '
    appendOutput($targetDigits[targetIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The group size is chosen once per case from B2.
The final trim removes only zeros above the true leading digit.
Every number goes to the shared output buffer.

## Complexity

Each source digit touches every limb once, and each output group does the same.

| phase | time | space |
|---|---|---|
| input read | one pass over k digits | one input string |
| value build | k multiply-add passes | array of limbs |
| conversion | one long division per output group | array of output digits |
| output | count plus all digits | block buffer |

| measure | Big O |
|---|---|
| time per case | O(k × L), with L the limb count |
| space per case | O(L) plus output digits |

Repeated string-based multiplication would cost far more than these limb operations.

Grouping output digits cuts the division count for small bases.
