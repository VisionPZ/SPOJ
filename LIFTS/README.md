# LIFTS — Lifts (SPOJ)

<https://www.spoj.com/problems/LIFTS/>

## Problem

A hero crosses a chasm by stepping between lifts that rise and fall. Two neighboring lifts line up only at certain moments.

Read `t` cases. Each case gives `n` lifts, each with a low height, a high height, a start height, and a start direction. Both chasm edges sit at height zero.

Print the fewest whole seconds for the crossing, or `-1` when no crossing exists.

The bounds and judge limits:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | not bounded in the statement |
| Lifts per case `n` | at most 100 |
| Heights and start | `-100 <= li <= si <= ui <= 100`, with `li < ui` |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The small height range keeps every lift period short.

The sample case:

```
1

4
-1 2 1 -1
0 3 0 1
-4 0 0 -1
-2 1 0 -1

```

```
29
```

## Idea

Measure heights in half-metres and time in half-seconds, so every position and meeting stays a whole number.

Think of each lift as a clock face that repeats its heights. Instead of watching every tick, compare the two clocks with the Chinese remainder theorem (CRT, a method for solving paired clock congruences). Precompute one period of heights and two residue tables per lift.

Then solve for the first shared time of each adjacent pair.

Each pair costs O(P) time and O(P) space, with `P <= 800`. A step-by-step scan repeats up to 160000 half-seconds for one pair. CRT jumps straight to the first meeting.

## Why It Works

Five facts prove the meeting times exact.

1. Both chasm edges act as fixed platforms at height zero. Each edge gets period 1 and one residue at height zero.
2. A lift climbs to its high point and returns, so its half-second period is `2 * (high - low)` in half-metres. The bound of 100 keeps that period at most 800.
3. A lift reaches any height at most twice per period. `firstResidue` and `secondResidue` store both times for each height.
4. CRT solves `t = r1 (mod P1)` and `t = r2 (mod P2)`. A solution exists when `(r1 - r2) mod g` is zero, with `g` the gcd of the two periods. Solutions repeat every `lcm(P1, P2)` half-seconds.
5. After a meeting the hero walks 4 half-seconds across the next lift. The last step adds 2 half-seconds to reach the far edge. Dividing the final time by 2 gives whole seconds.

The arrays and their roles:

| Term | Meaning |
| --- | --- |
| `periods` | half-second cycle length of each platform |
| `positions` | height at each time inside one period |
| `firstResidue` | first time a height occurs in the period |
| `secondResidue` | second time that height occurs |
| `inverseValue` | modular inverse used by CRT |
| `currentTime` | earliest half-second the hero can stand ready |

These tables let one pair search test at most two residues per height.

A helper in the generator traces the sample's first pair:

```
edge: period 1, height 0 at every residue
lift 1: period 12, heights 2 1 0 -1 -2 -1 0 1 2 3 4 3
shared height 0: residues 2, 6 of lift 1
first common time at or after 2: 2 half-seconds
after 4 half-seconds of walking the hero reaches time 6
```

The first meeting happens at the edge before any waiting. Residue 2 is the first time lift 1 reaches height zero.

## Code

**Setup and scanner.** One buffer holds the input, and the scanner keeps negative signs.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const heightOffset = 256
const noResidue = -1

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value
```

The read loop runs until the input ends. The scanner keeps the sign, which negative lift heights need. Parsing costs one pass over the input bytes.

**Number theory helpers.** Euclid gives the gcd, and an extended run gives the modular inverse.

```nim
proc gcdValues(aValue, bValue: int): int =
  var larger = aValue
  var smaller = bValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc inverseModulo(aValue, modulus: int): int =
  if modulus == 1:
    return 0
  var oldCoeff = 1
  var coeff = 0
  var oldValue = aValue
  var value = modulus
  while value != 0:
    let quotient = oldValue div value
    let nextValue = oldValue - quotient * value
    oldValue = value
    value = nextValue
    let nextCoeff = oldCoeff - quotient * coeff
    oldCoeff = coeff
    coeff = nextCoeff
  var answerValue = oldCoeff mod modulus
  if answerValue < 0:
    answerValue += modulus
  return answerValue
