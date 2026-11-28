# G10186 — Cumpleaños Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10186/>

## Problem

A family holds a raffle with fewer than ten participants standing in a line. Each participant picks a number from `0` to `100`, and one winning target number is chosen.

A participant whose own number is prime adds the next neighbor's number, while a non-prime subtracts it. The last participant uses the previous neighbor instead (or `0` when alone). Compare absolute values of these results and print the name and original number of the participant whose result has the smallest absolute distance to the target.

Constraints and limits for the task:

| item | bound |
|---|---|
| participants | `< 10` |
| numbers and target | `0` to `100` |
| judge languages | C++ 4.3.2, C, C#, Python 3 (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Scanning the four token groups cleanly in one pass finds the winner directly.

Sample input and output:

```
3
Juan Pedro Maria
58 31 76
88
```

```
Pedro 31
```

Pedro (`31`, prime) computes `|31 + 76| = 107`, whose distance `19` from `88` beats Juan (`|27 - 88| = 61`) and Maria (`|45 - 88| = 43`).

## Idea

Simulate each participant's arithmetic rule directly, like measuring who lands closest to a target mark on a number line. Because SPOJ compares absolute distance `|resultValue - targetValue|` rather than filtering strictly above the target, track the minimum `diff` and break ties by earliest index.

Parsing tokens across the whole input buffer handles arbitrary blank lines and compiles cleanly under C++98 (`-std=c++98`).

## Why It Works

1. `isPrimeValue` checks divisors up to `sqrt(value)`, classifying each integer in `0 .. 100`.
2. Neighbor lookup selects `enteredValues[idx + 1]` for everyone except the last participant, who uses `enteredValues[idx - 1]` (or `0` when `participantCount == 1`).
3. Taking `raw < 0 ? -raw : raw` keeps only non-negative magnitudes as required.
4. Selecting strictly smaller `diff = |resultValue - targetValue|` picks the nearest result and preserves earlier participants on ties.

Key identifiers in the program:

| term | meaning |
|---|---|
| `participantCount` | number of raffle entrants |
| `enteredValues` | numbers picked by each participant |
| `targetValue` | winning target value on the paper |
| `isPrimeValue` | trial-division primality test |
| `bestIndex` | index of the winning participant |

Worked trace on the sample: Juan (`58`, composite) gives `27` (distance `61`), Pedro (`31`, prime) gives `107` (distance `19`), and Maria (`76`, composite) gives `45` (distance `43`), so Pedro wins with `31`.

## Code

**Neighbor evaluation and winner selection.** `main` computes each participant's absolute result and selects the smallest absolute gap to `targetValue`.

```cpp
    int bestDiff = -1;
    int bestIndex = 0;
    for (int idx = 0; idx < participantCount; idx++) {
      int currentValue = enteredValues[idx];
      int neighborValue = 0;
      if (participantCount == 1) {
        neighborValue = 0;
      } else if (idx == participantCount - 1) {
        neighborValue = enteredValues[idx - 1];
      } else {
        neighborValue = enteredValues[idx + 1];
      }
      int raw = isPrimeValue(currentValue)
          ? (currentValue + neighborValue)
          : (currentValue - neighborValue);
      int resultValue = raw < 0 ? -raw : raw;
      int diff = resultValue - targetValue;
      if (diff < 0) {
        diff = -diff;
      }
      if (bestDiff < 0 || diff < bestDiff) {
        bestDiff = diff;
        bestIndex = idx;
      }
    }
```

## Complexity

| metric | cost |
|---|---|
| time | O(P * sqrt(M)) |
| space | O(P) |

For `P < 10` participants and values bounded by `M = 100`, both runtime and memory are tiny constants.
