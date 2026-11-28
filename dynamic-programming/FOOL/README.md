# FOOL — Any fool can do it (SPOJ)

<https://www.spoj.com/problems/FOOL/>

## Problem

Decide whether each word made of curly braces and commas matches the given set grammar, and print one verdict per word.

The grammar calls a valid whole word a `Set`. A `Set` is an opening brace, an optional `List`, then a closing brace. A `List` is one or more `Element` items separated by commas. An `Element` is one character or another `Set`. The legal single characters are the `Atom` items: `{`, `}` and `,`.

Input: a first line with the number of words, then one word per line. Each word has 1 to 200 characters from `{`, `}` and `,`.

Output: `Word #k: Set` or `Word #k: No Set` on its own line, where `k` counts from one.

| Item | Bound |
|---|---|
| Words per input | not bounded by the statement; the first line gives the count |
| Word length | 1 to 200 characters |
| Alphabet | `{`, `}`, `,` |
| Judge limit | 6400 ms, 1536 MB |

The 200-character ceiling sets the row table size. The word count sets the output size.

The sample input:

```
4
{}
{{}}
{{}},{,}}
{,,}
```

The sample output:

```
Word #1: Set
Word #2: Set
Word #3: Set
Word #4: No Set
```

The third word holds two valid sets, so it passes.

## Idea

Think of each start position as a notebook listing every place a valid list can end. Fill the notebooks from right to left, then read the answer from the notebook at position one.

The program is a bottom-up interval dynamic program. Each row is a bitset of end offsets, four 64-bit words wide, which covers the 200-character limit. Row i holds every end offset j where the slice from i to j is a valid `List`.

A single character always forms a valid `Element`, so row i starts with bit i. A `Set` at i and j adds bit j when row i+1 reaches j-1. A comma at k joins a left slice ending at k-1 with a right slice starting at k+1, and a row union adds every end of the right row.

A recursive parser restarts at every split and repeats work. The rows reuse each shorter result once, and a union copies 64 ends at a time. One 200-character word builds 200 rows of four machine words. Build short rows first, then let commas and closing braces extend them.

## Why It Works

Every row is complete before any row to its left is built.

1. Bit i of row i is set, since one character is a valid `Element`.
2. A `Set` slice starts with `{` and ends with `}`. Its inside is empty or a `List`, so `wordLength == 2` passes and longer slices read row i+1.
3. A comma at offset k separates a left part reaching k-1 from a right part starting at k+1. `unionRows` then merges the reachable ends.
4. Rows run from right to left, so every row that a step reads is already final. No row is revisited.

The terms used by the program:

| Term | Meaning |
|---|---|
| `setRowBit` | marks one reachable end in a row |
| `hasRowBit` | reads one reachable end from a row |
| `unionRows` | merges all ends of one row into another |
| `rowWordCount` | machine words per row, four for 200 bits |

A row stores ends, not whole slices, so a union costs four machine-word operations.

A script traced `{{,}}`, a five-character word:

```
word: {{,}}  length: 5
offset char  reachable end offsets
     4    }  {4}
     3    }  {3}
     2    ,  {2}
     1    {  {1, 3}
     0    {  {0, 4}
answer: row 1 reaches offset 3 -> Set
```

Row 1 reaches offset 3, the last character, so the whole word is a `Set`.

## Code

**Constants.** Shared sizes and the digit base, defined once.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxWordChars = 200
const rowWordCount = 4
const bitsPerWord = 64
```

`rowWordCount` covers 200 bits with four 64-bit words. `firstDigitValue` turns a digit byte into its value. `flushBlockBytes` caps the output buffer.

**Hand scanners.** Both tokens come from one buffered read.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWordBounds(data: string, pos: var int): tuple[first, last: int] =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let first = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return (first, pos - 1)
```

`nextInt` skips separators by index and builds the case count. `nextWordBounds` returns the first and last character of a word. Neither scanner allocates a token string.

