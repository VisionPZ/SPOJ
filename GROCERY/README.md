# GROCERY — Grocery store (SPOJ)

<https://www.spoj.com/problems/GROCERY/>

## Problem

List every set of four prices whose product equals their sum, with no total above 20.00 EUR. Prices are whole cents, and each price appears with two digits after the decimal point.

Input: none. Output: one quadruple per line, prices in non-decreasing order and separated by one space. Print each quadruple once; any output order is accepted.

| item | bound |
|---|---|
| number of prices | exactly 4 |
| price of one item | at least 1 cent |
| total of four items | at most 2000 cents |
| judge limit | 1000 ms, 1536 MB |

The cent bound limits the search to a few hundred thousand triples.

Sample output:

```
0.50 1.00 2.50 16.00
1.25 1.60 1.75 1.84
1.25 1.40 1.86 2.00
...
```

The first line uses cents 50, 100, 250 and 1600.

## Idea

Fix three prices and the fourth follows from one division, like solving for the last corner of a rectangle once three corners are known. The search walks the first three prices in sorted order, then checks that the computed fourth price is an integer and keeps the prices ordered.

The algorithm uses integer arithmetic in cents and solves the product equation for the last price. Each triple costs constant work. A naive scan tries every quadruple up to 2000 cents and takes cubic time.

Working in cents removes rounding and keeps every comparison exact.

## Why It Works

1. Writing prices in cents turns euros with two decimals into integers.
2. A euro sum of 20.00 becomes a cent sum of 2000.
3. The euro equation becomes a*b*c*d = 1000000 times the cent sum.
4. Rearranging gives d = 1000000*(a+b+c) divided by (a*b*c - 1000000).
5. The divisor is positive only when a*b*c exceeds 1000000.
6. Since d is at least c, the product a*b*c*c cannot exceed 2*10^9, which bounds all loops.

| term | meaning |
|---|---|
| `scaleFactor` | 1000000, the cent conversion factor |
| `maxTotalCents` | 2000, the largest allowed sum |
| `productLimit` | 2*10^9, the largest possible product |
| `divisor` | a*b*c minus the scale factor |

The three constants keep every loop finite and every product exact.

Here is the sample line checked with `gen.py`:

| quantity | cent value |
|---|---|
| first price | 50 |
| second price | 100 |
| third price | 250 |
| fourth price | 1600 |
| total | 2000 |
| product | 2000000000 |

The product equals 1000000 times the total, so the line is a solution.

## Code

**Input and cent formatting.** The program reads stdin once and converts cent amounts to euro text.

```nim
const flushBlockBytes = 1 shl 17
const scaleFactor = 1000000
const maxTotalCents = 2000
const productLimit = 2000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatCents(amount: int64): string =
  let wholePart = amount div 100
  let fractionPart = amount mod 100
  if fractionPart < 10:
    return $(wholePart) & ".0" & $(fractionPart)
  return $(wholePart) & "." & $(fractionPart)
```

The reader consumes stdin even though the judge sends no data.
The formatter pads a one-digit cent part with a zero.
One buffer holds every output line.
Integer division avoids floating point rounding.

**Triple loop and solution check.** The driver keeps prices ordered, solves for the last price and verifies the equation.

```nim
for firstCents in 1 .. maxTotalCents:
  if int64(firstCents) * firstCents * firstCents * firstCents > productLimit:
    break
  for secondCents in firstCents .. maxTotalCents:
    if int64(firstCents) * secondCents * secondCents * secondCents > productLimit:
      break
    for thirdCents in secondCents .. maxTotalCents:
      if int64(firstCents) * secondCents * thirdCents * thirdCents > productLimit:
        break
      let divisor = int64(firstCents) * secondCents * thirdCents - scaleFactor
      if divisor <= 0:
        continue
      let numerator = scaleFactor * (firstCents + secondCents + thirdCents)
      if numerator mod divisor != 0:
        continue
      let fourthCents = numerator div divisor
      if fourthCents < thirdCents:
        continue
      let totalCents = firstCents + secondCents + thirdCents + fourthCents
      if totalCents > maxTotalCents:
        continue
      if int64(firstCents) * secondCents * thirdCents * fourthCents != scaleFactor * totalCents:
        continue
      appendOutput(formatCents(firstCents))
      outputBuffer.add ' '
      appendOutput(formatCents(secondCents))
      outputBuffer.add ' '
      appendOutput(formatCents(thirdCents))
      outputBuffer.add ' '
      appendOutput(formatCents(fourthCents))
      outputBuffer.add '\n'
```

The product bound cuts each loop early.
The divisibility test removes non-integer fourth prices.
The final check rejects any arithmetic mistake.
The block buffer flushes as the list grows.

## Complexity

The product bound keeps the triple loop small for every allowed price.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| triple loop | bounded by the cent limit | constant |
| output | one write per block | block buffer |

The triple loop dominates the runtime.

| measure | Big O |
|---|---|
| time | O(C^3) with C bounded by 2000 |
| space | O(1) besides the input and output buffers |

Trying all four prices would take O(C^4) time, while solving for the last price takes O(C^3).
The constant bounds keep the full list well inside the time limit.
