# MAXROO — Max and the kangaroo farm (SPOJ)
<https://www.spoj.com/problems/MAXROO/>

## Problem

Count the days needed to empty a line of hungry kangaroos when every even position is fed each day.

The input is one integer N, the initial number of kangaroos.
Each morning the hungry kangaroos are numbered 1 through K.
Every even-numbered kangaroo is fed.
When only one kangaroo remains, that one is fed.
Output one integer: the number of days until none remain.

| item | bound |
|---|---|
| kangaroos N | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Fed kangaroos never return, so the hungry count only drops.

Sample input:

```
9
```

Sample output:

```
5
```

## Idea

Each day keeps the odd positions, like halving a queue and rounding up the survivors.

If K kangaroos are hungry, the survivors are positions 1, 3, 5 and so on.
Their count is K divided by two, rounded up.
A single kangaroo is fed and leaves.
Repeating this halving counts the days.
A simulation of each kangaroo would need N steps and cannot handle a billion.

The halving rule is the whole solution.

## Why It Works

1. Feeding even positions removes floor(K/2) kangaroos.
2. The survivors are the odd positions, numbered ceil(K/2) in count.
3. Renumbering does not change how many remain.
4. A count of one becomes zero after one more day.

| term | meaning |
|---|---|
| `initialRoos` | the starting kangaroo count |
| `hungryRoos` | the count still waiting to be fed |
| `daysWorked` | the number of days already counted |

For the sample the count goes 9, 5, 3, 2, 1, 0.
That is five transitions, so the answer is 5.

## Code

**Input and scanning.** The reader loads the single integer into one string.

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

The scanner ignores the newline and builds the value digit by digit.
The value stays in int64.

**Halving loop and output.** Each pass counts one day and rounds the count up.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

Adding one before the division gives the rounded-up survivor count.
The single survivor needs one more day and leaves directly.

## Complexity

The count halves on every pass, so the loop is short.

| phase | time | space |
|---|---|---|
| input read | one integer | one input string |
| halving loop | about 30 passes | two integers |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(log N) |
| space | O(1) |

Tracking every kangaroo would cost N work instead of a few dozen steps.

The halving loop gives the exact day count for the full input range.
