# PHDISP — The Philosophical Dispute (SPOJ)

<https://www.spoj.com/problems/PHDISP/>

## Problem

A point follows the curve x = sin(√t), y = cos(t) as t grows.
For each dot center and radius, give any t in [0, 10^12] where the curve enters the dot, or FAIL.

Input: an integer case count, then one line with x0 y0 and one line with eps per case.
Output: one time per case, written with one digit after the decimal point, or FAIL.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases | at most 150 |
| Center x0, y0 | -1 to 1 |
| Radius eps | at least 0.0001 |
| Time t | 0 to 10^12 |
| Judge limit | 3000 ms, 1536 MB |

The small radius drives the design, since the dot covers little area.

The sample input:

```
1
0.744 0.554
0.01
```

The sample output:

```
5.3
```

The answer 5.3 is a tenth where the curve lies inside the dot.

## Idea

Match the slow coordinate first, then let the fast coordinate sweep.
Think of a painter walking slowly across a wall while waving a brush quickly up and down.
Each slow position gets a full vertical sweep, so some stroke enters the dot.

The method is a band-and-phase search.
It lists the slow-coordinate bands where sin(√t) can match x0.
Inside each band it jumps to times where cos(t) equals y0, then tests nearby tenths.
Each band costs a few arithmetic steps, and the search stops at the first hit.
Stepping t by tenths from zero can need 10^13 tests before the first hit.
Fix the slow coordinate first, and the fast sweep lands inside the dot.

## Why It Works

1. Put u = √t. Then x = sin u, so exact x matches sit in two families of u.
2. Those families are arcsin(x0) + 2πk and π − arcsin(x0) + 2πk, for integer k.
3. Near one match, |sin u − x0| stays below eps across a band of u values.
4. The cosine runs through every value from −1 to 1 every 2π in t.
5. Once a band in t spans more than 2π, some t in it gives y = y0.
6. The limit t ≤ 10^12 gives u ≤ 10^6, so every band grows wide enough for eps ≥ 0.0001.

The terms used by the search:

| Term | Meaning |
|---|---|
| u = √t | slow input to the sine |
| arcsin(x0) + 2πk | rising family of exact x matches |
| π − arcsin(x0) + 2πk | falling family of exact x matches |
| `primaryPhase` | arccos(y0), the first phase with y = y0 |
| `fullTurn - primaryPhase` | the second phase with y = y0 |
| u² | time that belongs to slow coordinate u |

The two families cover every time the fast coordinate reaches y0.

A trace of the sample case:

```
center (0.744, 0.554), radius 0.01
arcsin(x0) = 0.839037, pi - arcsin(x0) = 2.302556
rising band u = 0.824193 .. 0.854130, t = 0.679 .. 0.730
falling band u = 2.287462 .. 2.317400, t = 5.232 .. 5.370
cos target phase = 2*pi - arccos(y0) = 5.299550
t = 5.2: x = 0.758652, y = 0.468517, distance = 0.086730
t = 5.3: x = 0.744256, y = 0.554374, distance = 0.000453
t = 5.4: x = 0.729645, y = 0.634693, distance = 0.081960
```

The falling band holds the target phase, and 5.3 is the first winning tenth.
The printed tenth is checked directly, so rounding cannot push the point outside the dot.

## Code

**Constants and input.** The program fixes its bounds once, then reads the whole stream.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const fullTurn = 2.0 * PI
const timeCeiling = 1.0e12
const rootCeiling = 1.0e6
const gridScale = 10
const maxRootPeriod = 159200

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

`maxRootPeriod` covers every slow coordinate up to `rootCeiling`.
`readLine` appends to one buffer, so odd spacing cannot desync the tokens.
The read costs one pass over the input bytes.

**Number scanners.** Both scanners walk the buffer by index.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  elif pos < data.len and data[pos] == '+':
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float(int(data[pos]) - firstDigitValue)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fractionScale = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value += fractionScale * float(int(data[pos]) - firstDigitValue)
      fractionScale = fractionScale * 0.1
      pos += 1
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentSign = 1
    if pos < data.len and data[pos] == '-':
      exponentSign = -1
      pos += 1
    elif pos < data.len and data[pos] == '+':
      pos += 1
    var exponent = 0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponent = exponent * 10 + int(data[pos]) - firstDigitValue
      pos += 1
    value = value * pow(10.0, float(exponentSign * exponent))
  return signValue * value
