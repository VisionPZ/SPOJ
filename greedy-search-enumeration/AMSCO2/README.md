# AMSCO2 — Decipher the AMSCO cipher (SPOJ)

<https://www.spoj.com/problems/AMSCO2/>

## Problem

An AMSCO ciphertext mixes single letters and digraphs in a checkerboard grid, then writes columns in key order. Recover the plaintext for each line, given the numeric key and the ciphertext. Output one uppercase plaintext per line with no spaces.

| item | bound |
|---|---|
| lines N | fewer than 1000 |
| key length | at most 9 |
| ciphertext length | at most 250 |
| letters | A-Z only |
| judge limit | 100 ms, 1536 MB |

The key digits give the rank of each column. Column 1 is written first, then column 2, and so on. Chunk sizes alternate across both rows and columns, starting with a digraph in the top-left cell.

Sample input:

```
7456321 HETEAMTTOWIMONNSEJNDTOSEBRERRHOOISSMIURNORISHIROR
41325 CECRTEGLENPHPLUTNANTEIOMOWIRSITDDSINTNALINESAALEMHATGLRGR
```

Sample output:

```
RIDERSONTHESTORMINTOTHISHOUSEWEAREBORNJIMMORRISON
INCOMPLETECOLUMNARWITHALTERNATINGSINGLELETTERSANDDIGRAPHS
```

## Idea

Undo the writing order before reading the grid, like sorting shuffled pages by their printed number. Split the ciphertext into column pieces by ascending key digit, then walk the grid row by row and take the next chunk from each column. The chunk size follows one parity rule: even row-plus-column sums hold two letters, odd sums hold one. Simulating every possible grid size would add search work, while the row lengths and final tail follow directly from the total character count. Use the direct sizes and rebuild the text once.

## Why It Works

1. A cell at row r and column c holds two letters when r + c is even, and one otherwise.
2. Even-numbered rows therefore hold ceil(K/2) digraphs and floor(K/2) singles.
3. Odd-numbered rows swap the pattern and hold one fewer letter.
4. Repeatedly subtracting full row lengths leaves the tail of the last row.
5. Reading columns by ascending key digit restores each column's letter stream before row-major assembly.

| term | meaning |
|---|---|
| `keyLabels` | rank of each grid column |
| `fullRows` | number of complete rows before the tail |
| `tailLength` | character count left for the final row |
| `lastColumns` | number of populated cells in the final row |
| `columnTexts` | restored letter stream for each column |

For key 7456321, column 1 sits at grid position 6. That column collects HE, T, EA, M, so the ciphertext starts with HETEAM. Reading row by row then gives RIDERSONTHE and more letters.

| key | first cipher column | restored start |
|---|---|---|
| 7456321 | HETEAM | RIDERSONTHE |
| 41325 | CEC | INCOMPLETE |

The final chunk may be shorter than its nominal size when the plaintext ends mid-cell.

## Code

**Input and tokens.** Each input line supplies a key token and a ciphertext token.

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
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc chunkSize(rowIndex: int, columnIndex: int): int =
  if (rowIndex + columnIndex) mod 2 == 0:
    return 2
  return 1
```

Whitespace separates the key from the cipher text.
The parity helper returns the nominal size of one grid cell.

**Grid sizing.** Full rows are removed by subtraction, leaving the short last row.

```nim
while scanPos < inputData.len:
  let keyToken = nextToken(inputData, scanPos)
  if keyToken.len == 0:
    break
  let cipherToken = nextToken(inputData, scanPos)
  let keyLength = keyToken.len
  var keyLabels = newSeq[int](keyLength)
  for digitIndex in 0 .. keyLength - 1:
    keyLabels[digitIndex] = int(keyToken[digitIndex]) - 48

  var evenRowLength = 0
  var oddRowLength = 0
  for columnIndex in 0 .. keyLength - 1:
    evenRowLength = evenRowLength + chunkSize(0, columnIndex)
    oddRowLength = oddRowLength + chunkSize(1, columnIndex)

  var fullRows = 0
  var tailLength = cipherToken.len
  while true:
    let rowLength = if fullRows mod 2 == 0: evenRowLength else: oddRowLength
    if tailLength < rowLength:
      break
    tailLength = tailLength - rowLength
    fullRows = fullRows + 1

  var lastColumns = 0
  var usedInTail = 0
  var prefixBeforeLast = 0
  for columnIndex in 0 .. keyLength - 1:
    usedInTail = usedInTail + chunkSize(fullRows, columnIndex)
    lastColumns = lastColumns + 1
    if usedInTail >= tailLength:
      break
    prefixBeforeLast = prefixBeforeLast + chunkSize(fullRows, columnIndex)
```

Alternating row lengths depend only on the key width.
The last populated column keeps whatever letters remain.

**Column restoration.** Each key rank takes one slice of the ciphertext.

```nim
  var columnLengths = newSeq[int](keyLength)
  for columnIndex in 0 .. keyLength - 1:
    var total = 0
    for rowIndex in 0 .. fullRows - 1:
      total = total + chunkSize(rowIndex, columnIndex)
    if columnIndex < lastColumns - 1:
      total = total + chunkSize(fullRows, columnIndex)
    elif columnIndex == lastColumns - 1:
      total = total + tailLength - prefixBeforeLast
    columnLengths[columnIndex] = total

  var columnTexts = newSeq[string](keyLength)
  var cipherPos = 0
  for label in 1 .. keyLength:
    var targetColumn = 0
    for columnIndex in 0 .. keyLength - 1:
      if keyLabels[columnIndex] == label:
        targetColumn = columnIndex
        break
    for offset in 0 .. columnLengths[targetColumn] - 1:
      columnTexts[targetColumn].add cipherToken[cipherPos + offset]
    cipherPos = cipherPos + columnLengths[targetColumn]
```

Column lengths count every chunk in that column.
Ascending labels reverse the encryption's writing order.

**Assembly.** Row-major reading of the restored columns produces the plaintext.

```nim
  var columnPos = newSeq[int](keyLength)
  var lastRow = fullRows
  if lastColumns > 0:
    lastRow = fullRows + 1
  var plainText = ""
  for rowIndex in 0 .. lastRow - 1:
    for columnIndex in 0 .. keyLength - 1:
      if rowIndex == fullRows and columnIndex >= lastColumns:
        break
      var size = chunkSize(rowIndex, columnIndex)
      if rowIndex == fullRows and columnIndex == lastColumns - 1:
        size = columnTexts[columnIndex].len - columnPos[columnIndex]
      for offset in 0 .. size - 1:
        plainText.add columnTexts[columnIndex][columnPos[columnIndex] + offset]
      columnPos[columnIndex] = columnPos[columnIndex] + size
  appendOutput(plainText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each cell consumes the next chunk from its column stream.
The completed line joins the buffered output.

## Complexity

Each cipher character is read twice, once for slicing and once for assembly.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| sizing | constant work per line | a few length counters |
| restore and assemble | one pass over cipher characters | one string per column |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| time | O(total ciphertext length) |
| space | O(key length plus ciphertext length) |

Searching over all plausible grid shapes would replace this single pass with repeated retries.

The parity rule fixes the grid, so decryption stays a direct reconstruction.
