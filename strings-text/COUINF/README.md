# COUINF — Infinity Problem (SPOJ)

<https://www.spoj.com/problems/COUINF/>

## Problem

An Avengers fan owes the heroes one fixed line of respect. Print that line and ignore every input byte.

The statement defines no input at all. The output is one sentence ending with a newline.

| Item | Bound |
|---|---|
| Input | none |
| Output | one fixed line |
| Judge limit | 1 s |
| Memory limit | 1536 MB |

The sample as printed in the statement:

```
No Input
```

```
Thank You, Avengers
```

## Idea

The answer never changes, so the program is a notice pinned to a wall. Every visitor sees the same words, whatever they bring.

Store the sentence once. Drain stdin so the stream ends cleanly. Append the sentence to one output buffer, then flush it. No scan, branch, or arithmetic touches the data.

The fixed text makes this a constant-time reply. A program that echoed input would grow with the stream and give the wrong sentence.

## Why It Works

1. The statement fixes the byte string, so no computation can improve it.
2. The trailing newline closes the single required output line.
3. Draining stdin leaves the stream at EOF, even when stray bytes arrive.
4. One buffered write emits the short reply without repeated system calls.

| Term | Meaning |
|---|---|
| `requiredMessage` | the exact reply, including its newline |
| `inputData` | buffer that collects stray input bytes |
| `outputBuffer` | pending output bytes |
| `flushBlockBytes` | threshold that triggers a write |

`gen.py` prints this trace while building the files:

```
trace: input ignored; fixed reply bytes -> Thank You, Avengers
```

The trace matches the sample line byte for byte.

## Code

**Input reader.** Drains stdin into one buffer before writing anything.

```nim
const flushBlockBytes = 1 shl 17
const requiredMessage = "Thank You, Avengers\n"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

`readLine` stops at EOF, which happens immediately for valid input. The newline is restored after each line. `discard` later marks the collected bytes as unused.

**Message writer.** Appends the sentence and flushes the remaining bytes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

discard inputData
appendOutput(requiredMessage)
stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes only past 128 KiB. The last write emits this short line. No parser runs, so the cost stays constant.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over stray bytes | stray input bytes |
| Reply | one constant append | one line |
| Output | one final write | one buffer |

The reply needs no data-dependent work.

| Measure | Big O |
|---|---|
| Time | O(input bytes) |
| Space | O(input bytes) |

Echoing input would emit many wrong lines and grow with the stream size. One fixed write stays correct and constant.
