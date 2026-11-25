# ENPRIME — Prime Number (SPOJ)

<https://www.spoj.com/problems/ENPRIME/>

## Problem

Despite its title, this problem asks for a factorial: read one integer X and print X! = X × (X-1) × ... × 1.

| Item | Bound |
|---|---|
| Input | one integer X |
| Output | the exact factorial, no modulo |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
4
```

```
24
```

## Idea

Multiply the integers 2 through X into one running big number. Think of it as column arithmetic on paper, except Python integers grow as long as needed. The loop runs X-1 multiplications, and each multiplication touches only the digits of the current product. Parsing the input with `split` and building a list of tokens first would allocate objects for no benefit.

## Why It Works

1. The product 1 × 2 × ... × X is exactly X! by definition.
2. Python integers hold arbitrarily many digits, so no overflow occurs.
3. Starting at 2 with a seed of 1 leaves 0! and 1! correct, both equal to 1.
4. `set_int_max_str_digits` lifts the digit cap that newer Python builds put on `str()` of huge integers.

| Term | Meaning |
|---|---|
| `nextNumber` | reads the single integer from the byte buffer |
| `maxValue` | the input X |
| `factorialValue` | running product, ends as X! |
| `multiplier` | the next factor to fold in |

The multiplier loop stops as soon as it passes X, so the count is exactly X-1 multiplications for X ≥ 2.

A script-traced example from `gen.py`:

```
X = 4
running 1 -> 2 -> 6 -> 24
result 24
```

The trace matches the sample answer.

## Code

**Scanner and digit cap.** This block reads X and lifts the string-conversion limit.

```python
try:
    sys.set_int_max_str_digits(10000000)
except AttributeError:
    pass
```

Python 3.11 and newer refuse long `str()` calls by default.
The guard keeps the code working on older interpreters too.

**Factorial loop.** This block folds in each factor.

```python
inputData = sys.stdin.buffer.read()
scanPos = 0
maxValue, scanPos, found = nextNumber(inputData, scanPos)
factorialValue = 1
multiplier = 2
while multiplier <= maxValue:
    factorialValue *= multiplier
    multiplier += 1
sys.stdout.write(str(factorialValue) + "\n")
```

The loop runs exactly max(0, X-1) times.
Each step multiplies one small int into the growing big int.
One write emits the whole answer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Multiplications | O(X) big-int products | result digits |
| Output | one write | result digits |

| Measure | Big O |
|---|---|
| Time | O(X · D) with D the digits of X! |
| Space | O(D) |

A recursive version does the same work but adds X stack frames.
