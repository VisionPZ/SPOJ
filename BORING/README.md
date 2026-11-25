# BORING — Boring Factorials (Reloaded) (SPOJ)

<https://www.spoj.com/problems/BORING/>

## Problem

Compute N! modulo a prime P that is close to N. Wilson's theorem turns the missing tail of (P-1)! into a short product.

Input starts with T, the number of test cases. Each later line holds two integers N and P, where P is prime. Print N! mod P on one line per case. The bound |N-P| < 10000 keeps the missing tail short.

| item | bound |
|---|---|
| test cases T | 1 to 9999 |
| integer N | 0 < N < 4 × 10^18 |
| prime P | 1 < P < 4 × 10^18 |
| distance | \|N - P\| < 10000 |
| judge limit | 2500 ms, 1536 MB |

When N reaches P or exceeds it, the factorial contains P and the answer is zero.

Sample input:

```
3
2 5
5 11
21 71
```

Sample output:

```
2
10
6
```

## Idea

Replace a huge factorial with its missing tail, like balancing a scale by weighing only the few weights that were left off. Wilson's theorem says (P-1)! is minus one modulo P. The numbers from N+1 to P-1 are the negatives of 1 up to d, where d = P-1-N. Their product is (-1)^d × d!, so N! equals minus the inverse of that short factorial. A 128-bit product and normalized division give fast modular multiplication. Multiplying 1 through N would need trillions of steps. Use Wilson's tail and Fermat inversion.

## Why It Works

1. Wilson's theorem gives (P-1)! ≡ -1 (mod P) for prime P.
2. When N < P, the identity (P-1)! = N! × (N+1) × … × (P-1) holds.
3. Each missing factor P-j equals -j, for j from 1 to d = P-1-N.
4. The missing product equals (-1)^d × d!, which is fast to form because d < 10000.
5. Fermat's theorem inverts that product by raising it to power P-2.
6. The final sign is (-1)^(d+1), so an odd d keeps the inverse and an even d negates it.
7. The product of two residues fills four 32-bit limbs. Scaling the divisor puts its top limb above half the base, so each quotient estimate needs at most two corrections.

| term | meaning |
|---|---|
| `missingCount` | d = P - 1 - N, the number of missing factors |
| `chunkProduct` | a product of small factors kept inside an int64 |
| `factorialResidue` | d! modulo P |
| `inverseValue` | the modular inverse of factorialResidue |
| `scaledHigh` | top 32-bit limb of the scaled divisor |

For N = 2 and P = 5, d = 2 and 2! = 2. Its inverse modulo 5 is 3. The even d negates 3, giving 5 - 3 = 2. For N = 5 and P = 11, d = 5 and 120 mod 11 = 10. The inverse of 10 is 10, and the odd d keeps it, giving 10.

The chunk guard stops before an int64 product overflows. The division guard handles primes below 2^32 with one direct product.

## Code

