## Problem

The program decrypts a complex-base code. Each case gives a complex number X and a complex base B. The program prints the digits of X in base B, highest digit first and separated by commas. Here |B| is the modulus sqrt(Br² + Bi²), and each digit a satisfies 0 <= a < |B|. The program prints `The code cannot be decrypted.` when no valid digit sequence exists.

The judge bounds every case as follows.

| Quantity | Bound |
|---|---|
| Test cases T | about 100000 |
| Components of X | |Xr|,|Xi| <= 1000000 |
| Components of B | |Br|,|Bi| <= 16 |
| Modulus of B | |B| > 1 |
| Highest digit index n | n <= 100 |
| Time limit | 5 s |
| Memory limit | 1536 MB |

The digit bound comes from the modulus, and the base stays small.

## Idea

The program uses repeated division in a Gaussian-integer numeral system. Each step picks the digit a that makes X - a divisible by B, then replaces X with (X - a)/B. A brute-force search over digit strings would grow exponentially with the digit count.

Each case costs O(log|X|) integer tests.

## Why It Works

For a trial digit a, put u = Xr - a. The quotient (X - a)/B has two parts:

realPart = (u*Br + Xi*Bi) / N

imagPart = (Xi*Br - u*Bi) / N

Here N = Br² + Bi². The digit works exactly when N divides both numerators. The program tests each digit in the allowed range and stops at the first one that works.

Write g = gcd(|Br|,|Bi|) and B = g*(b + i*c), where gcd(|b|,|c|) = 1. The smallest positive real integer divisible by B equals g*(b² + c²). This value is at least |B|. Every allowed digit is strictly below |B|, so two different digits cannot both work. The search therefore finds the unique digit whenever one exists. If no digit works, no representation exists, since every representation must supply such a first digit.

Each division divides the magnitude of X by |B| > 1, so the process reaches zero. When X is nonzero and the quotient is zero, the final digit equals X and is nonzero. The 101-digit cap enforces n <= 100.

The first sample case gives the following divisions.

| Step | X | Chosen digit | Next X |
|---|---|---|---|
| 1 | (-935, 2475) | 18 | (-77, -120) |
| 2 | (-77, -120) | 11 | (8, 0) |
| 3 | (8, 0) | 8 | (0, 0) |

Reading the digits from last to first gives 8,11,18.

## Code

```
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

`nextInt` reads an optional sign, so negative input survives. The scanner walks `inputData` once by index. The cost is linear in the input length.

```
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

The read loop keeps a last line without a newline. `largestDigit` stops at the largest square below `baseNorm`. The zero case stores one digit. The cost is one pass over the input.

```
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

This loop runs at most `maxDigitCount` times. The two `mod` tests compare against zero, so negative numerators cause no error. Each step tests at most 23 digits.

```
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

`k` walks from the highest digit down to zero. The buffer flushes every `flushBlockBytes` bytes, which caps memory. The cost is linear in the output size.

## Complexity

Reading takes O(T) time and space linear in the input size. Each case divides at most about 50 times. Each division tests at most 23 digits. The arithmetic takes O(T log|X|) time with a small constant. The output buffer holds one flush block, so extra space stays constant. A brute-force search over digit strings would take exponential time in the digit count.
