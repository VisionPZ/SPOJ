# HS12HDPW — Hidden Password (SPOJ)

<https://www.spoj.com/problems/HS12HDPW/>

## Problem

Decode a password from two strings. Each group of six characters in the first string encodes two indices into the second string.

The input starts with t cases. Each case gives n, the number of groups, then the two strings on separate lines. The first string holds 6n characters and may contain spaces between groups. The second string holds 64 characters. Print 2n decoded characters per case on one line.

| Item | Bound |
|---|---|
| Test cases | t < 100 |
| Groups per case | n < 100 |
| Second string | exactly 64 characters |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
2
2
qwe345 rf3Arg
XSBSRasdew9873465hkldsfsalndfvnfq489uqovkLKJHaeDaae555Sk5asdpASD

3
2S4J5K 111111 lrtb2A
isimgsow45ipfgisd56wfgngdfcdkgc7kKKKkuuJJgfstdygQdWORQADFSLKF2K8
```

```
keep
coding

```

## Idea

Think of a lock with six dials. Each dial contributes one bit to each of two numbers.

For bit position i, the program reads bit i of character i for the first index. It reads bit (i + 3) mod 6 of the same character for the second index. Each selected bit is placed at position i of its number. The two numbers select characters from the 64-character string. Every one of the 6n characters costs two shifts and two masks.

The six bits of a group are assembled directly into two indices.

## Why It Works

1. Six characters carry six selectable bits, one per character position.
2. Bit i of character i becomes bit i of the first index.
3. Bit (i + 3) mod 6 of character i becomes bit i of the second index.
4. Both indices range from 0 to 63, matching the alphabet length.

| Term | Meaning |
|---|---|
| `firstString` | the n groups of six characters, spaces skipped |
| `secondString` | the 64-character alphabet |
| `bitIndex` | position from 0 to 5 inside a group |
| `pairedBit` | (bitIndex + 3) mod 6 |
| `firstIndex` | position in `secondString` for the first output character |

Each group yields exactly two output characters.

A traced first group from `gen.py`:

```
char 0 q bits 01110001 a-bit 1 b-bit 0
char 1 w bits 01110111 a-bit 1 b-bit 1
char 2 e bits 01100101 a-bit 1 b-bit 1
char 3 3 bits 00110011 a-bit 0 b-bit 1
char 4 4 bits 00110100 a-bit 1 b-bit 0
char 5 5 bits 00110101 a-bit 1 b-bit 1
a 55, b 46
characters ke
```

The trace yields indices 55 and 46, which spell `ke`.

## Code

**Input and scanner.** Non-space characters are read into two strings per case.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextCharacter(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let symbol = data[pos]
  pos += 1
  return symbol

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1
  if data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

```

`nextCharacter` skips the spaces between groups. `nextInteger` reads counts and handles signs.

**Output helper.** Password characters are appended to one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 128 KiB. The final write closes the output.

**Decode driver.** Each group is turned into two indices, then two characters.

```nim
let caseCount = nextInteger(inputData, scanPos)
for _ in 0 ..< caseCount:
  let tupleCount = nextInteger(inputData, scanPos)
  var firstString = ""
  for _ in 0 ..< tupleCount * 6:
    firstString.add nextCharacter(inputData, scanPos)
  var secondString = ""
  for _ in 0 ..< 64:
    secondString.add nextCharacter(inputData, scanPos)
  for tupleIndex in 0 ..< tupleCount:
    let tupleStart = tupleIndex * 6
    var firstIndex = 0
    var secondIndex = 0
    for bitIndex in 0 ..< 6:
      let characterCode = int(firstString[tupleStart + bitIndex])
      let pairedBit = (bitIndex + 3) mod 6
      if (characterCode and (1 shl bitIndex)) != 0:
        firstIndex = firstIndex or (1 shl bitIndex)
      if (characterCode and (1 shl pairedBit)) != 0:
        secondIndex = secondIndex or (1 shl bitIndex)
    appendOutput($secondString[firstIndex])
    appendOutput($secondString[secondIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
```

Bit masks use `and`, and bit assembly uses `or`. Each case ends with one newline.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Group decode | constant work per character | two case strings |
| Output | one write per 128 KiB block | one output buffer |

The number of groups bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total groups) |
| Space | O(input bytes) |

Trying all 64 possible indices per group would add needless work. Direct bit assembly builds each index in six steps.
