# SBSTR1 — Substring Check (Bug Funny) (SPOJ)
<https://www.spoj.com/problems/SBSTR1/>

## Problem

A detective holds a ten-digit code and a five-digit fragment. The fragment must appear inside the code, in order and without gaps. Print 1 when it appears and 0 when it does not.

Input: 24 lines. Each line holds binary string A of length 10, one space, and binary string B of length 5. Output: one line per input line, holding either 1 or 0.

The task fixes every size.

| Item | Value |
| --- | --- |
| Input lines | exactly 24 |
| Length of A | 10 |
| Length of B | 5 |
| Characters | 0 or 1 |
| Judge time limit | 1000 ms |
| Judge memory limit | 1536 MB |

Every line costs the same fixed amount of work.

The sample input:

```
1010110010 10110
1110111011 10011
1111010101 01100
1000111100 01000
0100000100 01111
1001101000 00010
0110110101 01110
1101001110 01011
0000111101 01110
1011101110 01100
0011101001 11011
1101011100 01010
0101010001 11101
0110001000 00110
1111001001 11001
0001100110 01101
0001100000 11000
1010110110 11110
1011000011 11001
1110100100 01100
0100110111 11100
0101111001 10110
0010000010 01101
0100110111 10101
```

The sample output:

```
1
0
0
0
0
0
0
0
0
0
0
0
0
0
1
0
1
0
0
0
0
0
0
0
```

## Idea

Slide a short ruler over each line, the way you check a word inside a sentence. The ruler covers five characters. You compare what it covers with the fragment and move one step right. That is the whole trick.

The scanner records each token's start and length, so it copies no string. `containsPattern` walks a five-byte window across A and compares bytes in place. One window costs at most five comparisons, and a line costs at most six windows. Building a fresh string per window would allocate six strings per line; in-place comparison allocates none.

Fixed lengths keep the whole check constant time.

## Why It Works

Three facts carry the program.

1. A substring of length 5 inside a string of length 10 starts at an offset from 0 through 5. The bound is `textLen - patternLen`, taken inclusive.
2. Byte-by-byte comparison decides window equality exactly. A first match proves B occurs inside A.
3. Six failed windows cover every possible start, so no match proves B does not occur.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `textStart` | index of A inside the input buffer |
| `patternStart` | index of B inside the input buffer |
| `i` | window offset, from 0 up to `textLen - patternLen` |
| `j` | byte position inside one window |

The indices always stay inside their own tokens.

A script traces the six windows for A = 1010110010 and B = 10110.

```text
offset 0: 10101  no
offset 1: 01011  no
offset 2: 10110  yes
offset 3: 01100  no
offset 4: 11001  no
offset 5: 10010  no
```

Offset 2 matches, so the first sample answer is 1. No rounding or sign handling is needed.

## Code

**Constants and token scanner.** The scanner returns offsets, not copied strings.

```nim
const flushBlockBytes = 1 shl 16

proc nextToken(data: string, i: var int): tuple[first: int, length: int] =
  while i < data.len and data[i] <= ' ':
    i += 1
  let tokenStart = i
  while i < data.len and data[i] > ' ':
    i += 1
  result.first = tokenStart
  result.length = i - tokenStart
```

The first loop skips every byte at or below a space, so spaces and newlines share one rule. `i` is a `var` parameter, so the scan position survives across calls. The cost is one pass over the token bytes.

**Window comparison.** The nested loops compare bytes without allocation.

```nim
proc containsPattern(data: string, textStart, textLen, patternStart, patternLen: int): bool =
  if patternLen > textLen:
    return false
  var i = 0
  while i + patternLen <= textLen:
    var matched = true
    var j = 0
    while j < patternLen:
      if data[textStart + i + j] != data[patternStart + j]:
        matched = false
        break
      j += 1
    if matched:
      return true
    i += 1
  return false
```

The bound `i + patternLen <= textLen` yields six windows for the fixed lengths. The early return stops at the first match. The inner loop costs at most `patternLen` comparisons per window.

**Input buffer.** One line loop collects the whole stream.

```nim
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var i = 0
var outputBuffer = ""
```

The loop ends at end of file, so no case triggers an extra read. The added newline keeps token boundaries intact. Reading costs one pass over the input bytes.

**Driver.** Two tokens produce one answer byte.

```nim
while true:
  let textToken = nextToken(inputData, i)
  if textToken.length == 0:
    break
  let patternToken = nextToken(inputData, i)
  if patternToken.length == 0:
    break
  if containsPattern(inputData, textToken.first, textToken.length, patternToken.first, patternToken.length):
    outputBuffer.add('1')
  else:
    outputBuffer.add('0')
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
```

A zero-length token ends the run. Each answer adds two bytes to the buffer. `setLen(0)` reuses one allocation after each flushed block.

## Complexity

Each stage reads fixed-size tokens and writes two bytes.

| Stage | Time | Space |
| --- | --- | --- |
| Input read | one pass over N bytes | N bytes |
| Token scan | O(1) per line | O(1) |
| Window match | at most 30 byte compares per line | O(1) |
| Output | one write per 64 KiB block | one block |
| Total, 24 lines | O(N) | O(N) |

N is the input size in bytes, about 400 here.

| Measure | Big O |
| --- | --- |
| Time | O(N), constant work per line |
| Space | O(N) for input plus one output block |

A fresh string per window would allocate six strings per line; in-place comparison allocates none.
