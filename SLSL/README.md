# SLSL — ConghaiSolon (SPOJ)

<https://www.spoj.com/problems/SLSL/>

## Problem

Add two positive integers and print their sum.
Each operand may contain as many as 100000 digits, and may carry leading zeros.

The input is one line with the two integers separated by a space.
Print the sum as one decimal integer without leading zeros.

| Item | Bound |
|---|---|
| Operand length | up to 100000 digits |
| Test cases | one pair |
| Judge limit | 1000 ms |

Fixed-width integer types cannot hold operands of this size.

Sample input:

```
5 08
```

Sample output:

```
13
```

The leading zero in the second operand does not appear in the answer.

## Idea

Picture adding two long columns of digits on paper from right to left.

Take one digit from each operand, add any carried one, and store the unit digit.
Pass the tens part to the next column.
Reverse the stored digits at the end and drop extra leading zeros.

Column addition touches each input digit once and needs no big-integer library.

## Why It Works

1. Summing right to left keeps every carry local to the next column.
2. A column total never exceeds 19, so one carry digit is enough.
3. Reversing stored digits restores normal most-significant-first order.
4. Removing surplus zeros yields the canonical form, as with 08 becoming 8.

| Term | Meaning |
|---|---|
| `sumDigits` | reversed digits of the running sum |
| `columnTotal` | two operand digits plus the incoming carry |
| `storedCount` | number of valid digits after the final column |

The algorithm matches paper addition exactly, so the result is exact.

Script-generated example from `gen.py`:

```
5 8 13
999 1 1000
458 937 1395
```

Each traced line lists both operands and their exact sum.

## Code

**Input and buffer.** This block reads the line, scans tokens, and defines buffered output.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

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

`nextToken` keeps all digits intact as text.
`appendOutput` flushes once the buffer reaches 128 KiB.
No operand is converted to a machine integer.

**Column addition.** This block adds digits from right to left and prints the sum.

```nim
let firstToken = nextToken(inputData, scanPos)
let secondToken = nextToken(inputData, scanPos)
var longestLength = firstToken.len
if secondToken.len > longestLength:
  longestLength = secondToken.len

var sumDigits: seq[char] = @[]
sumDigits.setLen(longestLength + 1)
var firstPos = firstToken.len - 1
var secondPos = secondToken.len - 1
var storedCount = 0
var carry = 0
while firstPos >= 0 or secondPos >= 0 or carry > 0:
  var columnTotal = carry
  if firstPos >= 0:
    columnTotal += int(firstToken[firstPos]) - firstDigitValue
    firstPos -= 1
  if secondPos >= 0:
    columnTotal += int(secondToken[secondPos]) - firstDigitValue
    secondPos -= 1
  sumDigits[storedCount] = char(columnTotal mod 10 + firstDigitValue)
  storedCount += 1
  carry = columnTotal div 10

while storedCount > 1 and sumDigits[storedCount - 1] == char(firstDigitValue):
  storedCount -= 1
var sumText = ""
for index in countdown(storedCount - 1, 0):
  sumText.add sumDigits[index]
appendOutput(sumText)
appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop continues while digits remain or a carry persists.
The result array has room for one extra carry digit.
Trailing zeros in the stored array become leading zeros after reversal.

## Complexity

Each input digit participates in exactly one column addition.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Addition | one pass over operand digits | result digits |
| Output | one write per 128 KiB block | block buffer |

Memory grows only with operand length and the buffered result.

| Measure | Big O |
|---|---|
| Time | O(D) |
| Space | O(D) |

Converting either operand to a fixed-width integer overflows beyond 19 digits.
