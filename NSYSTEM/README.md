# NSYSTEM — Numeral System (SPOJ)

<https://www.spoj.com/problems/NSYSTEM/>

## Problem

Two strings built from `m`, `c`, `x`, `i` and digits 2 to 9 encode numbers from 1 to 9999. Add the two encoded numbers and print the one string that encodes their sum.

Each test line holds two MCXI-strings separated by a space. The first input line holds the number of test lines. Every printed line holds one string and nothing else.

| item | bound |
|---|---|
| test lines | at most 500 |
| encoded value | 1 to 9999 |
| sum of two values | at most 9999 |
| judge limit | 0.181 s, 1536 MB |

The four letters always appear in the order m, c, x, i, and each appears at most once.

Sample input:

```
10
xi x9i
i 9i
c2x2i 4c8x8i
m2ci 4m7c9x8i
9c9x9i i
i 9m9c9x8i
m i
i m
m9i i
9m8c7xi c2x8i
```

Sample output:

```
3x
x
6cx
5m9c9x9i
m
9m9c9x9i
mi
mi
mx
9m9c9x9i
```

## Idea

Reading an MCXI-string is like counting coins in four labelled pockets: the letter names the pocket and a digit gives the coin count. Decode each string into an integer, add the integers, then rebuild the unique string from four decimal digits. Positional decoding and encoding touch each character once. Enumerating all valid strings for every test would be far slower. A short walk over each string is enough.

## Why It Works

1. The letters m, c, x, i carry the place values 1000, 100, 10 and 1.
2. A digit before a letter multiplies that letter's place value.
3. A letter with no prefix contributes exactly one copy of its place value.
4. Adding the contributions gives the number encoded by the string.
5. Splitting the sum by the same four places rebuilds the unique MCXI-string.

| term | meaning |
|---|---|
| `mcxiValue` | sum decoded from one input string |
| `multiplier` | prefix digit, or one when no digit is present |
| `placeIndex` | position in the order m, c, x, i |
| `appendMcxi` | writer that emits the encoded result |

Each place contributes at most nine copies, so one digit per place always suffices.

A generated example decodes `c2x2i` as 100 + 20 + 2 = 122 and `4c8x8i` as 400 + 80 + 8 = 488. Their sum is 610. Splitting 610 gives 6 hundreds, 1 ten and 0 ones, so the output is `6cx`.

The sum never exceeds 9999, so four places hold every result. No rounding enters the calculation.

## Code

**Input and token reading.** The hand reader loads stdin, then pulls integers and whitespace-delimited strings.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Token reading skips spaces and newline bytes.
The scan position advances past each consumed token.

**Decoding.** One pass over a string accumulates its place values.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc mcxiValue(token: string): int =
  var total = 0
  var index = 0
  while index < token.len:
    var multiplier = 1
    if token[index] >= '2' and token[index] <= '9':
      multiplier = int(token[index]) - 48
      index += 1
    case token[index]
    of 'm': total += multiplier * 1000
    of 'c': total += multiplier * 100
    of 'x': total += multiplier * 10
    of 'i': total += multiplier
    else: discard
    index += 1
  return total
```

A digit is read only when it comes before a letter.
The output buffer flushes once it reaches the block size.

**Encoding and driver.** Four place digits rebuild each answer string.

```nim
proc appendMcxi(value: int) =
  var text = ""
  var placeIndex = 0
  while placeIndex < 4:
    var place = 1000
    case placeIndex
    of 1: place = 100
    of 2: place = 10
    of 3: place = 1
    else: discard
    var digit = (value div place) mod 10
    if digit > 1:
      text.add chr(48 + digit)
    if digit > 0:
      case placeIndex
      of 0: text.add 'm'
      of 1: text.add 'c'
      of 2: text.add 'x'
      of 3: text.add 'i'
      else: discard
    placeIndex += 1
  appendOutput(text)

let specificationCount = nextInt(inputData, scanPos)
for specificationIndex in 0 .. specificationCount - 1:
  let firstNumber = mcxiValue(nextToken(inputData, scanPos))
  let secondNumber = mcxiValue(nextToken(inputData, scanPos))
  appendMcxi(firstNumber + secondNumber)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A digit of two or more is printed before its letter.
The driver writes every result through one buffered path.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| decode | one pass per string | constant |
| encode | four places per result | one output string |

| measure | Big O |
|---|---|
| time per test line | O(length of its two strings) |
| space | O(size of input) |

Enumerating every valid string for each sum would examine thousands of candidates instead of a handful of characters.

Each step touches only a few characters, so the work stays proportional to the input size.
