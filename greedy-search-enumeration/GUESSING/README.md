# GUESSING — Number Guessing Game (SPOJ)

<https://www.spoj.com/problems/GUESSING/>

## Problem

Guess a hidden six-digit number from `000000` to `999999` using feedback from candidate queries. After each guess, the server returns `A` (exact digit matches at the same index) and `B` (cross-index digit matches where indices differ).

On SPOJ, reaching `A = 6` on the interactive query endpoint reveals the `TEXT` string `LIFE IS LIKE A BOX OF CHOCOLATES. YOU NEVER KNOW WHAT YOU'RE GONNA GET.`. In this program, empty standard input solves the interactive SPOJ secret (`875520`) and emits that sentence, while six-digit targets on standard input exercise the solver offline.

Constraints and limits for the task:

| item | bound |
|---|---|
| target space | `000000` to `999999` (`codeLength = 6`) |
| feedback `A` | count of `guess[i] == target[i]` |
| feedback `B` | count of `i != j` with `guess[i] == target[j]` |
| judge language | `TEXT` (offline solver in Nim) |
| judge limit | 1000 ms, 1536 MB |

Checking every code up to `999999` one at a time wastes up to a million queries.

Interactive exchange examples observed on SPOJ:

```
000000 -> 1A5B
555555 -> 2A10B
875520 -> 6A2B
```

```
LIFE IS LIKE A BOX OF CHOCOLATES. YOU NEVER KNOW WHAT YOU'RE GONNA GET.
```

Once the server confirms `6A`, it prints the `TEXT` sentence required for an accepted submission.

## Idea

Split unknown positions in half with binary search after counting digits, like weighing half a tray of coins against empty slots. Querying six identical digits reports that digit's exact multiplicity via `scoreGuess`.

The algorithm discovers digit counts in at most nine uniform probes, picks one `absentDigit`, and recursively bisects remaining indices via `placeDigit`. Each target finishes in at most 21 oracle calls instead of scanning up to one million candidates.

Divide-and-conquer placement finds every digit position directly in `O(1)` time per six-digit code.

## Why It Works

1. Querying `d` across all six positions yields exact match count `A` equal to how many times `d` appears in `secret`.
2. Checking `0 .. 8` stops early once `totalFound == codeLength`, and any remaining occurrences belong to `maxDigitValue`.
3. Because a six-digit string uses at most six distinct digits out of ten, at least four digits have zero occurrences, guaranteeing an `absentDigit`.
4. Filling unprobed positions with `absentDigit` ensures those indices contribute zero matches to `scoreGuess`.
5. Putting `digit` only into `[loIndex, midIndex)` makes `scoreGuess` return `leftCount`, the exact multiplicity of `digit` in the left half.
6. Recursing stops at `neededCount == 0` or `neededCount == spanLen`, filling forced spans with zero queries, and assigns the final digit immediately.

Key identifiers in the program:

| term | meaning |
|---|---|
| `codeLength` | fixed digit count `6` |
| `scoreGuess` | oracle returning exact positional matches `A` |
| `absentDigit` | digit guaranteed missing from `secret` |
| `placeDigit` | binary-search splitter over remaining unknown indices |
| `solveTarget` | recovers all six digits via `scoreGuess` |

Worked trace on `secret = 875520` (`absentDigit = 1` after counting `{0:1, 2:1, 5:2, 7:1, 8:1}`):

| step | probe | `A` | conclusion |
|---|---|---|---|
| place `0` in `[0..5]` | `000111` | `0` | `0` lies in `[3, 4, 5]` |
| split `[3, 4, 5]` | `111011` | `0` | `0` lies in `[4, 5]` |
| split `[4, 5]` | `111101` | `0` | index `5` must be `0` |

Repeating the same split for `2`, `5`, and `7` pins every slot and leaves index `0` as `8` with zero extra queries.

## Code

**Uniform digit counting and driver.** `solveTarget` counts digit multiplicities up to `codeLength`, finds `absentDigit`, and solves each remaining digit cleanly.

```nim
proc solveTarget(secret: DigitCode): DigitCode =
  var counts: array[10, int]
  var totalFound = 0
  for digit in 0 ..< maxDigitValue:
    if totalFound == codeLength:
      break
    var uniformGuess: DigitCode
    for idx in 0 ..< codeLength:
      uniformGuess[idx] = digit
    let hitCount = scoreGuess(uniformGuess, secret)
    counts[digit] = hitCount
    totalFound += hitCount
  if totalFound < codeLength:
    counts[maxDigitValue] = codeLength - totalFound

  var absentDigit = 0
  for digit in 0 .. maxDigitValue:
    if counts[digit] == 0:
      absentDigit = digit
      break

  var presentDigits: seq[int] = @[]
  for digit in 0 .. maxDigitValue:
    if counts[digit] > 0:
      presentDigits.add digit

  var resolved: DigitCode
  var assigned: array[6, bool]
  var unknownPos: seq[int] = @[0, 1, 2, 3, 4, 5]

  for idx in 0 ..< presentDigits.len:
    let digit = presentDigits[idx]
    if idx == presentDigits.len - 1:
      for pos in unknownPos:
        resolved[pos] = digit
      break
    placeDigit(digit, absentDigit, secret, unknownPos, 0, unknownPos.len, counts[digit], resolved, assigned)
    var nextUnknown: seq[int] = @[]
    for pos in unknownPos:
      if not assigned[pos]:
        nextUnknown.add pos
    unknownPos = nextUnknown
  resolved
```

**Binary-search position splitter.** `placeDigit` puts `digit` on the left half `[loIndex, midIndex)` and `absentDigit` everywhere else to count left matches.

```nim
proc placeDigit(
    digit: int,
    absentDigit: int,
    secret: DigitCode,
    unknownPos: seq[int],
    loIndex: int,
    hiIndex: int,
    neededCount: int,
    resolved: var DigitCode,
    assigned: var array[6, bool]
) =
  if neededCount <= 0:
    return
  let spanLen = hiIndex - loIndex
  if neededCount == spanLen:
    for idx in loIndex ..< hiIndex:
      let pos = unknownPos[idx]
      resolved[pos] = digit
      assigned[pos] = true
    return
  let midIndex = loIndex + (spanLen div 2)
  var probe: DigitCode
  for idx in 0 ..< codeLength:
    probe[idx] = absentDigit
  for idx in loIndex ..< midIndex:
    probe[unknownPos[idx]] = digit
  let leftCount = scoreGuess(probe, secret)
  placeDigit(digit, absentDigit, secret, unknownPos, loIndex, midIndex, leftCount, resolved, assigned)
  placeDigit(digit, absentDigit, secret, unknownPos, midIndex, hiIndex, neededCount - leftCount, resolved, assigned)
```

## Complexity

| metric | cost |
|---|---|
| time | O(N) |
| space | O(1) |

For `N` hidden targets of fixed width `codeLength`, each target uses at most 21 constant-time oracle probes, whereas scanning `10^6` codes linearly takes up to a million steps per target.
