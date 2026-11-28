# PONDO2 — Pondo Two (SPOJ)
<https://www.spoj.com/problems/PONDO2/>

## Problem

A strip of n meters holds either bumbuu (`u`) or bomboo (`o`). Give away a suffix of the strip, chosen from the right end. The number of `u` meters given must not exceed the number of `o` meters given. Report the longest allowed suffix length.

The first line gives n. The second line gives the n-character string. Print one integer, the maximum length.

| Constraint | Value |
| --- | --- |
| Strip length n | at most 100000 |
| Characters | `u` or `o` |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

Only the rightmost part is given away, so every candidate is a suffix of the string.

The first sample pair follows byte for byte.

```
6
uuouou
```

```
4
```

The suffix `ouou` gives two `u` meters and two `o` meters.

## Idea

Treat the giveaway like paying with credit: each `o` adds one credit, each `u` spends one, like coins dropped into a till from the right end. The program walks the strip from right to left and keeps this running balance. Every time the balance is non-negative, the current suffix length is recorded. A fresh count for every suffix would cost O(n^2), but one pass costs O(1) per meter. Record the best suffix during a single right-to-left walk.

## Why It Works

1. Give away a suffix of length k, which covers the last k characters.
2. The condition for that suffix is count of `u` at most count of `o`.
3. Define balance as count of `o` minus count of `u`.
4. Extending a suffix by one meter changes the balance by exactly one.
5. A suffix is allowed exactly when its balance is at least zero.
6. Scanning from the right visits suffixes in increasing length order.

The named values below are updated once per meter.

| Term | Meaning |
| --- | --- |
| `landBalance` | count of `o` minus count of `u` in the current suffix |
| `givenLength` | length of the current suffix |
| `bestLength` | longest allowed suffix found so far |
| `landIndex` | position currently added to the suffix |
| `land` | full strip read from the input |

A single running balance replaces one count pair per suffix.

A script check of the first sample lists every suffix of `uuouou`.

| Length | Suffix | Balance | Allowed |
| --- | --- | --- | --- |
| 1 | u | -1 | no |
| 2 | ou | 0 | yes |
| 3 | uou | -1 | no |
| 4 | ouou | 0 | yes |
| 5 | uouou | -1 | no |
| 6 | uuouou | -2 | no |

The largest allowed length is 4. If every meter is `o`, the balance never drops and the whole strip qualifies.

## Code

**Input and string reader.** Two procedures read the header number and the strip of characters.

```nim
const flushBlockBytes = 1 shl 17

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

proc nextLandString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != 'u' and data[pos] != 'o':
    pos += 1
  var land = ""
  while pos < data.len and (data[pos] == 'u' or data[pos] == 'o'):
    land.add data[pos]
    pos += 1
  return land

```

The string reader skips the newline after n. It stops at the first character outside the alphabet.

**Buffered output.** One string holds the answer and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer avoids one write per suffix. A single final flush emits the integer.

**Right-to-left scan.** The loop grows the suffix one meter at a time.

```nim
let landLength = nextInt(inputData, scanPos)
let land = nextLandString(inputData, scanPos)
var landBalance = 0
var givenLength = 0
var bestLength = 0
var landIndex = landLength - 1
while landIndex >= 0:
  if land[landIndex] == 'o':
    landBalance += 1
  else:
    landBalance -= 1
  givenLength += 1
  if landBalance >= 0:
    bestLength = givenLength
  landIndex -= 1
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each `o` raises the balance and each `u` lowers it. The best length updates only when the balance stays non-negative. The answer is written once after the loop.

## Complexity

The scan reads each meter once and stores only the strip and a few counters.

| Phase | Time | Space |
| --- | --- | --- |
| read input | one pass over n characters | one string of length n |
| suffix scan | one pass from right to left | three integers |
| output | one line | block buffer |

Work per meter is constant, so the total follows the strip length.

| Measure | Big O |
| --- | --- |
| time | O(n) |
| space | O(n) |

Counting both letters afresh for every suffix costs O(n^2), while the running balance costs O(n). One balance and one pass find the longest allowed suffix.
