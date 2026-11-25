# WOWTALENT — Warm Welcome to SIU (SPOJ)
<https://www.spoj.com/problems/WOWTALENT/>

## Problem

Each input line holds a student name. Print one greeting that wraps that name in fixed words.

The input holds one or more lines. Every line contains letters and spaces, with at most 100 characters.
The output repeats one line per input line.

| Item | Value |
|---|---|
| Input | name lines of at most 100 characters |
| Output | one greeting per line |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The full line must survive, so the program keeps line boundaries.

The statement sample follows verbatim.

```
Siam Hasan Antik
```

```
Welcome Siam Hasan Antik to SIU
```

## Idea

Think of a receptionist writing the same greeting around each name on a list.
The program holds the whole input in one buffer and walks to each line break.
It copies the bytes between breaks between a fixed prefix and a fixed suffix.
Each byte is copied once, so the cost grows with the input size.
Reading the stream again for every name would repeat work.

One pass over the buffer gives every greeting.

## Why It Works

1. Each line break marks the exact end of one name.
2. An empty line carries no name and produces no output.
3. A carriage return before the break is dropped before copying.
4. Copying the measured range keeps spaces inside the name.
5. The prefix and suffix supply the required words.

The main terms and ranges:

| Term | Meaning |
|---|---|
| `inputData` | the whole input, with line breaks kept |
| `nameStart` | index of the first byte of the current name |
| `nameEnd` | index one past the last byte of that name |
| `appendOutput` | adds text and flushes a full block |

These ranges isolate each name without splitting the input into objects.

A script trace of the sample builds the greeting from pieces.

```
input line: Siam Hasan Antik
pieces: ['Welcome', 'Siam Hasan Antik', 'to', 'SIU']
joined: Welcome Siam Hasan Antik to SIU
```

The joined pieces match the sample output exactly.

## Code

**Read the whole stream.**
```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

One string holds all input bytes. Line breaks stay inside that string.
The read loop visits each line once.

**Buffer output in blocks.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. The length reset reuses the same string.
Each flush writes one block.

**Copy each name into a greeting.**
```nim
let welcomePrefix = "Welcome "
let welcomeSuffix = " to SIU\n"
var scanPos = 0

while scanPos < inputData.len:
  let nameStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  var nameEnd = scanPos
  if nameEnd > nameStart and inputData[nameEnd - 1] == '\r':
    nameEnd -= 1
  if nameEnd > nameStart:
    let studentName = inputData[nameStart ..< nameEnd]
    appendOutput(welcomePrefix)
    appendOutput(studentName)
    appendOutput(welcomeSuffix)
  scanPos += 1
```

The inner scan stops at the next line break. A trailing carriage return is removed.
Each name byte is copied once.

**Emit the final partial block.**
```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last write clears whatever remains. No per-line write occurs.

## Complexity

Each phase visits its bytes once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Greeting | one pass over name bytes | one name slice |
| Output | one write per full block | block buffer |

Every input byte is handled a constant number of times.

| Measure | Big O |
|---|---|
| Time | O(input bytes) |
| Space | O(input bytes) |

Searching the stream once per name would cost O(names times input bytes), so one pass wins.
