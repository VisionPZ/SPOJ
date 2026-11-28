# G10184 — Arroz con Pollo Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10184/>

## Problem

Compute the rice amount, chicken amount, and total cost for a table of diners. Four people eat 0.5 kg of rice and 0.25 kg of chicken.

Each input line gives the diner count, the rice price per kilogram, and the chicken price per kilogram. A line containing three zeroes ends the input. Print the three amounts on one line, separated by spaces. Show a non-whole amount with exactly two decimal places and a whole amount without a decimal point.

| Item | Bound |
|---|---|
| Values | positive integers per line |
| Output | three amounts per line |
| Judge limit | 1000 ms, 1536 MB |

The price bound makes the cost numerator large, so the arithmetic needs 64-bit integers.

Sample input:

```
12 1200 6000
200 1000 4000
60 1500 5000
0 0 0
```

Sample output:

```
1.50 0.75 6300
25 12.50 75000
7.50 3.75 30000
```

## Idea

Keep every amount in exact hundredths, like counting money in cents, and format only at the end. Rice is diners divided by 8, chicken is diners divided by 16, and cost is diners times twice the rice price plus the chicken price, all over 16. One multiply and one division give each amount in cents. Floating-point math would drift on large prices and force awkward rounding rules. Integer scaling settles both rounding and formatting.

## Why It Works

1. Scaling the numerator by 100 turns each fraction into an integer division with a remainder.
2. Rounding half up happens when twice the remainder reaches or exceeds the denominator.
3. A cent total divisible by 100 is a whole number, so it prints without a decimal point.
4. The cost numerator folds both prices over the common denominator 16, matching 0.5 and 0.25 kg per four people.
5. The three-zero sentinel breaks the loop before any amount is formatted.

The terms used by the formatter:

| Term | Meaning |
|---|---|
| `dinerCount` | the number of people at the table |
| `ricePrice` | price per kilogram of rice |
| `chickenPrice` | price per kilogram of chicken |
| `scaledTotal` | the numerator multiplied by `hundredScale` |
| `scaledValue` | the amount in hundredths after rounding |
| `wholePart` | the digits before the decimal point |
| `centPart` | the two digits after the decimal point |
| `costNumerator` | diners times twice the rice price plus the chicken price |

Each term names one value on the path from input to printed text.

A script-traced example:

```
diners 12, rice 1200 per kg, chicken 6000 per kg
rice: 12*100/8 = 150 cents -> 1.50
chicken: 12*100/16 = 75 cents -> 0.75
cost: 12*(2*1200+6000)*100/16 = 630000 cents -> 6300
```

The trace reproduces the first sample line.

## Code

**Input and number scanner.** These declarations load stdin and read one integer at a time.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const riceDenominator: int64 = 8
const chickenDenominator: int64 = 16
const costDenominator: int64 = 16
const hundredScale: int64 = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): tuple[value: int64, found: bool] =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result.found = pos < data.len
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  result.value = value
```

The scanner reports whether a number was present. All values stay in 64-bit integers.

**Exact amount formatter.** This block turns a fraction into the required text.

```nim
proc formatAmount(numerator: int64, denominator: int64): string =
  let scaledTotal = numerator * hundredScale
  var scaledValue = scaledTotal div denominator
  let remainder = scaledTotal mod denominator
  if remainder * 2 >= denominator:
    scaledValue += 1
  let wholePart = scaledValue div hundredScale
  let centPart = scaledValue mod hundredScale
  if centPart == 0:
    result = $wholePart
  elif centPart < 10:
    result = $wholePart & ".0" & $centPart
  else:
    result = $wholePart & "." & $centPart
```

The division and remainder stay exact in hundredths. The padding branch supplies two decimal digits.

**Case loop and output.** This block reads triples and emits one answer line each.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dinerResult = nextNumber(inputData, scanPos)
  if not dinerResult.found:
    break
  let riceResult = nextNumber(inputData, scanPos)
  let chickenResult = nextNumber(inputData, scanPos)
  let dinerCount = dinerResult.value
  let ricePrice = riceResult.value
  let chickenPrice = chickenResult.value
  if dinerCount == 0 and ricePrice == 0 and chickenPrice == 0:
    break
  let riceText = formatAmount(dinerCount, riceDenominator)
  let chickenText = formatAmount(dinerCount, chickenDenominator)
  let costNumerator = dinerCount * (2 * ricePrice + chickenPrice)
  let costText = formatAmount(costNumerator, costDenominator)
  appendOutput(riceText)
  appendOutput(" ")
  appendOutput(chickenText)
  appendOutput(" ")
  appendOutput(costText)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel stops the loop before any formatting. Each line leaves through the block buffer.

## Complexity

The scan and three formatter calls set the cost per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input string |
| Per case | three divisions and a few multiplies | one answer line |
| Output | one line per case | block buffer |

The work grows linearly with the number of case triples.

| Measure | Big O |
|---|---|
| Time | O(cases) |
| Space | O(N) for the input string |

Float math with manual rounding is the common naive route and drifts on large values, so exact cents win.
