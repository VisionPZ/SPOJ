## Problem

Read 24 lines from input. Each line holds binary string A of length 10 and binary string B of length 5, separated by one space. Print 1 when B occurs inside A, and print 0 otherwise. The judge page lists esoteric languages, but exact output bytes are all that matter.

The limits are fixed.

| Item | Value |
| --- | --- |
| Lines | 24 |
| Length of A | 10 |
| Length of B | 5 |
| Characters | 0 or 1 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Every line produces exactly one answer line.

## Idea

Read the whole input into one buffer, then walk it with an index that skips spaces. For each pair, slide a five-character window across A and compare its bytes with B at each start offset. Stop at the first match and print 1; a full pass with no match prints 0; append answers to one output buffer.

Each line costs at most six windows times five byte comparisons, so the work per line is constant.

## Why It Works

A substring of length 5 inside A of length 10 must start at an offset from 0 through 5. That bound is `textLen - patternLen`, taken inclusive. Comparing each window byte by byte decides equality exactly. A first match proves B occurs, and no match proves it does not.

The index formula uses `i` from 0 up to `textLen - patternLen`. Window bytes are `data[textStart + i + j]`. Pattern bytes are `data[patternStart + j]`.

Here are the six windows for A = 1010110010 and B = 10110.

| Start offset | Window | Match |
| --- | --- | --- |
| 0 | 10101 | no |
| 1 | 01011 | no |
| 2 | 10110 | yes |
| 3 | 01100 | no |
| 4 | 11001 | no |
| 5 | 10010 | no |

Offset 2 matches, so the answer is 1. This is the first line of the sample.

## Code

```
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

The scanner skips every byte at or below a space, so spaces and newlines need no special case. `length` is `i` minus `tokenStart`, so the token is never copied. Cost is one pass over the token bytes.

```
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

The bound `i + patternLen <= textLen` gives textLen minus patternLen plus one windows. Direct byte comparison avoids a fresh string per window. Cost is at most `patternLen` comparisons per window.

```
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add(lineBuffer)
  inputData.add('\n')

var i = 0
var outputBuffer = ""
```

Reading by line appends into one buffer, so the whole input is scanned once. The added newline keeps token boundaries intact. Cost is one pass over the input bytes.

```
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

The outer loop ends when a token has zero `length`. Each answer adds two bytes to `outputBuffer`. A flush runs every `flushBlockBytes` bytes, which caps memory at the block size. Cost is one pass over the token pairs.

## Complexity

Reading costs O(N) for N input bytes, where N is the input size. Scanning and matching cost O(1) per line, because the lengths are fixed. Total time is O(N).

The input buffer holds N bytes. The output buffer holds at most `flushBlockBytes` bytes. Total space is O(N).

Building a new string for each window would allocate six strings per line. In-place byte comparison allocates none.
