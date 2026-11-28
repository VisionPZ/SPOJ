# MOZSATD — Sharmeen and the distribution (SPOJ)

<https://www.spoj.com/problems/MOZSATD/>

## Problem

Remove any whole salami amounts, then split the rest into two integer halves. Report the largest half that can be obtained. The goal is a maximum, not any split.

Input gives the count n, then the n amounts on one line. Output is one line with the amount Sharmeen receives.

| item | bound |
|---|---|
| salami count n | 1 to 100000 |
| each amount | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Only the parity and the smallest odd amount decide the answer.

Sample input:

```
3
8 2 5
```

Sample output:

```
5
```

## Idea

Think of removing coins from a pile until the rest can be cut exactly in half. If the pile is already even, keep everything. If it is odd, dropping the smallest odd coin is the cheapest repair. That is a parity argument, costing one pass over the amounts. Trying every subset of coins would take exponential time and cannot scale to n = 100000.

Keep the running sum and the smallest odd amount. Divide the repaired sum by two and print it.

## Why It Works

1. Any share equals half of the sum that remains after the gifts.
2. A remaining sum splits into two integers only when it is even.
3. An even total needs no gift, so the empty gift set is best.
4. An odd total needs an odd gift sum; the smallest odd amount beats any larger odd sum.
5. Subtracting that amount leaves an even sum, and the resulting half is maximal.

| term | meaning |
|---|---|
| `totalTaka` | sum of every salami amount |
| `smallestOddAmount` | least odd amount seen |
| `hasOddAmount` | whether an odd amount exists |
| `sharedTaka` | half of the repaired sum |

The sample amounts are 8, 2, 5. The total is 15, which is odd. The smallest odd amount is 5. Removing it leaves 10, and half of 10 is 5.

| step | value |
|---|---|
| original total | 15 |
| smallest odd amount | 5 |
| repaired total | 10 |
| reported share | 5 |

The last row matches the sample output.

## Code

**Input and scanning.** The reader loads stdin and parses every salami amount.

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
```

The parser ignores spaces and line breaks between amounts. Sums stay in `int64` to hold up to 1e14.

**Parity repair.** One pass chooses the best gift set and writes the share.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let salamiCount = nextInt(inputData, scanPos)
var totalTaka: int64 = 0
var smallestOddAmount: int64 = 0
var hasOddAmount = false
for salamiIndex in 0 .. salamiCount - 1:
  let salamiAmount = int64(nextInt(inputData, scanPos))
  totalTaka += salamiAmount
  if salamiAmount mod 2 == 1:
    if not hasOddAmount or salamiAmount < smallestOddAmount:
      smallestOddAmount = salamiAmount
      hasOddAmount = true
var sharedTaka: int64 = 0
if totalTaka mod 2 == 0:
  sharedTaka = totalTaka div 2
else:
  sharedTaka = (totalTaka - smallestOddAmount) div 2
appendOutput($sharedTaka)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The odd check uses `mod` for judge compiler compatibility. The flag tracks the first odd amount. One flush writes the single answer.

## Complexity

The scan touches each amount once.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| parity repair | one pass over n amounts | constant |
| output | one buffered line | block buffer |

The input read and repair share the same linear pass.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) for input, O(1) for the scan |

Checking all gift subsets would take O(2^n) time, so only the parity argument handles the full bound. The single pass sets the cost.
