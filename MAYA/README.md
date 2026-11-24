## Problem

Convert Maya numbers to decimal integers. Each number starts with its digit count n. The next n lines show one digit each, from the highest position down to the units position. A dot counts one, a dash counts five, and the letter S counts zero. Symbols on a digit line use spaces as separators, so a line such as ... - holds three dots and one dash. A blank line follows each number, and n = 0 ends the input. Print one decimal value per line.

The bounds and judge limits are:

| Item | Bound |
| --- | --- |
| Digits per number | n ≤ 7 |
| Value per digit | 0 to 19 |
| Number count | until n = 0 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

Seven digits keep every answer below 1.2 billion.

## Idea

The Maya system uses base 20, but the third position multiplies by 18 instead of 20. The weight of a position is called its place value. We store the seven place values once, then read the digits from the top of each number downward. Each step adds the digit times its place value to a running total. Splitting each digit line into tokens would allocate an object per symbol, while a hand scanner counts characters in the input buffer.

Each digit costs one symbol count and one multiply-add, so one number costs O(n) for its n digits.

## Why It Works

A dash stands for five and a dot stands for one, so a count of each symbol gives the digit value. The letter S marks zero. The third position jumps from 20 to 360, which is 18 times 20. Every later position multiplies by 20, so the place values are 1, 20, 360, 7200, 144000, 2880000, and 57600000.

The input lists digits from the highest position down. For a number with `digitCount` digits, the digit at position `j` uses place value `placeValues[digitCount - 1 - j]`. The total is the sum of each symbol's value times that weight.

A script-generated example uses the five-digit sample number:

| Position | Symbol line | Digit | Weight | Product |
| --- | --- | --- | --- | --- |
| top | ... - | 8 | 144000 | 1152000 |
| second | . - - | 11 | 7200 | 79200 |
| third | S | 0 | 360 | 0 |
| fourth | S | 0 | 20 | 0 |
| bottom | S | 0 | 1 | 0 |

The products sum to 1231200, the second line of the sample output.

## Code

The constants fix the scanner radix, the flush size, and the symbol codes:

```nim
const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  dotSymbol = '.'
  dashSymbol = '-'
  zeroSymbol = 'S'
  dashValue = 5
```

The scanner reads the digit count and stops at `dataLength`, the buffer length. It skips blank separator lines, so an empty line cannot shift the digits. The scan costs O(input bytes).

```nim
proc nextDigitCount(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  result = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i
```

This step stops at the newline that ends the digit-count line. It leaves the scanner at the first symbol line. The step costs one line length.

```nim
proc advanceToNextLine(inputData: string, i: var int) =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '\n':
    inc i
  if i < dataLength:
    inc i
```

The loop reads exactly one digit line, whose length is at most about 14 symbols. Counting characters ignores the spaces between symbols. The shell test returns zero before any dot or dash is used.

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

Seven entries cover the largest legal number. The final weight is 57600000, twenty times 2880000. The table costs constant space.

```nim
const placeValues = [1'i64, 20, 360, 7200, 144000, 2880000, 57600000]
```

The outer loop ends when `nextDigitCount` returns zero at the end marker. The inner loop runs exactly `digitCount` times, so it reads one line per digit. Output flushes every 262144 bytes, which caps the buffer at one block.

```nim
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

## Complexity

Input scanning takes O(input bytes). Each number reads at most seven digit lines, so the conversion is constant time per number. Output flushing takes O(output bytes).

Total time is O(input bytes + output bytes + total digits). Total space is O(input bytes + block bytes).

The cost splits into three phases.

| Phase | Time | Extra space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Per number | O(n), n ≤ 7 | constant |
| Output flush | O(output bytes) | one output block |

A reader that splits each line into tokens allocates one object per symbol. The hand scanner only counts characters and allocates no tokens.
