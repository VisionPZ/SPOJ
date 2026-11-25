# TRIPPL — Balance Triple (SPOJ)
<https://www.spoj.com/problems/TRIPPL/>

## Problem

Every pair of teams in a tournament has one winner. Find the largest possible number of triples whose wins form a cycle.
The first line gives T, the number of test cases. Each next line gives one team count n.
Print one maximum per case, on its own line.

| Item | Bound |
|---|---|
| Test cases | T ≤ 100000 |
| Teams per case | n ≤ 1000000 |
| Time limit | 1000 ms |
| Memory | not stated |

Two formulas settle each case in constant time.

The statement renders the sample on one line because its whitespace collapsed.

```
3345 
```

```
125 
```

The logical input is T = 3 with team counts 3, 4, and 5.

```
3
3
4
5
```

```
1
2
5
```

## Idea

Spreading wins evenly is like filling cups to one level; the flattest cups leave the most cyclic triples.
Every triple is cyclic or transitive. A transitive triple has one team that beats both others.
That team owns a pair of wins, so pairs of wins count transitive triples.
The total number of wins is fixed, and equal win counts minimize the number of pairs.
The program divides the win total by n, then uses the quotient and the remainder.
It subtracts the pairs from all triples and prints the result.
Each case costs constant time, while searching all tournaments costs exponential time.

Equal win counts turn the whole problem into one division per case.

## Why It Works

1. A triple of teams either cycles or has one team beating the other two.
2. A team with d wins beats C(d, 2) pairs of other teams.
3. Every transitive triple is counted once, at its winning team.
4. Cyclic triples equal all triples minus the sum of C(d, 2) over teams.
5. Win counts sum to n(n - 1)/2, so they differ by at most one.

The main terms and formulas follow.

| Term | Meaning |
|---|---|
| `degreeSum` | total wins over all teams |
| `baseDegree` | win count of teams with fewer wins |
| `extraCount` | number of teams with one more win |
| `transitiveCount` | triples having one team that beats both others |
| `triplesOf` | total triples for the current team count |

The quotient gives the lower win count and the remainder gives the higher count.

A trace from `gen.py --trace`:

```
3 teams degrees 2x0 1x3 transitive 0 balanced 1
4 teams degrees 2x2 1x2 transitive 2 balanced 2
5 teams degrees 3x0 2x5 transitive 5 balanced 5
6 teams degrees 3x3 2x3 transitive 12 balanced 8
```

The trace matches the sample values and extends them by one case.

## Code

**Bulk input and integer scanner.** This block reads stdin once and parses integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The read loop ends at end of input.
The scanner skips every byte that is not a digit.
The digit value comes from the character code.

**Combination helpers and output buffer.** This block builds counts and buffers answer text.

```nim
proc pairsOf(value: int64): int64 =
  value * (value - 1) div 2

proc triplesOf(value: int64): int64 =
  value * (value - 1) * (value - 2) div 6

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

Both helpers use 64-bit integers to hold large counts.
The buffer leaves after reaching 131072 bytes.
`appendOutput` adds text and then checks the size.

**Answer loop.** This block handles small cases directly, then applies the degree formula.

```nim
let testCount = nextInteger(inputData, scanPos)
for caseIndex in 0..<testCount:
  let teamCount = int64(nextInteger(inputData, scanPos))
  if teamCount < 3:
    appendOutput("0\n")
  else:
    let degreeSum = teamCount * (teamCount - 1) div 2
    let baseDegree = degreeSum div teamCount
    let extraCount = degreeSum mod teamCount
    let highDegree = baseDegree + 1
    let transitiveCount = extraCount * pairsOf(highDegree) +
                          (teamCount - extraCount) * pairsOf(baseDegree)
    appendOutput($(triplesOf(teamCount) - transitiveCount))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Fewer than three teams give no triples.
The remainder counts teams with the higher win count.
The final write flushes the last partial block.

## Complexity

Cost follows the number of cases and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Degree formula | constant work per case | none |
| Output | one write per 128 KiB block | block buffer |

The work per case never depends on the team count.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(I + B) |

A naive search over all tournaments costs O(2^(n²)) per case and cannot handle large n.
The degree formula gives the answer in constant time.
