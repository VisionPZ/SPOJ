# STPAR — Street Parade (SPOJ)

<https://www.spoj.com/problems/STPAR/>

## Problem

A narrow side street works as a stack: the last truck entering leaves first. Given the arrival order of numbered trucks, decide whether they can leave in order from 1 to n.

Input: several test cases. Each starts with `n`, then one line holding a permutation of `1..n` in arrival order. The number `0` ends the input.

Output: `yes` or `no` for each case.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Trucks per case `n` | at most 1000 |
| Arrival order | a permutation of `1..n` |
| Terminator | line containing `0` |
| Judge limit | 1000 ms, 1536 MB |

The narrow lane holds trucks in stack order, so only the top truck can leave.

The sample input and output:

```
5
5 1 2 4 3
0
```

```
yes
```

## Idea

Push every arriving truck onto the side street, then pop whenever the top is the next truck the organizers want. Think of stacking plates and taking the top plate only when it is the next clean one.

The program simulates one stack (a last-in-first-out list) per case. Each truck is pushed once and popped at most once, so the cost is `O(n)` time and `O(n)` space.

Trying every choice of when to push or pop branches exponentially. The forced pop rule removes those choices without losing any valid arrangement.

Greedy pops settle each truck the moment it can leave the lane.

## Why It Works

Four facts prove the simulation.

1. The side street behaves as a stack: the last truck parked must leave first.
2. A truck cannot return to the approach street, so it enters the stack once.
3. Popping the top when it matches the next wanted truck is safe. Delaying that pop only buries it under later trucks.
4. If every truck pops in order `1..n`, the arrangement succeeds. Otherwise a wanted truck sits below a larger truck and can never be reached.

The values used by the driver:

| Term | Meaning |
| --- | --- |
| `stack` | trucks currently parked in the side street |
| `nextExpected` | smallest truck number not yet sent to the parade |
| `arrivingTruck` | next truck read from the approach street |
| `truckCount` | number of trucks in this case |

The loop ends when `nextExpected` equals `truckCount + 1`.

A script trace of the sample case:

```
| arrival | pushed stack | popped | next expected |
| --- | --- | --- | --- |
| 5 | [5] | [] | 1 |
| 1 | [5] | [1] | 2 |
| 2 | [5] | [2] | 3 |
| 4 | [5, 4] | [] | 3 |
| 3 | [] | [3, 4, 5] | 6 |
next expected = 6, count + 1 = 6 -> yes
```

Truck 5 waits while trucks 1 and 2 pass. Then trucks 3, 4, and 5 leave in order.

## Code

**Input and scanner.** One buffer holds the stream, and a digit scanner walks it.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All numbers are positive, so the scanner needs no sign branch.
`appendOutput` flushes at 256 KiB, which covers many short answers.
Each integer parse visits its digits once.

**Stack simulation.** The driver pushes arrivals and pops matching trucks immediately.

```nim
while true:
  let truckCount = nextInt(inputData, i)
  if truckCount == 0:
    break
  var stack: seq[int] = @[]
  var nextExpected = 1
  for j in 0..<truckCount:
    let arrivingTruck = nextInt(inputData, i)
    stack.add arrivingTruck
    while stack.len > 0 and stack[stack.len - 1] == nextExpected:
      stack.setLen(stack.len - 1)
      nextExpected += 1
  if nextExpected == truckCount + 1:
    appendOutput("yes")
  else:
    appendOutput("no")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The `while` loop stops at the zero sentinel before allocating a stack.
`stack.setLen(stack.len - 1)` removes the top in constant time.
The inner pop loop runs once per truck overall, never once per pair.

## Complexity

Each case performs one linear pass over the arrival permutation.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Stack simulation | O(n) pushes and O(n) pops | O(n) for the stack |
| Decision | O(1) comparison | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n) | O(n) |

At `n = 1000` the stack holds at most 1000 integers.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n) per case, O(total trucks) overall |
| Space | O(n) per case, plus buffers |

Exploring all push and pop schedules grows exponentially, while the greedy stack decides each case in linear time.
