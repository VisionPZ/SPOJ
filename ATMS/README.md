## Problem

Read a client count, then that many loan amounts. Each amount is a positive decimal number with at most 30 digits. For every amount, print two lines: the ATM numbers used to receive the loan, then the ATM numbers used to return it. Print each list in decreasing order, or print "No" when the amount cannot be formed.

| Quantity | Bound |
| --- | --- |
| Clients | at most 10000 |
| Loan amount | positive, below 10^30, at most 30 digits |
| ATMs | 100, numbered 0 to 99 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The 30-digit amounts exceed machine integers, so the program works on decimal digits.

## Idea

Write each loan in base minus two, called negabinary here. An even ATM i pays 2^i ducats, and an odd ATM i receives 2^i ducats. Both effects equal (-2)^i, so choosing ATMs means writing the amount as a sum of distinct powers of -2. This is the negabinary representation, with digits 0 and 1. Every integer has exactly one such representation, so the program never searches. The return line uses the representation of the negated amount.

Cost per line: at most 101 halvings of a 40-digit decimal value.

## Why It Works

For even i, (-2)^i = 2^i. For odd i, (-2)^i = -2^i. Each ATM therefore supplies one negabinary digit, and a set digit means that ATM is used.

From a signed remainder v, the next digit r is v modulo 2, and the next remainder is (v - r) / (-2). The program stores only the magnitude in `workDigits` and the sign in `signNegative`. It adds r for a negative remainder, subtracts r for a positive remainder, halves the digits, and flips the sign. A set digit past `lastAtmIndex` needs an ATM outside the room, so the answer is "No".

The program keeps four small pieces of state during each conversion.

| Term | Meaning |
| --- | --- |
| `workDigits` | magnitude of the remaining value, units digit first |
| `signNegative` | sign of that remaining value |
| `oddDigit` | next negabinary digit, equal to the remainder modulo 2 |
| `usedBits` | marks the ATM indices that appear in the answer |

These four values replace a big integer and a search over ATM subsets.

The worked example comes from `gen.py`. It converts 7 by groups of four.

| Value | Quotient | Remainder | Digit 2k | Digit 2k+1 | Next value |
| --- | --- | --- | --- | --- | --- |
| 7 | 1 | 3 | 1 | 1 | 2 |
| 2 | 0 | 2 | 0 | 1 | 1 |
| 1 | 0 | 1 | 1 | 0 | 0 |

The set digits are 0, 1, 3, and 4, so the loan line is "4 3 1 0". The negated amount -7 uses digits 0 and 3, so the return line is "3 0".

## Code

The whole input stream lands in one string before parsing begins.

```nim
{.checks: off.}
{.optimization: speed.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const digitCapacity = 40
const bitCapacity = 128
const lastAtmIndex = 99

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The loop reads every line before any case runs, so no syscall sits inside the case loop. `nextInt` handles the client count only. Amounts can overflow an int, so they need a separate scanner. The pass costs one scan of the input bytes.

The scanner finds the end of a token, then walks back through it.

```nim
proc nextDigits(data: string, position: var int, digits: var array[0..digitCapacity - 1, int]) =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var tokenEnd = position
  while tokenEnd < data.len and data[tokenEnd] >= '0' and data[tokenEnd] <= '9':
    tokenEnd += 1
  for i in 0..<digitCapacity:
    digits[i] = 0
  var digitIndex = 0
  var k = tokenEnd - 1
  while k >= position:
    digits[digitIndex] = int(data[k]) - firstDigitValue
    digitIndex += 1
    k -= 1
  position = tokenEnd
```

Walking back puts the units digit at index 0, which the halving loop needs. Storing digits forward would break every later division. The loop writes at most 40 digits per amount.

One buffer collects every answer and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc digitsAreZero(digits: array[0..digitCapacity - 1, int]): bool =
  for i in 0..<digitCapacity:
    if digits[i] != 0:
      return false
  return true
```

`appendOutput` never writes per number, so the stream layer stays out of the hot path. `digitsAreZero` checks all 40 digits on each halving. The check costs one compare per digit.

The conversion loops over signed remainders and records each negabinary digit.

```nim
proc appendAtmList(valueDigits: array[0..digitCapacity - 1, int], negative: bool) =
  var workDigits = valueDigits
  var signNegative = negative
  var usedBits: array[0..bitCapacity - 1, bool]
  var highestBit = -1
  var bitIndex = 0
  while not digitsAreZero(workDigits):
    let oddDigit = workDigits[0] mod 2
    if oddDigit == 1:
      usedBits[bitIndex] = true
      highestBit = bitIndex
    if signNegative:
      if oddDigit == 1:
        var digitIndex = 0
        while true:
          let raised = workDigits[digitIndex] + 1
          workDigits[digitIndex] = raised mod 10
          if raised < 10:
            break
          digitIndex += 1
    elif oddDigit == 1:
      var digitIndex = 0
      while workDigits[digitIndex] == 0:
        workDigits[digitIndex] = 9
        digitIndex += 1
      workDigits[digitIndex] -= 1
    var carry = 0
    for i in countdown(digitCapacity - 1, 0):
      let current = carry * 10 + workDigits[i]
      workDigits[i] = current div 2
      carry = current mod 2
    signNegative = not signNegative
    bitIndex += 1
  if highestBit > lastAtmIndex:
    appendOutput("No")
  else:
    var firstNumber = true
    for i in countdown(highestBit, 0):
      if usedBits[i]:
        if not firstNumber:
          outputBuffer.add ' '
        appendOutput($(i))
        firstNumber = false
  outputBuffer.add '\n'
```

The loop stops when `workDigits` becomes zero, after at most 101 steps. The sign branch adds or subtracts `oddDigit` before halving, which keeps the division exact for negative remainders. The last loop prints marked indices from `highestBit` down to zero. Each step touches 40 digits.

Each client needs one parse and two conversions.

```nim
let caseCount = nextInt(inputData, scanPos)
var valueDigits: array[0..digitCapacity - 1, int]
for caseIndex in 0..<caseCount:
  nextDigits(inputData, scanPos, valueDigits)
  appendAtmList(valueDigits, false)
  appendAtmList(valueDigits, true)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first call converts the loan, and the second converts its negation. The final write flushes the remaining buffer after the loop. The loop runs once per client.

## Complexity

Reading takes time linear in the input size and holds one input buffer. Each conversion takes O(101 × 40) digit operations, a constant under the bounds. The full run takes O(n × 101 × 40) time and O(input bytes + 40 + 128) space. Enumerating all ATM subsets would take O(2^100) time per client.
