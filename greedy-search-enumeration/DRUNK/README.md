# DRUNK — Drunk Game (SPOJ)
<https://www.spoj.com/problems/DRUNK/>

## Problem

Two players take coins from one pile. Each player aims at 1, 4, 9 or 16 coins, but luck delivers X-1, X or X+1 coins with weights C1:C2:C3. Only amounts between 1 and the pile size are possible, and weights of impossible amounts are dropped. Alice moves first. Each player wants to win or lose, as the mood line says. Report Bob's chance of getting the outcome he wants, rounded to four decimals.

The first input token is the test count T. Each test case supplies the pile size N, three weights, then Alice's mood and Bob's mood. Mood 0 means losing and mood 1 means winning. One output line per case holds a decimal with exactly four digits after the point.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| pile size N | 1 to 1000000 |
| each weight | 1 to 100000 |
| mood | 0 or 1 |
| judge limit | 1000 ms, 1536 MB |

The pile never grows, and each turn removes at least one coin.

Sample input:

```
2
1
1 2 3
0 0
5
1 2 3
0 1
```

This input holds two cases with the same three weights and opposite Bob moods.

Sample output:

```
1.0000
0.4333
```

The second line is Bob's chance to win with five coins at the start.

## Idea

Think of each turn as a weighted three-way die: the player names a square handful, and luck picks the real handful, so we average the continuations before choosing. The algorithm is a bottom-up dynamic program over pile sizes. It stores two values per size: Bob's win chance when Alice moves and Bob's win chance when Bob moves. Each size costs four decisions with at most three outcomes each, about a dozen arithmetic steps. A game tree would branch anew at every turn, while this sweep reuses each smaller pile once. One pass gives Bob's chance for the starting pile.

## Why It Works

1. A decision X is legal only when the pile holds at least X coins.
2. An outcome X-1 needs X ≥ 2, and an outcome X+1 needs X+1 ≤ pile size.
3. We keep the weights of legal outcomes and divide by their sum to get probabilities.
4. Each expected value multiplies a probability by the next player's win chance.
5. Alice takes the smallest average when she wants to win and the largest when she wants to lose.
6. Bob takes the largest average when he wants to win and the smallest when he wants to lose.
7. At an empty pile the player to move loses, so Alice's value is 1 and Bob's value is 0.
8. Alice moves first, so her value at N is Bob's win chance. A losing mood reports one minus that chance.

The table names the values used in the code.

| term | meaning |
|---|---|
| `aliceWins` | Bob's win chance with Alice to move at a pile size |
| `bobWins` | Bob's win chance with Bob to move at a pile size |
| `pairDivisor` | reciprocal of C2+C3 for a one-coin decision |
| `tripleDivisor` | reciprocal of C1+C2+C3 for a full decision |
| `precisionScale` | 10000, the factor that turns a chance into four decimals |

The two value arrays share one index, the number of coins left.

The generator script produced this example for N=5, weights 1:2:3 and moods 0,1. It lists the averages available to each player and the value chosen at that size.

| coins left | Alice averages | `aliceWins` | Bob averages | `bobWins` |
|---|---|---|---|---|
| 1 | 0 | 0 | 1 | 1 |
| 2 | 2/5 | 2/5 | 3/5 | 3/5 |
| 3 | 21/25 | 21/25 | 4/25 | 4/25 |
| 4 | 53/125, 1/3 | 53/125 | 72/125, 2/3 | 2/3 |
| 5 | 136/375, 13/30 | 13/30 | 421/625, 17/30 | 421/625 |

Alice picks 13/30 at five coins, and Bob wants a win, so the printed answer is 0.4333.

Rounding uses `precisionScale`: multiply, add 0.5, then truncate to an integer. The whole part and a four-digit padded fraction form the line.

## Code

**Input and scanner.** Constants, one read of stdin, and the integer scanner.

```nim
const flushBlockBytes = 1 shl 17
const precisionScale = 10000.0
const decisionCoins = [1, 4, 9, 16]

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
```

`inputData` holds every line with a trailing newline.
`nextInt` skips separators and builds each value digit by digit.
`decisionCoins` lists the four square targets in ascending order.

**Output helper.** The block buffer and the four-decimal formatter.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatProbability(value: float64): string =
  var scaled: int64 = int64(value * precisionScale + 0.5)
  if scaled < 0:
    scaled = 0
  if scaled > int64(precisionScale):
    scaled = int64(precisionScale)
  let wholePart = int(scaled div int64(precisionScale))
  let fracPart = int(scaled mod int64(precisionScale))
  result = $wholePart
  result.add '.'
  if fracPart < 1000:
    result.add '0'
  if fracPart < 100:
    result.add '0'
  if fracPart < 10:
    result.add '0'
  result.add $fracPart
