# VAL_GAM4 — Happy Valentine Day (Valentine Adventure Game) (SPOJ)

<https://www.spoj.com/problems/VAL_GAM4/>

## Problem

Walk from 0 to home at unit speed. Flags offer checkpoints and wars can send you back to the last checkpoint. Report the expected travel time modulo 1000000007.

Each case starts with home position h and object count q. The next q lines hold a type (`X` for war, `F` for flag), a position, and a probability as numerator and denominator. Positions increase strictly. A line `0 0` ends the input. Print one integer per case.

| item | bound |
|---|---|
| home h | 1 to 1000000000000000000 |
| objects q | 0 to 10000 |
| probability denominator | below 1000000007 |
| input size | below 500 KB |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
32 0
32 1
X 16 1 2
32 2
F 8 1 1
X 16 1 2
32 2
F 8 1 2
X 16 1 2
0 0
```

Sample output:

```
32
48
40
44
```

## Idea

Every lost war rewalks a stretch of road, like a board game card that sends you back to the last flag. Track how much a restart still costs, and each object becomes one cheap update.

Let R be the expected time from restarting at the current checkpoint. The expected time from the current position has the form cost + weight * R. A war loss hands control back to R, so weight grows. A flag taken replaces R by a fixed affine copy alpha + beta * R. Both updates cost constant time. Enumerating flag stacks would cost exponential time. Takeaway: keep one affine pair per position and sweep from home back to the start.

## Why It Works

1. Every restart is instantaneous, so total time equals forward travel only.
2. From a position with restart value R, the remaining time is linear in R.
3. A war with win chance p gives cost = distance + p * nextCost and weight = p * nextWeight + 1 - p.
4. A flag with take chance f gives alpha = nextCost / (1 - nextWeight * f) and beta = nextWeight * (1 - f) / (1 - nextWeight * f).
5. At the start, restarting is the same state as starting, so the answer is cost / (1 - weight).

| term | meaning |
|---|---|
| `cost` | fixed part of the expected time at a position |
| `weight` | multiplier on the restart value at a position |
| `alpha` | new fixed part after taking a flag |
| `beta` | new multiplier after taking a flag |
| `chance` | modular probability for the current object |
| `closing` | inverse of one minus the start weight |

A script evaluates the last sample case with home 32, flag at 8 with chance 1/2, and war at 16 with chance 1/2. At the war, cost is 16 and weight is 1/2. At the flag, alpha is 64/3 and beta is 1/3, giving cost 88/3 and weight 1/3. The closing factor is 3/2, so the product is 44. This matches the printed sample.

All divisions use modular inverses, which is valid because every denominator is below the prime modulus. Products of two residues fit in 64 bits.

## Code

**Input reader and modular helpers.** The stream is loaded once, and inverses use fast powering.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc nextType(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'X' and data[pos] != 'F':
    pos += 1
  result = data[pos]
  pos += 1

proc norm(value: int64): int64 =
  let reduced = value mod answerModulus
  if reduced < 0:
    return reduced + answerModulus
  return reduced

proc inverse(value: int64): int64 =
  var baseVal = norm(value)
  var exponentVal = answerModulus - 2
  result = 1'i64
  while exponentVal > 0:
    if exponentVal mod 2 == 1:
      result = result * baseVal mod answerModulus
    baseVal = baseVal * baseVal mod answerModulus
    exponentVal = exponentVal div 2

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextType` skips separators until an object type appears.
`norm` lifts a signed remainder into the residue range.
`inverse` uses Fermat's theorem with exponent modulus minus two.

**Backward sweep.** One pass from home to the start computes both affine parts.

```nim
while true:
  let homePosition = nextInt(inputData, scanPos)
  let objectCount = nextInt(inputData, scanPos)
  if homePosition == 0 and objectCount == 0:
    break
  let objectTotal = int(objectCount)
  var objectPos = newSeq[int64](objectTotal + 1)
  var objectProb = newSeq[int64](objectTotal)
  var objectIsWar = newSeq[bool](objectTotal)
  for objectIndex in 0 .. objectTotal - 1:
    let objectType = nextType(inputData, scanPos)
    let place = nextInt(inputData, scanPos)
    let numerator = nextInt(inputData, scanPos)
    let denominator = nextInt(inputData, scanPos)
    objectIsWar[objectIndex] = objectType == 'X'
    objectPos[objectIndex + 1] = place
    objectProb[objectIndex] = numerator * inverse(denominator) mod answerModulus
  var cost = newSeq[int64](objectTotal + 1)
  var weight = newSeq[int64](objectTotal + 1)
  cost[objectTotal] = norm(homePosition - objectPos[objectTotal])
  weight[objectTotal] = 0
  for index in countdown(objectTotal - 1, 0):
    let segmentLength = norm(objectPos[index + 1] - objectPos[index])
    let chance = objectProb[index]
    if objectIsWar[index]:
      cost[index] = norm(segmentLength + chance * cost[index + 1])
      weight[index] = norm(chance * weight[index + 1] + 1 - chance)
    else:
      let denominatorValue = norm(1 - weight[index + 1] * chance)
      let inverseDenominator = inverse(denominatorValue)
      let alpha = cost[index + 1] * inverseDenominator mod answerModulus
      let failureWeight = norm(1 - chance) * weight[index + 1] mod answerModulus
      let beta = failureWeight * inverseDenominator mod answerModulus
      let deal = norm(chance * beta + 1 - chance)
      cost[index] = norm(segmentLength + cost[index + 1] + weight[index + 1] * chance mod answerModulus * alpha)
      weight[index] = norm(weight[index + 1] * deal)
  let closing = inverse(norm(1 - weight[0]))
  appendOutput($(cost[0] * closing mod answerModulus))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final walk home initializes `cost`.
A flag divides by its affine denominator, then updates both parts.
The closing inverse resolves the self-reference at the start.

## Complexity

Each object costs two modular inverses and constant arithmetic.

| phase | time | space |
|---|---|---|
| parse a case | one pass over q objects | three arrays of size q |
| backward sweep | one step per object | two arrays of size q |
| output | one buffered write | one output string |

| measure | Big O |
|---|---|
| time | O(q log MOD) per case |
| space | O(q) |

Tracking every flag stack would visit exponentially many states. Takeaway: one affine pair per position gives the expectation in a single backward pass.
