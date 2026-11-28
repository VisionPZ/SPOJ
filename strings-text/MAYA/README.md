# MAYA — Numeral System of the Maya (SPOJ)

<https://www.spoj.com/problems/MAYA/>

## Problem

Maya numbers stack dots and dashes into places, and each place carries its own weight. The third place jumps by 18 instead of 20.

Read numbers until a digit count of zero. Each number starts with its digit count `n`. The next `n` lines show one digit each, from the highest place down to the units place.

A dot counts one, a dash counts five, and `S` counts zero. Print one decimal value per number.

The bounds and judge limits:

| Item | Bound |
| --- | --- |
| Digits per number | at most 7 |
| Value per digit | 0 to 19 |
| Number count | until `n = 0` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Seven places keep every answer below 1.2 billion.

The sample case:

```
1
..

5
... -
. - -
S
S
S

0
```

```
2
1231200
```

## Idea

Count the marks on each row, then multiply by that row's weight.

The program reads a tally sheet: dots and dashes are tally marks, and `S` means an empty row. A hand scanner counts those symbols directly in the input buffer. Each digit becomes `dots + 5 * dashes`, or zero when `S` appears.

A running total adds digit times place value.

Each digit costs one symbol count and one multiply-add, so one number costs O(n) for `n` digits. Splitting each line into tokens allocates one object per symbol, which the scanner avoids.

## Why It Works

Five facts prove the conversion exact.

1. A dash stands for five and a dot for one, so counting each symbol gives the digit value.
2. The letter `S` marks zero. The scanner returns zero before any dot or dash count is used.
3. The third place jumps from 20 to 360, which is 18 times 20. Every later place multiplies by 20.
4. The input lists digits from highest to lowest, so digit `j` uses `placeValues[digitCount - 1 - j]`.
5. Seven places cap the largest value at 57600000 in the top place, which keeps every total inside a 64-bit integer.

The constants and their roles:

| Term | Meaning |
| --- | --- |
| `placeValues` | weights 1, 20, 360, 7200, 144000, 2880000, 57600000 |
| `dotSymbol` | character counting as one |
| `dashSymbol` | character counting as five |
| `zeroSymbol` | shell character marking zero |
| `dashValue` | multiplier for each dash |
| `decimalValue` | running sum of digit times place value |

These weights need no multiplication at run time, because the table stores them directly.

A script converts the five-digit sample number place by place:

```
top    ... -   digit 8   weight 144000   product 1152000
second . - -   digit 11  weight 7200     product 79200
third  S        digit 0   weight 360      product 0
fourth S        digit 0   weight 20       product 0
bottom S        digit 0   weight 1        product 0
sum    1231200
```

The products sum to 1231200, which is the second output line of the sample.

## Code

**Constants.** Symbol codes and flush size live in one block.

```nim
const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  dotSymbol = '.'
  dashSymbol = '-'
  zeroSymbol = 'S'
  dashValue = 5
```

The scanner uses these codes instead of literals. The flush size caps the output buffer at 256 KiB.

**Count and advance.** Two helpers read the digit count and skip to the next line.

```nim
proc nextDigitCount(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  result = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i

proc advanceToNextLine(inputData: string, i: var int) =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '\n':
    inc i
  if i < dataLength:
    inc i
```

The first scanner stops at the newline ending the count line. The second leaves `i` at the first symbol line. Both cost one line length each.

**Symbol counting.** One digit line becomes a value without token objects.

```nim
proc readSymbolValue(inputData: string, i: var int): int =
  let dataLength = inputData.len
  var dotCount = 0
  var dashCount = 0
  var shellFound = false
  while i < dataLength and inputData[i] != '\n':
    let currentSymbol = inputData[i]
    if currentSymbol == dotSymbol:
      inc dotCount
    elif currentSymbol == dashSymbol:
      inc dashCount
    elif currentSymbol == zeroSymbol:
      shellFound = true
    inc i
  if i < dataLength:
    inc i
  if shellFound:
    return 0
  result = dotCount + dashCount * dashValue
```

The loop reads exactly one digit line and ignores the spaces between symbols. The shell test returns zero before any count is used. Counting costs one pass over that line.

**Place values and driver.** Seven fixed weights convert each number.

```nim
const placeValues = [1'i64, 20, 360, 7200, 144000, 2880000, 57600000]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
var outputBuffer = ""
while true:
  let digitCount = nextDigitCount(inputData, i)
  if digitCount == 0:
    break
  advanceToNextLine(inputData, i)
  var decimalValue = 0'i64
  var j = 0
  while j < digitCount:
    let symbolValue = readSymbolValue(inputData, i)
    decimalValue += int64(symbolValue) * placeValues[digitCount - 1 - j]
    inc j
  outputBuffer.add $decimalValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The outer loop ends when `nextDigitCount` returns zero at the end marker. The inner loop runs exactly `digitCount` times. Output flushes every 262144 bytes and caps the buffer at one block.

## Complexity

The work follows the input bytes, not the number of symbols per token.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Per number | O(n), with `n <= 7` | constant |
| Output flush | O(output bytes) | one output block |

The place-value table costs constant space.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + output bytes + total digits) |
| Space | O(input bytes + one block) |

A reader that splits each line into tokens allocates one object per symbol. The hand scanner only counts characters.
