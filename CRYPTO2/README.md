# CRYPTO2 — The Bytelandian Cryptographer (Act II) (SPOJ)

<https://www.spoj.com/problems/CRYPTO2/>

## Problem

Each input is a three-digit number that had one subtracted from it. Print the original number, keeping three digits and allowing 1000.

Input: one encrypted value, from `000` to `999`.

Output: the original value, padded to three digits. Print `1000` when the original needs four digits.

The judge bounds are small:

| Item | Bound |
| --- | --- |
| Encrypted inputs | `000` to `999` |
| Decrypted outputs | `001` to `1000` |
| Time limit | 200 ms |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

One value is read per run and one line is printed.

The sample input and output:

```
699
```

```
700
```

## Idea

Add one to undo the shift, like turning a page number forward by one. The program reads all input into one buffer, scans digits by hand, and writes one buffered answer.

Each value costs constant time and constant space. A formatter that parsed and printed each line on its own would make more stream calls.

One addition recovers the original number.

## Why It Works

The cryptographer subtracted one, so adding one reverses the change.

1. Input values are non-negative, so the scanner skips separators without losing a sign.
2. The digit loop stops at the first non-digit after a number, so a trailing newline is harmless.
3. A decrypted value below 100 gets one leading zero, and a value below 10 gets two.
4. A decrypted value of 1000 prints as four digits with no padding.

The padding rules are as follows:

| Decrypted value | Leading zeros | Printed value |
| --- | --- | --- |
| 1 | 2 | `001` |
| 9 | 2 | `009` |
| 99 | 1 | `099` |
| 100 | 0 | `100` |
| 999 | 0 | `999` |
| 1000 | 0 | `1000` |

A script shows the sample and the carry case:

| Step | Sample | Carry case |
| --- | --- | --- |
| Encrypted token | `699` | `999` |
| Parsed integer | 699 | 999 |
| Add one | 700 | 1000 |
| Printed line | `700` | `1000` |

The extra digit prints as part of the number.

## Code

**Read and constants.** The constant holds the digit value of zero.

```nim
const firstDigitValue = 48

proc readInputStream(): string =
  var inputBuffer = ""
  var inputLine = ""
  while readLine(stdin, inputLine):
    inputBuffer.add inputLine
    inputBuffer.add '\n'
  return inputBuffer
```

The loop runs once per input line and stops at the end of the stream. Reading once avoids a stream call per value. The added newline marks the end of the token.

**Digit scanner.** The scanner walks the buffer and builds the number.

```nim
proc nextInteger(inputData: string, i: var int, value: var int): bool =
  var j = i
  var accumulator = 0
  var foundDigit = false
  while j < inputData.len:
    let charValue = int(inputData[j]) - firstDigitValue
    if charValue >= 0 and charValue <= 9:
      accumulator = accumulator * 10 + charValue
      foundDigit = true
      j += 1
    elif foundDigit:
      break
    else:
      j += 1
  i = j
  value = accumulator
  return foundDigit
```

The loop stops at the buffer end or at the first non-digit after a number. `foundDigit` prevents output for trailing whitespace. One pass over the characters supplies the value.

**Output builder.** Two comparisons add the missing zeros, and the four-digit case prints directly.

```nim
proc appendDecrypted(outputBuffer: var string, encryptedValue: int) =
  let decryptedValue = encryptedValue + 1
  if decryptedValue >= 1000:
    outputBuffer.add $decryptedValue
  else:
    if decryptedValue < 100:
      outputBuffer.add '0'
    if decryptedValue < 10:
      outputBuffer.add '0'
    outputBuffer.add $decryptedValue
  outputBuffer.add '\n'
```

The branch handles the four-digit result first. Each append costs constant work because the number has at most four digits. The newline ends the line.

**Driver.** The loop ends when the scanner finds no more digits.

```nim
var inputData = readInputStream()
var i = 0
var outputBuffer = ""
while true:
  var encryptedValue = 0
  if not nextInteger(inputData, i, encryptedValue):
    break
  appendDecrypted(outputBuffer, encryptedValue)
stdout.write outputBuffer
```

One buffer collects every printed line, and one write flushes the answer. The loop handles a single value in the judge input and still works for more.

## Complexity

Reading and scanning each take one pass over the input bytes.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Digit scan | one pass over input bytes | O(1) |
| Padding | O(1) per value | O(1) |
| Output | one write for all lines | output bytes |
| Total | O(L + K) | O(L + K) |

Here L is the input byte length and K is the output length.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(L + K), constant for one value |
| Space | O(L + K), constant for one value |

A program that read and wrote each line separately would make more stream calls.
