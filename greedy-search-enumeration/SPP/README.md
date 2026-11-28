# SPP — Recursive Sequence (Version II) (SPOJ)

<https://www.spoj.com/problems/SPP/>

## Problem

A recurrence of order k starts from k given values and repeats a fixed linear rule. Report the sum of terms m through n, reduced modulo p.

Input starts with the test count. Each test gives k, the k starting values, the k recurrence weights, then m, n and p. Output one line per test with the reduced sum.

| item | bound |
|---|---|
| test cases | about 50 |
| order k | 1 to 15 |
| start values b | 0 to 10^9 |
| weights c | 0 to 10^9 |
| indices m, n | 1 to 10^18 |
| modulus p | 1 to 10^8 |
| judge limit | 3000 ms, 1536 MB |

The index bound drives the design: no loop over terms can finish.

Sample input:

```
1
2
1 1
1 1
2 10 1000003
```

Sample output:

```
142
```

## Idea

Fast-forward the recurrence the way you skip ahead in a video: double the jump each time instead of stepping term by term.

The algorithm exponentiates a matrix that carries the last k terms and the running prefix sum. Multiplication composes two jumps, so binary powers reach index 10^18 in about 60 rounds.
A round costs k cubed operations. The direct recurrence costs one operation per term and cannot handle 10^18 terms.
Two prefix values subtract to give the requested range sum.

## Why It Works

1. The state holds the newest term first, then older terms, then the prefix sum.
2. One matrix step shifts every term back and adds the new term to the sum.
3. Powers of the same matrix compose, so binary exponentiation jumps many steps.
4. The sum from index 1 to n minus the sum to index m minus one is the answer.
5. Each addition and product is reduced modulo p, so int64 holds every intermediate.

| term | meaning |
|---|---|
| `stateVector` | last k terms and the running prefix sum |
| `transition` | companion matrix for one step |
| `advanceVector` | apply one matrix step to the state |
| `multiplyMatrix` | compose two matrices under the modulus |
| `upperPower` | exponent that reaches index n |
| `lowerPower` | exponent that reaches index m minus one |

The table names the pieces that carry the jump.

Worked example for k = 2, starting values 1 and 1, weights 1 and 1, modulus 1000003:

```
terms: 1 1 2 3 5 8 13 21 34 55
prefix sums: 1 2 4 7 12 20 33 54 88 143
S_10 = 143, S_1 = 1, answer = 142
```

The two prefix sums differ by exactly the requested range.

## Code

**Transition helpers.** These routines apply and compose jumps without growing the state.

```nim
proc multiplyMatrix(left: seq[int64], right: seq[int64], size: int, modulus: int64): seq[int64] =
  var result = newSeq[int64](size * size)
  for rowIndex in 0 .. size - 1:
    for columnIndex in 0 .. size - 1:
      var total: int64 = 0
      for innerIndex in 0 .. size - 1:
        total = (total + left[rowIndex * size + innerIndex] * right[innerIndex * size + columnIndex]) mod modulus
      result[rowIndex * size + columnIndex] = total
  return result

proc advanceVector(state: var seq[int64], transition: seq[int64], size: int, modulus: int64) =
  var updated = newSeq[int64](size)
  for columnIndex in 0 .. size - 1:
    var total: int64 = 0
    for rowIndex in 0 .. size - 1:
      total = (total + state[rowIndex] * transition[rowIndex * size + columnIndex]) mod modulus
    updated[columnIndex] = total
  state = updated

```

Each vector update loops over k plus one positions.
Each matrix product loops over three dimensions.
The modulus is applied on every accumulated product.

**Case driver.** This loop builds the companion matrix and jumps to both endpoints.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let order = nextInt(inputData, scanPos)
  var initialValues = newSeq[int64](order)
  for valueIndex in 0 .. order - 1:
    initialValues[valueIndex] = int64(nextInt(inputData, scanPos))
  var coefficients = newSeq[int64](order)
  for valueIndex in 0 .. order - 1:
    coefficients[valueIndex] = int64(nextInt(inputData, scanPos))
  let lowerIndex = int64(nextInt(inputData, scanPos))
  let upperIndex = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  let size = order + 1
  var transition = newSeq[int64](size * size)
  for sourceIndex in 0 .. order - 1:
    transition[sourceIndex * size] = coefficients[sourceIndex] mod modulus
    transition[sourceIndex * size + order] = coefficients[sourceIndex] mod modulus
  for targetIndex in 1 .. order - 1:
    transition[(targetIndex - 1) * size + targetIndex] = 1
  transition[order * size + order] = 1
  var stateVector = newSeq[int64](size)
  var runningTotal: int64 = 0
  for valueIndex in 0 .. order - 1:
    runningTotal = (runningTotal + initialValues[valueIndex]) mod modulus
    stateVector[order - 1 - valueIndex] = initialValues[valueIndex] mod modulus
  stateVector[order] = runningTotal
  var upperPower = upperIndex - int64(order)
  var lowerPower = int64(0)
  var lowerState = stateVector
  if lowerIndex - 1 > int64(order):
    lowerPower = lowerIndex - 1 - int64(order)
  else:
    var prefixTotal: int64 = 0
    for valueIndex in 0 .. int(lowerIndex) - 2:
      prefixTotal = (prefixTotal + initialValues[valueIndex]) mod modulus
    lowerState[order] = prefixTotal
  while upperPower > 0 or lowerPower > 0:
    if (upperPower and 1) == 1:
      advanceVector(stateVector, transition, size, modulus)
    if (lowerPower and 1) == 1:
      advanceVector(lowerState, transition, size, modulus)
    transition = multiplyMatrix(transition, transition, size, modulus)
    upperPower = upperPower shr 1
    lowerPower = lowerPower shr 1
  var answer = stateVector[order] - lowerState[order]
  if answer < 0:
    answer = answer + modulus
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The lower prefix uses direct values when its index stays inside the starting block.
Both powers advance while one matrix squares underneath them.
The final subtraction wraps once to stay non-negative.

## Complexity

Costs split into squaring work and state updates.

| phase | time | space |
|---|---|---|
| read one test | O(k) | O(k) |
| matrix squaring | O(k^3 log n) | O(k^2) |
| state jumps | O(k^2 log n) | O(k) |
| output | one line | block buffer |

Squaring dominates the phase table.

| measure | Big O |
|---|---|
| time per test | O(k^3 log n) |
| space per test | O(k^2) |

A term-by-term loop would take O(n) time and never finish for n = 10^18.
The matrix jump keeps the work tied to the order and the bit length of n.
