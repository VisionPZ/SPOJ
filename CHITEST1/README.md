# CHITEST1 — Sum of two numbers

## Problem

Add the two numbers on each test line and print one sum per line. The printed answer must be accurate to better than 10 to the minus sixth.

Input: a count `N`, then `N` lines, each holding two whitespace-separated numbers.
Output: `N` lines, each holding the sum of the matching pair.

| item | bound |
|---|---|
| test count `N` | given on the first line |
| numbers | signed decimal values |
| required accuracy | better than 10^-6 |
| judge limit | 1000 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
3 2 33.3 4-1 4
```

```
57.33
```

The statement compresses its example into one input line. The generated sample uses the same printed answer in a line-broken form: one case, `23.33` plus `34`, giving `57.33`.

## Idea

Think of adding prices on a receipt, one pair at a time. The scanner reads each price directly from the input buffer, and a decimal addition gives the total.

The real algorithm is a hand written decimal token scanner plus double precision addition. Each digit costs one multiply and one add, and each pair costs one addition.

## Why It Works

1. The scanner skips any byte that is not a digit, a minus sign, or a dot.
2. A minus sign before the digits flips the sign of the value.
3. Decimal digits after the dot are accumulated with a shrinking power-of-ten scale.
4. Double precision keeps well over fifteen significant digits, far beyond 10^-6.
5. Formatting to six decimal places then trimming zeros prints a clean answer.

| term | meaning |
|---|---|
| `nextNumber` | scans one signed decimal value by index |
| `wholePart` | digits before the decimal point |
| `fractionPart` | digits after the decimal point |
| `scale` | current power of ten for the fraction |
| `formatSum` | prints six decimals and trims surplus zeros |

Script-generated example for the rendered sample:

```
first  = 23.33
second = 34.00
sum    = 57.33
formatFloat gives 57.330000, trimming gives 57.33
```

A pair such as `3.5` and `-0.5` gives `3`, because trailing zeros and the dot are removed.

## Code

**Imports and buffer size.** The float formatter comes from the string utility module.

```nim
import strutils

const flushBlockBytes = 1 shl 17
```

The block size is 128 KiB. It keeps the write count low when many cases are present.

**Decimal scanner.** Reads a signed value straight from the shared input buffer.

```nim
proc nextNumber(inputData: string, pos: var int): float =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9') and
        inputData[pos] != '-' and inputData[pos] != '.':
    pos += 1
  var signValue = 1.0
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    wholePart = wholePart * 10.0 + float(int(inputData[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scale = 1.0
  if pos < inputData.len and inputData[pos] == '.':
    pos += 1
    while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
      scale = scale * 10.0
      fractionPart = fractionPart + float(int(inputData[pos]) - 48) / scale
      pos += 1
  return signValue * (wholePart + fractionPart)
```

The minus sign is consumed before the digits. The scale grows by ten for every fractional digit, so digits keep their place value.

**Formatter.** Produces six decimals, then removes surplus zeros.

```nim
proc formatSum(value: float): string =
  result = formatFloat(value, ffDecimal, 6)
  while result.len > 0 and result[result.len - 1] == '0':
    result.setLen result.len - 1
  if result.len > 0 and result[result.len - 1] == '.':
    result.setLen result.len - 1
```

Six decimals satisfy the accuracy rule. Trimming is done by shortening the string, with no extra allocation.

**Driver.** Reads the count, sums each pair, and writes in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let caseCount = int(nextNumber(inputData, pos))
var outputBuffer = ""
for _ in 0 ..< caseCount:
  let firstNumber = nextNumber(inputData, pos)
  let secondNumber = nextNumber(inputData, pos)
  outputBuffer.add formatSum(firstNumber + secondNumber)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

All lines feed one buffer, so the token stream is independent of line breaks. The last write emits any buffered tail.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| number scan | one step per digit | constant |
| addition and format | constant per case | one short string |
| output | one write per 128 KiB block | 128 KiB |

| measure | Big O |
|---|---|
| time | O(total input digits) |
| space | O(input bytes) |

Using a parsed string token for every number would allocate repeatedly. Index scanning avoids those allocations while keeping the same linear cost.
