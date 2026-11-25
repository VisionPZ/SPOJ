# EDUPT49 — O Pátio de Manobras e o Trem de Carga (SPOJ)

<https://www.spoj.com/problems/EDUPT49/>

## Problem

Cars arrive in a fixed order and must leave in a desired order, using one siding that acts as a stack. Decide whether the reordering is possible, and print the moves that achieve it.

Input starts with N, followed by the arrival order and the desired order, each holding N distinct car numbers. A PUSH moves the next arriving car onto the stack. A POP moves the top car onto the departing train. Output one move per line, or the word IMPOSSIVEL when no sequence works.

The counts are moderate.

| item | bound |
|---|---|
| car count N | 1 to 1000 |
| car numbers | distinct, from 1 to N |
| judge limit | 1000 ms, 1536 MB |

Every car must be pushed before it can leave the siding, even if it leaves immediately.

Sample input:

```
5
1 2 3 4 5
3 2 5 4 1
```

Sample output:

```
PUSH
PUSH
PUSH
POP
POP
PUSH
PUSH
POP
POP
POP
```

## Idea

Push cars until the wanted one reaches the top, then pop it, like pulling plates off a stack exactly when a waiter asks for them.

The real algorithm is a greedy stack simulation with one arrival cursor. Each car is pushed once and popped once, so the scan is linear. Trying all push and pop sequences would branch exponentially. The takeaway is that the next wanted car forces the next move.

## Why It Works

1. The stack top is the only car that can leave at any moment.
2. If the top is not the wanted car, more arrivals must be pushed.
3. Pushing stops as soon as the wanted car reaches the top.
4. That car is then popped, and the desired order advances.
5. If arrivals run out before the top matches, no valid sequence exists.

| term | meaning |
|---|---|
| `maneuverStack` | cars currently waiting on the siding |
| `nextArrivalIndex` | position of the next car in the arrival line |
| `operationText` | collected move lines, kept until success is known |
| `desiredCar` | next car required by the departure order |

The greedy choice is forced, so the move sequence is unique when it exists.

For the sample the wanted cars are 3, 2, 5, 4, 1. Three pushes place 3 on top, and two pops release 3 then 2. Two more pushes place 5 on top, and three pops release 5, 4 and 1.

For arrival 1, 2, 3, 4 and target 4, 2, 3, 1, the first pop releases 4. The top is then 3 while the next wanted car is 2. No arrivals remain, so the answer is IMPOSSIVEL.

Failed runs discard `operationText` and print only the failure word.

## Code

**Input and scanner.** The whole stream is read once, and three integers are pulled per case header.

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
```

The scanner ignores all white space.
It reads the count and both orders in sequence.
No negative values occur in this task.

**Buffered output and order reads.** Both permutations are stored before any move is chosen.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let carCount = nextInt(inputData, scanPos)
var arrivalOrder = newSeq[int](carCount)
for arrivalIndex in 0 .. carCount - 1:
  arrivalOrder[arrivalIndex] = nextInt(inputData, scanPos)
var desiredOrder = newSeq[int](carCount)
for desiredIndex in 0 .. carCount - 1:
  desiredOrder[desiredIndex] = nextInt(inputData, scanPos)
```

The arrival order fills one array.
The desired order fills a second array.
Both arrays have the same length.

**Greedy simulation and output.** Pushes continue until the wanted car is on top, then one pop records the delivery.

```nim
var maneuverStack = newSeq[int]()
var nextArrivalIndex = 0
var operationText = ""
var possible = true
for desiredCar in desiredOrder:
  while (maneuverStack.len == 0 or maneuverStack[maneuverStack.len - 1] != desiredCar) and nextArrivalIndex < carCount:
    operationText.add "PUSH\n"
    maneuverStack.add arrivalOrder[nextArrivalIndex]
    nextArrivalIndex += 1
  if maneuverStack.len > 0 and maneuverStack[maneuverStack.len - 1] == desiredCar:
    operationText.add "POP\n"
    maneuverStack.setLen(maneuverStack.len - 1)
  else:
    possible = false
    break

if possible:
  appendOutput(operationText)
else:
  appendOutput("IMPOSSIVEL\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each push appends one move line.
A missing top car ends the run as impossible.
Only a successful run releases the stored move lines.

## Complexity

Each car is pushed once and popped at most once.

| phase | time | space |
|---|---|---|
| input read | one pass over both orders | one input string |
| stack scan | one push per car and one pop per car | two order arrays and a stack |
| output | up to two lines per car | one move buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Enumerating all push and pop choices would grow exponentially, while the forced greedy move settles each step in constant time.
