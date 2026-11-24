## Problem

Read one positive integer supplied by a cryptographer. The integer counts the positive values that cannot be written as `a·p + b·q` for two fixed primes and non-negative integers `a` and `b`. Print the count of positive integers below `p·q` that share no factor with `p·q`. The input has at most 99 decimal digits.

| Quantity | Bound |
| --- | --- |
| Input digits | at most 99 |
| Inputs per file | one |
| Time limit | 200 ms |
| Memory limit | 1536 MB |

The input is far larger than a machine integer, so the program works on decimal digits.

## Idea

Print twice the input. The count of non-representable values is `(p−1)(q−1)/2`, and the requested count is Euler's function `(p−1)(q−1)`. Their ratio is two. Doubling a decimal string costs O(d) for d digits.

Factoring the 99-digit product would cost far more and is not needed.

## Why It Works

For two coprime coins `p` and `q`, the Frobenius count of gaps equals `(p−1)(q−1)/2`. Euler's totient of the product of two distinct primes is `(p−1)(q−1)`. The second value is exactly twice the first.

The program multiplies by two from the least significant digit. Each step computes `digit·2 + carry`, stores the units digit, and passes the tens digit to the next place. A carry after the last digit becomes a new leading digit. Leading zeros are removed before printing.

## Code

The whole input is read once, and the scan starts at the first digit.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
while i < inputData.len and inputData[i] <= ' ':
  i += 1

var numberDigits = newSeq[byte]()
while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
  numberDigits.add byte(int(inputData[i]) - 48)
  i += 1
```

The scanner keeps decimal digits in little-endian input order. Parsing one number visits each digit once.

The doubling pass walks the digits backwards and writes the result into a second buffer.

```nim
var doubledDigits = newSeq[byte](numberDigits.len + 1)
var carry = 0
for j in 0..<numberDigits.len:
  let k = numberDigits.len - 1 - j
  let doubledValue = numberDigits[k] * 2 + byte(carry)
  doubledDigits[doubledDigits.len - 1 - j] = doubledValue mod 10
  carry = int(doubledValue div 10)
doubledDigits[0] = byte(carry)

var l = 0
while l < doubledDigits.len - 1 and doubledDigits[l] == 0:
  l += 1

var outputBuffer = ""
for j in l..<doubledDigits.len:
  outputBuffer.add char(int(doubledDigits[j]) + 48)
outputBuffer.add '\n'
stdout.write outputBuffer
```

One spare slot holds the final carry. The loop keeps at least one digit even when the result is zero. Output is written once.

## Complexity

Parsing takes O(d) time and O(d) space. Doubling takes O(d) time and O(d) space. Total time and space are O(d) for d input digits. Big-integer multiplication would add library overhead and still cost O(d).
