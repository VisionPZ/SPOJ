# FACTMULO — Product of factorials (again) (SPOJ)

<https://www.spoj.com/problems/FACTMULO/>

## Problem

Count how many times a prime divides the product of the first n factorials. Each factor contributes its own prime exponent, so the answer is a sum of many small counts.

Input starts with T, the number of test cases. Each later line holds a prime p and an integer n. Print one line per test case with the exponent of p in F(n) = 1! × 2! × … × n!. The answer can exceed 64 bits.

| item | bound |
|---|---|
| test cases T | 1 to 99999 |
| prime p | 1 < p < 10^18 |
| limit n | 0 < n < 10^18 |
| judge limit | 1500 ms, 1536 MB |

The notation V(p, n) means the largest exponent i with p^i dividing F(n).

Sample input:

```
2
2 3
3 4
```

Sample output:

```
2
2
```

## Idea

Group the divisible terms in batches, like counting every tenth customer in a long queue instead of asking each one. Legendre's count for k! gives the exponent of p as floor(k/p) + floor(k/p^2) + …, and summing those floors over k gives a closed form for each power p^j. Each power costs a constant number of big-integer limb operations, and at most 60 powers fit below 10^18. Scanning every k and every factorial would cost O(n) per case and cannot finish. Use power batches and base-10^9 limbs.

## Why It Works

1. The exponent of p in k! equals the sum of floor(k / p^j) over j >= 1.
2. Summing over k = 1..n and swapping sums gives sum over j of S(n, p^j), where S(n, d) = sum of floor(k / d).
3. With q = n div d and r = n mod d, the value S(n, d) equals d × q × (q-1)/2 + (r+1) × q.
4. One of d × q and q-1 is even, so the division by two stays inside 64-bit integers.
5. Powers above n give q = 0 and add nothing, so the loop stops after at most log_p(n) steps.
6. Base-10^9 limbs hold answers near 5 × 10^35, far beyond a 64-bit word.

| term | meaning |
|---|---|
| `primePower` | current value p^j |
| `quotient` | n div primePower, the largest floor value |
| `remainder` | n mod primePower, the size of the last group |
| `pairedValue` | primePower × quotient |
| `answer` | base-10^9 limb array holding the running total |

For p = 2 and n = 5, primePower = 2 gives quotient = 2, remainder = 1, pairedValue = 4 and neighborValue = 1. The half and other product add 2, and (remainder+1) × quotient adds 4, so the first batch totals 6. The next primePower = 4 gives quotient = 1 and adds 2, for a final answer of 8.

No rounding appears: every division is an integer division. The even-factor guard avoids an overflow before the base-10^9 multiply.

## Code

**Input and output scaffolding.** The reader loads all tokens once and buffers output in large blocks.

```nim
const flushBlockBytes = 1 shl 17
const decimalBase = 1000000000
const limbCapacity = 6

type BigLimbArray = array[0 .. limbCapacity - 1, int64]

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

The scanner skips spaces and line breaks.
Each new digit builds the value in an int64-sized word.
Writes leave the buffer only after the threshold is reached.

**Big limb accumulation.** The product of two 64-bit halves is added with carry propagation.

```nim
proc addProduct(accumulator: var BigLimbArray, leftFactor: int64, rightFactor: int64, extraTerm: int64) =
  var leftDigits: array[0 .. 2, int64]
  var rightDigits: array[0 .. 2, int64]
  var leftLength = 0
  var rightLength = 0
  var remaining = leftFactor
  while remaining > 0:
    leftDigits[leftLength] = remaining mod decimalBase
    remaining = remaining div decimalBase
    leftLength += 1
  remaining = rightFactor
  while remaining > 0:
    rightDigits[rightLength] = remaining mod decimalBase
    remaining = remaining div decimalBase
    rightLength += 1
  for leftIndex in 0 .. leftLength - 1:
    var innerCarry = int64(0)
    for rightIndex in 0 .. rightLength - 1:
      let limbPosition = leftIndex + rightIndex
      let limbValue = accumulator[limbPosition] + leftDigits[leftIndex] * rightDigits[rightIndex] + innerCarry
      accumulator[limbPosition] = limbValue mod decimalBase
      innerCarry = limbValue div decimalBase
    var carryPosition = leftIndex + rightLength
    while innerCarry > 0:
      let carryValue = accumulator[carryPosition] + innerCarry
      accumulator[carryPosition] = carryValue mod decimalBase
      innerCarry = carryValue div decimalBase
      carryPosition += 1
  var carryOver = int64(0)
  var extraRemaining = extraTerm
  var extraPosition = 0
  while extraRemaining > 0 or carryOver > 0:
    let extraDigit = extraRemaining mod decimalBase
    extraRemaining = extraRemaining div decimalBase
    let limbValue = accumulator[extraPosition] + extraDigit + carryOver
    accumulator[extraPosition] = limbValue mod decimalBase
    carryOver = limbValue div decimalBase
    extraPosition += 1
```

Both factors split into three base-10^9 digits.
Each digit pair contributes one limb product and a carry.
The extra term is added as digits with its own carry.

**Power sweep and output.** The closed form runs once per prime power and prints the limbs.

```nim
proc appendBigNumber(accumulator: BigLimbArray) =
  var highest = limbCapacity - 1
  while highest > 0 and accumulator[highest] == 0:
    highest -= 1
  appendOutput($accumulator[highest])
  var position = highest - 1
  while position >= 0:
    var limbText = $accumulator[position]
    while limbText.len < 9:
      limbText = "0" & limbText
    appendOutput(limbText)
    position -= 1

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let primeValue = int64(nextInt(inputData, scanPos))
  let factorialLimit = int64(nextInt(inputData, scanPos))
  var answer: BigLimbArray
  for limbIndex in 0 .. limbCapacity - 1:
    answer[limbIndex] = 0
  var primePower = primeValue
  while primePower <= factorialLimit:
    let quotient = factorialLimit div primePower
    let remainder = factorialLimit mod primePower
    let pairedValue = primePower * quotient
    let neighborValue = quotient - 1
    var halfValue = int64(0)
    var otherValue = int64(0)
    if (quotient and 1'i64) == 0:
      halfValue = pairedValue div 2
      otherValue = neighborValue
    else:
      halfValue = neighborValue div 2
      otherValue = pairedValue
    addProduct(answer, halfValue, otherValue, (remainder + 1) * quotient)
    if primePower > factorialLimit div primeValue:
      break
    primePower = primePower * primeValue
  appendBigNumber(answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The guard before the next multiply prevents an int64 overflow.
The highest limb prints without padding, and lower limbs use nine digits.
One flush clears the buffer after the last test case.

## Complexity

Each case visits prime powers up to n and does constant work per power.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| power sweep | at most 60 powers per case | six limbs |
| output | one decimal line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(log_p n) |
| space | O(1) |

A direct loop over every k and every factorial needs O(n) work and cannot handle n near 10^18. Batched powers and fixed limbs keep all cases short.
