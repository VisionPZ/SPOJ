# PONDO1 — Pondo One (SPOJ)
<https://www.spoj.com/problems/PONDO1/>

## Problem

Two racers start at the same line on a track of length L. The Pondo advances x meters, then the Pundu jumps by whole steps of y until it is at least as far along. Report WIN when the Pondo reaches the finish first, and LOSS otherwise.

The only input line holds x, y and L. Print one word, WIN or LOSS.

| Constraint | Value |
| --- | --- |
| x, y, L | positive integers below 1000000000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The Pondo moves first in every round, and the Pundu reacts to the position reached.

The first sample pair follows byte for byte.

```
1 2 2
```

```
LOSS
```

The Pundu reaches the finish after the first Pondo step, so the Pondo loses.

## Idea

Picture the finish as a fence and the Pundu's steps as fixed strides: the race is lost only when a stride lands past the fence before the Pondo gets there. Two ceiling divisions give that moment directly. The program computes the last Pondo position short of the finish and the first multiple of y at or past the finish. It compares those two numbers with constant work. Simulating every round can take 1000000000 iterations, so the two divisions replace the loop. Decide the race from two rounded divisions.

## Why It Works

1. The Pondo needs ceil(L / x) steps to reach or pass L.
2. Its last position before the finish is (ceil(L / x) - 1) times x.
3. The Pundu always stands on a multiple of y.
4. Its first multiple at or past L is ceil(L / y) times y.
5. That multiple is reachable from the previous multiple, which sits y meters lower.
6. The Pundu wins exactly when the Pondo has passed that previous multiple.

The table names the four values used in the comparison.

| Term | Meaning |
| --- | --- |
| `pondoStepsToFinish` | number of Pondo steps needed to reach L |
| `lastPondoReach` | largest multiple of x strictly below L |
| `punduFinishReach` | smallest multiple of y at or above L |
| `punduStep` | one robot stride, also the gap before the finishing stride |

Comparing `lastPondoReach` with `punduFinishReach - punduStep` decides the race. A strict greater-than means the robot moves first onto the finish.

A script check of both statement samples gives the following numbers.

| x | y | L | last Pondo reach | first Pundu finish | result |
| --- | --- | --- | --- | --- | --- |
| 1 | 2 | 2 | 1 | 2 | LOSS |
| 5 | 7 | 15 | 10 | 21 | WIN |

When x is at least L, the first Pondo step ends the race and `lastPondoReach` is zero. All arithmetic uses `int64`, so a product of two values below one billion stays exact.

## Code

**Input and scanner.** One line supplies the two step sizes and the track length.

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

```

The scanner skips spaces and line breaks. It folds digits into one value per call.

**Buffered output.** A single string holds the one-word answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes on size and once at the end. No write happens inside a loop.

**Race decision.** Two ceiling divisions produce the comparison values.

```nim
let pondoStep = int64(nextInt(inputData, scanPos))
let punduStep = int64(nextInt(inputData, scanPos))
let trackLength = int64(nextInt(inputData, scanPos))
let pondoStepsToFinish = (trackLength + pondoStep - 1) div pondoStep
let lastPondoReach = (pondoStepsToFinish - 1) * pondoStep
let punduFinishReach = ((trackLength + punduStep - 1) div punduStep) * punduStep
if lastPondoReach > punduFinishReach - punduStep:
  appendOutput("LOSS")
else:
  appendOutput("WIN")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Adding the divisor minus one rounds each division up. The strict comparison matches the rule that the Pondo must already be short when the robot lands.

## Complexity

The program stores a few integers and never loops over the track length.

| Phase | Time | Space |
| --- | --- | --- |
| read input | three numbers | one input string |
| decide race | two divisions and one comparison | constant |
| output | one word | block buffer |

Each phase touches a fixed amount of data.

| Measure | Big O |
| --- | --- |
| time | O(1) |
| space | O(1) |

A round-by-round simulation needs up to L / x rounds, while the closed form needs two divisions. Two rounded divisions settle the whole race in constant time.
