## Problem

Read several arrival orders of trucks numbered 1 to n. A side street works like a stack: trucks enter it in arrival order and leave in reverse order. Decide whether the trucks can leave in the order 1, 2, …, n. Print `yes` or `no` for each order. Input ends with a line containing zero.

| Quantity | Bound |
| --- | --- |
| Trucks per order | at most 1000 |
| Test cases | until zero |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The trucks do not have to stop in the side street, and every truck must eventually leave.

## Idea

Walk through the arrivals and push each truck onto a stack. After every push, keep popping while the top truck is the next one that should leave. At the end the order is possible exactly when all n trucks have left.

Each truck is pushed once and popped at most once, so the cost per order is O(n). Trying every choice of which trucks enter the side street would cost exponential time.

## Why It Works

The side street only reverses the order of trucks that enter it. Once the next required truck is on top, leaving it there cannot help any later truck, so popping it immediately is safe. If it is buried under another truck, no amount of waiting with new arrivals will expose it, so the current choice is forced.

The sample order `5 1 2 4 3` is possible: after pushing 5 and 1, truck 1 is on top and leaves; the same happens for 2, then 4 stays until 3 leaves, and finally 5 leaves.

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

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

Every number is non-negative, so the scanner needs no sign branch. Parsing one number visits each digit once.

The driver simulates the queue and the side street.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let truckCount = nextInt(inputData, scanPos)
  if truckCount == 0:
    break
  var stack: seq[int] = @[]
  var nextExpected = 1
  var possible = true
  for arrivalIndex in 0..<truckCount:
    let arrivingTruck = nextInt(inputData, scanPos)
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

The `nextExpected` value counts trucks already released. A final value of `truckCount + 1` means every truck left in order. Output is written in blocks, not once per order.

## Complexity

Parsing one order costs O(n). The stack walk pushes n trucks and pops at most n, so it also costs O(n) time and O(n) space. Total time is O(total trucks) and total space is O(n) plus the input buffer. Enumerating stack choices would cost O(2ⁿ).
