# FINAL6 — Cupid (SPOJ)

<https://www.spoj.com/problems/FINAL6/>

## Problem

A distance is written in scientific notation as one digit, a dot, a fraction, the letter e, and a non-negative exponent. Write the same value in ordinary decimal form using the fewest digits after the dot.

Input: one line containing a string of the form a.deb. The leading digit and exponent have no leading zeros, and the fraction has no trailing zeros. Output: one decimal number, with no dot for integers and no trailing fractional zeros.

| Item | Bound |
|---|---|
| Leading digit a | 0 to 9 |
| Fraction d | less than 10^100 |
| Exponent b | 0 to 100 |
| Judge limit | 1000 ms |

The exponent moves the decimal point, so the digits themselves never change.

Sample input:

```
8.549e2
```

Sample output:

```
854.9
```

## Idea

Think of a decimal point sliding one place right for each exponent unit. Join the leading digit and the fraction digits into one digit string. Multiplying by 10^b puts the point after 1 + b digits of that string.

If the point lands past the end, append the missing zeros and print an integer. Otherwise split at that position and keep the tail as the fraction. Trim trailing zeros from the tail to get the shortest exact form. Each digit is copied once, so the work is linear in the output length.

## Why It Works

1. The mantissa equals the leading digit followed by the fraction digits.
2. The value equals that joined digit string times 10 raised to b minus the fraction length.
3. The decimal point therefore sits after 1 + b digits of the joined string.
4. Trailing zeros in a fraction add no value, so removing them keeps the shortest exact decimal.

| Term | Meaning |
|---|---|
| `digitString` | leading digit plus fraction digits |
| `exponentValue` | the integer b |
| `fractionLength` | count of fraction digits |
| `integerLength` | position 1 + b of the point |

The zero fraction case is handled by the same trimming loop.

Script-generated example from `gen.py`:

```
notation: 8.549e2
digits: 8 5 4 9
fraction digits: 3
exponent: 2
point after 3 digits
integer part: 854
fraction part: 9
output: 854.9
```

The traced point position matches the sample answer `854.9`.

## Code

**Input scanner and output buffer.** This block reads input into one string and provides digit and token scanners.

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
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextToken` reads the whole notation as one string. `nextInt` parses digits by index without conversion helpers. The buffer flushes at 128 KiB.

**Point placement.** This block finds the dot and e, then renders the plain decimal.

```nim
let notation = nextToken(inputData, scanPos)
var decimalPoint = 0
var exponentMark = 0
for charIndex in 0..<notation.len:
  if notation[charIndex] == '.':
    decimalPoint = charIndex
  elif notation[charIndex] == 'e':
    exponentMark = charIndex

var digitString = ""
digitString.add notation[0]
for charIndex in (decimalPoint + 1)..<exponentMark:
  digitString.add notation[charIndex]

var exponentValue = 0
for charIndex in (exponentMark + 1)..<notation.len:
  exponentValue = exponentValue * 10 + int(notation[charIndex]) - firstDigitValue

let fractionLength = exponentMark - decimalPoint - 1
var resultText = ""
if exponentValue >= fractionLength:
  resultText.add digitString
  for zeroIndex in 0..<(exponentValue - fractionLength):
    resultText.add '0'
else:
  let integerLength = 1 + exponentValue
  for charIndex in 0..<integerLength:
    resultText.add digitString[charIndex]
  var fractionEnd = digitString.len
  while fractionEnd > integerLength and digitString[fractionEnd - 1] == '0':
    fractionEnd -= 1
  if fractionEnd > integerLength:
    resultText.add '.'
    for charIndex in integerLength..<fractionEnd:
      resultText.add digitString[charIndex]

appendOutput(resultText)
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The digit string is built without integer conversion, so all 100 digits survive. The trimming loop removes trailing zeros only from the fraction.

## Complexity

All work is a small number of passes over a few hundred characters.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Digit parse | one pass over notation | digit string |
| Rendering | one pass over output digits | result string |
| Output | one write per 128 KiB block | block buffer |

Both strings grow with the notation length and the exponent.

| Measure | Big O |
|---|---|
| Time | O(L + b) |
| Space | O(L + b) |

Floating-point conversion would lose digits at 10^100; string placement stays exact.
