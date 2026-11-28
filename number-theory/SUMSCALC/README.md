# SUMSCALC — Five Sums (SPOJ)

<https://www.spoj.com/problems/SUMSCALC/>

## Problem

For each value n, print five sums. They cover 1 to n, evens up to 2n, odds up to 2n−1, squares up to n², and cubes up to n³. Print the five answers on one line, separated by spaces.

| item | bound |
|---|---|
| test cases | one count on the first line, then one n per case |
| n | 1 to 10000 |
| test cases count | up to 200000 |
| judge limit | 1000 ms, 1536 MB |

The largest n drives the need for closed-form formulas instead of loops.

Sample input:

```
3
4
5
6
```

Sample output:

```
10 20 16 30 100
15 30 25 55 225
21 42 36 91 441
```

## Idea

Picture each sum as a staircase of blocks that folds into a rectangle, so one multiplication counts the whole shape. The algorithm uses closed-form power sums: n(n+1)/2, n(n+1), n², n(n+1)(2n+1)/6, and the square of n(n+1)/2. Each case costs a fixed number of 64-bit operations, independent of n. Adding terms one by one would cost up to 10000 steps per case and would waste the time budget. The formulas turn every case into a handful of arithmetic steps.

## Why It Works

1. The first sum pairs 1 with n, 2 with n−1, and so on, giving n(n+1)/2.
2. The even sum is twice the first sum, and the odd sum below 2n is n².
3. The square sum has the standard closed form n(n+1)(2n+1)/6.
4. The cube sum equals the square of the first sum, so it reuses that value.
5. All intermediate products stay inside a 64-bit integer at n = 10000.

| term | meaning |
|---|---|
| `caseCount` | number of values to process |
| `numberValue` | the value n for one case |
| `sumFirst` | sum of integers from 1 to n |
| `sumEven` | sum of even numbers up to 2n |
| `sumOdd` | sum of odd numbers up to 2n−1 |
| `sumSquares` | sum of squares up to n² |
| `sumCubes` | sum of cubes up to n³ |

The table shows that every output column has its own formula.

A script-traced example from the generator:

```
n = 4
sumFirst = 4 * 5 / 2 = 10
sumEven = 4 * 5 = 20
sumOdd = 4 * 4 = 16
sumSquares = 4 * 5 * 9 / 6 = 30
sumCubes = 10 * 10 = 100
```

The trace reproduces the first sample line exactly.

## Code

**Input and scanner.** The reader loads stdin once and pulls integers with a digit scanner.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scan advances one position per number.
The output buffer flushes when it reaches the block size.
Both helpers run once per case in constant time.

**Formula loop.** Each case computes five sums and appends one answer line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = int64(nextInt(inputData, scanPos))
  let sumFirst = numberValue * (numberValue + 1) div 2
  let sumEven = numberValue * (numberValue + 1)
  let sumOdd = numberValue * numberValue
  let sumSquares = numberValue * (numberValue + 1) * (2 * numberValue + 1) div 6
  let sumCubes = sumFirst * sumFirst
  appendOutput($sumFirst)
  outputBuffer.add ' '
  appendOutput($sumEven)
  outputBuffer.add ' '
  appendOutput($sumOdd)
  outputBuffer.add ' '
  appendOutput($sumSquares)
  outputBuffer.add ' '
  appendOutput($sumCubes)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per case, not once per integer.
int64 products protect the square and cube formulas from overflow.
The final write emits any bytes left in the buffer.

## Complexity

Every case uses a fixed number of operations, so the test count sets the total cost.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input string |
| formula work | constant operations per case | five 64-bit values |
| output | one line per case | block buffer |

The phase table shows that input and output dominate the runtime.

| measure | Big O |
|---|---|
| time | O(T) for T test cases |
| space | O(N) for the input buffer |

Summing each term in a loop would cost O(T × n); the closed forms remove that factor.
