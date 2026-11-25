# TESTPASS — Password01 (SPOJ)
<https://www.spoj.com/problems/TESTPASS/>

## Problem

Each password must satisfy four checks. It needs 6 to 20 characters. It needs one capital, one small letter, one digit and one special character. It must not repeat a two-character block or a three-character block back to back.

The first line gives the password count. Each following line holds one password. Print `YES` when all checks pass, otherwise `NO`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Password length | 6 to 20 characters |
| Special character | any non-alphanumeric character |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The length cap keeps every direct scan short.

The sample case:

```
8
PASS
P@ss
P@ss123123
Alabama@#1
nonoP@ssw0rd
My2P@SSword
abcddcba123#
MyP@sswordIsReallyLong@RosesAreBlue
```

```
NO
NO
NO
YES
NO
YES
NO
NO
```

## Idea

Scan each password once for character classes, then once more for repeated blocks. Think of a bouncer checking a guest list, then checking for a repeated dance move. Four flags record the required classes, and two sliding windows catch repeats.

## Why It Works

1. The length check rejects strings shorter than 6 or longer than 20.
2. Four flags confirm that every required character class appears.
3. A two-character repeat means block i equals block i+1.
4. A three-character repeat means triple i equals triple i+1.

The main terms:

| Term | Meaning |
|---|---|
| `isValid` | the routine that applies all password checks |
| `hasSpecial` | flag for a non-alphanumeric character |
| `pairRepeat` | adjacent equal two-character blocks |
| `tripleRepeat` | adjacent equal three-character blocks |

These terms split the rules into class checks and window checks.

A script trace marks `P@ss123123` false because `123` appears twice in a row. It marks `nonoP@ssw0rd` false because `no` repeats at the start.

## Code

**Input buffer and token scanner.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const answerYes = "YES"
const answerNo = "NO"

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos ..< pos]
```
The token scanner returns one password per call. All input bytes stay in one buffer.

**Character class helpers.**
```nim
proc isUpper(c: char): bool =
  return c >= 'A' and c <= 'Z'

proc isLower(c: char): bool =
  return c >= 'a' and c <= 'z'

proc isDigit(c: char): bool =
  return c >= '0' and c <= '9'
```
Each helper is one range test. A character failing all three counts as special.

**Validation routine.**
```nim
proc isValid(password: string): bool =
  if password.len < 6 or password.len > 20:
    return false
  var hasUpper = false
  var hasLower = false
  var hasDigit = false
  var hasSpecial = false
  for c in password:
    if isUpper(c):
      hasUpper = true
    elif isLower(c):
      hasLower = true
    elif isDigit(c):
      hasDigit = true
    else:
      hasSpecial = true
  if not (hasUpper and hasLower and hasDigit and hasSpecial):
    return false
  for i in 0 ..< password.len - 3:
    if password[i] == password[i + 2] and password[i + 1] == password[i + 3]:
      return false
  for i in 0 ..< password.len - 5:
    if password[i] == password[i + 3] and password[i + 1] == password[i + 4] and
       password[i + 2] == password[i + 5]:
      return false
  return true
```
The first loop collects class flags. The two window loops reject back-to-back repeats.

**Verdict loop and flush.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for j in 0..<caseCount:
  let password = nextToken(inputData, scanPos)
  if isValid(password):
    appendOutput(answerYes)
  else:
    appendOutput(answerNo)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
Each password produces one verdict line. A final flush writes the remaining bytes.

## Complexity

The cost is a constant number of short scans per password.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Validation | up to three passes over 20 characters | constant |
| Output | one write per 128 KiB block | block buffer |

Each phase is linear in the total input size, with a small constant.

Big O uses C as the total character count.

| Measure | Big O |
|---|---|
| Time | O(C) |
| Space | O(C) for stored input |

Building every substring table would add allocations. Direct index windows avoid that cost.
