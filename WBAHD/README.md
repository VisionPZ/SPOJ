# WBAHD — Weak Bridge Ahead (SPOJ)

<https://www.spoj.com/problems/WBAHD/>

## Problem

A weak bridge allows only one car at a time. Cars queue on both sides, and no car may overtake another. Only the front car of each queue can enter the bridge. Each car needs a known number of seconds to cross. Choose an order that minimizes the longest wait, where a car's wait is the time before it steps onto the bridge.

The first line gives the test count. Each case gives `N`, `M`, then the `N` left-side crossing times and the `M` right-side crossing times. Print `Case x: k`, where `x` starts at one and `k` is the smallest possible maximum wait.

| Item | Bound |
|---|---|
| Test cases | 1 to 10 |
| Left cars `N` | 1 to 10000 |
| Right cars `M` | 1 to 10000 |
| One crossing time | 1 to 10<sup>9</sup> seconds |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
2
1 1
5
3
3 2
9 11 4
10 12
```

The sample output:

```
Case 1: 3
Case 2: 34
```

## Idea

Think of a narrow turnstile with two lines. The last person through has waited while everyone else passed. Give the slowest possible person the final spot, and that longest wait becomes as short as the rules allow.

The program sums every crossing time and records the final crossing time in each queue. The overall last car must be the last car of one queue, so the better choice keeps the larger final time for last. The answer is the total minus that larger final time. Each car is read once, so a case costs one pass over the input.

## Why It Works

1. Waiting times increase along the crossing order, since all crossing times are positive.
2. The final car therefore has the greatest waiting time.
3. Its wait equals the total of all earlier crossing times.
4. That total equals the overall sum minus the final car's own crossing time.
5. Within a queue, the last car must cross after every earlier car in that queue.
6. The overall last car is thus the final car of either the left queue or the right queue.
7. Keeping the larger final crossing time for last minimizes the remaining sum.

| Term | Meaning |
|---|---|
| `leftCarCount` | number of cars waiting on the left |
| `rightCarCount` | number of cars waiting on the right |
| `totalCrossingTime` | sum of all crossing times |
| `lastLeftCrossing` | crossing time of the last left car |
| `lastRightCrossing` | crossing time of the last right car |
| `largestFinalCrossing` | larger of the two final crossing times |

A script-generated trace of the sample:

```
case 1: total 5+3 = 8, finals 5 and 3, larger 5, answer 8-5 = 3
case 2: total 9+11+4+10+12 = 46, finals 4 and 12, larger 12, answer 46-12 = 34
```

Both traced values match the sample output.

## Code

**Input and scanner.** Read all lines once and scan integers by index.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles the long lists of crossing times. Sixty-four-bit accumulation avoids overflow.

**Driver.** Sum the times, keep both final times, and print the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let leftCarCount = nextInt(inputData, scanPos)
  let rightCarCount = nextInt(inputData, scanPos)
  var totalCrossingTime: int64 = 0
  var lastLeftCrossing = 0
  var lastRightCrossing = 0
  for carIndex in 0 ..< leftCarCount:
    let crossingTime = nextInt(inputData, scanPos)
    totalCrossingTime += int64(crossingTime)
    if carIndex == leftCarCount - 1:
      lastLeftCrossing = crossingTime
  for carIndex in 0 ..< rightCarCount:
    let crossingTime = nextInt(inputData, scanPos)
    totalCrossingTime += int64(crossingTime)
    if carIndex == rightCarCount - 1:
      lastRightCrossing = crossingTime
  let largestFinalCrossing = if lastLeftCrossing > lastRightCrossing: lastLeftCrossing else: lastRightCrossing
  let answer = totalCrossingTime - int64(largestFinalCrossing)
  appendOutput("Case " & $(caseIndex + 1) & ": " & $answer & "\n")
stdout.write outputBuffer
```

The last car of each queue is captured while reading. String concatenation builds the case label without formatting calls.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| One case | O(N + M) additions | O(1) |
| Output | one write per filled buffer | one output string |

| Measure | Big O |
|---|---|
| Time | O(test cases + total cars) |
| Space | O(input size) |

Listing every interleaving would take C(N + M, N) orders. The subtraction settles a case during the single read.
