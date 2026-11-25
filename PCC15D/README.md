# PCC15D — GST Calculator (SPOJ)

<https://www.spoj.com/problems/PCC15D/>

## Problem

A cafeteria receipt lists each item with a quantity, a price, and a tax rate. Standard-rated items add six percent; zero-rated items add nothing. Maslee needs the total amount to pay and the amount of tax inside that total.

The input starts with the number of test cases `T`. Each case starts with an item count `N`. Then come `N` lines of the form `name quantity price rate`. The price has two decimal places and the rate is `SR` or `ZR`. For each case print `Case #k:`, then `Total Amount Include GST:` and `Total Amount GST Paid:` with two decimals each.

| Item | Bound |
|---|---|
| Test cases `T` | one integer; no further bound in statement |
| Items per case | one integer `N`; no further bound in statement |
| Price | rounded to two decimal places |
| Judge limit | 10000 ms |
| Memory | 1536 MB |

The two-decimal price rule lets the whole calculation stay in integer cents.

The sample input:

```
2
4
MeksisPrepaid 1 30.00 SR
JatiRice 1 32.00 ZR
RybenaJuice 2 18.00 SR
PeanutButter 5 4.50 SR
3
GardenihaBread 3 2.40 ZR
WaterSpinach 5 1.10 ZR
iPong6 1 2779.00 SR
```

The sample output:

```
Case #1:
Total Amount Include GST: 125.81
Total Amount GST Paid: 5.31
Case #2:
Total Amount Include GST: 2958.44
Total Amount GST Paid: 166.74
```

## Idea

Like adding a six percent service charge to each line of a paper receipt, compute the charged price of each item. Then add those prices up. Prices have two decimals, so store them as integer cents instead of floating point numbers.

For an item, multiply quantity by price cents to get the subtotal in cents. A standard-rated subtotal becomes `round(subtotal * 106 / 100)` cents, with halves rounded up; a zero-rated subtotal stays unchanged. The tax is the included amount minus the subtotal. Two running sums hold the answers.

Each item costs one scan of four tokens and a few integer operations.

## Why It Works

1. Two decimal places mean every price is an exact integer count of cents.
2. Adding six percent multiplies that cent count by `106 / 100`.
3. Adding 50 before dividing by 100 rounds the result to the nearest cent, with halves going up.
4. Tax equals the included amount minus the subtotal, so no separate floating point sum can drift.

| Term | Meaning |
|---|---|
| `priceCents` | the price written as an integer number of cents |
| `subtotalCents` | quantity times `priceCents` |
| `includedCents` | subtotal cents with tax, rounded to a cent |
| `rateToken` | the string `SR` or `ZR` |

Integer arithmetic keeps the printed total and tax consistent to the last cent.

A script-generated view of the first sample case:

```
MeksisPrepaid  1 x 30.00 -> 3000 cents -> 3180 cents -> 31.80, tax 1.80
JatiRice       1 x 32.00 -> 3200 cents -> 3200 cents -> 32.00, tax 0.00
RybenaJuice    2 x 18.00 -> 3600 cents -> 3816 cents -> 38.16, tax 2.16
PeanutButter   5 x  4.50 -> 2250 cents -> 2385 cents -> 23.85, tax 1.35
total                                             125.81, tax 5.31
```

The final row matches both output lines of case one.

## Code

**Token scanner.** A single string holds the input and a scanner reads names and rates.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var tokenValue = ""
  while pos < data.len and data[pos] > ' ':
    tokenValue.add data[pos]
    pos += 1
  return tokenValue
```

Item names are single words, so `nextToken` stops at the next space. `scanPos` stays between cases.

**Price reader.** The decimal string becomes an exact cent count.

```nim
proc nextCents(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int64(data[pos]) - firstDigitValue
    pos += 1
  var centValue = wholePart * 100
  if pos < data.len and data[pos] == '.':
    pos += 1
    var digitCount = 0
    var fractionValue: int64 = 0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9' and digitCount < 2:
      fractionValue = fractionValue * 10 + int64(data[pos]) - firstDigitValue
      pos += 1
      digitCount += 1
    if digitCount == 1:
      fractionValue *= 10
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      pos += 1
    centValue += fractionValue
  return centValue
```

One fractional digit is scaled by ten, so `4.5` and `4.50` agree. Extra digits are skipped after two are read.

**Output helpers.** The buffer and money formatter write cents with a decimal point.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendMoney(cents: int64) =
  appendOutput($(cents div 100))
  outputBuffer.add '.'
  let fractionPart = cents mod 100
  if fractionPart < 10:
    outputBuffer.add '0'
  appendOutput($(fractionPart))
```

The leading zero keeps a value like five cents printed as `0.05`. No floating point conversion occurs here.

**Case loop.** Every item updates the two running sums.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let itemCount = nextInt(inputData, scanPos)
  var totalWithGst: int64 = 0
  var totalGst: int64 = 0
  for itemIndex in 0 ..< itemCount:
    discard nextToken(inputData, scanPos)
    let quantity = int64(nextInt(inputData, scanPos))
    let priceCents = nextCents(inputData, scanPos)
    let rateToken = nextToken(inputData, scanPos)
    let subtotalCents = quantity * priceCents
    if rateToken == "SR":
      let includedCents = (subtotalCents * 106 + 50) div 100
      totalWithGst += includedCents
      totalGst += includedCents - subtotalCents
    else:
      totalWithGst += subtotalCents
  appendOutput("Case #" & $(caseIndex + 1) & ":\n")
  appendOutput("Total Amount Include GST: ")
  appendMoney(totalWithGst)
  outputBuffer.add '\n'
  appendOutput("Total Amount GST Paid: ")
  appendMoney(totalGst)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The item name is skipped because it does not affect the total. The case number starts at one.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One item | four token scans and constant arithmetic | constant |
| Output | three lines per case, flushed by block | one buffer |

The total work follows the total number of item lines.

| Measure | Big O |
|---|---|
| Time | O(total items) |
| Space | O(input bytes) |

Floating point accumulation could drift by a cent across many items; integer cents avoid that risk.
