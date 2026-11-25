# VENOM — Touch of Venom (SPOJ)

<https://www.spoj.com/problems/VENOM/>

## Problem

A hero starts with health `H`. The enemy deals `i * P` damage on attack `i`, and the hero heals `A` after each survived attack. Find the time of the fatal attack.

Input: a line with `t`, then `t` lines with `H P A`. Output: one survival time per case. Time counts both attacks and heals, starting at 1.

| item | bound |
|---|---|
| test cases `t` | 1 to 1000000 |
| initial health `H` | 1 to 1000000 |
| poison `P` | 1 to 1000000 |
| heal `A` | 0 to `P - 1` |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
3
3 7 2
81 4 1
87 8 4
```

Sample output:

```
1
13
9
```

## Idea

Treat the health before attack `k` as a running total, like a bank balance with weekly pay and rising bills. The fatal attack is the first one whose bill exceeds that balance. A binary search over the attack number finds it in a handful of comparisons.

The balance before attack `k` is `H + (k - 1) * A`. The summed damage through attack `k` is `P * k * (k + 1) / 2`. Simulation takes up to 2827 steps per case, which is slow for a million cases. The closed form makes each step of the search constant time.

The takeaway: solve the inequality once, then search over attack numbers.

## Why It Works

1. Before attack `k`, exactly `k - 1` heals have happened, so health is `H + (k - 1) * A`.
2. Damage through attack `k` sums `P * (1 + 2 + ... + k)`, which equals `P * k * (k + 1) / 2`.
3. Attack `k` is fatal exactly when health is at most that damage, since death means health at most zero.
4. The condition switches once from false to true, so a binary search finds the smallest fatal `k`.
5. Time `2 * k - 1` counts `k` attacks and the `k - 1` heals between them.

| term | meaning |
|---|---|
| `attackIndex` | current attack number `k` |
| `carriedHealth` | health before that attack |
| `totalDamage` | damage dealt through that attack |
| `killsHero` | true when that attack is fatal |

Doubling the upper bound starts the search without needing a formula for its range.

Worked example for `H = 81`, `P = 4`, `A = 1`, computed from the two formulas above:

| attack `k` | `carriedHealth` | `totalDamage` | fatal? |
|---|---|---|---|
| 5 | 85 | 60 | no |
| 6 | 86 | 84 | no |
| 7 | 87 | 112 | yes |

The first fatal attack is 7, so the answer is `2 * 7 - 1 = 13`.

Products reach about `4 * 10^12`, so all arithmetic uses `int64`.

## Code

**Input and scanner.** One read loads the whole input, and the scanner skips separators.

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
```

Separators are skipped, so spaces and line breaks are interchangeable.
The scan position is a `var` parameter and survives across calls.

**Buffered output.** Text is written once the buffer passes 128 KiB.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` keeps the same allocation for later blocks.

**Fatal-attack test.** Both sides of the inequality use `int64`.

```nim
proc killsHero(health: int64, poison: int64, healAmount: int64, attackIndex: int64): bool =
  let carriedHealth = health + (attackIndex - 1) * healAmount
  let totalDamage = poison * attackIndex * (attackIndex + 1) div 2
  return carriedHealth <= totalDamage
```

The damage product reaches `10^6 * 2000 * 2001`, which fits `int64`.

**Driver.** Doubling finds a fatal attack, then binary search locates the first one.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let health = int64(nextInt(inputData, scanPos))
  let poison = int64(nextInt(inputData, scanPos))
  let healAmount = int64(nextInt(inputData, scanPos))
  var upperAttack = 1'i64
  while not killsHero(health, poison, healAmount, upperAttack):
    upperAttack *= 2
  var lowerAttack = 1'i64
  while lowerAttack < upperAttack:
    let middleAttack = (lowerAttack + upperAttack) div 2
    if killsHero(health, poison, healAmount, middleAttack):
      upperAttack = middleAttack
    else:
      lowerAttack = middleAttack + 1
  appendOutput($(2 * lowerAttack - 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final write covers the tail after the last block.
Every case emits one line, so output size stays linear in `t`.

## Complexity

| phase | time per case | space |
|---|---|---|
| input read | one pass over all bytes | one input string |
| bound doubling | up to 12 tests | constant |
| binary search | up to 12 tests | constant |
| output | one line | 128 KiB buffer |

| measure | Big O |
|---|---|
| time per case | O(log answer) |
| total time | O(t log answer) |
| space | O(input size) |

Simulation costs O(answer) steps per case, up to 2827 steps for the stated bounds. The search replaces those steps with a fixed dozen comparisons.
