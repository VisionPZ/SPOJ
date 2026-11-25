# TIEBRKR — Tiebreaker (SPOJ)
<https://www.spoj.com/problems/TIEBRKR/>

## Problem

Several tickets carry numbers and a WIN or NOWIN label. The task keeps the winning numbers, sorts them from lowest to highest, and prints the count followed by the sorted list.

Input starts with t from 1 to 100. Each ticket then uses two lines: an integer ticket number, then the word WIN or NOWIN. Output has two lines: the number of winning tickets, then the winning numbers separated by spaces in ascending order.

| item | bound |
|---|---|
| ticket count t | 1 to 100 |
| ticket number | positive integer |
| ticket status | WIN or NOWIN |
| judge limit | 1000 ms, 1536 MB |

The statement also says "highest to lowest", but the sample lists 101, 501, 5011, so ascending order is correct.

Sample input:

```
5
5011
WIN
4000
NOWIN
101
WIN
500
NOWIN
501
WIN
```

Sample output:

```
3
101 501 5011
```

## Idea

Keep only the winning tickets, then order them like sorting a hand of numbered cards by face value. The algorithm scans the tickets once, stores the winners, and insertion-sorts that short list. Each ticket costs one number read, one status read, and at most t shifts. Scanning all pairs of tickets would cost quadratic time for no benefit. Takeaway: filter first, then sort only the winners.

## Why It Works

1. A WIN ticket belongs in the answer and a NOWIN ticket does not.
2. NOWIN begins with N while WIN begins with W, so one character decides the status.
3. The scanner skips whitespace and stops at the first uppercase letter of a status.
4. Insertion sort keeps the winner list in ascending order.
5. The count line and the sorted list form the required two output lines.

| term | meaning |
|---|---|
| `ticketCount` | number of tickets to inspect |
| `ticketNumber` | number printed on one ticket |
| `isWinner` | true when the status word is WIN |
| `winningTickets` | list of numbers kept for output |
| `winnerCount` | size of that list |

The sample keeps 5011, 101 and 501, then sorts them to 101, 501, 5011. The count line prints 3, which matches the sample output. The empty winner list prints 0 followed by an empty second line.

## Code

**Input and scanning.** The reader loads the input, then reads each number and status word.

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

proc nextStatus(data: string, pos: var int): bool =
  while pos < data.len and not (data[pos] >= 'A' and data[pos] <= 'Z'):
    pos += 1
  var isNoWin = false
  if pos < data.len and data[pos] == 'N':
    isNoWin = true
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    pos += 1
  return not isNoWin
```

`nextInt` reads one ticket number from the digit stream.
`nextStatus` reads one status word and checks its first letter.

**Filter, sort and output.** Winners are sorted in place and written on two lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let ticketCount = nextInt(inputData, scanPos)
var winningTickets = newSeq[int](ticketCount)
var winnerCount = 0
for ticketIndex in 0 .. ticketCount - 1:
  let ticketNumber = nextInt(inputData, scanPos)
  let isWinner = nextStatus(inputData, scanPos)
  if isWinner:
    winningTickets[winnerCount] = ticketNumber
    winnerCount += 1
if winnerCount > 1:
  for position in 1 .. winnerCount - 1:
    let valueToInsert = winningTickets[position]
    var insertionPos = position - 1
    while insertionPos >= 0 and winningTickets[insertionPos] > valueToInsert:
      winningTickets[insertionPos + 1] = winningTickets[insertionPos]
      insertionPos -= 1
    winningTickets[insertionPos + 1] = valueToInsert
appendOutput($winnerCount)
outputBuffer.add '\n'
for winnerIndex in 0 .. winnerCount - 1:
  if winnerIndex > 0:
    outputBuffer.add ' '
  appendOutput($winningTickets[winnerIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`winningTickets` holds at most t entries.
The sort loop runs only when at least two tickets won.
`appendOutput` buffers the result and flushes it once.

## Complexity

At most 100 tickets are inspected and sorted.

| phase | time | space |
|---|---|---|
| input read | one pass over t tickets | one input string |
| filter and sort | t reads plus up to t squared shifts | t winner slots |
| output | two lines | block buffer |

| measure | Big O |
|---|---|
| time | O(t^2) worst case |
| space | O(t) |

A general purpose sort has the same asymptotic cost but more code. Takeaway: filtering and insertion sorting the winners gives the required order directly.
