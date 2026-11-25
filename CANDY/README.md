# CANDY — Candy I (SPOJ)

<https://www.spoj.com/problems/CANDY/>

## Problem

Equalize candy packets by moving single candies from richer packets to poorer packets. Report the smallest number of moves, or `-1` when equal counts are impossible.

Input holds blocks. Each block starts with packet count N, then N candy counts on separate lines. A line with `-1` ends the input. Output holds one answer per block, in order.

| item | bound |
|---|---|
| packets N | 1 to 10000 |
| candy per packet | 0 to 999 |
| blocks | until `-1` |
| judge limit | 1000 ms, 1536 MB |

The divisibility test decides the whole block.

Sample input:

```
5
1
1
1
1
6
2
3
4
-1
```

Sample output:

```
4
-1
```

## Idea

Equal shares are the average, and every moved candy leaves one surplus packet and fills one deficit packet, like shifting chairs to fill empty seats. Compute the average, reject a fractional average, then add the surplus above it. Each packet needs one division, and one pass sums the surplus. Resimulating every single move would take far longer. Count surplus once and finish.

## Why It Works

1. Equal shares mean every packet ends with the same integer count.
2. That count is the total divided by the packet count.
3. A nonzero remainder makes an integer target impossible, so the answer is `-1`.
4. Each surplus candy above the target must be moved exactly once.
5. Surplus candies equal deficit candies, so counting surplus gives the minimum moves.

| term | meaning |
|---|---|
| `candyTotal` | sum of all packet counts in one block |
| `targetCount` | integer average, `candyTotal` divided by packet count |
| `moveCount` | sum of positive gaps above `targetCount` |

The table shows that one sum and one scan settle each block.

A script trace of the sample:

```
block counts = [1, 1, 1, 1, 6]
total = 10, packets = 5, target = 2
surplus = [0, 0, 0, 0, 4] -> 4 moves
block counts = [3, 4]
total = 7, remainder = 1 -> -1
```

The trace gives 4 moves and `-1`, matching the sample output.

## Code

**Bulk input and scanner.** The reader loads all input and `nextInt` handles the negative sentinel.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const endMarker = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

Newlines and spaces need no special handling.
The minus branch reads only the end marker.
One pass over the text fills `inputData`.

**Buffered output.** One string collects every answer before a single final write.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large blocks flush after a fixed byte count.
No write happens per packet.

**Block answers.** The loop sums counts, tests divisibility, and writes the surplus.

```nim
while true:
  let packetCount = nextInt(inputData, scanPos)
  if packetCount == endMarker:
    break
  var candyCounts = newSeq[int](packetCount)
  var candyTotal: int64 = 0
  for packetIndex in 0 .. packetCount - 1:
    candyCounts[packetIndex] = nextInt(inputData, scanPos)
    candyTotal = candyTotal + int64(candyCounts[packetIndex])
  if candyTotal mod int64(packetCount) != 0:
    appendOutput("-1")
  else:
    let targetCount = candyTotal div int64(packetCount)
    var moveCount: int64 = 0
    for packetIndex in 0 .. packetCount - 1:
      if int64(candyCounts[packetIndex]) > targetCount:
        moveCount = moveCount + int64(candyCounts[packetIndex]) - targetCount
    appendOutput($moveCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`candyTotal` uses int64 to hold up to 10 million candies.
The final flush emits the last buffered answers.

## Complexity

Each block uses one sum pass and one surplus pass.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| block sums | two passes over N counts | array of N counts |
| output | one write per block | block buffer |

The buffer keeps memory flat as blocks grow.

| measure | Big O |
|---|---|
| time | O(N) per block |
| space | O(N) per block |

Moving candies one at a time would cost O(total candies) instead. Counting surplus once is the takeaway.
