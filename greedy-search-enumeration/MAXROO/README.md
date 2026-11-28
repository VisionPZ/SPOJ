# MAXROO — Max and the kangaroo farm (SPOJ)

<https://www.spoj.com/problems/MAXROO/>

## Problem

N hungry kangaroos start on the farm. Each day Max lines up the hungry roos, numbers them 1 to K, and feeds the even-numbered ones. A lone hungry roo is fed that day. Days pass until no roo is left hungry; count them.

The input is one integer N, the number of roos. The output is the number of days.

| item | bound |
|---|---|
| N | 1 ≤ N ≤ 10^9 |
| output | one integer |
| judge limit | 1000 ms, 1536 MB |

The hungry count halves each day, so the loop runs about 30 times.

Sample input:

```
9
```

Sample output:

```
5
```

## Idea

Cutting a stack of coins in half each round empties it in a handful of rounds. The even-numbered roos are exactly half of the line, rounded down, so the hungry count becomes ceil(K/2) after a day.

The program follows this rule day by day instead of simulating every roo. When one roo remains, it is fed that day, so the count drops to zero.

Takeaway: track the count, not the animals.

## Why It Works

1. Feeding positions 2, 4, 6, ... removes floor(K/2) roos, leaving ceil(K/2).
2. The rule holds for every K ≥ 2.
3. For K = 1 the statement feeds that single roo, so the next count is 0.
4. The count strictly falls each day, so the loop ends at zero.
5. Counting loop turns gives the number of days.

For the sample, 9 hungry roos become 5, then 3, then 2, then 1, then 0. That is 5 days.

The special case K = 1 matters: halving would leave 1 forever, so the code zeroes it directly.

## Code

**Input and scanning.** The hand reader loads the file and parses one 64-bit value.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value
```

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Day loop.** The hungry count is halved each turn.

```nim
let initialRoos = nextInt(inputData, scanPos)
var hungryRoos = initialRoos
var daysWorked: int64 = 0
while hungryRoos > 0:
  daysWorked += 1
  if hungryRoos == 1:
    hungryRoos = 0
  else:
    hungryRoos = (hungryRoos + 1) div 2

appendOutput($daysWorked)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`(hungryRoos + 1) div 2` is the ceil of the half.
The `== 1` branch feeds the lone roo.
The loop runs at most 31 times for N up to 10^9.

## Complexity

The day loop halves the count until it reaches zero.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| day loop | one step per day | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(log N) |
| space | O(1) |

Feeding roo by roo would cost O(N) steps, far too many for 10^9.

Takeaway: halving turns a billion days into thirty.