```

The Euclid loop ends when the remainder reaches zero. The early return handles a modulus of one. Each inverse call costs O(log P) time.

**Buffered output.** A single string collects every answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush runs when the buffer passes 256 KiB. The program reuses the same string for every block. Appending costs one pass over the answer text.

**Lift period tables.** One loop fills heights and both residue tables for each platform.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0..<testCount:
  let liftCount = nextInt(inputData, scanPos)
  let platformCount = liftCount + 2
  var periods = newSeq[int](platformCount)
  var positions = newSeq[seq[int]](platformCount)
  var firstResidue = newSeq[seq[int]](platformCount)
  var secondResidue = newSeq[seq[int]](platformCount)
  for platformIndex in 0..<platformCount:
    var lowPos = 0
    var highPos = 0
    var initPos = 0
    var direction = 1
    if platformIndex > 0 and platformIndex <= liftCount:
      lowPos = 2 * nextInt(inputData, scanPos)
      highPos = 2 * nextInt(inputData, scanPos)
      initPos = 2 * nextInt(inputData, scanPos)
      direction = nextInt(inputData, scanPos)
    let period = if highPos > lowPos: 2 * (highPos - lowPos) else: 1
    periods[platformIndex] = period
    var positionSeq = newSeq[int](period)
    var firstSeq = newSeq[int](513)
    var secondSeq = newSeq[int](513)
    for slot in 0..512:
      firstSeq[slot] = noResidue
      secondSeq[slot] = noResidue
    var height = initPos
    var stepDir = direction
    for i in 0..<period:
      positionSeq[i] = height
      let slot = height + heightOffset
      if firstSeq[slot] == noResidue:
        firstSeq[slot] = i
      else:
        secondSeq[slot] = i
      if stepDir == 1:
        if height < highPos:
          height += 1
        else:
          height -= 1
          stepDir = -1
      else:
        if height > lowPos:
          height -= 1
        else:
          height += 1
          stepDir = 1
    positions[platformIndex] = positionSeq
    firstResidue[platformIndex] = firstSeq
    secondResidue[platformIndex] = secondSeq
```

The outer loop covers every platform, including both edges. The edge test keeps period 1 and avoids division by zero. The inner loop takes at most 800 steps per platform.

**CRT meeting search.** Each adjacent pair resolves to the first shared time.

```nim
  var currentTime = 2
  var possible = true
  for platformIndex in 0..<platformCount - 1:
    let firstPeriod = periods[platformIndex]
    let secondPeriod = periods[platformIndex + 1]
    let common = gcdValues(firstPeriod, secondPeriod)
    let cycleLength = (firstPeriod div common) * secondPeriod
    let reducedSecond = secondPeriod div common
    let inverseValue = inverseModulo(firstPeriod div common, reducedSecond)
    var bestTime = high(int)
    for i in 0..<firstPeriod:
      let sharedHeight = positions[platformIndex][i]
      let slot = sharedHeight + heightOffset
      for j in [firstResidue[platformIndex + 1][slot], secondResidue[platformIndex + 1][slot]]:
        if j != noResidue and (i - j) mod common == 0:
          var remainderValue = ((j - i) div common) mod reducedSecond
          if remainderValue < 0:
            remainderValue += reducedSecond
          let stepCount = (remainderValue * inverseValue) mod reducedSecond
          var baseTime = (i + firstPeriod * stepCount) mod cycleLength
          if baseTime < currentTime:
            let skip = (currentTime - baseTime + cycleLength - 1) div cycleLength
            baseTime += skip * cycleLength
          if baseTime < bestTime:
            bestTime = baseTime
    if bestTime == high(int):
      possible = false
      break
    currentTime = bestTime + (if platformIndex < liftCount: 4 else: 2)
  if possible:
    appendOutput($(currentTime div 2))
  else:
    appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop visits each adjacent pair once. The inner loop tests both residues of each shared height. `currentTime` jumps by 4 half-seconds, or 2 for the last step.

## Complexity

Precomputation and meeting search both scale with the period length.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | input buffer |
| Period tables | O(P) per platform | O(P) per platform |
| CRT pair search | O(P) per adjacent pair | O(1) extra |
| Output | O(t) | one output block |

Here `P` is at most 800 because heights stay inside `[-100, 100]`.

| Measure | Big O |
| --- | --- |
| Time | O(n P) per case, O(T n P) overall |
| Space | O(n P) at any moment |

A direct scan over time costs O(T n L), with `L` the least common multiple of two periods. The largest `L` here is about 159200.
