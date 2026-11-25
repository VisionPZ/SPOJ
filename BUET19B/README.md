# BUET19B — GCD (SPOJ)

<https://www.spoj.com/problems/BUET19B/>

## Problem

A list of N integers is given. The task is to print the greatest common divisor (G.C.D.) shared by every number in the list.

Input starts with N, then one line holds the N integers. Output holds one number.

| Item | Bound |
|---|---|
| List length | 1 ≤ N ≤ 100000 |
| Each value | below 100000 |
| Judge limit | 1000 ms, 1536 MB |

One pass over the list is enough.

The sample case:

```
5
2 4 6 8 2
```

```
2
```

## Idea

Carry one running value: the gcd of everything read so far. Start it at 0, then fold each new number in with Euclid's algorithm. Think of the running value as the biggest square tile that fits exactly into every rod measured so far; each new rod can only make the tile smaller. Each fold takes a few divisions, so the whole pass costs about N × log(100000) steps. Checking every divisor of every number costs far more. When the running value reaches 1, the loop stops, because 1 is the smallest possible gcd.

## Why It Works

1. `gcd(0, x) = x`, so the first fold copies the first number into the running value.
2. Gcd folds in any order: `gcd(gcd(a, b), c) = gcd(a, b, c)`. So a running value after k numbers is the gcd of those k numbers.
3. Euclid's step keeps the answer: `gcd(a, b) = gcd(b, a mod b)`, and the remainder is smaller each round, so it ends.
4. Divisors can only shrink when a new number joins. So a running value of 1 can never grow back, and stopping early is safe.
5. The loop runs exactly N times unless it stops at 1, so every input number is folded in.

| Term | Meaning |
|---|---|
| `runningGcd` | gcd of the numbers read so far |
| `gcdPair` | Euclid's algorithm on two numbers |
| `numberCount` | N, the length of the list |
| `nextValue` | the next number from the input |

The running value is the whole answer at the end.

A script-traced example from `gen.py`:

```
numbers 2 4 6 8 2
shared prime factors 2^1
answer 2
```

The trace matches the sample answer.

## Code

**Input and hand scanner.** This block reads integers out of one big string by index.

```cpp
static string inputData;
static size_t scanPos = 0;

static int nextInt() {
    while (scanPos < inputData.size() && (inputData[scanPos] < '0' || inputData[scanPos] > '9'))
        scanPos++;
    int value = 0;
    while (scanPos < inputData.size() && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
        value = value * 10 + (inputData[scanPos] - '0');
        scanPos++;
    }
    return value;
}
```

The scanner skips newlines and spaces without special handling.
Scanning costs one pass over the consumed characters.

**Euclid step.** This block returns the gcd of two numbers.

```cpp
static int gcdPair(int leftValue, int rightValue) {
    while (rightValue != 0) {
        int remainder = leftValue % rightValue;
        leftValue = rightValue;
        rightValue = remainder;
    }
    return leftValue;
}
```

Each round replaces the pair with a smaller one.
The loop ends when the second value hits 0, and the first holds the gcd.
Values below 100000 need at most about 25 rounds.

**Main: bulk read, fold, print.** This block holds the whole program driver.

```cpp
int main() {
    char readChunk[1 << 20];
    size_t bytesRead;
    while ((bytesRead = fread(readChunk, 1, sizeof readChunk, stdin)) > 0)
        inputData.append(readChunk, bytesRead);

    int numberCount = nextInt();
    int runningGcd = 0;
    for (int readIndex = 0; readIndex < numberCount && runningGcd != 1; readIndex++)
        runningGcd = gcdPair(runningGcd, nextInt());

    printf("%d\n", runningGcd);
    return 0;
}
```

One fread loop collects all input bytes into one string.
The loop runs at most N times, and the `runningGcd != 1` test stops it early.
One printf emits the single answer line.

## Complexity

The cost splits into input, one fold per number, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Folds | O(log V) per number, V < 100000 | constant |
| Output | one write | constant |

| Measure | Big O |
|---|---|
| Time | O(N log V) |
| Space | O(N) for the input buffer |

Testing every divisor of every number costs O(N × √V), about 3×10^7 steps; folding stays near 2.5×10^6.
