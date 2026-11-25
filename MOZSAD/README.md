# MOZSAD — Sharmeen And Digits (SPOJ)

<https://www.spoj.com/problems/MOZSAD/>

## Problem

Sharmeen knows only the digit zero. Given one signed integer, report how many zero digits appear in its decimal writing. A minus sign is not a digit and never counts.

One integer n in the range −10⁸ to 10⁸ arrives on stdin. Print the count of `0` digits, followed by a newline.

| Item | Bound |
|---|---|
| Integer n | −10⁸ ≤ n ≤ 10⁸ |
| Instances | one per input file |
| Judge limit | 1000 ms, 1536 MB |

The written form decides the answer, not the numeric value alone.

The sample case:

```
100604
```

```
3
```

## Idea

Treat the input as text and inspect each character. Counting zeros is like a librarian tallying letter `o` marks on a shelf label; the label's sign is not a letter. Numeric division needs extra handling for zero and negatives. Each character costs constant time, so total time is O(L) for L characters.

## Why It Works

1. The statement writes n in decimal, so each digit appears as one character.
2. The minus sign is a different character and cannot match `0`.
3. The value 0 has one written digit, which is a zero.
4. Counting matching characters therefore answers every allowed input.

| Term | Meaning |
|---|---|
| `numberText` | the input token, sign included |
| `zeroCount` | running total of matching digits |
| `index` | position inside the token |

The token's characters are the only data the count needs.

A script-traced example from `gen.py`:

```
100604 gives remainders 4 0 6 0 0 1
three of those remainders are zero
```

The division trace finds three zeros, matching the sample answer.

## Code

**Input and tokenizer.** This block loads stdin and reads the signed token by index.

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

One readLine loop stores the whole input.
The tokenizer skips spaces and keeps the minus sign.
The scan costs one pass over the token.

**Buffered output.** This block collects answer bytes before writing.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.
Each append runs in constant time.

**Digit count and final flush.** This block counts zero characters and writes the total.

```nim
let numberText = nextToken(inputData, scanPos)
var zeroCount = 0
for index in 0..<numberText.len:
  if numberText[index] == '0':
    zeroCount += 1

appendOutput($(zeroCount) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits each character once.
The minus sign fails the equality test.
The final write flushes the buffer at exit.

## Complexity

The cost splits into reading the token, counting characters, and writing the count.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Count | O(L) character visits | constant |
| Output | one write per 128 KiB block | block buffer |

Each phase is bounded by the token length.

| Measure | Big O |
|---|---|
| Time | O(L) for L input bytes |
| Space | O(L) for the input string |

Repeated division also costs O(L), but needs sign and zero special cases.
The text scan handles every case in one pass.
