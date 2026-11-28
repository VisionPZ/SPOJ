# ABSP1 — abs(a-b) I (SPOJ)

<https://www.spoj.com/problems/ABSP1/>

## Problem

Given a non-decreasing array, report the sum of absolute differences over every distinct pair. The naive double loop times out, so a direct formula is needed.

Input starts with the test count. Each test gives the array length and then the sorted array values. Print one sum per test.

| item | bound |
|---|---|
| test count T | up to 1000 |
| array length N | up to 10000 |
| array value | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The input array is already sorted, so each pair difference is non-negative.

Sample input:

```
3
3
1 2 3
3
1 4 5
3
2 4 6
```

Sample output:

```
4
8
8
```

## Idea

Think of each array value as a weight on a seesaw whose tilt grows away from the midpoint. Every value contributes its larger-neighbor count minus its smaller-neighbor count. A coefficient formula turns the double loop into one pass, while scanning all pairs costs O(N^2) per test.

## Why It Works

1. In a sorted array, a value at position i has N - i - 1 later neighbors and i earlier neighbors.
2. Each later neighbor contributes plus the value, and each earlier neighbor contributes minus the value.
3. Therefore the coefficient of value i is (N - i - 1) - i = 2i - N + 1.
4. Summing that coefficient times every value gives the total over all pairs.
5. The result stays within 64 bits because N is at most 10000 and values at most 1e9.

| term | meaning |
|---|---|
| `values` | sorted array for one test case |
| `coefficient` | number of larger neighbors minus smaller neighbors |
| `pairTotal` | accumulated sum of all pair differences |

The coefficient is negative for early values and positive for late ones.

A worked trace from `gen.py`:

```
array 1 2 3, N = 3
i=0: coefficient -2 -> -2
i=1: coefficient  0 ->  0
i=2: coefficient +2 -> +6
total = 4
```

The total 4 matches the first line of the sample output.

## Code

**Input and scanner.** The whole input is read once and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const pairCoefficientFactor = 2

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

The scanner skips all separators between numbers.
Input is kept in one string for speed.
All array values fit in a signed 64-bit integer.

**Buffered output.** Results collect in one string before a block flush.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each test appends one line.
Large batches flush when the buffer fills.
One final write clears remaining text.

**Formula pass.** One pass over the array computes the pair sum.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = int64(nextInt(inputData, scanPos))
  var pairTotal: int64 = 0
  for elementIndex in 0 .. elementCount - 1:
    let coefficient = pairCoefficientFactor * elementIndex - elementCount + 1
    pairTotal = pairTotal + values[elementIndex] * int64(coefficient)
  appendOutput($pairTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The coefficient uses the array length and the position.
The multiplication is done in int64 to avoid overflow.
The loop visits each element once.

## Complexity

Each test reads its array once and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over all values | one input string |
| formula pass | one step per element | one value array |
| output | one line per test | block buffer |

The array dominates space, and the formula dominates time.

| measure | Big O |
|---|---|
| time | O(N) per test |
| space | O(N) per test |

The pair loop would take O(N^2) per test and time out on large arrays.
The coefficient formula gives the same sum in linear time.
