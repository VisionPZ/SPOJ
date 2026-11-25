# ADASEQEN — Ada and Subsequence (SPOJ)

<https://www.spoj.com/problems/ADASEQEN/>

## Problem

Find the most expensive subsequence common to two lowercase strings, where each letter has a given price. Print the total price for each test case.

Each case begins with `N` and `M`, followed by 26 letter prices, then the two strings. Input ends at end of file. A common subsequence may skip characters in both strings, and an empty subsequence has cost zero.

| item | bound |
|---|---|
| string lengths N, M | 1 to 2000 |
| letter price | 1 to 100000 |
| test cases | until end of file |
| judge limit | 2000 ms, 1536 MB |

The product of `N` and `M` drives the dynamic program, not the alphabet size.

Sample input:

```
4 4
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
abcd
dbca
```

Sample output:

```
2
```

## Idea

Keeping only the previous row of the table is like filling a crossword one line at a time with the line above as your sole reference. The algorithm runs weighted longest-common-subsequence dynamic programming with two rolling rows. Each cell costs O(1), so a case costs O(N M). Listing every common subsequence would cost exponential time. Take the best of skipping either character or matching both, then read the answer from the last cell.

## Why It Works

1. A cell holds the best cost for the two string prefixes ending at that row and column.
2. Skipping a character from the first string keeps the value from the previous row.
3. Skipping a character from the second string keeps the value from the left cell.
4. Matching equal characters adds that letter's price to the diagonal cell.
5. Two rows are enough because each cell reads only the previous row and the current row.

| term | meaning |
|---|---|
| `letterPrices` | price of each of the 26 lowercase letters |
| `previousRow` | costs for the earlier row of the first string |
| `currentRow` | costs being filled for the current row |
| `pairedValue` | diagonal cost plus the matched letter's price |

For `baa` and `aab`, the letter `b` costs 7 and the letter `a` costs 1. The common subsequence `b` earns 7, while `aa` earns 2, so the answer is 7.

## Code

**Input and buffer.** The reader loads one case at a time and the buffer collects all answers.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner reads prices as integers and strings as tokens.
Empty prefixes start with zero cost in both rows.
The output buffer is shared across every test case.

**Weighted DP.** Each row updates every column using three candidates.

```nim
while hasMoreData(inputData, scanPos):
  let firstLength = nextInt(inputData, scanPos)
  let secondLength = nextInt(inputData, scanPos)
  var letterPrices = newSeq[int64](26)
  for letterIndex in 0 .. 25:
    letterPrices[letterIndex] = int64(nextInt(inputData, scanPos))
  let firstString = nextToken(inputData, scanPos)
  let secondString = nextToken(inputData, scanPos)
  var previousRow = newSeq[int64](secondLength + 1)
  var currentRow = newSeq[int64](secondLength + 1)
  for firstIndex in 1 .. firstLength:
    currentRow[0] = 0
    for secondIndex in 1 .. secondLength:
      var bestValue = previousRow[secondIndex]
      if currentRow[secondIndex - 1] > bestValue:
        bestValue = currentRow[secondIndex - 1]
      if firstString[firstIndex - 1] == secondString[secondIndex - 1]:
        let letterId = int(firstString[firstIndex - 1]) - 97
        let pairedValue = previousRow[secondIndex - 1] + letterPrices[letterId]
        if pairedValue > bestValue:
          bestValue = pairedValue
      currentRow[secondIndex] = bestValue
    swap previousRow, currentRow
  appendOutput($previousRow[secondLength])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The left column stays at zero after each row swap.
The letter id comes from the character code minus 97.
The last cell of the final row holds the answer.

## Complexity

The nested loop visits one cell for every pair of prefix lengths.

| phase | time | space |
|---|---|---|
| input read | one pass over each case | one input string |
| weighted DP | `O(N M)` cell updates | two rows of length M |
| output | one line per case | block buffer |

The DP loop dominates the running time.

| measure | Big O |
|---|---|
| time | `O(N M)` per test case |
| space | `O(M)` |

Enumerating subsequences would cost exponential time, so the table is the deciding gain. Rolling rows keep the memory small even at the largest lengths.
