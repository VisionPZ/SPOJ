## Problem

Read t test cases. Each case gives n lifts, each with lowest height li, highest height ui, starting height si, and start direction di. Both chasm edges sit at height zero. Print the fewest whole seconds for the hero to cross, or -1 when no crossing exists.

| Quantity | Bound |
| --- | --- |
| Test cases | t, not bounded in the statement |
| Lifts per case | n ≤ 100 |
| Heights and start | -100 ≤ li ≤ si ≤ ui ≤ 100, and li < ui |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The small height range keeps every lift period short.

## Idea

Work in half-metres and half-seconds so every lift height and meeting time stays a whole number. Precompute each lift's height across one period, then use the Chinese remainder theorem (CRT) to find the first shared time of two adjacent lifts. A step-by-step scan would repeat up to 160000 steps for one pair.

Cost per adjacent pair: O(P) time and O(P) space, with P ≤ 800.

## Why It Works

The two edges act as fixed platforms at height zero. Each edge gets period 1 and one residue at height zero. A lift climbs from its low point to its high point and back, so its period is 4*(ui-li) half-seconds. Its height at time t depends only on t mod P.

A lift reaches any height at most twice per period. The residue tables store those two positions for each height. Two lifts meet when their heights match at the same time.

CRT solves the pair of congruences t ≡ r1 (mod P1) and t ≡ r2 (mod P2). A solution exists when (r1 - r2) mod g equals zero, with g the gcd of the two periods. The solution repeats every lcm(P1, P2) half-seconds.

After a meeting the hero walks 4 half-seconds across the next lift. The final meeting adds 2 half-seconds to reach the finish. Dividing the last time by 2 gives the answer in seconds.

A helper in the generator prints the trace for the sample's first pair. The table below holds that verified output.

| Step | Value |
| --- | --- |
| Edge | period 1, height 0 at every residue |
| Lift 1 | period 12, heights 2 1 0 -1 -2 -1 0 1 2 3 4 3 |
| Shared height 0 | residues 2 and 6 of lift 1 |
| First common time | 2 half-seconds |
| After 4 half-seconds | time 6 |

The first meeting happens at the edge before any waiting is needed.

## Code

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

The Euclid loop ends when the remainder reaches zero. The early return handles a modulus of one, where every residue fits. Each inverse call costs O(log P) time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush runs when the buffer passes 256 KiB. The program writes in large blocks and reuses the same string. Appending costs one pass over the answer text.

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

The outer loop covers all platforms, including both edges. Each lift fills one period of heights and two residue tables. The edge test keeps period 1 and avoids division by zero. The work is at most 800 steps per platform.

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

The outer loop visits each adjacent pair once. The inner loop tests both residues of each height exactly once. `currentTime` jumps by 4 half-seconds, or 2 for the last step. The search costs O(P) time per pair.

## Complexity

Reading costs O(B) time for an input of B bytes. Precomputation costs O(P) time and space per platform, with P ≤ 800. The CRT search costs O(P) time per adjacent pair.

Each case uses O(n*P) time and O(n*P) space. Across the run the time is O(T*n*P) for T cases. Space stays O(n*P) at any moment.

A direct scan over time would cost O(T*n*L), with L the least common multiple of two periods. The largest L here is about 159200, so that scan repeats many cycles.
