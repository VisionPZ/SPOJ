# BUET19A — Mod (SPOJ)

<https://www.spoj.com/problems/BUET19A/>

## Problem

Two players say numbers instead of showing fingers. Each number picks a gesture by its remainder on division by 3, and the usual rock-paper-scissors winner is printed.

Input starts with T, the number of rounds. Each round holds two integers X and Y, for Gon and Killua. Print GON, KILLUA, or DRAW on its own line for every round.

| item | bound |
|---|---|
| rounds T | 1 to 100000 |
| numbers X and Y | 0 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The number of rounds drives the output size; the value bound keeps each remainder cheap.

The sample case:

```
3
0 1
1 0
3 3
```

```
KILLUA
GON
DRAW
```

## Idea

Fold each number into one of three slots, like dropping a ball into a three-slot wheel, then read the winner from the slot pair. The algorithm is modular reduction: dividing by 3 maps a number to ROCK, PAPER, or SCISSORS in constant time. One wrapped difference between the two remainders decides GON, KILLUA, or DRAW. Comparing every gesture pair by hand would spend more work on the same choice. One modulo and one test per round settle every case.

## Why It Works

1. Division by 3 leaves a remainder of 0, 1, or 2, which maps to one gesture.
2. Equal remainders mean equal gestures, so the round is a DRAW.
3. The wrapped difference of the remainders is 1 exactly when Gon's gesture beats Killua's.
4. The wrapped difference is 2 when Killua wins, so the last branch covers that case.
5. The loop visits each round once, so every pair produces one label.

| Term | Meaning |
|---|---|
| `gonSign` | Gon's number folded into 0, 1, or 2 |
| `killuaSign` | Killua's number folded into 0, 1, or 2 |
| `caseCount` | the number of rounds to judge |
| `gestureCount` | the divisor 3, one value per gesture |

The two folded values carry all the information needed for a winner.

A script-traced example for the sample pairs:

```
X=0 rem 0 ROCK, Y=1 rem 1 PAPER -> KILLUA
X=1 rem 1 PAPER, Y=0 rem 0 ROCK -> GON
X=3 rem 0 ROCK, Y=3 rem 0 ROCK -> DRAW
```

The trace reproduces the sample output line for line.

## Code

**Input and hand scanner.** This block loads all input and reads integers by index.

```nim
const flushBlockBytes = 1 shl 17
const gestureCount = 3

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

The scanner skips every non-digit, so spaces and newlines need no special case.
Each call consumes one number and moves the index past it.
The whole input is scanned once.

**Buffered winner decisions.** This block judges each round and writes through one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let gonNumber = nextInt(inputData, scanPos)
  let killuaNumber = nextInt(inputData, scanPos)
  let gonSign = gonNumber mod gestureCount
  let killuaSign = killuaNumber mod gestureCount
  if gonSign == killuaSign:
    appendOutput("DRAW")
  elif (gonSign - killuaSign + gestureCount) mod gestureCount == 1:
    appendOutput("GON")
  else:
    appendOutput("KILLUA")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly caseCount times, reading two numbers per round.
The buffer flushes at the block limit, then once more at the end.
Each round appends one short label and a newline.

## Complexity

The cost splits into one input pass, one decision per round, and buffered writes.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all numbers | one input string |
| Decisions | one modulo and one test per round | constant |
| Output | one label per round | block buffer |

The input string holds the bulk of the memory; decisions need no extra array.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(T) for the stored input |

The bound follows from reading each round once and deciding in place.

Comparing every gesture pair by hand would do more work per round for the same result. Reading once and deciding on the spot keeps the pass short.
