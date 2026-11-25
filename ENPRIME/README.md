# ENPRIME — Prime Number (SPOJ)

<https://www.spoj.com/problems/ENPRIME/>

## Problem

Despite the title, the task prints a factorial. Read one integer X and print X! exactly, with no modulo.

Input holds a single integer X. Output holds its exact factorial on one line.

| item | bound |
|---|---|
| input | one integer X |
| output | exact factorial, no modulo |
| judge limit | 1000 ms, 1536 MB |

The result grows far past 64 bits, so the product needs storage of its own.

The sample case:

```
4
```

```
24
```

## Idea

Build the product in columns, like doing long multiplication on paper with a fresh carry for each column. The algorithm is grade-school multiplication in base one billion, using int64 arithmetic per step. Each multiplication touches every limb once, so the cost grows with the product's digit count. A native integer would overflow almost at once. The limb array keeps every digit exact from start to finish.

## Why It Works

1. The product starts at 1, so both 0! and 1! print 1.
2. Each loop step multiplies the running value by the next integer, which matches the factorial definition.
3. A limb stays below one billion and the factor stays small, so the product fits in int64.
4. The remainder becomes the new limb, and the quotient becomes the carry for the next column.
5. When a carry remains after the last limb, new limbs append the leftover digits.
6. Printing the top limb plainly and padding the rest to nine digits rebuilds the exact decimal value.

| Term | Meaning |
|---|---|
| `limbs` | the running product stored in base 1000000000 |
| `carry` | the overflow passed to the next limb |
| `multiplier` | the next factor folded into the product |
| `limbBase` | one billion, the radix of every limb |
| `topLimbIndex` | the position of the most significant limb |

The limb array holds the whole answer before any digit is written.

A script-traced example for the sample value:

```
X = 4
running 1 -> 2 -> 6 -> 24
result 24
```

The trace matches the sample output.

## Code

**Input, hand scanner, and radix.** This block loads the value and sets the limb constants.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000
const limbWidth = 9

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

The scanner skips all non-digits, so spaces and newlines need no special case.
The radix is nine decimal digits per limb.
Reading once keeps the scan linear in the byte count.

**Buffered output and padded limbs.** This block writes digit groups with leading zeros.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendPaddedLimb(value: int, width: int) =
  var digits = ""
  var divisor = 100000000
  var digitIndex = 0
  while digitIndex < width:
    digits.add char(48 + ((value div divisor) mod 10))
    divisor = divisor div 10
    digitIndex += 1
  appendOutput(digits)
```

The divisor walks from the highest digit down to the lowest.
Lower limbs arrive at exactly nine digits each.
The buffer flushes once it reaches the block limit.

**Factorial loop and printing.** This block folds in every factor and emits the digits.

```nim
let maxValue = nextInt(inputData, scanPos)
var limbs = newSeq[int](1)
limbs[0] = 1
var multiplier = 2
while multiplier <= maxValue:
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < limbs.len:
    let product = int64(limbs[limbIndex]) * int64(multiplier) + carry
    limbs[limbIndex] = int(product mod int64(limbBase))
    carry = product div int64(limbBase)
    limbIndex += 1
  while carry > 0:
    limbs.add(int(carry mod int64(limbBase)))
    carry = carry div int64(limbBase)
  multiplier += 1

var topLimbIndex = limbs.len - 1
appendOutput($limbs[topLimbIndex])
topLimbIndex -= 1
while topLimbIndex >= 0:
  appendPaddedLimb(limbs[topLimbIndex], limbWidth)
  topLimbIndex -= 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs maxValue minus one times for values of at least two.
The inner loop visits every limb once per factor.
The top limb is written plainly, then each lower limb is padded.

## Complexity

The cost splits into reading one value, repeated limb products, and buffered output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Multiplication | one pass over limbs per factor | one limb array |
| Output | buffered digit blocks | block buffer |

The limb array grows with the result, while the buffer flushes in fixed blocks.

| Measure | Big O |
|---|---|
| Time | O(X · D), with D the digit count of X! |
| Space | O(D) |

Each factor touches every limb once, so the work follows the result's size.

A native 64-bit product would overflow for small X, and a recursive version adds X stack frames. The limb loop keeps every digit exact with flat memory.
