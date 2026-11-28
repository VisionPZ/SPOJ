# ROOBOT — Robot (SPOJ)

<https://www.spoj.com/problems/ROOBOT/>

## Problem

A robot takes N random steps from the origin, then scores the width of the rectangle its path spans. Report the expected score after all steps.

The first line holds N. The second line holds four decimals U, R, D, L that sum to one and are the probabilities of stepping up, right, down, and left. One line holds the expected score with at least the required precision.

| item | bound |
|---|---|
| steps N | 1 to 200 |
| probabilities | 0 to 1, at most six decimals, sum one |
| answer error | relative or absolute 1e-6 |
| judge limit | 1000 ms, 1536 MB |

The rectangle includes the origin and every later position.

Sample input:

```
2
0.100000 0.200000 0.300000 0.400000
```

Sample output:

```
1.780000
```

## Idea

Track how far the walk sits from its highest point, like measuring how far a runner trails the record mark. That distance only grows, shrinks, or resets when a new record appears. A new record adds exactly one to the score, so summing those chances gives the expected height. Repeating the same idea for all four extrema avoids storing whole paths.

A state is one distance value, so a step touches a few states. Listing every path would grow as four to the power of N.

## Why It Works

1. The score equals the sum of the x range and the y range.
2. The x range grows by one exactly when the walk sets a new x maximum or a new x minimum.
3. Let d be the distance from the current position down to the running maximum.
4. A right step lowers d by one, or resets it to zero after adding one to the score.
5. A left step raises d by one, and a vertical step leaves d unchanged.
6. The same rules with roles swapped track the distance above the running minimum.

| term | meaning |
|---|---|
| `advanceDistance` | one-step update of a distance distribution |
| `extremumGain` | probability mass that sets a new record |
| `expectedPoints` | sum of the four expected range contributions |

The four contributions add because expectation is linear.

The script example uses N = 2 with U = 0.1, R = 0.2, D = 0.3, L = 0.4. The horizontal x range has expectation 1.04. The vertical y range has expectation 0.74. Their sum is 1.78, which the sampler prints as 1.780000.

The second statement sample uses equal probabilities and N = 3, giving 2.375000.

## Code

**Parsing and fixed formatting.** Decimals are read by hand and printed with six digits.

```nim
proc nextDouble(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fractionPart = 0.0
    var scale = 1.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10.0 + float64(int(data[pos]) - 48)
      scale = scale * 10.0
      pos += 1
    return wholePart + fractionPart / scale
  return wholePart
```

The scanner accepts any decimal place count.
The scale grows with the digits read.
No locale or formatting library is needed.

```nim
proc formatFixed(value: float64): string =
  let scaledValue = int64(value * 1000000.0 + 0.5)
  let integerPart = scaledValue div 1000000
  let fractionPart = scaledValue mod 1000000
  var rendered = $integerPart
  rendered.add '.'
  var placeValue: int64 = 100000
  while placeValue >= 1:
    let digitValue = (fractionPart div placeValue) mod 10
    rendered.add chr(48 + int(digitValue))
    placeValue = placeValue div 10
  return rendered
```

Scaling rounds to the nearest micro-unit.
Six digits meet the stated error bound.
Zero padding keeps the printed shape stable.

**Distance update.** One procedure handles all four extrema.

```nim
proc advanceDistance(state: seq[float64], stayProbability, growProbability,
                     shrinkProbability: float64, extremumGain: var float64): seq[float64] =
  var nextState = newSeq[float64](state.len)
  for distance in 0 .. state.len - 2:
    let chance = state[distance]
    if chance == 0.0:
      continue
    nextState[distance] += chance * stayProbability
    nextState[distance + 1] += chance * growProbability
    if distance > 0:
      nextState[distance - 1] += chance * shrinkProbability
    else:
      nextState[distance] += chance * shrinkProbability
      extremumGain += chance * shrinkProbability
  return nextState
```

The state array holds distances from zero to N.
A record only happens at distance zero.
The extra slot absorbs the grow transition safely.

**Four sweeps and output.** Each axis gets one below-max and one above-min sweep.

```nim
for stepIndex in 0 .. moveCount - 1:
  belowMaxHorizontal = advanceDistance(belowMaxHorizontal, horizontalStay,
    probabilityLeft, probabilityRight, horizontalMaxGain)
  aboveMinHorizontal = advanceDistance(aboveMinHorizontal, horizontalStay,
    probabilityRight, probabilityLeft, horizontalMinGain)
  belowMaxVertical = advanceDistance(belowMaxVertical, verticalStay,
    probabilityDown, probabilityUp, verticalMaxGain)
  aboveMinVertical = advanceDistance(aboveMinVertical, verticalStay,
    probabilityUp, probabilityDown, verticalMinGain)

let expectedPoints = horizontalMaxGain + horizontalMinGain + verticalMaxGain + verticalMinGain
appendOutput(formatFixed(expectedPoints))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The axis stay probabilities include the other axis moves.
All four gains use the same transition rule.
One line is written per input file.

## Complexity

Each step updates a short list of distances per extremum.

| phase | time | space |
|---|---|---|
| input read | one pass over four decimals | input string |
| distance sweeps | four updates of N + 2 states per step | four state arrays |
| output | one formatted line | block buffer |

No path enumeration appears anywhere.

| measure | Big O |
|---|---|
| time | O(N^2) |
| space | O(N) |

Listing all four-to-the-N step sequences would grow exponentially, while these sweeps stay quadratic. The distance state keeps the whole computation small.
