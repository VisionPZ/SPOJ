# CERC07N — Weird Numbers (SPOJ)

<https://www.spoj.com/problems/CERC07N/>

## Problem

Convert integers between decimal notation and positional notation with a negative base. Each query names the direction, the positive base radius, and one number; print the converted value on its own line.

A query starts with `to-R` followed by a decimal integer, or `from-R` followed by digits written in base `-R`. The line `end` closes the input. Decimal output keeps a minus sign only for negative values.

| item | bound |
|---|---|
| radius R | 2 to 10 |
| decimal value | -1000000 to 1000000 |
| base representation | no leading zeros |
| judge limit | 1549 ms, 1536 MB |

The digit positions alternate sign, so value grows with alternating powers of the radius.

Sample input:

```
to-2 10
from-2 1010
to-10 10
to-10 -10
from-10 10
end
```

Sample output:

```
11110
-10
190
10
-10
```

## Idea

Treat a negative base like a regular place-value system whose places flip sign, the way a checkered board alternates colors. Repeated division by the positive radius extracts one digit at a time. Fix the remainder to stay nonnegative, then divide by the negative base to advance one place. Reading from decimal reverses the process with a running power sum. This keeps every step in 64-bit integers and needs no search.

## Why It Works

1. A digit at position `P` contributes `digit * (-R)^P` to the total.
2. Every integer has one representation without leading zeros.
3. Choosing the remainder in `0..R-1` makes the next quotient an exact integer division by `-R`.
4. The quotient magnitude shrinks, so repeated division terminates.
5. A running power sum rebuilds the decimal value from any valid digit string.

| term | meaning |
|---|---|
| `baseValue` | the negative radix read from the query |
| `positiveBase` | the absolute radix, used for remainders |
| `remainder` | the next digit, forced into `0..positiveBase-1` |
| `digitText` | the digit string of a `from` query |
| `value` | the running decimal value during reconstruction |

The two directions invert each other, so checking a round trip verifies both.

Converting decimal 10 to base -2 gives:

```
10 = 0 + (-2) * (-5)
-5 = 1 + (-2) * 3
 3 = 1 + (-2) * (-1)
-1 = 1 + (-2) * 1
 1 = 1 + (-2) * 0
digits from last to first: 1 1 1 1 0
```

The trace yields `11110`, which matches the first sample answer.

## Code

**Input and parsing.** The reader loads all lines and splits each command into its parts.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCommand(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc nextSigned(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    return -value
  return value

proc nextDigitText(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digits = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digits.add data[pos]
    pos += 1
  return digits
```

The command scanner reads letters only, so `to-2` splits into `to` and `-2`.
The signed scanner handles negative decimal values.
The digit scanner keeps base representations as text to avoid overflow.

**Conversion.** Division extracts digits; a power sum rebuilds the decimal value.

```nim
proc convertToNegabase(decimalValue: int64, baseValue: int64): string =
  if decimalValue == 0:
    return "0"
  let positiveBase = -baseValue
  var current = decimalValue
  var reversedDigits = ""
  while current != 0:
    var remainder = current mod positiveBase
    if remainder < 0:
      remainder = remainder + positiveBase
    reversedDigits.add char(int(remainder) + 48)
    current = (current - remainder) div baseValue
  var forwardDigits = ""
  for index in 0 .. reversedDigits.len - 1:
    forwardDigits.add reversedDigits[reversedDigits.len - 1 - index]
  return forwardDigits

proc convertFromNegabase(digitText: string, baseValue: int64): int64 =
  var value: int64 = 0
  for index in 0 .. digitText.len - 1:
    value = value * baseValue + int64(int(digitText[index]) - 48)
  return value
```

The quotient is exact because the remainder is removed first.
Collected digits come out in reverse place order and are flipped once.
Reconstruction multiplies by the negative base at each place.

**Output driver.** Each query writes one line through the block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let command = nextCommand(inputData, scanPos)
  if command == "" or command == "end":
    break
  let baseValue = nextSigned(inputData, scanPos)
  if command == "to":
    let decimalValue = nextSigned(inputData, scanPos)
    appendOutput(convertToNegabase(decimalValue, baseValue))
  else:
    let digitText = nextDigitText(inputData, scanPos)
    appendOutput($convertFromNegabase(digitText, baseValue))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop stops at `end` or when no command letters remain.
Both directions append their answer through the same buffer.
One final write empties the remaining bytes.

## Complexity

Each query costs a number of steps proportional to its digit count.

| phase | time | space |
|---|---|---|
| input read | one pass over query text | one input string |
| conversion | one step per output digit | digit string |
| output | one write per block | block buffer |

Every phase scales with the length of one number, not with the query count at once.

| measure | Big O |
|---|---|
| time per query | O(digits) |
| space | O(digits) plus input text |

Trying every candidate digit string would grow exponentially with the digit count. The remainder rule turns conversion into a short linear walk.
