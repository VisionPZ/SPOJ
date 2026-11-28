# CBANK — Charu and Coin Distribution (SPOJ)

<https://www.spoj.com/problems/CBANK/>

## Problem

Count the ways to pay exactly N rupees with coins worth 0.25, 0.50, 1, and 2 rupees. Report the count modulo 1000000007.

Input starts with the number of test cases, followed by one integer N per line. Output one answer per line.

The statement gives these bounds.

| item | bound |
|---|---|
| test cases | up to 10000 |
| amount N | up to 1000000000 |
| coins of each type | 4 N |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The large amount rules out any loop over the money.

Sample input:

```
2
1
2
```

Sample output:

```
4
10
```

## Idea

Scale all coins to quarters and count the integer solutions of one equation, like counting change with a fixed set of denominations.

The algorithm derives a closed form for the number of solutions and evaluates it with modular arithmetic. Each test case costs a fixed number of multiplications. A coin-change dynamic program would walk up to 4 N amounts per case. The formula replaces that walk with three sums.

## Why It Works

1. Scaling by four turns the four coins into values 1, 2, 4, and 8.
2. The target becomes 4 N quarters, and the 4 N coin cap never binds.
3. Grouping by the number of eight-quarter coins leaves a sum over blocks.
4. Each block contributes a quadratic in the block index.
5. Summing those quadratics gives three closed terms evaluated modulo the modulus.

The main terms are listed below.

| term | meaning |
|---|---|
| `targetQuarters` | N multiplied by four |
| `blockCount` | the number of full eight-quarter blocks |
| `firstCoefficient` | the leading coefficient of the quadratic |
| `secondCoefficient` | the leading coefficient plus the remainder offset |
| `modMultiply` | multiplication reduced by the modulus |

The block split turns a long coin sum into three short products.

A script trace on tiny amounts shows the raw coin-change counts.

```
N=1 quarters=4 ways=4
N=2 quarters=8 ways=10
N=3 quarters=12 ways=20
N=4 quarters=16 ways=35
N=5 quarters=20 ways=56
N=6 quarters=24 ways=84
N=7 quarters=28 ways=120
```

The values 4 and 10 match the sample, and the sequence follows the same quadratic blocks.

Products stay below 64 bits because each factor is reduced before multiplying.

## Code

**Input and modular helper.** The reader loads the amounts, and the helper keeps products small.

```nim
const flushBlockBytes = 1 shl 17
const modulus = 1000000007
const inverseTwo = 500000004
const inverseSix = 166666668
const quartersPerRupee = 4
const quartersPerLargeCoin = 8
const quartersPerMediumCoin = 4

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

proc modMultiply(left, right: int64): int64 =
  return (left * right) mod int64(modulus)
```

The two inverse constants replace division by two and six.
The scanner reads each amount without scanning the whole line.
Reducing after each product keeps values inside 64 bits.

**Output buffering.** The buffer flushes large blocks to the terminal.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One line is written per test case.
The buffer avoids a write call for every answer.

**Closed-form evaluation.** Each case fills the three terms of the quadratic sum.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let rupees = int64(nextInt(inputData, scanPos))
  let targetQuarters = rupees * quartersPerRupee
  let blockCount = targetQuarters div quartersPerLargeCoin
  let remainder = targetQuarters mod quartersPerLargeCoin
  let firstCoefficient = int64(remainder div quartersPerMediumCoin + 1)
  let secondCoefficient = firstCoefficient + int64((remainder mod quartersPerMediumCoin) div 2)
  let blockMod = blockCount mod int64(modulus)
  let nextBlockMod = (blockCount + 1) mod int64(modulus)
  let doubleBlockMod = (2 * blockCount + 1) mod int64(modulus)
  let pairProduct = modMultiply(blockMod, nextBlockMod)
  let linearSum = modMultiply(pairProduct, inverseTwo)
  let squareSum = modMultiply(modMultiply(pairProduct, doubleBlockMod), inverseSix)
  let firstPart = modMultiply(4, squareSum)
  let middlePart = modMultiply(modMultiply(2, firstCoefficient + secondCoefficient), linearSum)
  let lastPart = modMultiply(modMultiply(nextBlockMod, firstCoefficient), secondCoefficient)
  let answer = (firstPart + middlePart + lastPart) mod int64(modulus)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The remainder picks the two coefficients from the target modulo eight.
The linear and square sums use the arithmetic-series formulas with modular inverses.
The three parts add to the answer without any loop over the amount.

## Complexity

Each test case runs in constant time.

| phase | time | space |
|---|---|---|
| input read | one pass over the amounts | one input string |
| formula | a fixed number of products | a few integers |
| output | one line per case | block buffer |

The formula work does not grow with N.

| measure | Big O |
|---|---|
| time | O(1) per case |
| space | O(1) per case |

A coin-change table would cost O(N) per case and fail on a billion quarters.

The closed form keeps all 10000 cases within the limit.
