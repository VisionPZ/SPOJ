## Problem

Read several data sets. Each gives a number `n`, a count `k`, and `k` positions in a bracket string of length `2n`. Count the proper bracket expressions whose opening brackets include all `k` given positions. Print one count per data set.

| Quantity | Bound |
| --- | --- |
| Data sets `d` | 1 to 10 |
| Pairs `n` | 1 to 19 |
| Fixed positions `k` | 1 to `n` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

A proper expression never has more closing brackets than opening brackets in any prefix, and ends with equal counts.

## Idea

Sweep the string from left to right while tracking the current balance. At each position try a closing bracket when the balance is positive and an opening bracket when fewer than `n` are open. Positions named in the input allow only an opening bracket. Add the number of ways reaching each balance in a second table.

Each of the `2n` positions updates at most `n + 1` balances, so the cost per data set is O(n²). Enumerating all bracket strings would cost O(4ⁿ).

## Why It Works

A prefix balance records how many more openings than closings have appeared. A closing bracket is legal only when that balance is positive. An opening bracket is legal only when fewer than `n` openings have been used, so the total cannot exceed `n`. Reaching balance zero after `2n` positions means the expression is proper.

The update rule is:

- if `balance > 0`, add `ways[balance]` to `nextWays[balance − 1]`
- if `balance < n`, add `ways[balance]` to `nextWays[balance + 1]`
- at a fixed position, skip the closing branch

The sample data set `n = 4`, fixed positions 5 and 7 has two valid expressions. The final table reports the count at balance zero.

## Code

Input is read once and parsed with a digit scanner.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

Every input number is positive, so the scanner needs no sign branch. Parsing one number visits each digit once.

The driver marks fixed positions and runs the balance DP.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dataSetCount = nextInt(inputData, i)
for j in 0..<dataSetCount:
  let pairCount = nextInt(inputData, i)
  let fixedCount = nextInt(inputData, i)
  var mustOpen = newSeq[bool](2 * pairCount + 1)
  for k in 0..<fixedCount:
    let l = nextInt(inputData, i)
    mustOpen[l] = true
  var ways = newSeq[int64](pairCount + 1)
  ways[0] = 1
  for k in 1..(2 * pairCount):
    var nextWays = newSeq[int64](pairCount + 1)
    for balance in 0..pairCount:
      if ways[balance] == 0:
        continue
      if not mustOpen[k]:
        if balance > 0:
          nextWays[balance - 1] += ways[balance]
      if balance < pairCount:
        nextWays[balance + 1] += ways[balance]
    ways = nextWays
  appendOutput($ways[0])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `mustOpen` array is indexed by one-based position, matching the statement. Each balance contributes to at most two entries of the next row. The answer is the count at balance zero. Output is written in blocks, not once per data set.

## Complexity

Marking fixed positions costs O(k). The balance table costs O(n²) time and O(n) space per data set. Output costs O(1) per data set. Total time is O(n² + k) per data set and total space is O(n) plus the input buffer. Enumerating all strings would cost O(4ⁿ).