**Input and modular power.** The reader buffers tokens, and binary exponentiation handles huge exponents.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc multiplyMod(leftValue: int64, rightValue: int64, modulusValue: int64): int64 =
  if modulusValue < (1'i64 shl 32):
    let smallLeft = uint64(leftValue mod modulusValue)
    let smallRight = uint64(rightValue mod modulusValue)
    return int64((smallLeft * smallRight) mod uint64(modulusValue))
  let mask = 0xffffffff'u64
  let baseShift = 32'u64
  let firstLow = uint64(leftValue) and mask
  let firstHigh = uint64(leftValue) shr baseShift
  let secondLow = uint64(rightValue) and mask
  let secondHigh = uint64(rightValue) shr baseShift
  var product = [0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64]
  for row in 0 .. 1:
    let rowValue = if row == 0: firstLow else: firstHigh
    var carry = 0'u64
    for column in 0 .. 1:
      let columnValue = if column == 0: secondLow else: secondHigh
      let combined = rowValue * columnValue + product[row + column] + carry
      product[row + column] = combined and mask
      carry = combined shr baseShift
    var position = row + 2
    while carry > 0'u64:
      let combined = product[position] + carry
      product[position] = combined and mask
      carry = combined shr baseShift
      position += 1
  let divisorLow = uint64(modulusValue) and mask
  let divisorHigh = uint64(modulusValue) shr baseShift
  let scale = (1'u64 shl baseShift) div (divisorHigh + 1'u64)
  let scaledFull = uint64(modulusValue) * scale
  let scaledLow = scaledFull and mask
  let scaledHigh = scaledFull shr baseShift
  var remainder = [0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64, 0'u64]
  var scaleCarry = 0'u64
  for index in 0 .. 5:
    let combined = product[index] * scale + scaleCarry
    remainder[index] = combined and mask
    scaleCarry = combined shr baseShift
  remainder[6] = scaleCarry
  for shift in countdown(4, 0):
    let topPair = remainder[shift + 2] * (1'u64 shl baseShift) + remainder[shift + 1]
    var estimate = topPair div scaledHigh
    if estimate >= (1'u64 shl baseShift):
      estimate = (1'u64 shl baseShift) - 1'u64
    var productLow = estimate * scaledLow
    var productHigh = estimate * scaledHigh + (productLow shr baseShift)
    var productTop = productHigh shr baseShift
    var productMiddle = productHigh and mask
    var productBottom = productLow and mask
    while productTop > remainder[shift + 2] or
          (productTop == remainder[shift + 2] and
           (productMiddle > remainder[shift + 1] or
            (productMiddle == remainder[shift + 1] and productBottom > remainder[shift]))):
      estimate -= 1
      productLow = estimate * scaledLow
      productHigh = estimate * scaledHigh + (productLow shr baseShift)
      productTop = productHigh shr baseShift
      productMiddle = productHigh and mask
      productBottom = productLow and mask
    var borrow = 0'i64
    for index in 0 .. 2:
      let subValue = if index == 0: productBottom else:
                     (if index == 1: productMiddle else: productTop)
      var difference = int64(remainder[shift + index]) - int64(subValue) - borrow
      if difference < 0:
        difference += int64(1'u64 shl baseShift)
        borrow = 1
      else:
        borrow = 0
      remainder[shift + index] = uint64(difference)
  let scaledRemainder = remainder[1] * (1'u64 shl baseShift) + remainder[0]
  return int64(scaledRemainder div scale)

proc powerMod(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  var powerResult = 1'i64
  var baseCopy = baseValue mod modulusValue
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1'i64) != 0:
      powerResult = multiplyMod(powerResult, baseCopy, modulusValue)
    baseCopy = multiplyMod(baseCopy, baseCopy, modulusValue)
    exponentCopy = exponentCopy shr 1
  return powerResult
```

Small primes use one uint64 product.
Large primes use four 32-bit product limbs and a scaled divisor.
Each quotient estimate needs at most two corrections.

**Tail product and answer.** The short factorial is built in chunks and inverted once.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let factorialIndex = int64(nextInt(inputData, scanPos))
  let primeModulus = int64(nextInt(inputData, scanPos))
  if factorialIndex >= primeModulus:
    appendOutput("0\n")
    continue
  let missingCount = primeModulus - 1 - factorialIndex
  var chunkProduct = 1'i64
  var factorialResidue = 1'i64
  var factorValue = 1'i64
  while factorValue <= missingCount:
    if chunkProduct <= high(int64) div factorValue:
      chunkProduct = chunkProduct * factorValue
    else:
      factorialResidue = multiplyMod(factorialResidue, chunkProduct, primeModulus)
      chunkProduct = factorValue
    factorValue += 1
  factorialResidue = multiplyMod(factorialResidue, chunkProduct, primeModulus)
  let inverseValue = powerMod(factorialResidue, primeModulus - 2, primeModulus)
  var answer = primeModulus - inverseValue
  if (missingCount and 1'i64) != 0:
    answer = inverseValue
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Cases with N at least P write zero at once.
The guard flushes a chunk before an int64 multiply overflows.
The parity of missingCount selects the final sign.

## Complexity

Each case multiplies at most 10000 small factors and inverts one residue.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| tail product | d small factor steps | a few int64 values |
| inversion | about 60 modular powers | a few int64 values |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(d + log P) |
| space | O(1) |

Multiplying from 1 to N needs about 4 × 10^18 steps. Wilson's tail reduces that to at most 10000 steps.
