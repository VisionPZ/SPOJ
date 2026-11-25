# ADAFUROW — Ada and Furrows (SPOJ)
<https://www.spoj.com/problems/ADAFUROW/>

## Problem

Maintain sets of vegetable kinds in furrows and answer set questions about two furrows at a time. Add puts one kind into one furrow, and harvest removes one kind. The four questions ask for union size, intersection size, symmetric difference size, and one-way difference size.

The first input line gives `queryCount`. Each following line holds an operator, then two numbers `x` and `y`, both at most 20000. Print one answer per question operator.

| item | bound |
|---|---|
| queries | 1 to 300000 |
| furrow index | 0 to 20000 |
| vegetable kind | 0 to 20000 |
| judge limit | 2000 ms, 1536 MB |

Add and harvest lines produce no output.

Sample input:

```
10
+ 1 4
! 0 2
+ 0 2
\ 0 2
^ 0 1
v 2 0
+ 2 4
! 2 0
+ 1 0
! 0 2
```

Sample output:

```
0
1
0
1
2
2
```

## Idea

Keep each furrow as a row of bits, like checkboxes on one long form, then compare two rows with one word operation. A bit is set when the furrow holds that kind. Union becomes OR, intersection becomes AND, symmetric difference becomes XOR, and one-way difference becomes AND with a complement. Each question reads 313 machine words and counts their bits. A Python set would pay hash-table costs on every question, while the bit rows stay in cache. Store rows once, then answer with word operations.

## Why It Works

1. Kinds run from 0 to 20000, so 20001 bits cover every kind.
2. Sixty-four bits fit in one word, so each furrow needs 313 words.
3. OR over two rows sets a bit exactly when either furrow holds that kind.
4. AND sets a bit exactly when both furrows hold the kind.
5. XOR and masked complement give the remaining two questions.
6. Counting set bits in every word yields the requested size.

Each question maps to one word expression.

| operator | word expression | answer |
|---|---|---|
| `v` | OR | kinds in either furrow |
| `^` | AND | kinds in both furrows |
| `!` | XOR | kinds in exactly one furrow |
| `\` | AND with NOT | kinds in the first furrow only |

The four questions share one word loop with different bit logic.

A script-generated walk through the first sample gives these sets and answers:

| step | furrow 0 | furrow 1 | furrow 2 | output |
|---|---|---|---|---|
| `+ 1 4` | empty | 4 | empty | none |
| `! 0 2` | empty | 4 | empty | 0 |
| `+ 0 2` | 2 | 4 | empty | none |
| `\ 0 2` | 2 | 4 | empty | 1 |
| `^ 0 1` | 2 | 4 | empty | 0 |
| `v 2 0` | 2 | 4 | empty | 1 |
| `+ 2 4` | 2 | 4 | 4 | none |
| `! 2 0` | 2 | 4 | 4 | 2 |
| `+ 1 0` | 2 | 0, 4 | 4 | none |
| `! 0 2` | 2 | 0, 4 | 4 | 2 |

The last answer counts kinds 2 and 4 once each.

Flags such as `wordCount` and `bitsPerWord` match the 64-bit words. Bit masks use shifts, and no floating point appears.

## Code

**Constants and reader.** The input string and hand scanner handle spaced operators.

```nim
const flushBlockBytes = 1 shl 17
const furrowLimit = 20000
const bitsPerWord = 64
const wordCount = furrowLimit div bitsPerWord + 1

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc skipSeparators(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
```

The scanner skips the operator and reads both operands.
The word count covers kinds 0 through 20000.

**Bit counting and buffer.** A SWAR popcount avoids any library call.

```nim
proc countBits(value: uint64): int =
  var packedBits = value
  packedBits = packedBits - ((packedBits shr 1) and 0x5555555555555555'u64)
  packedBits = (packedBits and 0x3333333333333333'u64) + ((packedBits shr 2) and 0x3333333333333333'u64)
  packedBits = (packedBits + (packedBits shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  return int((packedBits * 0x0101010101010101'u64) shr 56)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The masks collect bit counts into the top byte.
The buffer flushes after 131072 bytes.

**Query loop.** Updates touch one bit, and questions scan the two rows.

```nim
let queryCount = nextInt(inputData, scanPos)
var furrowBits = newSeq[uint64]((furrowLimit + 1) * wordCount)

for queryIndex in 0 .. queryCount - 1:
  skipSeparators(inputData, scanPos)
  let operationChar = inputData[scanPos]
  scanPos += 1
  let firstFurrow = nextInt(inputData, scanPos)
  let secondFurrow = nextInt(inputData, scanPos)
  if operationChar == '+' or operationChar == '-':
    let wordOffset = firstFurrow * wordCount + secondFurrow div bitsPerWord
    let kindMask = 1'u64 shl (secondFurrow mod bitsPerWord)
    if operationChar == '+':
      furrowBits[wordOffset] = furrowBits[wordOffset] or kindMask
    else:
      furrowBits[wordOffset] = furrowBits[wordOffset] and not kindMask
  else:
    var kindTotal = 0
    let firstBase = firstFurrow * wordCount
    let secondBase = secondFurrow * wordCount
    if operationChar == 'v':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] or furrowBits[secondBase + wordIndex])
    elif operationChar == '^':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] and furrowBits[secondBase + wordIndex])
    elif operationChar == '!':
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] xor furrowBits[secondBase + wordIndex])
    else:
      for wordIndex in 0 .. wordCount - 1:
        kindTotal += countBits(furrowBits[firstBase + wordIndex] and not furrowBits[secondBase + wordIndex])
    appendOutput($kindTotal)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each update masks a single word.
Each question writes one line through the buffer.

## Complexity

Reading and writing stay linear, and each question scans all words of two rows.

| phase | time | space |
|---|---|---|
| input read | one pass over query lines | one input string |
| add or harvest | one masked word write | bit rows |
| question | 313 words and popcounts | buffer |
| output | one line per question | block buffer |

The fixed 313-word row bounds every question.

| measure | Big O |
|---|---|
| time | O(Q * K / 64) |
| space | O(furrows * K / 64) |

A hash-set comparison copies or scans every kind on each question, while the words stay compact and fast.

Store each furrow as bits and reduce every question to a few word operations.
