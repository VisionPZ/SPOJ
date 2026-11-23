## Problem

Read one encrypted three-digit value. It is the original value minus one. Print the original value, padded to three digits. Print `1000` when the value needs four digits.

The judge bounds are small, as this table shows.

| Item | Value |
| --- | --- |
| Encrypted inputs | `000` to `999` |
| Decrypted outputs | `001` to `1000` |
| Time limit | 200 ms |
| Memory limit | 1536 MB |
| Source limit | 50000 B |

One value is read per run and one line is printed. The sample reads `699` and prints `700`.

## Idea

The encrypted value is the original value minus one. Adding one recovers the original value. The program reads all input into one buffer, scans digits by hand, and writes one buffered answer. Each value costs constant time and constant space.

## Why It Works

Adding one undoes the subtraction that the cryptographer made. Input values are non-negative, so the scanner skips separators without losing a sign. The padded form depends only on the decrypted value, as this table shows.

| Decrypted value | Leading zeros | Printed value |
| --- | --- | --- |
| 1 | 2 | `001` |
| 9 | 2 | `009` |
| 99 | 1 | `099` |
| 100 | 0 | `100` |
| 999 | 0 | `999` |
| 1000 | 0 | `1000` |

The four-digit result prints without padding. The sample works as follows.

| Step | Value |
| --- | --- |
| Encrypted token | `699` |
| Parsed integer | 699 |
| Add one | 700 |
| Printed line | `700` |

The printed line matches the statement. The carry case works as follows.

| Step | Value |
| --- | --- |
| Encrypted token | `999` |
| Parsed integer | 999 |
| Add one | 1000 |
| Printed line | `1000` |

The extra digit prints as part of the number.

## Code

```
const firstDigitValue = 48

proc readAllInput(): string =
  var inputBuffer = ""
  var inputLine = ""
  while readLine(stdin, inputLine):
    inputBuffer.add inputLine
    inputBuffer.add '\n'
  return inputBuffer
```

The constant holds the digit value of zero. The loop runs once per input line and stops at end of file. Reading once avoids a stream call per value.

```
proc nextInteger(inputData: string, scanPos: var int, value: var int): bool =
  var position = scanPos
  var accumulator = 0
  var foundDigit = false
  while position < inputData.len:
    let charValue = int(inputData[position]) - firstDigitValue
    if charValue >= 0 and charValue <= 9:
      accumulator = accumulator * 10 + charValue
      foundDigit = true
      position += 1
    elif foundDigit:
      break
    else:
      position += 1
  scanPos = position
  value = accumulator
  return foundDigit
```

The loop stops at the buffer end or at the first non-digit after a number. `foundDigit` prevents output for trailing whitespace. The scan makes one pass over the input characters.

```
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

The branch handles the four-digit result first. Two comparisons add the missing zeros. Each append cost is constant because the number has at most four digits.

```
var inputData = readAllInput()
var scanPos = 0
var outputBuffer = ""
while true:
  var encryptedValue = 0
  if not nextInteger(inputData, scanPos, encryptedValue):
    break
  appendDecrypted(outputBuffer, encryptedValue)
stdout.write outputBuffer
```

The loop ends when the scanner finds no more digits. One buffer collects every printed line. A single write flushes the answer.

## Complexity

Reading takes time proportional to the input byte length, call it L. Scanning makes one more pass over those bytes. Building and writing the answer takes time proportional to its length, call it K. Total time is O(L + K), which is constant for one three-digit value. Both buffers use O(L + K) space, also constant for this input. A program that parsed and printed each line on its own would make more stream calls and run slower.
