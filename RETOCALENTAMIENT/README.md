# RETOCALENTAMIENT — Pertre (SPOJ)

<https://www.spoj.com/problems/RETOCALENTAMIENT/>

## Problem

Pertre wrote down the visible size of the moon for n consecutive days. The moon follows a fixed 30-day cycle: 0, 1, 2, …, 15, 14, …, 1, then it repeats. From her record, decide whether the next day's size is surely smaller, surely larger, or impossible to tell.

Input gives n, then n recorded sizes on one line. Output prints "MENGUANTE" if the next size is surely smaller, "CRECIENTE" if it is surely larger, and -1 if the data cannot decide.

| Item | Bound |
|---|---|
| Days recorded | 1 ≤ n ≤ 92 |
| Recorded sizes | 0 ≤ ai ≤ 15 |
| Consistency | record always fits the cycle |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
3 4 5 6 7
```

```
CRECIENTE
```

## Idea

Slide the record over the 30-day cycle and test every alignment, like matching a strip of patterned paper against a repeating wall. Only some shifts line up. Each shift that fits predicts one direction for the next day: up or down. If every fitting shift predicts the same direction, that direction is the answer; otherwise print -1. The check costs at most 30 × 92 comparisons per case.

## Why It Works

1. The cycle repeats every 30 days, so a record is fully described by its start phase, a number from 0 to 29.
2. The statement guarantees consistency, so at least one phase matches.
3. Neighboring cycle values are never equal, so the next day is either larger or smaller, never the same.
4. Two matching phases with different next directions mean two possible futures, so the answer is -1.
5. If all matching phases point the same way, that way is certain.

| Term | Meaning |
|---|---|
| `moonCycle` | the 30 sizes of one lunar cycle |
| `moonRecord` | the n sizes Pertre wrote |
| `phase` | where day 1 of the record sits in the cycle |
| `decidedDirection` | direction shared by fitting phases so far |
| `mixedDirections` | two fitting phases disagree |

A script-traced example from `gen.py`:

```
record 3 4 5 6 7
phase 3 in 30-day cycle
next size 8
```

The trace matches the sample answer: 8 is larger than 7, so "CRECIENTE".

## Code

**Cycle and hand scanner.** This block builds the cycle and reads integers by index.

```c
static int nextInteger(const char *data, int length, int *position) {
  while (*position < length && (data[*position] < '0' || data[*position] > '9')) {
    (*position)++;
  }
  if (*position >= length) {
    return -1;
  }
  int value = 0;
  while (*position < length && data[*position] >= '0' && data[*position] <= '9') {
    value = value * 10 + (data[*position] - FIRST_DIGIT);
    (*position)++;
  }
  return value;
}
```

One pass over the consumed characters reads each number.
The -1 return marks end of input between cases.
Scanning allocates nothing.

**Bulk input.** This block loads all of stdin once.

```c
  int inputLength = 0;
  size_t bytesRead;
  while (inputLength < (int)sizeof(inputData)) {
    bytesRead = fread(inputData + inputLength, 1, sizeof(inputData) - (size_t)inputLength, stdin);
    if (bytesRead == 0) {
      break;
    }
    inputLength += (int)bytesRead;
  }
```

A 64 MiB buffer holds even a 200000-case stress file.
One `fread` loop replaces per-token reads.

**Phase test.** This block walks all 30 alignments.

```c
    int decidedDirection = 0;
    int mixedDirections = 0;
    int phase;
    for (phase = 0; phase < CYCLE_LENGTH; phase++) {
      int matches = 1;
      for (recordIndex = 0; recordIndex < dayCount; recordIndex++) {
        if ((int)moonCycle[(phase + recordIndex) % CYCLE_LENGTH] != (int)moonRecord[recordIndex]) {
          matches = 0;
          break;
        }
      }
      if (!matches) {
        continue;
      }
      int lastSize = (int)moonCycle[(phase + dayCount - 1) % CYCLE_LENGTH];
      int nextSize = (int)moonCycle[(phase + dayCount) % CYCLE_LENGTH];
      int direction = nextSize > lastSize ? 1 : -1;
      if (decidedDirection == 0) {
        decidedDirection = direction;
      } else if (decidedDirection != direction) {
        mixedDirections = 1;
        break;
      }
    }
```

Mismatched phases exit after one bad day, so most cost is on true matches.
The break on disagreement stops the whole scan early.
Each case costs at most 30 × 92 byte compares.

**Answer and buffered output.** This block prints the decision.

```c
    if (mixedDirections || decidedDirection == 0) {
      appendText("-1\n");
    } else if (decidedDirection > 0) {
      appendText("CRECIENTE\n");
    } else {
      appendText("MENGUANTE\n");
    }
```

`appendText` fills a 128 KiB buffer and flushes when full.
The final `fwrite` emits the last partial block.

## Complexity

The cost splits into input, the phase scan, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Phase scan | O(30 × n) per case | record array |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n) per case, 30 is a constant |
| Space | O(input size) |

Reading only the last two sizes would fail: a size of 8 sits on both a rising and a falling part of the cycle.
