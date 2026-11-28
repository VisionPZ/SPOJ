# CRYPTO3 — The Bytelandian Cryptographer (Act III) (SPOJ)

<https://www.spoj.com/problems/CRYPTO3/>

## Problem

An input integer counts the values not expressible as a non-negative combination of two primes. From that count, compute how many smaller integers are coprime to the primes' product.

Input: one positive integer of at most 99 decimal digits.

Output: the hidden value, printed as a decimal integer.

The input bounds are small:

| Item | Bound |
| --- | --- |
| Input digits | at most 99 |
| Inputs per file | one |
| Time limit | 200 ms |
| Memory limit | 1536 MB |

The input is far larger than a machine integer, so the program works on decimal digits.

The sample input and output:

```
1
```

```
2
```

## Idea

Print twice the input, like doubling a price written on paper one digit at a time. The hidden number is exactly double the count the cryptographer revealed.

The program stores the decimal digits and walks them from right to left. Each step doubles a digit, adds the carry, writes the units digit, and passes the tens digit on.

Doubling costs O(d) time for d digits. Factoring the 99-digit product would cost far more and is not needed.

A card-and-carry pass replaces any number theory at run time.

## Why It Works

The two quantities follow from the two primes p and q.

1. For coprime coins p and q, the Frobenius (gap) count is `(p - 1)(q - 1) / 2`.
2. Euler's totient (count of coprime residues) of `p × q` is `(p - 1)(q - 1)`.
3. The second value is exactly twice the first, whatever the primes are.
4. Doubling from the least significant digit keeps every intermediate value below 20, so one carry bit suffices.

The digit pass uses the following terms:

| Term | Meaning |
| --- | --- |
| `numberDigits` | input digits in input order |
| `doubledDigits` | output digits with one spare leading slot |
| `doubledValue` | `digit × 2 + carry` |
| `carry` | tens digit passed to the next place |
| leading zero trim | removes zeros before the first real digit |

A carry after the last digit becomes a new leading digit. The print loop keeps at least one digit even when the result is zero.

A script doubles a five-digit input digit by digit:

```
input  1 2 3 4 5
digit  5 -> 5*2+0 = 10 -> write 0 carry 1
digit  4 -> 4*2+1 =  9 -> write 9 carry 0
digit  3 -> 3*2+0 =  6 -> write 6 carry 0
digit  2 -> 2*2+0 =  4 -> write 4 carry 0
digit  1 -> 1*2+0 =  2 -> write 2 carry 0
output 2 4 6 9 0
```

The sample input 1 gives 2, matching the sample output.

## Code

**Input and digits.** The scanner keeps the decimal digits in little-endian input order.

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

The read loop gathers the whole stream once. The skip loop finds the first digit. Parsing one number visits each digit once.

**Doubling pass.** The loop walks the digits backward and writes into a result buffer.

```nim
var doubledDigits = newSeq[byte](numberDigits.len + 1)
var carry = 0
for j in 0..<numberDigits.len:
  let k = numberDigits.len - 1 - j
  let doubledValue = numberDigits[k] * 2 + byte(carry)
  doubledDigits[doubledDigits.len - 1 - j] = doubledValue mod 10
  carry = int(doubledValue div 10)
doubledDigits[0] = byte(carry)
```

One spare slot holds the final carry. Each step stores the units digit and passes the tens digit. The loop costs O(d) time and O(d) space.

**Output.** Leading zeros are skipped, and one write emits the answer.

```nim
var l = 0
while l < doubledDigits.len - 1 and doubledDigits[l] == 0:
  l += 1

var outputBuffer = ""
for j in l..<doubledDigits.len:
  outputBuffer.add char(int(doubledDigits[j]) + 48)
outputBuffer.add '\n'
stdout.write outputBuffer
```

The trim loop stops before the last slot, so zero still prints as one digit. The constant 48 converts a digit back to a character. One write flushes the result.

## Complexity

Parsing and doubling each visit every digit once.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Digit parse | O(d) | O(d) |
| Doubling | O(d) | O(d) |
| Output | one write for the answer | O(d) |
| Total | O(d) | O(d) |

At the 99-digit limit, the buffers hold 100 bytes each.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(d) for d input digits |
| Space | O(d) for d input digits |

Big-integer multiplication would add library overhead and still cost O(d).
