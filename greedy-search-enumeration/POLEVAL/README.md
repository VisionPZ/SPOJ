<https://www.spoj.com/problems/POLEVAL/>

## Problem

Evaluate one polynomial at several integer points, then print each result on its own line under a case header. A polynomial of degree `d` has `d+1` coefficients given from highest power down to the constant.

Input holds several cases. Each case has four lines: the degree `d`, the `d+1` coefficients, the point count `k`, and the `k` points. A line containing -1 ends the input. Output has `k+1` lines per case: `Case X:` followed by one result per point.

| item | bound |
|---|---|
| degree d | 0 to 999 |
| point count k | 1 to 100 |
| coefficients and points | -100 to 100 |
| result size | at most `2^63 - 1` |
| judge limit | 1000 ms, 1536 MB |

The sample input:

```
2
1 -2 -1
5
0 1 -1 2 -2
3
2 1 -2 -1
4
0 -1 2 -2
-1
```

The sample output:

```
Case 1:
-1
-2
2
-1
7
Case 2:
-1
0
15
-9
```

## Idea

Nested multiplication is like peeling an onion: each step folds one coefficient into a running total and multiplies by the point. This is Horner's method, and it needs one multiply and one add per coefficient. Computing every power separately needs about twice as many multiplies and a large intermediate product. Read all tokens once, then evaluate each point in a tight loop.

## Why It Works

1. The coefficients arrive in descending degree order, which is exactly the order Horner's method needs.
2. After processing coefficient `c_j`, the running total equals the polynomial built from the coefficients seen so far.
3. Multiplying by the point shifts every existing power up by one before the next coefficient is added.
4. The final total is `p(x)`, the value of the polynomial at point `x`.
5. Signed values need a minus branch in the scanner, and the accumulator uses `int64`.

| term | meaning |
|---|---|
| `degree` | highest power in the polynomial |
| `coefficients` | values from `c_d` down to `c_0` |
| `evaluated` | running Horner total for one point |
| `point` | the integer `x` where the polynomial is evaluated |

The table names every value the loop touches.

A worked trace for `p(x) = x^2 - 2x - 1` at `x = -1`:

| step | coefficient | running total |
|---|---|---|
| start | - | 0 |
| 1 | 1 | 0 * -1 + 1 = 1 |
| 2 | -2 | 1 * -1 + -2 = -3 |
| 3 | -1 | -3 * -1 + -1 = 2 |

The trace ends at 2, matching the third result of Case 1.

## Code

**Input and token scanner.** The reader loads all lines, then `nextInt` skips separators and handles a leading minus.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

The scanner advances one index per token and stops at -1 for the last case.
Negative coefficients and negative points both use the same sign branch.

**Buffered output.** One string collects all result lines and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` writes only after the buffer reaches `flushBlockBytes`.
This avoids one write syscall per result line.

**Case loop and evaluation.** Each point is evaluated with nested multiplication and printed on its own line.

```nim
var degree = nextInt(inputData, scanPos)
var caseNumber = 1
while degree != -1:
  var coefficients = newSeq[int64](degree + 1)
  for coefficientIndex in 0 .. degree:
    coefficients[coefficientIndex] = int64(nextInt(inputData, scanPos))
  let pointCount = nextInt(inputData, scanPos)
  appendOutput("Case " & $caseNumber & ":\n")
  for pointIndex in 0 .. pointCount - 1:
    let point = int64(nextInt(inputData, scanPos))
    var evaluated: int64 = 0
    for coefficientIndex in 0 .. degree:
      evaluated = evaluated * point + coefficients[coefficientIndex]
    appendOutput($evaluated)
    outputBuffer.add '\n'
  caseNumber += 1
  degree = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per coefficient, so cost grows linearly with degree.
The accumulator stays in `int64`, which holds the guaranteed result range.
A final write flushes the remaining buffer after the last case.

## Complexity

Each case reads its tokens once and evaluates every point independently.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| evaluation | `k` times `d+1` steps | array of `d+1` coefficients |
| output | one append per line | block buffer |

The phase table shows that evaluation dominates for large degrees.

| measure | Big O |
|---|---|
| time per case | O(k * d) |
| space per case | O(d) |

Computing powers from scratch costs O(d) multiplies per coefficient and a much larger intermediate value. Nested multiplication keeps the same O(k * d) time with smaller intermediates and simpler code.
