# SEQ — Recursive Sequence (SPOJ)

<https://www.spoj.com/problems/SEQ/>

## Problem

Each test gives a short linear recurrence and asks for one distant term, reduced modulo one billion.

Input starts with the case count. Each case has four lines: the order `k`, the starting values `b1` to `bk`, the coefficients `c1` to `ck`, and the target index `n`. Output gives one reduced value per case, on its own line.

Notation below: `aj` is a term, `M` is the modulus, `S_i` is the state vector, `T` is the transition matrix, and `e` is the jump count. The modulus equals ten to the ninth, and `aj` uses the statement's indexing.

The bounds from the statement and judge:

| Item | Bound |
|---|---|
| Test cases | about 1000 |
| Order `k` | 1 to 10 |
| Starting values `bj` | 0 to 10^9 |
| Coefficients `cj` | 0 to 10^9 |
| Target `n` | 1 to 10^9 |
| Modulus `M` | 10^9 |
| Judge limit | 500 ms, 1536 MB |

The large target and small order drive the design; the case count sets the per-case budget.

The sample input:

```
3
3
5 8 2
32 54 6
2
3
1 2 3
4 5 6
6
3
24 354 6
56 57 465
98765432
```

The sample output:

```
8
714
257599514
```

## Idea

Picture the last `k` terms as cards in a row. One step shifts the row and writes a new card on the left. Companion-matrix exponentiation turns that shift into a jump, like skipping pages instead of reading every word.

The transition matrix encodes one step. Squaring it doubles the jump in `k` cubed modular products, and the binary expansion of `n` needs at most 30 squares. A term-by-term walk costs `n` products, as many as ten to the ninth per case.

A few dozen matrix squares replace a billion small steps.

## Why It Works

1. The state vector holds `k` consecutive terms, newest first. One transition writes the recurrence sum at the front and shifts every other term one slot right.
2. The transition matrix `T` stays fixed within a case, so its powers jump many steps at once.
3. Binary exponentiation visits at most 30 bits, because the target never exceeds ten to the ninth.
4. Reduction after every product keeps the running sum near one quintillion, inside `int64`.

The rows of the transition carry the whole mechanism:

| Row of `T` | Effect |
|---|---|
| first row | copies the `k` coefficients in order |
| row j, column j minus one | moves one older term one slot right |
| exponent `e` | counts shifts from the start state to the target state |

Those rows define one step, and their powers define every jump.

A script trace for order 2, seeds 3 and 5, coefficients 2 and 1, target 5:

```
order 2 target 5 exponent 3 binary 11
start state [5, 3]
start transition [[2, 1], [1, 0]]
bit set -> accumulator [13, 5]
squared transition [[5, 2], [2, 1]]
bit set -> accumulator [75, 31]
squared transition [[29, 12], [12, 5]]
answer 75
```

The two set bits add 1 + 2 = 3 shifts, and the leading slot ends at 75.

## Code

**Input and constants.** One buffer holds the stream, one scanner walks it by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const sequenceModulus: int64 = 1000000000
const maxOrder = 10

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```

`maxOrder` caps both arrays at the statement bound. `nextInt` walks `inputData` by index, so no token objects are built. The scanner accepts zeros and positive values, and the statement gives no negatives.

**Transition arithmetic.** Squaring doubles the jump; application advances the state.

```nim
proc squareTransition(transition: array[maxOrder, array[maxOrder, int64]], order: int): array[maxOrder, array[maxOrder, int64]] =
  for row in 0 .. order - 1:
    for col in 0 .. order - 1:
      var sum: int64 = 0
      for pivot in 0 .. order - 1:
        sum = (sum + transition[row][pivot] * transition[pivot][col]) mod sequenceModulus
      result[row][col] = sum

proc applyTransition(transition: array[maxOrder, array[maxOrder, int64]], state: array[maxOrder, int64], order: int): array[maxOrder, int64] =
  for row in 0 .. order - 1:
    var sum: int64 = 0
    for col in 0 .. order - 1:
      sum = (sum + transition[row][col] * state[col]) mod sequenceModulus
    result[row] = sum
```

Squaring costs `order` cubed products, and applying costs `order` squared. Each cell is reduced before the next product, which protects `int64`. Both procs use fixed arrays, so no allocation happens per step.

**Driver.** Read every case, jump to the target, and buffer the answers.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = int(nextInt(inputData, scanPos))
var outputBuffer = ""

for _ in 0 .. caseCount - 1:
  let order = int(nextInt(inputData, scanPos))
  var seedValues: array[maxOrder, int64]
  for idx in 0 .. order - 1:
    seedValues[idx] = nextInt(inputData, scanPos) mod sequenceModulus
  var coefficients: array[maxOrder, int64]
  for idx in 0 .. order - 1:
    coefficients[idx] = nextInt(inputData, scanPos) mod sequenceModulus
  let targetIndex = nextInt(inputData, scanPos)
  var answer: int64
  if targetIndex <= int64(order):
    answer = seedValues[int(targetIndex) - 1]
  else:
    var state: array[maxOrder, int64]
    for idx in 0 .. order - 1:
      state[idx] = seedValues[order - 1 - idx]
    var transition: array[maxOrder, array[maxOrder, int64]]
    for col in 0 .. order - 1:
      transition[0][col] = coefficients[col]
    for idx in 1 .. order - 1:
      transition[idx][idx - 1] = 1
    var accumulator = state
    var exponent = targetIndex - int64(order)
    while exponent > 0:
      if (exponent and 1) == 1:
        accumulator = applyTransition(transition, accumulator, order)
      transition = squareTransition(transition, order)
      exponent = exponent shr 1
    answer = accumulator[0]
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

One `readLine` loop fills `inputData` before any case is parsed. The direct branch returns a `seedValues` entry when the target lies inside the starting window. `outputBuffer` flushes at `flushBlockBytes`, and the final write emits the tail.

## Complexity

The work splits into input scanning, matrix squares, and block writes.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| One square | k cubed modular products | k squared cells |
| One apply | k squared modular products | k cells |
| Output | one write per block | block buffer |

Squaring dominates, and the case count multiplies it.

The bounds follow from the bit length of the target:

| Measure | Big O |
|---|---|
| Time | O(C log n · k^3) |
| Space | O(k^2) plus input and output buffers |

The constants stay small because the order never exceeds ten. Term-by-term stepping costs O(n) per case, up to ten to the ninth steps. Matrix powers keep every case near thirty squares.
