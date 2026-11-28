# AMR12G — The Glittering Caves of Aglarond (SPOJ)

<https://www.spoj.com/problems/AMR12G/>

## Problem

A grid of lamps has one switch per row. Choose exactly `K` switch presses, where a press flips every lamp in its row, and maximise the number of lit lamps at the end. Rows may be pressed repeatedly.

Input begins with `T`, the test count. Each case gives `N`, `M`, and `K`, then `N` lines of `M` characters, where `*` is lit and `.` is unlit. Print one integer per case: the largest possible lit count after exactly `K` presses.

| item | bound |
|---|---|
| test cases `T` | 1 to 100 |
| rows `N` | 1 to 50 |
| columns `M` | 1 to 50 |
| presses `K` | 1 to 100 |
| judge limit | 2000 ms, 1536 MB |

Two presses on one row cancel, so only the parity of each row's press count changes its final lamps.

Sample input:

```
2
2 2 1
..
**
2 2 2
..
**
```

Sample output:

```
4
2
```

## Idea

Treat each row as a coin whose parity decides its final face, like flipping a light switch an odd or even number of times. A row pressed an odd number of times shows `M - litCount` lamps, and an even row shows `litCount`. Extra presses beyond the odd rows come in cancelling pairs, so only the count of odd rows matters. Sort the per-row changes, take the best prefix with the right parity, and add the original lit total.

A DP over every row and press count would fill a 50 by 101 table per case. The sorted-prefix method touches one sorted list and one pass over possible odd-row counts. The takeaway is that extra presses are free once parity is chosen.

## Why It Works

1. Pressing a row twice returns every lamp in that row to its previous state.
2. Only odd press counts change a row, and each odd row costs one required press.
3. The gain of making row `r` odd is `M - 2 × litCount` for that row.
4. If `R` rows are odd, `K - R` must be even and nonnegative.
5. For a fixed `R`, the best choice takes the `R` largest gains.

| term | meaning |
|---|---|
| `litTotal` | lit lamps before any press |
| `gains` | change from flipping each row, sorted descending |
| `gainSum` | sum of the largest gains chosen so far |
| `toggledRows` | candidate number of odd rows |
| `bestLit` | largest lit count found |

The table names the values used by the prefix scan.

A script check of the sample gives the following numbers.

| case | `litTotal` | sorted `gains` | feasible odd rows | answer |
|---|---|---|---|---|
| first | 2 | 2, -2 | 1 | 4 |
| second | 2 | 2, -2 | 0 or 2 | 2 |

Both answers follow from adding the best allowed prefix of gains to the original total.

## Code

**Input and input helpers.** The whole input is read once, then rows are taken as words.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    word.add data[pos]
    pos += 1
  return word
```

`nextInt` reads the case header values.
`nextWord` returns one grid row.
`inputData` holds all input bytes.

**Buffered output and row-choice scan.** Gains are sorted, then each parity-feasible prefix is tested.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc sortGainsDescending(gains: var seq[int]) =
  for rightIndex in 1 .. gains.len - 1:
    let currentGain = gains[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and gains[leftIndex] < currentGain:
      gains[leftIndex + 1] = gains[leftIndex]
      leftIndex -= 1
    gains[leftIndex + 1] = currentGain

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var gains = newSeq[int](rowCount)
  var litTotal = 0
  for rowIndex in 0 .. rowCount - 1:
    let rowText = nextWord(inputData, scanPos)
    var litCount = 0
    for charIndex in 0 .. rowText.len - 1:
      if rowText[charIndex] == '*':
        litCount += 1
    gains[rowIndex] = columnCount - 2 * litCount
    litTotal += litCount
  sortGainsDescending(gains)
  var bestLit = -1
  var gainSum = 0
  var toggledRows = 0
  while toggledRows <= rowCount and toggledRows <= operationCount:
    if (operationCount - toggledRows) mod 2 == 0:
      let candidate = litTotal + gainSum
      if bestLit < candidate:
        bestLit = candidate
    if toggledRows < rowCount:
      gainSum += gains[toggledRows]
    toggledRows += 1
  appendOutput($bestLit)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`sortGainsDescending` places the largest row gain first.
`gainSum` grows by one sorted gain per loop step.
`bestLit` keeps the largest feasible candidate.

## Complexity

Counting lamps in a row takes one pass over its characters.

| phase | time | space |
|---|---|---|
| grid read | one pass over N × M characters | one input string |
| gain sort | insertion sort over N rows | one list of N gains |
| prefix scan | up to min(N, K) steps | one output buffer |

| measure | Big O |
|---|---|
| time per case | O(N × M + N² + K) |
| extra space | O(N) |

The row and press DP costs O(N × K²) per case, much more than the sorted-gain scan. Sorting the row gains reduces the choice to one short prefix walk.
