# XORRAY — 2D arrays with XOR property (SPOJ)

<https://www.spoj.com/problems/XORRAY/>

## Problem

Count arrays of shape N by M that use every value from 1 to N×M once. Larger values must sit at larger XOR coordinates i XOR j. Report the count modulo an input prime. The order inside one XOR group is free, so the answer is a product of factorials of group sizes.

The first line holds the case count and the prime P. Each later line holds N and M. Print one residue per case.

| Item | Bound |
|---|---|
| Cases T | 1 to 10000 |
| Rows N | 1 to 1000000000 |
| Columns M | 1 to 100000 |
| Prime P | between 1000000009 and 1999999973 |
| Judge limit | 3000 ms, 1536 MB |

Coordinates start at zero, so row i and column j have XOR coordinate i XOR j.

The sample asks for two shapes:

```
2 1000000007
2 2
997 799
```

The expected output is:

```
4
828630475
```

## Idea

Sort numbers into pigeonholes by their XOR coordinate, like dealing one card into each labelled box, then shuffle freely inside each box. A group of f cells contributes f! arrangements, so multiply those factorials. Recursive decomposition by the largest fitting power of two turns a huge grid into a short list of group sizes. Scanning all N×M cells would be impossible for a billion rows, while this recursion takes a few dozen steps.

## Why It Works

1. The strict rule orders groups by XOR value, so every group occupies a distinct consecutive range of numbers.
2. Two cells with the same XOR value impose no order on each other, so that group has f! orders.
3. The answer is the product of f! over all XOR values, taken modulo P.
4. A full block of size B pairs with any range of size s at most B. It gives count s for each of its B XOR values.
5. Splitting the larger side into a full block and a remainder keeps the XOR high bits separate, so groups never mix.
6. The remainder part contributes its own counts, and the uniform part adds one constant to every count.
7. Tracking how many XOR values share each count turns the product into a few modular powers.

| Term | Meaning |
|---|---|
| `blockSize` | largest power of two at most the larger side |
| `largerRemainder` | larger side minus the block size |
| `CountProfile` | map from a group size to the number of XOR values having it |
| `addAmount` | increments the multiplicity stored for one group size |
| `factorials` | factorials of every possible group size modulo P |
| `modPow` | modular power used for repeated group sizes |

Group sizes never exceed the smaller side, so the factorial table has a fixed bound.

A three by two grid splits into a block of size two and a remainder of one:

```
block part:  counts 2 for XOR values 0 and 1
remainder:   counts 1 for XOR values 0 and 1
profile:     {1: 2, 2: 2}
answer:      1! * 1! * 2! * 2! = 4
```

The trace agrees with a direct count of the three by two grid.

## Code

**Input and scanning.** The reader stores the prime and all shapes.

```nim
const flushBlockBytes = 1 shl 17

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

Shapes and the prime are all positive, so no sign branch is needed.
The scanner skips spaces and line breaks.
One pass loads the entire input.

**Count profile.** Groups are stored by size, not by XOR value.

```nim
type
  CountProfile = object
    values: seq[int64]
    amounts: seq[int64]

proc addAmount(profile: var CountProfile, key: int64, amount: int64) =
  var index = 0
  while index < profile.values.len:
    if profile.values[index] == key:
      profile.amounts[index] = profile.amounts[index] + amount
      return
    index += 1
  profile.values.add key
  profile.amounts.add amount
