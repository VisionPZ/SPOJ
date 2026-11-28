# VECTAR11 — Game of Squares (SPOJ)

<https://www.spoj.com/problems/VECTAR11/>

## Problem

Two players subtract a positive perfect square from a number in turn. The player who faces zero loses, and both players play optimally. Report whether the first player wins for each given number.

The first line holds the test count `T`. Each later line holds one starting number. Print `Win` or `Lose` on its own line for each number.

| item | bound |
|---|---|
| test count T | up to 100000 |
| starting number n | up to 1000000 |
| judge limit | 500 ms, 1536 MB |

The product `n` times the square root of `n` drives the precomputation design.

Sample input:

```
3
1
2
3
```

Sample output:

```
Win
Lose
Win
```

## Idea

A number is winning when one move reaches a losing number, like finding a safe rung below you on a ladder. Dynamic programming classifies every number from zero up to the largest query.

Each number tries squares in order and stops at the first losing target. Solving each query alone would repeat the same states many times. Precompute once, then answer every query by table lookup.

## Why It Works

1. Zero is losing because no square can be subtracted.
2. A number is winning exactly when some square leads to a losing number.
3. Squares increase with their roots, so the scan needs only squares up to the number.
4. The scan stops early at the first losing target, which settles the state.
5. Every query reads the finished table in constant time.

| term | meaning |
|---|---|
| `isWinning` | table that marks each number as winning or losing |
| `squareValues` | perfect squares up to the largest query |
| `numberQueries` | starting numbers read from input |
| `largestNumber` | highest starting number, the table limit |

The table covers every value that any query can reach.

A script-generated trace of the losing numbers up to 22:

```
0 2 5 7 10 12 15 17 20 22
```

For example, 8 is winning because subtracting 1 reaches the losing number 7.

## Code

**Input and scanner.** The reader loads all tokens, then the hand scanner extracts integers.

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

The scanner skips whitespace and line breaks between numbers.
It builds each value one digit at a time.
The position advances past the digits that were consumed.

**Buffered output.** One string holds results and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching the block size.
No write happens for a single answer.
One final write drains the remaining text.

**Game table and answers.** The sweep classifies numbers, then queries are answered.

```nim
let caseCount = nextInt(inputData, scanPos)
var numberQueries = newSeq[int](caseCount)
var largestNumber = 0
for queryIndex in 0 .. caseCount - 1:
  numberQueries[queryIndex] = nextInt(inputData, scanPos)
  if numberQueries[queryIndex] > largestNumber:
    largestNumber = numberQueries[queryIndex]

var squareValues = newSeq[int](0)
var squareRoot = 1
while squareRoot * squareRoot <= largestNumber:
  squareValues.add squareRoot * squareRoot
  squareRoot += 1

var isWinning = newSeq[bool](largestNumber + 1)
for numberValue in 1 .. largestNumber:
  for squareValue in squareValues:
    if squareValue > numberValue:
      break
    if not isWinning[numberValue - squareValue]:
      isWinning[numberValue] = true
      break

for queryIndex in 0 .. caseCount - 1:
  if isWinning[numberQueries[queryIndex]]:
    appendOutput("Win\n")
  else:
    appendOutput("Lose\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The table ends at the largest query, so no unused states are built.
The inner loop stops at the first winning move.
Every query then costs one lookup and one buffered write.

## Complexity

The sweep builds a table once, and queries only read it.

| phase | time | space |
|---|---|---|
| input read | one pass over all numbers | one input string |
| table build | square scans up to the largest number | boolean table and square list |
| answer loop | one lookup per query | block buffer |

The build dominates the total work.

| measure | Big O |
|---|---|
| time | O(M sqrt M + T), M is the largest number |
| space | O(M) |

A per-query recursive search would revisit the same states for every test case. The shared table removes that repeated work.
