# VZLA2019J — Jump! (SPOJ)
<https://www.spoj.com/problems/VZLA2019J/>

## Problem

Cacti stand at distinct positions on a line. You may jump each cactus alone, but two cacti one unit apart make you crash. Decide for every case whether all cacti can be jumped safely.

Input starts with T, the number of cases. Each case has a line holding K, followed by a line holding K ascending positions Ci. Output one line per case: Case #X: Survival! when all jumps are safe, otherwise Case #X: Oh no!

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| cacti K per case | 1 to 1000 |
| position Ci | 0 to 1000 |
| positions | ascending and distinct |
| judge limit | 1000 ms, 1536 MB |

Only neighbours in the sorted list can be one unit apart.

Sample input:

```
2
5
1 4 7 10 15
5
1 5 6 20 34
```

Sample output:

```
Case #1: Survival!
Case #2: Oh no!
```

## Idea

Two cacti one unit apart sit next to each other in sorted order, like two adjacent seats in a row. Compare each cactus with the one before it. One adjacent pair at distance one means failure. Checking all pairs repeats work, and neighbouring pairs are the only possible conflicts. Stop at the first conflict and keep the verdict.

## Why It Works

1. Positions ascend and stay distinct, so each neighbour gap is at least one.
2. Two cacti at distance one leave no integer position between them, so they are neighbours.
3. A gap of exactly one triggers the crash rule.
4. Every other gap is safe.
5. One ordered scan therefore decides the whole case.

| term | meaning |
|---|---|
| `cactusCount` | number of cacti in the current case |
| `previousCactus` | last position read |
| `currentCactus` | position being checked |
| `canSurvive` | stays true while no bad gap is seen |

The first case has gaps 3, 3, 3 and 5, so it survives.

## Code

**Input and scanning.** The hand reader loads the case count and each position in order.

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

Numbers may share a line or sit on separate lines.
The scanner skips whitespace and advances one index per number.

**Verdict scan and output.** Each case keeps one previous position and writes one line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let cactusCount = nextInt(inputData, scanPos)
  var previousCactus = nextInt(inputData, scanPos)
  var canSurvive = true
  for cactusIndex in 1 .. cactusCount - 1:
    let currentCactus = nextInt(inputData, scanPos)
    if currentCactus - previousCactus == 1:
      canSurvive = false
    previousCactus = currentCactus
  appendOutput("Case #" & $caseNumber & ": ")
  if canSurvive:
    appendOutput("Survival!\n")
  else:
    appendOutput("Oh no!\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A gap of one clears the survival flag.
The line prefix carries the one-based case number.
The buffer flushes once after all cases.

## Complexity

Each cactus is read once and compared once.

| phase | time | space |
|---|---|---|
| input read | one pass over all positions | one input string |
| gap scan | one comparison per cactus | constant |
| output | one line per case | block buffer |

These costs grow with the total number of cacti.

| measure | Big O |
|---|---|
| time | O(total cacti) |
| space | O(total cacti) for input |

Checking every pair would cost O(K^2) per case instead of O(K).

Adjacent gaps carry all the information the judge needs.
