# MOZSASN — Sharmeen And Sadness (SPOJ)

<https://www.spoj.com/problems/MOZSASN/>

## Problem

Sharmeen writes a string of length n for n days away from home. Position 0 holds a hyphen. Positions 1, 4, 7, and so on hold an underscore. Every other position holds a hyphen. Print that string and then a newline.

One integer n with 1 ≤ n ≤ 10⁵ arrives on stdin. Print the sadness string of n characters followed by a newline.

| Item | Bound |
|---|---|
| Days n | 1 ≤ n ≤ 100000 |
| Output length | n characters |
| Instances | one per input file |
| Judge limit | 1000 ms, 1536 MB |

The output size equals n, so streaming matters.

The sample case:

```
10
```

```
-_--_--_--
```

## Idea

The string is the three-character block `-_-` repeated, then cut to length n. Think of a roll of wallpaper with a fixed motif: you cut off exactly the length you need. A modular index test gives the same characters without storing the roll. Building every prefix before printing copies O(n²) bytes. One streaming pass costs O(n) time and O(1) buffer space.

## Why It Works

1. Repeating `-_-` gives positions 0, 1, 2 as hyphen, underscore, hyphen.
2. Inside each block, only the middle position becomes an underscore.
3. Therefore an underscore appears exactly when `dayIndex mod 3` equals 1.
4. The 128 KiB buffer flushes during the loop, so memory stays bounded.

| Term | Meaning |
|---|---|
| `dayCount` | the number of days read from input |
| `dayIndex` | zero-based position in the output |
| `flushBlockBytes` | buffer size that triggers a write |
| `outputBuffer` | pending output bytes |

One modulo decides each character.

A script-traced example from `gen.py`:

```
the block -_- repeated three times is -_--_--_-
the first 10 characters are -_--_--_--
```

The traced string equals the sample output.

## Code

**Input and scanner.** This block loads stdin and reads one integer by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop stores the whole input.
The scanner skips separators and builds the value.
The scan costs one pass over the digits.

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

**Pattern loop and final flush.** This block emits one character per day.

```nim
let dayCount = nextInt(inputData, scanPos)
for dayIndex in 0..<dayCount:
  if dayIndex mod 3 == 1:
    appendOutput("_")
  else:
    appendOutput("-")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly n times.
Each iteration appends one character.
The newline is added after the loop ends.

## Complexity

The cost splits into reading n, generating n characters, and writing blocks.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Pattern build | O(n) character visits | block buffer |
| Output | one write per 128 KiB block | block buffer |

Memory never grows with n.

| Measure | Big O |
|---|---|
| Time | O(n + L) for L input bytes |
| Space | O(L + B), with B = 128 KiB |

Building and copying every prefix costs O(n²) time.
A single streaming pass removes that cost.
