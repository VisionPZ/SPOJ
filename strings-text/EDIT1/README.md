# EDIT1 — Editor (SPOJ)

<https://www.spoj.com/problems/EDIT1/>

## Problem

The input is a stream of editor keys: ordinary characters append to the current line, `d` duplicates it, and a newline ends the line.
Output ends at a newline on an empty line, after which every finished line is printed in order.

The limits and input shape are fixed.

| rule | value |
| --- | --- |
| test cases | 1 |
| maximum line length | 150 characters |
| stop signal | newline on an empty current line |
| time limit | 1000 ms |
| memory limit | 1536 MB |

The stop signal is part of the input stream, not a separate count.

## Idea

Keep one current line and grow it in place. A `d` key copies the existing bytes into the free second half of that same string, so the line doubles without a new allocation. Finished lines go into one output buffer that flushes every 128 KiB.

Cost per key press: one byte append, or L copies when `d` doubles a line of length L.

## Why It Works

Only the current line changes during editing, so one string holds the whole editable state. Doubling writes each source byte once into the second half, and the destination index always exceeds the source index. A newline on an empty current line is the stop signal, so that empty line is never printed. Block flushing keeps the buffer at 128 KiB and produces one write per block.

The doubling step uses this index rule for each `i` below `originalLength`:

- `originalLength` is the line length before doubling.
- `doubledLength` is twice that length and becomes the new length.
- `i` walks the first half from its first byte to its last byte.
- `originalLength + i` is the target slot in the second half.

The sample input produces three lines. This table comes from a script that applies the rules above.

| input keys | d keys | produced line | length |
| --- | --- | --- | --- |
| sample-test | 0 | sample-test | 11 |
| -dd-d-dd | 5 | ------------------...------------------ | 44 |
| end signalled by two newlines | 2 | enen signalleenen ...le by two newlines | 42 |
| (empty line) | 0 | none | 0 |

The five `d` keys in the second line turn one dash into 44 dashes.

## Code

The constants and the in-place doubling procedure:

```nim
const readChunkBytes = 65536
const flushBlockBytes = 1 shl 17
const newlineKey = '\n'
const duplicateKey = 'd'

proc doubleLine(line: var string) =
  let originalLength = line.len
  let doubledLength = originalLength * 2
  line.setLen(doubledLength)
  for i in 0 ..< originalLength:
    line[originalLength + i] = line[i]
```

The copy loop runs `originalLength` times, once per byte in the first half. The forward order keeps each source byte intact until after it is copied. Doubling a line of length L costs L byte copies.

The whole input stream enters one buffer:

```nim
var inputData = newString(readChunkBytes)
var bytesRead = 0
while true:
  if bytesRead + readChunkBytes > inputData.len:
    inputData.setLen(inputData.len + readChunkBytes)
  let received = stdin.readBuffer(addr inputData[bytesRead], readChunkBytes)
  if received == 0:
    break
  bytesRead += received
inputData.setLen(bytesRead)
```

The loop ends when a read returns zero bytes. Growing `inputData` before each read keeps `addr inputData[bytesRead]` inside the buffer. The stream enters the buffer in one pass.

The editor loop walks the buffer once:

```nim
var currentLine = ""
var outputBuffer = ""
var i = 0

while i < inputData.len:
  let keyByte = inputData[i]
  if keyByte == newlineKey:
    i += 1
    if currentLine.len == 0:
      break
    outputBuffer.add currentLine
    outputBuffer.add newlineKey
    currentLine.setLen(0)
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen(0)
  elif keyByte == duplicateKey:
    i += 1
    doubleLine(currentLine)
  else:
    currentLine.add keyByte
    i += 1
```

The scan runs while `i` is below `inputData.len`, the exact input size. Breaking on an empty current line drops the stop signal from the output. Each finished line costs one append into `outputBuffer`.

The final flush:

```nim
if currentLine.len > 0:
  outputBuffer.add currentLine
  outputBuffer.add newlineKey
stdout.write outputBuffer
```

The last write flushes a partial block at the end of the stream. The guard preserves a line that arrives without a trailing newline. The write path stays one call per 128 KiB of output.

## Complexity

Let I be the number of input bytes and O the number of output bytes.

| phase | time | space |
| --- | --- | --- |
| read input | O(I) | O(I) |
| edit lines | O(O) | O(150) |
| write output | O(O) | O(128 KiB) |

Total time is O(I + O), and total space is O(I). A naive editor that rebuilt the whole output on every key would cost O(O squared). The in-place line and block buffer touch each byte once.
