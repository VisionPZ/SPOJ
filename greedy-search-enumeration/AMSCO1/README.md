# AMSCO1 — The AMSCO cipher (SPOJ)

<https://www.spoj.com/problems/AMSCO1/>

## Problem

Fill a grid with the plaintext using alternating two-letter groups and single letters, starting with two letters, then read the columns in the order given by a numeric key.

Each input line holds a key and a plaintext. Lines continue until end of file. Print one ciphertext per line, with no spaces.

| item | bound |
|---|---|
| input lines | fewer than 1000 |
| key length | at most 9 |
| plaintext length | at most 250 |
| judge limit | 108 ms, 1536 MB |

The key is a permutation of the column numbers, so each column is read once.

Sample input:

```
41325 INCOMPLETECOLUMNARWITHALTERNATINGSINGLELETTERSANDDIGRAPHS
```

Sample output:

```
CECRTEGLENPHPLUTNANTEIOMOWIRSITDDSINTNALINESAALEMHATGLRGR
```

The sample key reads columns 1, 3, 2, 4, 5 in that order.

## Idea

Filling the grid is like dealing cards into alternately wide and narrow piles, then collecting the piles by numbered ticket. This is an incomplete columnar transposition with alternating group sizes. Each letter is placed once and each column is read once, so work is linear in the plaintext length. Rebuilding the whole grid for every candidate reading would repeat work that the key order removes. Track the column strings directly and output them in key order.

## Why It Works

1. Every row starts with a two-letter group in the first column.
2. Group sizes alternate across columns, so the parity of the column index decides the size.
3. An odd column count flips the starting size on the next row; an even count keeps it.
4. Appending each group to its column builds the same result as writing a full grid.
5. Reading columns by ascending key digit reproduces the transposed ciphertext.

| term | meaning |
|---|---|
| `columnTexts` | letters collected for each column |
| `rowStart` | zero for a two-letter first group, one for a single |
| `takeCount` | group size chosen for one column |
| `digitValue` | key digit currently being read |

These terms follow the grid layout and the key order.

A script trace for the short key from the notes:

```
key 12, plain ABCDEFGHIJKLM
column 0 groups: AB DE GH JK MN
column 1 groups: C F I L
read digit 1 then digit 2: ABDEGHJKMN + CFIL = ABDEGHJKMNCFIL
```

The trace shows why the even-length key keeps every row in the same pattern.

## Code

**Input and token scanner.** Blank separators are skipped, so each line yields a key and a plaintext.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

The reader loads all input at once.
Tokens stop at any whitespace.
A missing key ends the loop.

**Grid simulation.** Groups are appended straight to their destination column.

```nim
proc encryptText(key: string, plain: string): string =
  let columnCount = key.len
  var columnTexts = newSeq[string](columnCount)
  var letterPos = 0
  var rowStart = 0
  while letterPos < plain.len:
    for columnIndex in 0 .. columnCount - 1:
      var takeCount = 1
      if (columnIndex + rowStart) mod 2 == 0:
        takeCount = 2
      let remaining = plain.len - letterPos
      if remaining < takeCount:
        takeCount = remaining
      if takeCount == 0:
        break
      columnTexts[columnIndex].add plain.substr(letterPos, letterPos + takeCount - 1)
      letterPos += takeCount
    if columnCount mod 2 == 1:
      rowStart = 1 - rowStart
```

The row start flips only for an odd key.
A short final group is clipped to the remaining letters.
Each group is copied once.

**Key-order output.** Columns are concatenated by ascending key digit.

```nim
  var cipherText = ""
  for digitValue in 1 .. columnCount:
    for columnIndex in 0 .. columnCount - 1:
      if int(key[columnIndex]) - 48 == digitValue:
        cipherText.add columnTexts[columnIndex]
        break
  return cipherText
```

The inner loop finds the column carrying each digit.
Every column is appended exactly once.
The key permutation guarantees a complete result.

**Driver loop.** Each input pair produces one output line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let key = nextToken(inputData, scanPos)
  if key.len == 0:
    break
  let plain = nextToken(inputData, scanPos)
  if plain.len == 0:
    break
  appendOutput(encryptText(key, plain))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Output accumulates in one buffer.
Large inputs flush in blocks.
The final flush writes the remainder.

## Complexity

Work splits into placement and key-order reading.

| phase | time | space |
|---|---|---|
| input read | one pass over lines | one input string |
| grid simulation | one copy per letter | column strings |
| output | one line per case | block buffer |

The phase table shows one pass over the plaintext.

| measure | Big O |
|---|---|
| time | O(L) per line |
| space | O(L) for one line |

Trying candidate layouts would add a factor of the key length.
The direct column build keeps each line linear.
