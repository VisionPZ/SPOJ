<https://www.spoj.com/problems/EPURSE/>

## Problem

Pick at most `B` throws to collect the most money from a line of `N` coins. A throw starts at any coin and moves left or right in steps of width `W`, collecting every coin still present along that arithmetic chain. A collected coin becomes a void and pays nothing again. Ties on money go to the fewest throws.

Each case has a line with `W B N`, then a line with `N` money values. Three zeros end the input. Output uses the exact line `Case#id: Jack wins $X out of Y throws.`

| item | bound |
|---|---|
| coins N | 1 to 100 |
| width W and budget B | positive integers |
| money per coin | -10^6 to 10^6 |
| judge limit | 1000 ms, 1536 MB |

The sample input:

```
2 3 10
-1 3 2 5 1 -2 0 5 1 -3
2 3 14
-1 3 2 5 -5 -5 1 -2 0 5 -5 -5 1 -3
3 3 5
-1 -2 -3 -4 -5
1 2 6
-1 -1 10 10 -1 -1
0 0 0
```

The sample output:

```
Case#1: Jack wins $15 out of 2 throws.
Case#2: Jack wins $10 out of 3 throws.
Case#3: Jack wins $0 out of 0 throws.
Case#4: Jack wins $18 out of 1 throws.
```

## Idea

Coins at distance `W` form separate chains, like beads on parallel strings. A throw always empties one end of one string, so the coins left on a string form one continuous segment. With one throw you can take a prefix or a suffix; with two throws you can take both ends and leave the cheapest middle segment. A small knapsack over chains then spends the throw budget.

## Why It Works

1. Throwing from coin `i` in steps of `W` never leaves its residue class, so chains are independent.
2. Each throw removes a prefix or a suffix of the remaining chain, so the surviving coins stay contiguous.
3. One throw gains the largest prefix sum or suffix sum, or zero by skipping the throw.
4. Two throws can remove any prefix and any suffix, so the gain is the chain total minus the cheapest remaining segment.
5. Extra throws on one chain add nothing, so a knapsack with zero, one, or two throws per chain finds the global best.
6. Scanning the budget array upward returns the smallest throw count that reaches the top money.

| term | meaning |
|---|---|
| `chains` | coins grouped by index modulo `W` |
| `chainGains` | best payoff for one throw and for two throws |
| `bestMoney` | best payoff for each throw budget so far |
| `turnLimit` | budget capped at the coin count |

The table names the per-chain payoff and the shared budget array.

A worked trace for chain `[5, -10, 5]`:

| quantity | value |
|---|---|
| total | 0 |
| best prefix or suffix | 5 |
| cheapest segment | -10 |
| gain with two throws | 0 - (-10) = 10 |

Two throws keep both fives and skip the negative middle, which matches the rule.

## Code

**Input and scanner.** One buffer holds every line, and `nextInt` reads signed money values.

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

The minus branch handles negative money.
The three-zero sentinel is detected after parsing each case header.

**Buffered output.** A single string collects case lines and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` batches lines into one write per block.
The final write flushes any remaining bytes.

**Chain payoff.** Prefix, suffix, and cheapest segment give both payoff levels.

```nim
proc chainGains(values: seq[int]): tuple[one: int, two: int] =
  var total = 0
  var maxPrefix = 0
  var maxSuffix = 0
  var running = 0
  for value in values:
    running += value
    total += value
    if running > maxPrefix:
      maxPrefix = running
  running = 0
  for index in countdown(values.len - 1, 0):
    running += values[index]
    if running > maxSuffix:
      maxSuffix = running
  var smallest = 0
  var current = 0
  for value in values:
    if current + value < value:
      current += value
    else:
      current = value
    if current < smallest:
      smallest = current
  var bestOne = 0
  if maxPrefix > bestOne:
    bestOne = maxPrefix
  if maxSuffix > bestOne:
    bestOne = maxSuffix
  return (bestOne, total - smallest)
```

The prefix and suffix passes each cost one walk over the chain.
The minimum-segment pass uses a running minimum and also costs one walk.

**Budget knapsack and output.** Each chain spends zero, one, or two throws, then the best throw count is found.

```nim
var width = nextInt(inputData, scanPos)
var allowance = nextInt(inputData, scanPos)
var ballCount = nextInt(inputData, scanPos)
var caseNumber = 1
while not (width == 0 and allowance == 0 and ballCount == 0):
  var chains = newSeq[seq[int]](ballCount + 1)
  for ballIndex in 1 .. ballCount:
    let money = nextInt(inputData, scanPos)
    let residue = (ballIndex - 1) mod width
    chains[residue].add money
  let turnLimit = min(allowance, ballCount)
  var bestMoney = newSeq[int](turnLimit + 1)
  for chain in chains:
    if chain.len == 0:
      continue
    let gains = chainGains(chain)
    var nextMoney = newSeq[int](turnLimit + 1)
    for turnCount in 0 .. turnLimit:
      nextMoney[turnCount] = bestMoney[turnCount]
      if turnCount >= 1:
        let candidate = bestMoney[turnCount - 1] + gains.one
        if candidate > nextMoney[turnCount]:
          nextMoney[turnCount] = candidate
      if turnCount >= 2:
        let candidate = bestMoney[turnCount - 2] + gains.two
        if candidate > nextMoney[turnCount]:
          nextMoney[turnCount] = candidate
    bestMoney = nextMoney
  let topMoney = bestMoney[turnLimit]
  var usedTurns = 0
  while bestMoney[usedTurns] < topMoney:
    usedTurns += 1
  appendOutput("Case#" & $caseNumber & ": Jack wins $" & $topMoney &
               " out of " & $usedTurns & " throws.\n")
  caseNumber += 1
  width = nextInt(inputData, scanPos)
  allowance = nextInt(inputData, scanPos)
  ballCount = nextInt(inputData, scanPos)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The budget is capped at the coin count because extra throws cannot help.
The upward scan over `bestMoney` returns the smallest budget that ties the best payoff.

## Complexity

Each chain is scanned three times, and the knapsack visits every budget entry once per chain.

| phase | time | space |
|---|---|---|
| grouping coins | one pass over `N` values | `N` chain slots |
| chain payoff | three passes per chain | constant per chain |
| knapsack | `W` chains times `B` budgets | `B+1` payoff entries |
| output | one append per case | block buffer |

The phase table shows that the knapsack dominates when the budget is large.

| measure | Big O |
|---|---|
| time per case | O(N + W * min(B,N)) |
| space per case | O(N + min(B,N)) |

Trying every start, direction, and throw order grows exponentially with the budget. The chain formula replaces that search with three linear passes.
