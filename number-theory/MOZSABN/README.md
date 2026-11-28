# MOZSABN — Sharmeen and binary number (SPOJ)

<https://www.spoj.com/problems/MOZSABN/>

## Problem

A binary number arrives as a string of zeros and ones, possibly with leading zeros. The task is to print how many one bits the string contains.

Input holds one such number, up to 10⁵ digits. Output holds one integer, the count of `1` characters.

| Item | Bound |
|---|---|
| Binary length | at most 10⁵ digits |
| Digits | only `0` and `1` |
| Leading zeros | allowed |
| Judge limit | 1000 ms, 1536 MB |

The length bound makes a single character pass the natural approach.

The sample case:

```
1011
```

```
3
```

## Idea

Count the `1` characters inside the binary token. Think of counting lit bulbs in a row: only lit bulbs raise the total. A hand scanner lifts the token by index, and one pass tallies it. Converting the number first would need big-integer work and more memory. One scan answers the whole task.

## Why It Works

1. The token contains only `0` and `1`, so each digit decides one bit.
2. `nextToken` skips surrounding whitespace and returns the whole number.
3. `setBitCount` increases only when the scanned character is `1`.
4. Leading zeros add nothing and leave the count unchanged.
5. The count fits in an int because the length is at most 10⁵.

| Term | Meaning |
|---|---|
| `inputData` | one string holding all stdin bytes |
| `scanPos` | current index in that string |
| `nextToken` | hand scanner that returns one word |
| `binaryDigits` | the binary number as a string |
| `setBitCount` | number of `1` characters found |

Counting digits directly avoids any numeric conversion.

A script-traced example from `gen.py`:

```
binary 1011
integer 11
set bits 3
```

The trace confirms three one bits, matching the sample output.

## Code

**Input and hand scanner.** This block loads stdin and lifts one token.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var token = ""
  while position < data.len and data[position] > ' ':
    token.add data[position]
    position += 1
  return token
```

One readLine loop collects the entire stream.
The scanner skips whitespace before gathering digits.
Reading the token costs one pass over its characters.

**Buffered output.** This block holds the final count line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
A single answer never reaches the threshold.

**Counting loop.** This block tallies one bits and writes the answer.

```nim
let binaryDigits = nextToken(inputData, scanPos)
var setBitCount = 0
for index in 0..<binaryDigits.len:
  if binaryDigits[index] == '1':
    setBitCount += 1
appendOutput($(setBitCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per binary digit.
Only the character `1` changes the total.
The final write emits the buffered answer.

## Complexity

The cost splits into input, one scan of the token, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Token scan | O(length) character checks | the token string |
| Output | one write for the answer | block buffer |

The scan touches each digit exactly once.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes |
| Space | O(N) for the input buffer |

Converting to an integer first adds big-integer cost; direct counting stays linear.