```

`nextInt` skips non-digits, so the case count needs no separator handling.
`nextFloat` keeps the minus sign, since center coordinates go below zero.
Neither scanner builds a token object.

**Distance test.** One candidate tenth becomes a point on the curve.

```nim
proc pointDistance(timeValue, centerX, centerY: float): float =
  let horizontalError = sin(sqrt(timeValue)) - centerX
  let verticalError = cos(timeValue) - centerY
  return sqrt(horizontalError * horizontalError + verticalError * verticalError)
```

The test uses the circle from the statement.
It costs two trigonometric calls per candidate.
The square root keeps the threshold in the statement's units.

**Band and phase search.** Bands filter the slow coordinate, phases target the fast one.

```nim
proc findGridIndex(centerX, centerY, radius: float): int =
  var bestIndex = -1
  let clampedX = max(-1.0, min(1.0, centerX))
  let clampedY = max(-1.0, min(1.0, centerY))
  let lowBase = max(-1.0, clampedX - radius)
  let highBase = min(1.0, clampedX + radius)
  let arcLow = arcsin(lowBase)
  let arcHigh = arcsin(highBase)
  let primaryPhase = arccos(clampedY)
  var phaseTable: array[2, float]
  phaseTable[0] = primaryPhase
  phaseTable[1] = fullTurn - primaryPhase
  for branchKind in 0 .. 1:
    for periodIndex in 0 .. maxRootPeriod:
      var bandLow: float
      var bandHigh: float
      if branchKind == 0:
        bandLow = arcLow + fullTurn * float(periodIndex)
        bandHigh = arcHigh + fullTurn * float(periodIndex)
      else:
        bandLow = PI - arcHigh + fullTurn * float(periodIndex)
        bandHigh = PI - arcLow + fullTurn * float(periodIndex)
      if bandLow < 0.0: bandLow = 0.0
      if bandLow > rootCeiling: break
      let timeLow = bandLow * bandLow
      var timeHigh = bandHigh * bandHigh
      if timeHigh > timeCeiling: timeHigh = timeCeiling
      if bestIndex >= 0 and timeLow > float(bestIndex) / float(gridScale): break
      for phaseIndex in 0 .. 1:
        let targetPhase = phaseTable[phaseIndex]
        var waveIndex = ceil((timeLow - targetPhase) / fullTurn - 1.0e-12)
        while true:
          let targetTime = targetPhase + fullTurn * waveIndex
          if targetTime > timeHigh + 1.0e-9: break
          if bestIndex >= 0 and targetTime > float(bestIndex) / float(gridScale): break
          let approxIndex = int(floor(targetTime * float(gridScale)))
          for offset in -1 .. 2:
            let candidateIndex = approxIndex + offset
            if candidateIndex < 0: continue
            if float(candidateIndex) > timeCeiling * float(gridScale): continue
            if bestIndex >= 0 and candidateIndex >= bestIndex: continue
            let candidateTime = float(candidateIndex) / float(gridScale)
            if pointDistance(candidateTime, clampedX, clampedY) <= radius:
              bestIndex = candidateIndex
          waveIndex += 1
  return bestIndex
```

The outer loop stops at `maxRootPeriod`, which covers `rootCeiling`.
`bandLow` and `bandHigh` bracket the u values where x can match.
`bestIndex` ends the scan once later bands start past the best time.
Each band visits two phase families and four nearby tenths.

**Driver.** One answer per case, appended to one output buffer.

```nim
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0 ..< caseCount:
  let centerX = nextFloat(inputData, scanPos)
  let centerY = nextFloat(inputData, scanPos)
  let radius = nextFloat(inputData, scanPos)
  let bestIndex = findGridIndex(centerX, centerY, radius)
  if bestIndex < 0:
    outputBuffer.add "FAIL\n"
  else:
    outputBuffer.add $(bestIndex div gridScale)
    outputBuffer.add "."
    outputBuffer.add $(bestIndex mod gridScale)
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
```

`bestIndex` holds tenths, so `div` and `mod` print one decimal digit.
`outputBuffer` flushes at `flushBlockBytes`, never per case.
The final write covers the tail after the loop.

## Complexity

The work splits into four phases.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input lines | input bytes |
| Token scan | one pass over digits and decimals | none |
| Band search | at most 159200 bands, a few tests each | constant |
| Output | one write per 128 KiB block | block buffer |

The band search dominates, and it stays small for 150 cases.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(K) per case, with K the bands examined, at most about 160000 |
| Space | O(input bytes) |

A tenth-step scan from zero can need 10^13 trigonometric evaluations.
The band search needs at most about 160000.
Matching the slow coordinate first keeps the search short.
