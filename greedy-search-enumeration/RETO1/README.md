# RETO1 — Crazy Computer (SPOJ)

<https://www.spoj.com/problems/RETO1/>

## Problem

Words arrive at strictly increasing integer seconds `t_i`. If two consecutive words differ by more than `c` seconds, all previous words vanish before adding the new word; otherwise the new word appends to the screen. Print how many words remain at the end.

Input begins with `N` and `C`, followed by `N` increasing timestamps. Output prints one positive integer.

Constraints and limits for the task:

| item | bound |
|---|---|
| words `N` | `1 <= N <= 100000` |
| delay `C` | `1 <= C <= 10^9` |
| timestamps `t_i` | `1 <= t_i <= 10^9`, strictly increasing |
| judge languages | C, C++, C++14, Java, Python 3 (no Nim) |
| judge limit | 1000 ms, 1536 MB |

Storing all words is unnecessary because only the current streak length affects the final answer.

Sample input and output:

```
6 5
1 3 8 14 19 20
```

```
3
```

Gaps after second `8` clear the board at `14`, leaving three words (`14, 19, 20`).

## Idea

Maintain a single streak counter like an odometer that resets to `1` whenever two timestamps drift farther apart than `delay`. Because old words drop together on any clear, knowing `remainingCount` and `previousTime` suffices.

Streaming `wordCount` timestamps in one pass costs `O(N)` time and `O(1)` extra space. Implementing the solution in C++14 matches SPOJ's allowed languages where Nim is excluded.

Comparing `currentTime - previousTime > delay` drives every update in constant time.

## Why It Works

1. The first word starts `remainingCount = 1` at `previousTime`.
2. Whenever `currentTime - previousTime <= delay`, the screen retains all prior words and grows by `1`.
3. Whenever `currentTime - previousTime > delay`, older words vanish and only the current word stays, resetting `remainingCount = 1`.
4. After processing all `wordCount` timestamps, `remainingCount` equals the final word count on screen.

Key identifiers in the program:

| term | meaning |
|---|---|
| `wordCount` | total timestamps `N` |
| `delay` | clear threshold `C` |
| `previousTime` | timestamp of the last word seen |
| `currentTime` | timestamp being processed |
| `remainingCount` | words currently remaining on screen |

Worked trace on `6 5` with `1 3 8 14 19 20`: `remainingCount` climbs `1 -> 2 -> 3`, resets to `1` at `14` (`14 - 8 > 5`), then climbs `1 -> 2 -> 3`.

## Code

**Linear gap scan.** `main` compares each consecutive timestamp gap against `delay` and writes `remainingCount`.

```cpp
  int64_t wordCount = nextInt64(inputData, scanPos);
  int64_t delay = nextInt64(inputData, scanPos);
  int64_t remainingCount = 1;
  int64_t previousTime = nextInt64(inputData, scanPos);

  for (int64_t idx = 1; idx < wordCount; idx++) {
    int64_t currentTime = nextInt64(inputData, scanPos);
    if (currentTime - previousTime > delay) {
      remainingCount = 1;
    } else {
      remainingCount++;
    }
    previousTime = currentTime;
  }
```

## Complexity

| metric | cost |
|---|---|
| time | O(N) |
| space | O(1) |

Scanning all `N` timestamps once runs in linear time with constant working memory.
