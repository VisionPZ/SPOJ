# MOZSAP — Sharmeen can do it. Do you? (SPOJ)

<https://www.spoj.com/problems/MOZSAP/>

## Problem

This problem has no input. The program must print one fixed line: `Print \C Programming`.

The input section is empty, so the program reads stdin but uses no values. Output holds exactly that line, including the backslash before the letter C.

| Item | Bound |
|---|---|
| Input | none |
| Output | one fixed line |
| Judge limit | 1000 ms, 1536 MB |

Every run produces the same bytes, so correctness depends on the literal.

The statement's example block reads:

```
Input:

Output:
This is a demo output
```

The required output line is:

```
Print \C Programming
```

## Idea

A constant-output task needs no parsing; the program writes one literal line. Think of a fixed sign: reading the room never changes the wording. The input reader still collects stdin, and a hand scanner walks the buffer. Output uses the same block buffer as larger tasks. One write emits the complete answer.

## Why It Works

1. The judge supplies no input values, so any stray bytes are ignored.
2. The literal keeps the backslash exactly as the statement prints it.
3. The scanner loop advances the index through all collected bytes.
4. The output buffer flushes only after reaching the block threshold.
5. The final write emits the single line even when no flush occurred.

| Term | Meaning |
|---|---|
| `inputData` | one string holding all stdin bytes |
| `scanPos` | current index in that string |
| `outputBuffer` | growable block of finished output |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | size that triggers a write |

The literal text is the whole solution; the scanner only preserves the IO shape.

A script-traced example from `gen.py`:

```
input (empty)
output 'Print \\C Programming\n'
```

The trace shows the exact bytes, including the trailing newline.

## Code

**Input and hand scanner.** This block loads stdin and defines the integer scanner.

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

One readLine loop collects the entire stream.
The scanner skips whitespace and reads digits by index.
Its cost is one pass over any supplied bytes.

**Buffered output.** This block collects the fixed line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer holds the line until a flush is needed.
The 128 KiB threshold keeps stream calls rare.

**Fixed answer.** This block scans input and emits the literal.

```nim
while scanPos < inputData.len:
  discard nextInt(inputData, scanPos)

appendOutput("Print \\C Programming\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan loop ends when the index reaches the end.
The doubled backslash in Nim source writes one literal backslash.
The final write emits all remaining bytes.

## Complexity

The cost splits into reading stdin, scanning it, and writing one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Scan | one pass over input bytes | constant |
| Output | one write for the line | block buffer |

No phase depends on a problem parameter.

| Measure | Big O |
|---|---|
| Time | O(N) for N input bytes |
| Space | O(N) for the input buffer |

Writing each byte separately would add N stream calls; one append avoids them.