```

Each stored key is one group size seen so far.
Its amount counts XOR values with that size.
Linear search is fine because only a few sizes appear.

**Recursive split.** A full block and a remainder replace a huge grid.

```nim
proc buildProfile(firstSide: int64, secondSide: int64): CountProfile =
  if firstSide == 0 or secondSide == 0:
    result.values = @[]
    result.amounts = @[]
    return result
  var largerSide = firstSide
  var smallerSide = secondSide
  if largerSide < smallerSide:
    let temporarySide = largerSide
    largerSide = smallerSide
    smallerSide = temporarySide
  var highestPower = 0
  while (int64(1) shl (highestPower + 1)) <= largerSide:
    highestPower += 1
  let blockSize = int64(1) shl highestPower
  if largerSide == blockSize:
    result.values = @[smallerSide]
    result.amounts = @[blockSize]
    return result
  let largerRemainder = largerSide - blockSize
  if smallerSide > blockSize:
    let smallerRemainder = smallerSide - blockSize
    let childProfile = buildProfile(largerRemainder, smallerRemainder)
    var childTotal: int64 = 0
    for amount in childProfile.amounts:
      childTotal = childTotal + amount
    result.values = @[]
    result.amounts = @[]
    for index in 0 .. childProfile.values.len - 1:
      addAmount(result, childProfile.values[index] + blockSize, childProfile.amounts[index])
    let missingAmount = blockSize - childTotal
    if missingAmount > 0:
      addAmount(result, blockSize, missingAmount)
    addAmount(result, largerRemainder + smallerRemainder, blockSize)
    return result
  let childProfile = buildProfile(largerRemainder, smallerSide)
  var childTotal: int64 = 0
  for amount in childProfile.amounts:
    childTotal = childTotal + amount
  result.values = @[]
  result.amounts = @[]
  for index in 0 .. childProfile.values.len - 1:
    addAmount(result, childProfile.values[index], childProfile.amounts[index])
  let missingAmount = blockSize - childTotal
  if missingAmount > 0:
    addAmount(result, 0, missingAmount)
  addAmount(result, smallerSide, blockSize)
  return result
```

A full block gives one uniform group size.
The other branch adds a uniform group for the disjoint high-bit range.
Zeros are padded before a shift so every XOR value is counted.

**Modular powers and output.** Factorials combine by multiplicity.

```nim
proc modPow(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var currentBase = baseValue mod modulus
  var remainingExponent = exponentValue
  result = 1
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      result = result * currentBase mod modulus
    currentBase = currentBase * currentBase mod modulus
    remainingExponent = remainingExponent shr 1

let caseCount = nextInt(inputData, scanPos)
let primeModulus = int64(nextInt(inputData, scanPos))
var rowCounts = newSeq[int](caseCount)
var columnCounts = newSeq[int](caseCount)
var maximumSmallSide = 0
for caseIndex in 0 .. caseCount - 1:
  rowCounts[caseIndex] = nextInt(inputData, scanPos)
  columnCounts[caseIndex] = nextInt(inputData, scanPos)
  let smallSide = min(rowCounts[caseIndex], columnCounts[caseIndex])
  if smallSide > maximumSmallSide:
    maximumSmallSide = smallSide

var factorials = newSeq[int64](maximumSmallSide + 1)
factorials[0] = 1
for value in 1 .. maximumSmallSide:
  factorials[value] = factorials[value - 1] * int64(value) mod primeModulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let valueProfile = buildProfile(int64(rowCounts[caseIndex]), int64(columnCounts[caseIndex]))
  var answer: int64 = 1
  for index in 0 .. valueProfile.values.len - 1:
    let countValue = valueProfile.values[index]
    let multiplicity = valueProfile.amounts[index]
    if countValue == 0:
      continue
    answer = answer * modPow(factorials[int(countValue)], multiplicity, primeModulus) mod primeModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Factorials are built once up to the largest smaller side.
Squaring in `modPow` keeps every product inside 64 bits.
One answer line is appended per case.

## Complexity

Each recursive level halves the larger side, and the profile holds few sizes.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all shapes | one input string and two lists |
| Factorial table | one step per value up to the largest smaller side | one factorial per value |
| Profile per case | one step per bit level for each stored size | one profile |
| Output | one line per case | block buffer |

No grid cell is ever visited.

| Measure | Big O |
|---|---|
| Time | O(max M + T × log(max N) × K) |
| Space | O(T + max M + K) |

K stays small because a group size cannot exceed the shorter side.
Visiting all N×M cells would be impossible at the stated bounds, so the recursive profile wins.
