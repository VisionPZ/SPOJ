# POUR1 — Pouring water (SPOJ)

<https://www.spoj.com/problems/POUR1/>

## Problem

Two jugs of different sizes stand empty on a table. You may fill a jug, empty it, or pour one into the other until it is full or empty. Find the fewest moves that leave exactly the target amount in either jug.

Input: `t`, the number of test cases, then `t` triples `a b c`, each on its own line. Output: one integer per case, the minimum number of steps, or −1 when the target cannot be measured.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `t` | 1 ≤ t ≤ 100 |
| Capacity and target values | positive integers ≤ 40000 |
| Allowed moves | fill, empty, pour until full or empty |
| Judge limit | 2000 ms, 1536 MB |

Both jugs start empty, and only one jug must hold the target amount.

The sample input and output:

```
2
5
2
3
2
3
4
```

```
2
-1
```

## Idea

Act out the pouring with one fixed routine, like measuring flour with two cups by always filling the left cup first. The program checks reachability, then plays out two pouring orders and keeps the shorter one.

Reachability has two simple rules. The target cannot exceed the larger jug. It must also divide evenly by the greatest common divisor (the largest shared factor) of the two capacities. If either rule fails, the answer is −1.

`stepsFor` simulates one direction: fill the first jug, pour into the second, and empty the second when it fills. The driver calls it with both jugs swapped, then takes the smaller count. A step ceiling of 2^20 stops any runaway simulation.

Cost per case: two simulations of at most 2^20 constant-time steps. A search over all `(a + 1)(b + 1)` fill states would reach 1.6 × 10^9 states at the limits.

Two short simulations and one divisor test replace a huge state search.

## Why It Works

Four facts carry the program.

1. A fill, empty, or pour always changes each amount by a multiple of `gcd(a, b)`. A target outside that divisor pattern can never appear.
2. Neither jug holds more than its own capacity, so a target above both capacities is impossible.
3. The fixed routine (fill first, pour, empty when full) walks a definite chain of states. The first time the target appears, the step count is valid for that direction.
4. Sweeping the jugs in both orders covers the cheaper route, since one order often needs far fewer steps. The ceiling keeps every trial finite.

The values the program tracks:

| Term | Meaning |
|---|---|
| `gcdOf` | greatest common divisor of the two capacities |
| `stepsFor` | step count for one pouring order |
| `stepCeiling` | cap of 2^20 simulated steps |
| `firstAmount`, `secondAmount` | litres currently in each jug |

Trying both orders captures the shortest of the two deterministic paths.

A script-traced example with `a = 5`, `b = 2`, `c = 3`:

```
start              (0, 0)  step 0
fill first jug     (5, 0)  step 1
pour into second   (3, 2)  step 2
first jug holds 3  -> answer 2
```

The second sample case has `a = 2`, `b = 3`, `c = 4`. Here 4 exceeds both capacities, so the answer is −1.

## Code

**Constants and divisor.** The ceiling bounds each simulation, and `gcdOf` uses repeated remainders.

```nim
const flushBlockBytes = 1 shl 17
const stepCeiling = 1 shl 20

proc gcdOf(leftValue, rightValue: int): int =
  var larger = leftValue
  var smaller = rightValue
  while smaller != 0:
    var remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

`stepCeiling` equals 2^20. The Euclidean loop in `gcdOf` runs O(log smaller) times and uses integer remainders only.

**Pouring simulation.** One order is played out until the target appears or the ceiling is hit.

```nim
proc stepsFor(firstCapacity, secondCapacity, target: int): int =
  var firstAmount = 0
  var secondAmount = 0
  var stepCount = 0
  while stepCount < stepCeiling:
    if firstAmount == target or secondAmount == target:
      return stepCount
    if firstAmount == 0:
      firstAmount = firstCapacity
    elif secondAmount == secondCapacity:
      secondAmount = 0
    else:
      var poured = firstAmount
      if secondCapacity - secondAmount < poured:
        poured = secondCapacity - secondAmount
      firstAmount = firstAmount - poured
      secondAmount = secondAmount + poured
    stepCount = stepCount + 1
  return -1
```

The loop checks both jugs before each move, so an already-correct start counts zero steps. The three branches cover fill, empty-on-full, and pour. `poured` is capped by the free space in the second jug.

**Scanner and driver.** The program reads all cases, filters impossible targets, then compares both orders.

```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

var inputData: string
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for j in 1 .. caseCount:
  var firstCapacity = nextInt(inputData, i)
  var secondCapacity = nextInt(inputData, i)
  var target = nextInt(inputData, i)
  var answer: int
  if target > firstCapacity and target > secondCapacity:
    answer = -1
  elif target mod gcdOf(firstCapacity, secondCapacity) != 0:
    answer = -1
  else:
    var firstWay = stepsFor(firstCapacity, secondCapacity, target)
    var secondWay = stepsFor(secondCapacity, firstCapacity, target)
    if firstWay < 0 or secondWay < 0:
      answer = max(firstWay, secondWay)
    else:
      answer = min(firstWay, secondWay)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

`nextInt` scans the buffered input by index. Over-large targets and targets outside the gcd pattern return −1 at once. Both `stepsFor` calls use the ceiling, and `max` recovers the existing count when one direction fails.

## Complexity

Each case does one divisor test and at most two bounded simulations.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| `gcdOf` | O(log min(a, b)) | O(1) |
| Two simulations | at most 2 × 2^20 steps | O(1) |
| Output | one write per 128 KiB block | 128 KiB |
| Total per case | bounded by the step ceiling | O(1) |

The ceiling keeps every case finite and predictable.

| Measure | Big O |
|---|---|
| Time | O(log min(a, b) + stepCeiling) per case |
| Space | O(1) per case, plus input and output buffers |

Capacities stay small, so the bound is a few million steps per case.

A breadth-first search over all fill states would hold `(a + 1)(b + 1)` pairs, up to 1.6 × 10^9 at the limits. The gcd test and two simulations avoid that memory cost.
