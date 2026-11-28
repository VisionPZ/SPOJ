# FR104 — Cifrado en Tabla Grado 10 (SPOJ)
<https://www.spoj.com/problems/FR104/>

## Problem

A list of student names must be written in a hidden form.
Each character is shifted by a secret key and written as two uppercase hex digits.
The names themselves sit in alphabetical order inside a vector.
The first input line holds the key, which must be between 0 and 3.
Each following line holds one name, and a line with `*` ends the list.
Print one shifted hex string per name, in alphabetical order.

| Item | Bound |
|---|---|
| Key | 0 to 3 |
| Name count | not stated |
| Name length | not stated |
| Time limit | 1000 ms |
| Memory | 1536 MB |

The key and the alphabet size are small, so ordering and hex writing dominate.

The sample from the statement:

```
2
Juan
JUAN1
Lazaro?
Pedrito
*
```

```
4C776370
4C57435033
4E637C63747141
526766746B7671
```

## Idea

Encrypting a name is like shifting every letter of a label by the same amount.
The program reads all input once and walks it line by line.
It keeps the key and collects every name until the `*` line.
It sorts the names with a quicksort that ignores letter case.
For each name it adds the key to each ASCII code and prints two hex digits.
One output buffer flushes in blocks, so writes stay rare.

Sorting once and shifting once per character gives the whole answer.

## Why It Works

1. Adding the key to an ASCII code changes the byte but keeps its structure.
2. Two hex digits write any byte from 0 to 255 exactly.
3. Uppercase digits match the sample, where `J` plus 2 becomes `4C`.
4. Comparing lowercase letters gives the alphabetical order shown in the sample.
5. A key above 3 violates the stated rule, so the program stops.

The main terms follow.

| Term | Meaning |
|---|---|
| `encryptionKey` | number added to every ASCII code |
| `nameList` | names kept until the terminator appears |
| `nameOrder` | case-insensitive comparison with a byte tie-break |
| `hexDigits` | the sixteen uppercase hex characters |
| `outputBuffer` | one buffer holding output text |

Each name costs one sort placement and one pass over its characters.

A trace from `gen.py --trace` for the sample:

```
Juan -> 4C776370
JUAN1 -> 4C57435033
Lazaro? -> 4E637C63747141
Pedrito -> 526766746B7671
```

The trace matches the sample output byte for byte.

## Code

**Bulk input and line scanner.** This block reads stdin once and finds each line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const hexDigits = "0123456789ABCDEF"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)
```

The read loop ends at end of input.
Both carriage returns and line feeds end a line.
The scanner holds indexes, not copied lines.

**Name ordering and quicksort.** This block sorts names by case-folded bytes.

```nim
proc nameOrder(left: string, right: string): int =
  let sharedLength = if left.len < right.len: left.len else: right.len
  for idx in 0..<sharedLength:
    var leftCode = int(left[idx])
    var rightCode = int(right[idx])
    if leftCode >= 65 and leftCode <= 90:
      leftCode += 32
    if rightCode >= 65 and rightCode <= 90:
      rightCode += 32
    if leftCode < rightCode:
      return -1
    if leftCode > rightCode:
      return 1
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  for idx in 0..<left.len:
    if int(left[idx]) < int(right[idx]):
      return -1
    if int(left[idx]) > int(right[idx]):
      return 1
  return 0

proc partitionNames(names: var seq[string], low: int, high: int): int =
  let middle = (low + high) div 2
  let heldMiddle = names[middle]
  names[middle] = names[high]
  names[high] = heldMiddle
  let pivot = names[high]
  var store = low
  for idx in low..<high:
    if nameOrder(names[idx], pivot) < 0:
      let heldName = names[store]
      names[store] = names[idx]
      names[idx] = heldName
      inc store
  let heldLast = names[store]
  names[store] = names[high]
  names[high] = heldLast
  return store

proc sortNames(names: var seq[string], low: int, high: int) =
  if low >= high:
    return
  let pivotPos = partitionNames(names, low, high)
  sortNames(names, low, pivotPos - 1)
  sortNames(names, pivotPos + 1, high)
```

The middle element becomes the pivot to avoid sorted-input failure.
Raw bytes break ties, so equal case-folded names keep one fixed order.
Quicksort costs n log n comparisons on average.

**Output buffer.** This block buffers text and flushes in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
The last partial block is written after the loop.
No write happens per character.

**Key, names, and hex writing.** This block parses input and prints ciphertext.

```nim
var nameList: seq[string] = @[]
var encryptionKey = -1

while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  var firstByte = lineStart
  while firstByte < lineEnd and inputData[firstByte] <= ' ':
    inc firstByte
  var lastByte = lineEnd
  while lastByte > firstByte and inputData[lastByte - 1] <= ' ':
    dec lastByte
  if firstByte >= lastByte:
    continue
  if encryptionKey < 0:
    var keyValue = 0
    for position in firstByte..<lastByte:
      if inputData[position] >= '0' and inputData[position] <= '9':
        keyValue = keyValue * 10 + int(inputData[position]) - firstDigitValue
    if keyValue > 3:
      break
    encryptionKey = keyValue
  else:
    if lastByte - firstByte == 1 and inputData[firstByte] == '*':
      break
    nameList.add inputData[firstByte .. lastByte - 1]

if nameList.len > 0:
  sortNames(nameList, 0, nameList.len - 1)
for name in nameList:
  for idx in 0..<name.len:
    let codeValue = int(name[idx]) + encryptionKey
    outputBuffer.add hexDigits[codeValue div 16]
    outputBuffer.add hexDigits[codeValue mod 16]
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first nonempty line supplies the key.
The `*` line stops collection before any encryption.
Each character costs two table lookups and two buffer adds.

## Complexity

Cost follows the number of names and their total length.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sorting | n log n name comparisons | name list |
| Hex writing | two digits per character | block buffer |

Sorting once keeps the per-name work small.

| Measure | Big O |
|---|---|
| Time | O(I + n log n + C) |
| Space | O(I + n + B) |

Here I is input bytes, n is name count, C is total characters, and B is block size.

Inserting each name into a sorted list would cost quadratic time.
Quicksort and one output pass finish in near-linear time.
