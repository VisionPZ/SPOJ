# AVRG — Simple Average (SPOJ)

<https://www.spoj.com/problems/AVRG/>

## Problem

A shopper buys six products and wants their average price. Given six integer costs in standard input, compute and print their mean.

Input contains six integers separated by whitespace without a test count. Output prints the floating-point division `sum / 6.0` expected by the SPOJ Python 3 judge.

Constraints and limits for the task:

| item | bound |
|---|---|
| product prices | 6 integer values |
| output format | floating-point `total / 6.0` |
| judge languages | Python 3, PyPy3, MAWK, BC (no Nim/C/C++) |
| judge limit | 1000 ms, 1536 MB |

Reading all six tokens in one pass avoids per-line `input()` overhead.

Sample input and output:

```
3
7
5
2
1
6
```

```
4.0
```

Summing `3 + 7 + 5 + 2 + 1 + 6` gives `24`, and `24 / 6.0` emits `4.0`.

## Idea

Accumulate all six integers and divide by `6.0`, like totaling six grocery receipts on a calculator and dividing evenly across six shares.

Integer parsing followed by single-division float output runs in `O(1)` time and space. SPOJ accepts Python 3's standard float formatting (`4.0`) across all judge test files.

Bulk byte decoding keeps startup overhead negligible within Python 3's one-second budget.

## Why It Works

1. `sys.stdin.buffer.read().decode("utf-8", "ignore").split()` loads the entire input stream in one syscall and splits out `raw_tokens`.
2. `[int(token) for token in raw_tokens[:6]]` parses the six item costs as integers and pads short inputs with `0`.
3. `total_cost / 6.0` computes the exact Python floating-point quotient expected by the SPOJ Python 3 judge.
4. Writing the result string directly to `sys.stdout` avoids extra flush calls.

Key identifiers in the program:

| term | meaning |
|---|---|
| `raw_tokens` | whitespace-split strings from standard input |
| `values` | first six parsed integer costs |
| `total_cost` | integer sum of the six costs |

Worked trace on `[3, 7, 5, 2, 1, 6]`: `total_cost` equals `24`, and `24 / 6.0` produces `4.0`.

## Code

**Input reader and mean output.** `main` reads the first six integers in one pass and writes `total_cost / 6.0`.

```python
def main():
    raw_tokens = sys.stdin.buffer.read().decode("utf-8", "ignore").split()
    values = [int(token) for token in raw_tokens[:6]]
    while len(values) < 6:
        values.append(0)
    total_cost = sum(values)
    sys.stdout.write(str(total_cost / 6.0) + "\n")
```

## Complexity

| metric | cost |
|---|---|
| time | O(1) |
| space | O(1) |

Reading and averaging six integer tokens runs in constant time and constant memory.
