<https://www.spoj.com/problems/LFBKE/>

## Problem

A borrower compares two bank offers. Bank 1 charges simple interest and bank 2 charges compound interest. Each case gives the loan amount p, the years y, and the two rates r1 and r2 in percent. Print the bank with the smaller interest amount, or the tie message.

| item | bound |
|---|---|
| test cases | 1 to 1000 |
| loan amount p | 1 to 1000000000 |
| years y | 1 to 50 |
| rates r1 and r2 | 3 to 50 percent |
| judge limit | 1000 ms, 1536 MB |

Exact equality must print Confused huh! including the exclamation mark.

Sample input:

```
4
10000 5 10 15
2000 4 3 5
100 3 5 4
12345 3 9 7
```

Sample output:

```
Bank 1
Bank 1
Bank 2
Bank 2
```

## Idea

The loan amount cancels from both interest amounts, like removing a common discount before comparing prices. Compare the integers (100+r2) to the power y and 100 to the power y-1 times (100+r1*y). The larger side means the smaller interest amount.

## Why It Works

1. Both interest amounts scale with p, so p cancels from the comparison.
2. Simple interest equals p times r1 times y divided by 100.
3. Compound interest equals p times ((100+r2)/100)^y minus p.
4. Multiplying the two factors by 100^y leaves two exact integers.
5. Base 1e9 limbs hold those integers exactly because y never exceeds 50.

| term | meaning |
|---|---|
| `compoundSide` | integer (100+r2)^y |
| `simpleSide` | integer 100^(y-1)(100+r1*y) |
| `limbBase` | radix 1000000000 used by each limb |
| `multiplySmall` | multiplies a big value by one small integer |
| `relation` | sign of the exact comparison |

Integer arithmetic keeps ties exact where floating point would round them apart.

## Code

**Exact integer arithmetic.** Small multipliers build the two comparison values.

```nim
const flushBlockBytes = 1 shl 17
const limbBase = 1000000000

type BigValue = seq[int32]

proc multiplySmall(value: var BigValue, factor: int32) =
  var carry: int64 = 0
  for limbIndex in 0 .. value.len - 1:
    let combined = int64(value[limbIndex]) * int64(factor) + carry
    value[limbIndex] = int32(combined mod int64(limbBase))
    carry = combined div int64(limbBase)
  while carry > 0:
    value.add int32(carry mod int64(limbBase))
    carry = carry div int64(limbBase)

proc smallPower(base: int32, exponent: int): BigValue =
  var product: BigValue = @[int32(1)]
  for step in 1 .. exponent:
    multiplySmall(product, base)
  return product

proc scaledSmallPower(base: int32, exponent: int, factor: int32): BigValue =
  var product: BigValue = @[int32(1)]
  for step in 1 .. exponent:
    multiplySmall(product, base)
  multiplySmall(product, factor)
  return product

proc compareBig(left: BigValue, right: BigValue): int =
  if left.len > right.len: return 1
  if left.len < right.len: return -1
  for limbIndex in countdown(left.len - 1, 0):
    if left[limbIndex] > right[limbIndex]: return 1
    if left[limbIndex] < right[limbIndex]: return -1
  return 0
```

Every limb stores nine decimal digits.
Repeated small multiplies avoid general big multiplication.
Comparison checks limb count, then limbs from high to low.

**Input, scanner, and bank choice.** Parsed rates feed the exact comparison.

```nim
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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let principal = nextInt(inputData, scanPos)
  discard principal
  let years = nextInt(inputData, scanPos)
  let simpleRate = nextInt(inputData, scanPos)
  let compoundRate = nextInt(inputData, scanPos)
  let compoundSide = smallPower(int32(100 + compoundRate), years)
  let simpleSide = scaledSmallPower(int32(100), years - 1, int32(100 + simpleRate * years))
  let relation = compareBig(compoundSide, simpleSide)
  if relation > 0:
    appendOutput("Bank 1")
  elif relation < 0:
    appendOutput("Bank 2")
  else:
    appendOutput("Confused huh!")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loan amount is consumed but does not affect the sign.
A positive relation means bank 1 charges less.
Zero relation prints the tie message.

## Complexity

Large powers use only small-integer multiplication.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| big powers | about y small multiplies per side | limbs of the two values |
| output | one write per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(y) per test case |
| space | O(y) limbs for the powers |

Floating point powers can misclassify exact ties, while limbs preserve every digit.

