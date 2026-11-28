# AMR12B — Gandalf vs the Balrog (SPOJ)

<https://www.spoj.com/problems/AMR12B/>

## Problem

Two players pick attacks from `N` ordered powers. Higher power wins except for listed pairs where the weaker attack wins. Decide the score under optimal play, and name the winning first attack when that score is two.

Input starts with `T`, the test count. Each case gives `N` and `M`, then `M` lines with two integers `x < y`, meaning attack `x` defeats attack `y`. Print `2 A` if some attack `A` beats every other attack. Print `1` when no such attack exists, and `0` is never needed.

| item | bound |
|---|---|
| test cases `T` | 1 to 15 |
| attacks `N` | 3 to 1000000 |
| anomalous pairs `M` | 0 to min(N(N - 1) / 2, 300000) |
| total `M` over cases | at most 300000 |
| judge limit | 2000 ms, 1536 MB |

Every pair of attacks has one winner, so the defeats form a tournament.

Sample input (the last line ends with a non-breaking space from the statement):

```
2
3 0
3 1
1 3 
```

Sample output:

```
2 3
1
```

## Idea

Look for one attack that beats all others, like a champion that no rival can topple. If such a champion exists, picking it wins before a second move is needed. Otherwise every attack has at least one attacker, so the reply step always rescues the first player. Normal pairs favour the larger index, so a champion loses only when an anomaly points up from a smaller index. Count those anomalies per attack and compare with the number of larger attacks.

Simulating both players for all first picks would build an N by N table. The champion test scans the anomaly list once and then the attack range once. The takeaway is that the second chance makes score zero impossible.

## Why It Works

1. Between any two attacks, exactly one defeats the other.
2. Attack `A` beats every smaller attack unless that smaller attack forms an anomaly with `A`.
3. Attack `A` beats every larger attack only when each pair with a larger attack is anomalous.
4. A tournament has at most one attack that beats all others.
5. If no champion exists, every attack loses to something, and that opponent also loses to something else, so a reply exists.
6. Hence the score is two exactly when a champion exists, and one otherwise.

| term | meaning |
|---|---|
| `hasLowerAnomaly` | marks attacks beaten by a smaller attack |
| `higherAnomalyCount` | count of larger attacks beaten by this attack |
| `attackCount` | number of attacks |
| `winningAttack` | champion index found by the scan |

The table names the arrays used by the champion test.

A script check of the sample gives the following defeats.

| case | anomalies | beats all | result |
|---|---|---|---|
| first | none | attack 3 | 2 3 |
| second | 1 defeats 3 | none | 1 |

In the second case the defeats form a cycle, so every first pick can be countered and then answered.

## Code

**Input and input helpers.** The whole input is read once and parsed with a digit scanner.

```nim
const flushBlockBytes = 1 shl 17

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
```

`nextInt` skips separators and reads each integer.
`inputData` keeps the full input in one string.
`appendOutput` batches the answer lines.

**Champion scan.** Anomalies are marked once, then attacks are tested in order.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let attackCount = nextInt(inputData, scanPos)
  let anomalyCount = nextInt(inputData, scanPos)
  var hasLowerAnomaly = newSeq[bool](attackCount + 1)
  var higherAnomalyCount = newSeq[int](attackCount + 1)
  for pairIndex in 0 .. anomalyCount - 1:
    let weakerAttack = nextInt(inputData, scanPos)
    let strongerAttack = nextInt(inputData, scanPos)
    hasLowerAnomaly[strongerAttack] = true
    higherAnomalyCount[weakerAttack] += 1
  var winningAttack = 0
  for attack in 1 .. attackCount:
    if not hasLowerAnomaly[attack] and higherAnomalyCount[attack] == attackCount - attack:
      winningAttack = attack
      break
  if winningAttack != 0:
    appendOutput("2 " & $winningAttack)
  else:
    appendOutput("1")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`weakerAttack` gains one beaten larger attack.
`strongerAttack` loses to a smaller attack.
`winningAttack` holds the unique champion, if one exists.

## Complexity

Each anomalous pair is read and marked once.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| anomaly marking | O(M) per case | two arrays of size N |
| champion scan | O(N) per case | none beyond the arrays |

| measure | Big O |
|---|---|
| time per case | O(N + M) |
| extra space | O(N) |

Building the full defeat table costs O(N²) and cannot fit the upper bound on N. The two count arrays reduce the champion test to one linear pass.
