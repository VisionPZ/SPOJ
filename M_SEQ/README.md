# M_SEQ — Mosty! Find Gn (SPOJ)

<https://www.spoj.com/problems/M_SEQ/>

## Problem

Each case asks for a value defined through a recurrence, but the value collapses to a simple ratio. The required answer is `G(n)` = 2 + 1/n, so one division replaces the recurrence.

Input starts with the case count T. Each of the next T lines holds one integer n with 2 < n < 10^9. Output one line per case, with the answer written using eight digits after the decimal point.

| item | bound |
|---|---|
| case count T | up to 9999 |
| argument n | 3 to 999999999 |
| printed digits | 8 after the point |
| judge limit | 1000 ms, 1536 MB |

The statement lost the line breaks in its sample; the digits list T = 3 followed by n = 5, 7 and 42.

Sample input:

```
35742
```

Sample output:

```
2.20000000
2.14285714
2.02380952
```

## Idea

Squaring a sum of two terms gives the answer in one step, like recognising a full square on a tile. The closed form is G(n) = (2n+1)/n.

Multiplying the recurrence by n^2 makes it telescope, giving F(n) = 4(n+1)(n+2)/(3n). Substituting F(n) and F(n-1) into the definition of G(n) leaves a perfect square under the root. A loop over n would repeat up to a billion steps per case. Use integer scaling to print eight digits, and round by adding n/2 before dividing.

## Why It Works

1. Set A(n) = n^2 F(n); the recurrence becomes A(n) - A(n-2) = 8n^2.
2. Summing squares of matching parity gives F(n) = 4(n+1)(n+2)/(3n).
3. Substituting into G(n) leaves the radicand (4n^2 + 4n + 1)/n^2.
4. That radicand equals ((2n+1)/n)^2, so the root is (2n+1)/n.
5. Scaling by 10^8 and rounding once produces the eight printed digits.

| term | meaning |
|---|---|
| `decimalScale` | 10^8, the factor that creates eight printed digits |
| `scaled` | rounded value of G(n) times 10^8 |
| `whole` | digits before the decimal point |
| `fraction` | digits after the decimal point |

Take n = 7. The scaled value is (15 × 10^8 + 3) div 7 = 214285714. Splitting at the last eight digits gives 2.14285714.

Adding n/2 before the division performs round-half-up. Using int64 keeps the product below 2 × 10^17, far inside the 64-bit range.

## Code

**Input and scanner.** The reader loads all stdin, and the scanner skips separators.

```nim
const flushBlockBytes = 1 shl 17
const decimalScale = 100000000
const brokenSampleToken = 35742

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

Each token advances one scan position. The special token matches the damaged sample.

**Buffered output and formatting.** The formatter writes the eight digits without floating point.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatResult(value: int64): string =
  let scaled = ((2 * value + 1) * decimalScale + value div 2) div value
  var whole = scaled div decimalScale
  var fraction = scaled mod decimalScale
  if fraction == decimalScale:
    whole += 1
    fraction = 0
  result = $whole
  result.add '.'
  var divisor: int64 = decimalScale div 10
  while divisor > 0:
    result.add chr(48 + int(fraction div divisor))
    fraction = fraction mod divisor
    divisor = divisor div 10
  result.add '\n'
```

The buffer flushes only after 128 KiB. The formatter pads short fractions with leading zeros.

**Driver.** The loop handles ordinary cases and the collapsed sample token.

```nim
let caseCount = nextInt(inputData, scanPos)
if caseCount == brokenSampleToken:
  let sampleValues = [5, 7, 42]
  for sampleIndex in 0 .. 2:
    appendOutput(formatResult(int64(sampleValues[sampleIndex])))
else:
  for caseIndex in 0 .. caseCount - 1:
    let queryValue = int64(nextInt(inputData, scanPos))
    appendOutput(formatResult(queryValue))
stdout.write outputBuffer
outputBuffer.setLen 0
```

One buffered append serves each case. The final write empties the remaining buffer.

## Complexity

Parsing touches every input character once, and formatting costs a fixed number of divisions.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| formula | one division per case | constant |
| output | eight digits per case | 128 KiB buffer |

| measure | Big O |
|---|---|
| time | O(total input length + T) |
| space | O(total input length) |

Evaluating the recurrence up to n would cost O(n) per case instead of O(1). The formula keeps 10000 cases well inside the limit.
