# MACHMAY — Machine Mayhem (SPOJ)
<https://www.spoj.com/problems/MACHMAY/>

## Problem

Build a robot in M steps by choosing one of N part types at each step. After every step, the counts of all part types must differ by at most two. Count the different valid robots modulo 1000000007. Two robots differ when any step chooses a different part.

Input starts with the test count T. Each following line holds M and N. Output has one integer per test case.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| part types N | 1 to 50 |
| steps M | 1 to 1000000000000000000 |
| result | modulo 1000000007 |
| judge limit | 1000 ms, 1536 MB |

M is far too large for one step at a time, so the count needs a shortcut.

Sample input:

```
3
1 1
2 2
3 2
```

The sample covers one part type and two part types.

Sample output:

```
1
4
6
```

With two part types and three steps, six of the eight sequences stay valid.

## Idea

Think of a robot as a line of counters that must stay inside a narrow band, like people sharing a ladder with a two-rung limit. The algorithm first walks the counters a few thousand steps and records how many robots exist at each length. Those counts obey a short linear recurrence, found by Berlekamp-Massey. Kitamasa exponentiation then jumps to step M using that recurrence. A direct walk over M steps is impossible at the stated bound; a full state matrix would be far larger. A short recurrence makes the jump cheap.

## Why It Works

1. At any step, counts take at most three values: the lowest, one above it and two above it.
2. A state stores how many part types sit at each of those three levels.
3. Adding a part moves one type up one level, and the base level shifts when no type remains there.
4. A part two levels above cannot be chosen while some type still sits at the base level.
5. Multiplying by the number of types in a level counts every distinct choice at once.
6. The totals at lengths r, r+N, r+2N and so on satisfy one linear recurrence for each remainder r.
7. Berlekamp-Massey recovers that recurrence from about twice as many counts as its order.
8. Kitamasa computes x to the power of M div N modulo the recurrence polynomial.
9. The resulting polynomial coefficients pick the starting totals and give the answer.

| term | meaning |
|---|---|
| `highIndex` | count of part types two levels above the base |
| `middleIndex` | count of part types one level above the base |
| `lowCount` | count of part types at the base level |
| `connection` | recurrence polynomial found by Berlekamp-Massey |
| `recurrence` | negated coefficients used by Kitamasa |
| `termLimit` | last step computed directly before jumping |

The state width is at most 51, so direct steps stay cheap.

The generator script produced this example for N=2 over the first four steps. State pairs give the counts at the upper and middle levels.

| steps | state counts | total robots |
|---|---|---|
| 0 | (0,0): 1 | 1 |
| 1 | (0,1): 2 | 2 |
| 2 | (0,0): 2, (1,0): 2 | 4 |
| 3 | (0,1): 6 | 6 |
| 4 | (0,0): 6, (1,0): 6 | 12 |

For two part types the totals repeat with a factor of three every two steps after step three.

Products of two residues stay below 1000000007 squared, so 64-bit integers hold them before reduction.

## Code

**Helpers.** Input, scanner, output buffer and modular inverse power.

```nim
const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007

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

proc modularPower(baseValue, exponentValue: int64): int64 =
  var powerResult = 1.int64
  var baseCopy = baseValue mod moduloBase
  var exponentCopy = exponentValue
  while exponentCopy > 0:
    if (exponentCopy and 1) == 1:
      powerResult = powerResult * baseCopy mod moduloBase
    baseCopy = baseCopy * baseCopy mod moduloBase
    exponentCopy = exponentCopy div 2
  return powerResult
```

`modularPower` supplies inverses for the recurrence search.
`nextInt` reads M as a 64-bit value on this platform.
`appendOutput` collects the one line per case.

**Recurrence tools.** Find the short recurrence and jump to a distant term.

```nim
proc berlekampMassey(terms: seq[int64]): seq[int64] =
  var connection = @[1.int64]
  var previous = @[1.int64]
  var order = 0
  var shift = 1
  var lastDiscrepancy = 1.int64
  for index in 0 .. terms.len - 1:
    var discrepancy = terms[index]
    for coefficientIndex in 1 .. order:
      discrepancy = (discrepancy + connection[coefficientIndex] * terms[index - coefficientIndex]) mod moduloBase
    if discrepancy == 0:
      shift += 1
    else:
      var savedConnection = connection
      let factor = discrepancy * modularPower(lastDiscrepancy, moduloBase - 2) mod moduloBase
      let wantedLength = previous.len + shift
      while connection.len < wantedLength:
        connection.add 0
      for previousIndex in 0 .. previous.len - 1:
        connection[previousIndex + shift] = (connection[previousIndex + shift] - factor * previous[previousIndex]) mod moduloBase
      if 2 * order <= index:
        order = index + 1 - order
        previous = savedConnection
        lastDiscrepancy = discrepancy
        shift = 1
      else:
        shift += 1
  connection.setLen(order + 1)
  return connection

proc multiplyPolynomials(leftPoly, rightPoly, recurrence: seq[int64]): seq[int64] =
  let order = recurrence.len
  var product = newSeq[int64](2 * order - 1)
  for leftIndex in 0 .. order - 1:
    if leftPoly[leftIndex] == 0:
      continue
    for rightIndex in 0 .. order - 1:
      if rightPoly[rightIndex] == 0:
        continue
      product[leftIndex + rightIndex] = (product[leftIndex + rightIndex] + leftPoly[leftIndex] * rightPoly[rightIndex]) mod moduloBase
  for degree in countdown(2 * order - 2, order):
    let highValue = product[degree]
    if highValue == 0:
      continue
    for coefficientIndex in 0 .. order - 1:
      product[degree - coefficientIndex - 1] = (product[degree - coefficientIndex - 1] + highValue * recurrence[coefficientIndex]) mod moduloBase
  return product[0 .. order - 1]

proc recurrenceTerm(initialTerms, recurrence: seq[int64], termIndex: int64): int64 =
  let order = recurrence.len
  if termIndex < int64(initialTerms.len):
    return initialTerms[int(termIndex)]
  var resultPoly = newSeq[int64](order)
  resultPoly[0] = 1
  var basePoly = newSeq[int64](order)
  if order == 1:
    basePoly[0] = recurrence[0]
  else:
    basePoly[1] = 1
  var exponentCopy = termIndex
  while exponentCopy > 0:
    if (exponentCopy and 1) == 1:
      resultPoly = multiplyPolynomials(resultPoly, basePoly, recurrence)
    basePoly = multiplyPolynomials(basePoly, basePoly, recurrence)
    exponentCopy = exponentCopy div 2
  var answer = 0.int64
  for termPosition in 0 .. order - 1:
    answer = (answer + resultPoly[termPosition] * initialTerms[termPosition]) mod moduloBase
  return answer
```

