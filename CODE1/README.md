# CODE1 — Secret Code (SPOJ)

<https://www.spoj.com/problems/CODE1/>

## Problem

A spy writes numbers as strings of digits in a strange complex-number base. The code hides a Gaussian integer (a number with a real part and an imaginary part) inside another complex number.

Input: one integer for the case count, then four integers per case. The first two give X, and the last two give base B.

Output: the digits of X in base B, highest digit first and separated by commas. Print `The code cannot be decrypted.` when no valid digit string exists.

The judge bounds every case as follows:

| Item | Bound |
| --- | --- |
| Test cases T | about 100000 |
| Parts of X | absolute value at most 1000000 |
| Parts of B | absolute value at most 16 |
| Modulus of B | greater than 1 |
| Highest digit index n | at most 100 |
| Time limit | 5 s |
| Memory limit | 1536 MB |

The digit bound comes from the modulus, and the base stays small.

The sample input and output:

```
4
-935 2475 -11 -15
1 0 -3 -2
93 16 3 2
191 -192 11 -12
```

```
8,11,18
1
The code cannot be decrypted.
16,15
```

## Idea

Convert the number by repeated division, like rewriting a decimal number in a new base. Here the base is a point on a grid, so each division tests candidate digits until one makes the remainder divisible.

The program picks a digit a that makes `X - a` divisible by B, records it, and divides by B. Each step tests at most 23 digits because the modulus is at most 23.

Each division shrinks the magnitude of X, so the process ends after O(log |X|) steps. Guessing whole digit strings would grow exponentially with the digit count.

Repeated division finds the unique digit at each step.

## Why It Works

A digit works exactly when both parts of the quotient are integers.

1. Write N for `Br² + Bi²`, the squared modulus (size squared) of the base.
2. For a trial digit a, the real part is `(u × Br + Xi × Bi) / N`, with `u = Xr - a`.
3. The imaginary part is `(Xi × Br - u × Bi) / N`, with the same u.
4. The digit works when N divides both numerators. The program tests digits from 0 upward and stops at the first hit.

The uniqueness argument uses a common factor g:

| Term | Meaning |
| --- | --- |
| `N` | `Br² + Bi²`, the squared modulus |
| `largestDigit` | largest square strictly below N |
| `g` | gcd (greatest common divisor) of `|Br|` and `|Bi|` |
| smallest divisible real integer | `g × (b² + c²)`, at least the modulus |
| `maxDigitCount` | cap of 101 digits |

Every allowed digit is below the modulus, so two digits cannot both work. When no digit works, no representation exists.

A script traces the first sample case with base `-11 -15`:

| Step | X | Digit | Next X |
| --- | --- | --- | --- |
| 1 | `(-935, 2475)` | 18 | `(-77, -120)` |
| 2 | `(-77, -120)` | 11 | `(8, 0)` |
| 3 | `(8, 0)` | 8 | `(0, 0)` |

Reading the digits from last to first gives `8,11,18`, the sample answer.

## Code

**Scanner and constants.** The scanner keeps a leading minus sign, so negative coordinates survive.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxDigitCount = 101

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var negative = false
  if i < inputData.len and inputData[i] == '-':
    negative = true
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - firstDigitValue
    i = i + 1
  if negative: return -value
  return value
```

The digit value comes from the constant 48. The scan walks the buffer once by index. Each case reads exactly four integers.

**Case setup.** The digit range follows from the squared modulus, and zero gets one digit.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
var digits: array[maxDigitCount + 1, int]
for j in 1 .. caseCount:
  var currentReal = nextInt(inputData, i)
  var currentImag = nextInt(inputData, i)
  var baseReal = nextInt(inputData, i)
  var baseImag = nextInt(inputData, i)
  var baseNorm = baseReal * baseReal + baseImag * baseImag
  var largestDigit = 0
  while (largestDigit + 1) * (largestDigit + 1) < baseNorm: largestDigit = largestDigit + 1
  var digitCount = 0
  var failed = false
  if currentReal == 0 and currentImag == 0:
    digits[0] = 0
    digitCount = 1
```

The read loop keeps a last line that lacks a newline. `largestDigit` stops at the largest square below `baseNorm`. The zero case stores a single digit and skips division.

**Division loop.** Each trial digit is tested against both divisibility conditions.

```nim
    while true:
      var chosenDigit = -1
      var chosenReal = 0
      var chosenImag = 0
      for digit in 0 .. largestDigit:
        var remainderReal = (currentReal - digit) * baseReal + currentImag * baseImag
        var remainderImag = currentImag * baseReal - (currentReal - digit) * baseImag
        if remainderReal mod baseNorm == 0 and remainderImag mod baseNorm == 0:
          chosenDigit = digit
          chosenReal = remainderReal div baseNorm
          chosenImag = remainderImag div baseNorm
          break
      if chosenDigit < 0:
        failed = true
        break
      digits[digitCount] = chosenDigit
      digitCount = digitCount + 1
      if chosenReal == 0 and chosenImag == 0: break
      if digitCount >= maxDigitCount:
        failed = true
        break
      currentReal = chosenReal
      currentImag = chosenImag
```

The loop runs at most `maxDigitCount` times. The two `mod` tests compare against zero, so negative numerators cause no error. Each step tests at most 23 digits.

**Output.** Digits print from the highest index down to zero.

```nim
  if failed:
    outputBuffer.add "The code cannot be decrypted.\n"
  else:
    var k = digitCount - 1
    while k >= 0:
      if k < digitCount - 1: outputBuffer.add ','
      outputBuffer.add $digits[k]
      k = k - 1
    outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

Index k walks from the last recorded digit down to zero. The comma check avoids a separator after the final digit. The buffer flushes every 128 KiB.

## Complexity

Each division tries a bounded set of digits and shrinks the number.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Digit range | O(1) trial squares | O(1) |
| Division steps | O(log \|X\|) steps per case | O(1) per step |
| Output | one write per 128 KiB block | 128 KiB |
| Total per case | O(log \|X\| × modulus) | O(101) digits |

At the largest base, the digit loop tests at most 23 values.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(T × log \|X\| × \|B\|) for T cases |
| Space | O(1) working space |

Guessing complete digit strings would take exponential time in the digit count.