```

`appendOutput` writes a full block and clears the buffer.
`formatProbability` rounds with an integer scale and pads small fractions.
The clamp keeps a chance inside the unit interval.

**Main sweep.** Read each case, fill both value arrays, and print Bob's answer.

```nim
let testCaseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCaseCount - 1:
  let pileCount = nextInt(inputData, scanPos)
  let minusWeight = float64(nextInt(inputData, scanPos))
  let sameWeight = float64(nextInt(inputData, scanPos))
  let plusWeight = float64(nextInt(inputData, scanPos))
  let aliceMood = nextInt(inputData, scanPos)
  let bobMood = nextInt(inputData, scanPos)
  let pairDivisor = 1.0 / (sameWeight + plusWeight)
  let singleDivisor = 1.0 / sameWeight
  let tripleDivisor = 1.0 / (minusWeight + sameWeight + plusWeight)
  let doubleDivisor = 1.0 / (minusWeight + sameWeight)
  var aliceWins = newSeq[float64](pileCount + 1)
  var bobWins = newSeq[float64](pileCount + 1)
  aliceWins[0] = 1.0
  for remaining in 1 .. pileCount:
    var aliceLowest = 2.0
    var aliceHighest = -1.0
    var bobLowest = 2.0
    var bobHighest = -1.0
    for decisionIndex in 0 .. 3:
      let decidedCoins = decisionCoins[decisionIndex]
      if decidedCoins > remaining:
        break
      var aliceExpected: float64
      var bobExpected: float64
      var divisor: float64
      if decidedCoins == 1:
        divisor = pairDivisor
        aliceExpected = sameWeight * bobWins[remaining - 1]
        bobExpected = sameWeight * aliceWins[remaining - 1]
        if remaining >= 2:
          aliceExpected = aliceExpected + plusWeight * bobWins[remaining - 2]
          bobExpected = bobExpected + plusWeight * aliceWins[remaining - 2]
        else:
          divisor = singleDivisor
      else:
        divisor = tripleDivisor
        aliceExpected = minusWeight * bobWins[remaining - decidedCoins + 1]
        bobExpected = minusWeight * aliceWins[remaining - decidedCoins + 1]
        aliceExpected = aliceExpected + sameWeight * bobWins[remaining - decidedCoins]
        bobExpected = bobExpected + sameWeight * aliceWins[remaining - decidedCoins]
        if remaining >= decidedCoins + 1:
          aliceExpected = aliceExpected + plusWeight * bobWins[remaining - decidedCoins - 1]
          bobExpected = bobExpected + plusWeight * aliceWins[remaining - decidedCoins - 1]
        else:
          divisor = doubleDivisor
      aliceExpected = aliceExpected * divisor
      bobExpected = bobExpected * divisor
      if aliceExpected < aliceLowest:
        aliceLowest = aliceExpected
      if aliceExpected > aliceHighest:
        aliceHighest = aliceExpected
      if bobExpected < bobLowest:
        bobLowest = bobExpected
      if bobExpected > bobHighest:
        bobHighest = bobExpected
    if aliceMood == 1:
      aliceWins[remaining] = aliceLowest
    else:
      aliceWins[remaining] = aliceHighest
    if bobMood == 1:
      bobWins[remaining] = bobHighest
    else:
      bobWins[remaining] = bobLowest
  let bobWinningChance = aliceWins[pileCount]
  let answer = if bobMood == 1: bobWinningChance else: 1.0 - bobWinningChance
  appendOutput(formatProbability(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Four divisors cover the legal weight sums at the pile edges.
`aliceLowest`, `aliceHighest`, `bobLowest` and `bobHighest` implement both moods.
`bobWinningChance` is Alice's value at the starting pile, since Alice moves first.
The final write flushes the remaining buffer once.

## Complexity

Each test case sweeps every pile size once with a constant number of decisions.

The phases split the work by input, sweep and output.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| value sweep | four decisions per pile size | two arrays of N+1 doubles |
| output | one line per case | block buffer |

The sweep dominates both time and memory.

| measure | Big O |
|---|---|
| time per case | O(N) |
| space per case | O(N) |

The bounds grow linearly with the starting pile size.

A game tree would revisit the same pile sizes through many different move orders.

The sweep stores each size once, so large piles stay within the judge limit.
