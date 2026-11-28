# TIEBRKR — Tiebreaker (SPOJ)

<https://www.spoj.com/problems/TIEBRKR/>

## Problem

A list of ticket numbers is given, each followed by its status `WIN` or `NOWIN`. The program prints how many tickets won, then those winning ticket numbers in increasing order.

Input starts with `t`, the number of tickets to check. Each ticket then takes two lines: its number, then its status. Output holds two lines: the count of winners, then the winning numbers separated by single spaces.

| Item | Bound |
|---|---|
| Tickets `t` | 1 ≤ t ≤ 100 |
| Ticket number | no stated bound; fits in one machine word |
| Status | `WIN` or `NOWIN` |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

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

```
3
101 501 5011
```

## Idea

Keep only the numbers whose status says `WIN`, then sort that short list. Think of a raffle: the caller reads every stub, throws away the losing ones, and lays the winners on the table in order. Sorting the winners costs at most a hundred insertions, so an insertion sort is enough and needs no library import. The whole run is one pass over the input plus a small sort.

## Why It Works

1. A ticket is a winner exactly when its status token starts with `W`, so the status reader returns true for `WIN` and false for `NOWIN`.
2. Winners are written into a fresh array in the order they are read, so nothing else is stored.
3. The insertion sort moves each winner leftward past the larger numbers before it, which leaves the array in increasing order.
4. The sample output lists `101 501 5011`, ascending, so the ascending order is what the judge expects even though the statement text says "highest to lowest".
5. When no ticket wins, the count line is `0` and the second line is empty, which the writer produces by emitting a newline with no numbers.

| Term | Meaning |
|---|---|
| `ticketCount` | `t`, number of tickets to check |
| `winningTickets` | array holding only the winning numbers |
| `winnerCount` | how many entries are filled |
| `isWinner` | true when the status token is `WIN` |
| `valueToInsert` | the winner being slid left during the sort |

A traced run of the sample:

```
read 5011 WIN   -> keep 5011
read 4000 NOWIN -> drop
read 101 WIN    -> keep 101
read 500 NOWIN  -> drop
read 501 WIN    -> keep 501
sort 5011 101 501 -> 101 501 5011
count 3
```

## Code

**Input, scanner and status reader.** This block loads stdin and reads one number and one word at a time.

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

One readLine loop collects all input bytes.
The number scanner skips every non-digit, so line breaks need no care.
The status scanner stops at the first capital letter and tests only that letter.
Scanning costs one pass over the consumed characters.

**Collecting and sorting winners.** This block keeps the winners and orders them.

```nim
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
```

The array is sized for the worst case, so no reallocation happens while filling it.
Insertion sort needs no import and runs fast on at most 100 values.
The guard `winnerCount > 1` skips the sort when there is nothing to order.

**Buffered output.** This block holds the two answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Writing the answer.** This block prints the count line and the number line.

```nim
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

The space is written before every number except the first, so lines never end in a space.
An empty winner list leaves the second line blank, as the judge expects.

## Complexity

The cost splits into input, one sort over the winners, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Collect | O(t) | winner array |
| Sort | O(w²), w ≤ t | constant |
| Output | one small write | buffer |

| Measure | Big O |
|---|---|
| Time | O(t²) worst case, O(t) in practice |
| Space | O(t) |

With t = 100 the sort performs at most 4950 comparisons, which is far below one second.