`berlekampMassey` returns coefficients that make each discrepancy zero.
`multiplyPolynomials` reduces degrees above the recurrence order.
`recurrenceTerm` exponentiates x and reads the answer from `initialTerms`.

**Count and driver.** Walk a few steps, fit the recurrence, then jump to M.

```nim
proc robotCount(stepCount, partCount: int64): int64 =
  if partCount == 1:
    return 1
  let width = int(partCount) + 1
  let guessOrder = int((partCount + 1) div 2)
  let remainder = int(stepCount mod partCount)
  let termLimit = (2 * guessOrder + 5) * int(partCount) + remainder
  let workLimit = if stepCount < int64(termLimit): int(stepCount) else: termLimit
  var currentState = newSeq[int64](width * width)
  var nextState = newSeq[int64](width * width)
  currentState[0] = 1
  var totalCounts = newSeq[int64](workLimit + 1)
  totalCounts[0] = 1
  for step in 1 .. workLimit:
    for stateIndex in 0 .. width * width - 1:
      nextState[stateIndex] = 0
    for highIndex in 0 .. int(partCount):
      for middleIndex in 0 .. int(partCount) - highIndex:
        let stateValue = currentState[highIndex * width + middleIndex]
        if stateValue == 0:
          continue
        let lowCount = partCount - int64(highIndex) - int64(middleIndex)
        if lowCount > 0:
          if lowCount >= 2:
            nextState[highIndex * width + middleIndex + 1] = (nextState[highIndex * width + middleIndex + 1] + stateValue * lowCount) mod moduloBase
          else:
            nextState[highIndex] = (nextState[highIndex] + stateValue) mod moduloBase
        if middleIndex > 0:
          if lowCount >= 1:
            nextState[(highIndex + 1) * width + middleIndex - 1] = (nextState[(highIndex + 1) * width + middleIndex - 1] + stateValue * int64(middleIndex)) mod moduloBase
          else:
            nextState[highIndex + 1] = (nextState[highIndex + 1] + stateValue * int64(middleIndex)) mod moduloBase
        if highIndex > 0 and lowCount == 0:
          nextState[width + highIndex - 1] = (nextState[width + highIndex - 1] + stateValue * int64(highIndex)) mod moduloBase
    swap currentState, nextState
    var stepTotal = 0.int64
    for stateIndex in 0 .. width * width - 1:
      stepTotal = (stepTotal + currentState[stateIndex]) mod moduloBase
    totalCounts[step] = stepTotal
  if stepCount <= int64(workLimit):
    return totalCounts[int(stepCount)]
  let sampleCount = 2 * guessOrder + 4
  var samples = newSeq[int64](sampleCount)
  for sampleIndex in 0 .. sampleCount - 1:
    samples[sampleIndex] = totalCounts[remainder + sampleIndex * int(partCount)]
  let connection = berlekampMassey(samples)
  let order = connection.len - 1
  var initialTerms = newSeq[int64](order)
  for termPosition in 0 .. order - 1:
    initialTerms[termPosition] = samples[termPosition]
  var recurrence = newSeq[int64](order)
  for coefficientIndex in 0 .. order - 1:
    recurrence[coefficientIndex] = (moduloBase - connection[coefficientIndex + 1]) mod moduloBase
  return recurrenceTerm(initialTerms, recurrence, int64(stepCount div partCount))

let testCaseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCaseCount - 1:
  let stepCount = int64(nextInt(inputData, scanPos))
  let partCount = int64(nextInt(inputData, scanPos))
  appendOutput($robotCount(stepCount, partCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`workLimit` stops the direct walk once enough samples exist.
`samples` follow one remainder, so every term uses the same recurrence.
The final write sends all test answers at once.

## Complexity

The direct walk is bounded by a small multiple of N steps per case.

| phase | time | space |
|---|---|---|
| direct walk | about N squared steps times N squared states | two small state grids |
| recurrence search | short polynomial work | arrays of about N terms |
| jump to M | polynomial exponentiation in log M | arrays of about N terms |

The walk dominates the runtime, and it does not grow with M.

| measure | Big O |
|---|---|
| direct walk | O(N^3) per case |
| recurrence search | O(N^2) per case |
| jump | O(N^2 log M) per case |
| space | O(N^2) |

All bounds stay small for N at most 50.

One step at a time would take O(M) work, which is impossible at 10 to the 18 steps.

The short recurrence reduces a huge step count to a small polynomial jump.