**Row helpers.** Three operations on the flat bitset table.

```nim
proc setRowBit(rows: var seq[uint64], rowIndex, bitIndex: int) =
  let wordIndex = bitIndex shr 6
  let bitOffset = bitIndex and (bitsPerWord - 1)
  let cellIndex = rowIndex * rowWordCount + wordIndex
  rows[cellIndex] = rows[cellIndex] or (1'u64 shl bitOffset)

proc hasRowBit(rows: seq[uint64], rowIndex, bitIndex: int): bool =
  let wordIndex = bitIndex shr 6
  let bitOffset = bitIndex and (bitsPerWord - 1)
  let cellIndex = rowIndex * rowWordCount + wordIndex
  return ((rows[cellIndex] shr bitOffset) and 1'u64) == 1'u64

proc unionRows(rows: var seq[uint64], targetRow, sourceRow: int) =
  for wordIndex in 0 ..< rowWordCount:
    let targetIndex = targetRow * rowWordCount + wordIndex
    let sourceIndex = sourceRow * rowWordCount + wordIndex
    rows[targetIndex] = rows[targetIndex] or rows[sourceIndex]
```

`setRowBit` writes one bit and `hasRowBit` reads one bit. `unionRows` merges four machine words. Each helper takes a row index plus a bit or row offset.

**Main predicate.** It builds the rows for one word.

```nim
proc isSetWord(data: string, first, last: int, rows: var seq[uint64]): bool =
  let wordLength = last - first + 1
  if wordLength < 2 or data[first] != '{' or data[last] != '}':
    return false
  if wordLength == 2:
    return true
  for cellIndex in 0 ..< (wordLength * rowWordCount):
    rows[cellIndex] = 0'u64
  for startOffset in countdown(wordLength - 1, 0):
    setRowBit(rows, startOffset, startOffset)
    if data[first + startOffset] == '{':
      for endOffset in startOffset + 1 ..< wordLength:
        if data[first + endOffset] == '}':
          if endOffset == startOffset + 1 or hasRowBit(rows, startOffset + 1, endOffset - 1):
            setRowBit(rows, startOffset, endOffset)
    for commaOffset in startOffset + 1 ..< wordLength - 1:
      if data[first + commaOffset] == ',' and hasRowBit(rows, startOffset, commaOffset - 1):
        unionRows(rows, startOffset, commaOffset + 1)
  return hasRowBit(rows, 1, wordLength - 2)
```

The loop runs from `wordLength - 1` down to zero. The `wordLength == 2` check accepts the empty inside. Each comma merges a shorter row, and the final read uses row 1.

**Driver.** One read of stdin and block-buffered output.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var listRows = newSeq[uint64](maxWordChars * rowWordCount)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let wordBounds = nextWordBounds(inputData, scanPos)
  var verdict = "No Set"
  if isSetWord(inputData, wordBounds.first, wordBounds.last, listRows):
    verdict = "Set"
  outputBuffer.add "Word #"
  outputBuffer.add $caseIndex
  outputBuffer.add ": "
  outputBuffer.add verdict
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
```

`inputData` holds every line with a newline appended. `listRows` is allocated once and reused for all words. `outputBuffer` flushes at `flushBlockBytes` and once after the loop.

## Complexity

A word of n characters uses n rows of four machine words.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all lines | input bytes |
| Row build | n rows times two scans of n offsets | n rows of four machine words |
| Output write | one write per block | one output block |
| Total, 100 000 short words | one row build per word | one reusable 6.4 KiB table |

The row table stays small because its size follows the 200-character ceiling, not the word count.

| Measure | Big O |
|---|---|
| Time | O(n^3 / 64) per word, plus one pass over the input bytes |
| Space | O(n) for the rows, plus one output block |

A recursive parser without memoization follows exponentially many split paths. The row program visits each slice once and merges 64 ends at a time.
