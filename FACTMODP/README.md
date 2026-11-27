# FACTMODP — Factorial Modulo Prime (SPOJ)

<https://www.spoj.com/problems/FACTMODP/>

## Problem

Compute N! modulo the prime P for many queries, where N can be far larger than P. If N reaches P, the factorial contains P as a factor and the answer is zero.

The first line holds the number of queries. Each following line holds N and P. Output one answer per query, separated by spaces.

| item | bound |
|---|---|
| queries | up to 100000 |
| N | up to 10¹¹ |
| P | prime, up to 10¹¹ |
| total square roots | sum of √P at most 320000 |
| judge limit | 10000 ms, 1536 MB |

Sample input and output:

```
3
1000 9907
1000000 9999907
10000000000 99999999907
```

```
4494 3354924 40583077821
```

The last query has N far above √P but still below P.

## Idea

Group the product into equal-sized blocks, like stacking identical crates before counting a warehouse.

Let m be slightly above √P and write N = q·m + r. One block product is H(x) = (x+1)(x+2)…(x+m). Evaluating H at 0, m, 2m, …, (q−1)m and multiplying those values gives the first q·m factors. The remaining r factors are multiplied directly. Each evaluation costs one polynomial lookup, so the work depends on √P rather than on N.

A product tree builds H and a second tree holds the evaluation points. Remainder trees push H down to every point. Polynomial multiplications run through number-theoretic transforms (exact Fourier transforms over small friendly primes); three primes and Garner reconstruction recover coefficients modulo the arbitrary prime P.

The program handles all queries with total cost bounded by the sum of √P.

## Why It Works

1. If N ≥ P, the product contains P, so the residue is zero.
2. Let m > √P. The numbers 1 through q·m split into q consecutive blocks of m.
3. Block j holds the numbers j·m + 1 through j·m + m, which equal H(j·m).
4. Therefore the product of all block values equals (q·m)! modulo P.
5. A polynomial of degree m is determined by its product tree; remainders against the point tree give all q values in O(m log² m).
6. Three friendly primes have a combined modulus above the largest possible convolution coefficient, so reconstruction modulo P is exact.

| term | meaning |
|---|---|
| `m` | block size, the integer above √P |
| `q` | number of full blocks |
| `H` | block polynomial of degree m |
| `Tree` | product tree holding intermediate polynomials |
| `evaluate` | remainder tree that produces H at every point |

Worked trace with the small query N = 10, P = 11, so m = 4, q = 2 and r = 2:

| step | value |
|---|---|
| H(x) | (x+1)(x+2)(x+3)(x+4) |
| H(0) | 24 ≡ 2 |
| H(4) | 5·6·7·8 = 1680 ≡ 8 |
| first two blocks | 2·8 ≡ 5 |
| tail factors | 9·10 ≡ 2 |
| result | 5·2 ≡ 10 |

The result agrees with 10! modulo 11, which Wilson's theorem also gives as −1 ≡ 10.

## Code

**Bulk input and unsigned scanner.** All input is read once and parsed by index.

```cpp
static u64 nextUnsigned() {
    while (scanPos < inputData.size() && (inputData[scanPos] < '0' || inputData[scanPos] > '9')) scanPos += 1;
    u64 value = 0;
    while (scanPos < inputData.size() && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
        value = value * 10 + (inputData[scanPos] - '0');
        scanPos += 1;
    }
    return value;
}
```

The scan skips whitespace before each number.
Every input value is non-negative, so no sign branch is needed.
The scanner allocates nothing.

```cpp
    u64 m = isqrt_u64(pmod - 1) + 1;
    u64 q = N / m;
    u64 r = N % m;
    if (q == 0) {
        u64 value = 1;
        for (u64 i = 2; i <= N; i += 1) value = (u64)((__uint128_t)value * i % pmod);
        return value;
    }
```

The block size is the integer square root plus one.
A query shorter than one block needs no tree.
Products use 128-bit intermediates before reduction.

```cpp
    Tree Ht = build(leaves);
    const auto& H = Ht.lv.back()[0];
    u64 padded = 1;
    while (padded < q) padded <<= 1;
    vector<vector<u64>> points;
    for (u64 j = 0; j < padded; j += 1) {
        u64 location = (j % padded) * m % pmod;
        points.push_back({(pmod - location) % pmod, 1});
    }
    Tree Tt = build(points);
    vector<u64> values = evaluate(H, Tt);
```

The first tree multiplies the m linear factors.
The second tree holds the q evaluation points, padded to a power of two.
The remainder tree returns every block value at once.

```cpp
    u64 answer = 1;
    for (u64 j = 0; j < q; j += 1) answer = (u64)((__uint128_t)answer * (values[j] % pmod) % pmod);
    for (u64 i = 1; i <= r; i += 1) answer = (u64)((__uint128_t)answer * ((q * m + i) % pmod) % pmod);
    return answer;
```

The first loop multiplies the full blocks.
The second loop appends the short tail.
Both use modular multiplication throughout.

## Complexity

With m = ⌈√P⌉, the product and remainder trees each cost O(m log² m) field operations. Memory holds two trees of total size O(m).

| phase | time | space |
|---|---|---|
| build block polynomial | O(m log² m) | O(m) |
| evaluate q points | O(m log² m) | O(m) |
| multiply results | O(q + r) | O(1) |

Total time is O(√P log² P) per query, and total work follows the bounded sum of √P. Multiplying every factor one by one would cost O(N), which is far larger when N approaches 10¹¹.
