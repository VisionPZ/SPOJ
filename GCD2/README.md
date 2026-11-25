# GCD2 — GCD2 (SPOJ)

<https://www.spoj.com/problems/GCD2/>

## Problem

Compute the greatest common divisor of a small integer and a decimal integer with up to 250 digits.

| item | bound |
|---|---|
| test cases | first input line |
| small value A | 0 to 40000 |
| large value B | A to less than 10^250 |
| judge limit | 1000 ms, 1536 MB |

The large value arrives as text, so machine integers cannot hold it.

Sample input:

```
2
2 6
10 11
```

Sample output:

```
2
1
```

## Idea

Reduce the long number modulo the small number first, like measuring a long rope with a short ruler before comparing lengths. Euclid's algorithm then runs on two small integers. Scanning the digits once costs O(d) per case, and the gcd costs O(log A). Converting the long number to a machine integer would overflow.

| term | meaning |
|---|---|
| `bigDigits` | decimal text of the large value |
| `smallValue` | the small integer A |
| `smallRemainder` | B modulo A, built one digit at a time |
| `gcdValues` | Euclid's algorithm on two small integers |

Modulo reduction keeps every intermediate value below 40000.

## Why It Works

1. A decimal digit scan keeps the remainder below the divisor at every step.
2. The final remainder equals B modulo A by the rules of modular arithmetic.
3. `gcd(A, B)` equals `gcd(A, B mod A)`, since A divides B minus that remainder.
4. Euclid's algorithm reaches gcd after O(log A) division steps.
5. When A is zero, gcd is B, so the trimmed digit text is the answer.

| term | meaning |
|---|---|
| `remainderOfDigits` | left-to-right digit scan with modulo |
| `trimmedDigits` | removes leading zeroes for the A = 0 case |
| `appendOutput` | buffered line writer |

The modulo identity removes the need for big-integer storage.

A worked example for A = 6 and B = 123456789:

```
start remainder 0
digit 1 -> 1
digit 2 -> 12 mod 6 = 0
digit 3 -> 3
digit 4 -> 34 mod 6 = 4
digit 5 -> 45 mod 6 = 3
digit 6 -> 36 mod 6 = 0
digit 7 -> 7 mod 6 = 1
digit 8 -> 18 mod 6 = 0
digit 9 -> 9 mod 6 = 3
gcd(6, 3) = 3
```

The trace reaches the same answer as reducing the whole number at once.

## Code

**Input and scanner.** The hand reader loads the case count and both operands.

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

proc nextDigits(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var token = ""
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    token.add data[pos]
    pos += 1
  return token
```

The scanner skips spaces and line breaks.
The digit reader returns the long operand as text.
Both procs advance the same scan position.

**Small-number arithmetic.** Modulo reduction and Euclid stay within machine integers.

```nim
proc remainderOfDigits(digits: string, divisor: int): int =
  var remainder = 0
  for digitChar in digits:
    remainder = (remainder * 10 + int(digitChar) - firstDigitValue) mod divisor
  return remainder

proc gcdValues(firstValue: int, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let nextRemainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = nextRemainder
  return leftValue

proc trimmedDigits(digits: string): string =
  var firstIndex = 0
  while firstIndex < digits.len - 1 and digits[firstIndex] == '0':
    firstIndex += 1
  return digits[firstIndex .. digits.len - 1]
```

The remainder never reaches the divisor.
The gcd loop uses at most a few dozen iterations.
Trimming handles the A = 0 branch.

**Driver and output.** Each pair yields one buffered line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pairCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. pairCount - 1:
  let smallValue = nextInt(inputData, scanPos)
  let bigDigits = nextDigits(inputData, scanPos)
  if smallValue == 0:
    appendOutput(trimmedDigits(bigDigits))
  else:
    let smallRemainder = remainderOfDigits(bigDigits, smallValue)
    appendOutput($gcdValues(smallValue, smallRemainder))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero branch prints the trimmed large value.
Other branches print the small gcd.
The buffer flushes once after the loop.

## Complexity

The digit scan dominates each case.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| digit reduction | one pass over up to 250 digits | constant |
| Euclid | O(log A) divisions | constant |
| output | one line per pair | block buffer |

Long operands never expand beyond their input text.

| measure | Big O |
|---|---|
| time | O(t * d + t log A) with d at most 250 |
| space | O(d) for the input text |

A big-integer division on 250 digits costs far more than this digit scan.

The modulo identity keeps the whole solution small and fast.
