# PERIOD5 — Periodic function, trip 5 (SPOJ)

<https://www.spoj.com/problems/PERIOD5/>

## Problem

A function is built by adding several periodic functions, each with an integer period no larger than N. The input gives the first N×N values of that sum and N×N new positions. Compute the function at each new position.

The first line holds N. The second line holds the N² known values. The third line holds the N² query positions, each between 0 and 10⁹−1. Print the answers on one line, separated by spaces.

| item | bound |
|---|---|
| N | below 258 |
| known values | N² |
| queries | N² |
| value size | abs(y) below 10⁹ |
| judge limit | 1 s to 7.5 s, depending on input file, 1536 MB |

Sample input and output:

```
3
15 3 17 2 16 4 15 3 17
10 100 1000 10000 100000 1000000 10000000 100000000 1000000000
```

```
16 16 16 16 16 16 16 16 16
```

Every query in the sample lands on the same value.

## Idea

Split the mixed signal into its pure periods, like separating a chord into single notes.

Each pure period m contributes one number for every residue modulo m. Adding those contributions gives the answer at any position. The known values determine a rational generating function with denominator built from cyclotomic polynomials (the minimal polynomials of roots of unity). Partial fractions split that fraction into one piece per period. Each piece repeats every m positions, so a query needs only one lookup per period.

Polynomial products use number-theoretic transforms (Fast Fourier transforms done exactly with modular arithmetic). A single large prime keeps every intermediate value exact, and the final signed answer is recovered by centring the residue. Scanning all possible paths without this split would need far more than N² work.

The program recovers all periods once, then answers each query with N lookups.

## Why It Works

1. A function with period m satisfies (Eᵐ − 1)f = 0, where E shifts the argument by one.
2. The product of cyclotomic polynomials Q = product of Qₘ, for m up to N, annihilates the sum.
3. Therefore the generating function is A/Q, and A follows from the first degree(Q) values.
4. Cyclotomic factors are pairwise coprime, so partial fractions write A/Q as a sum of Aₘ/Qₘ.
5. Qₘ divides 1 − zᵐ, so (1 − zᵐ)/Qₘ has degree below m; its coefficients repeat every m positions.
6. Each piece contributes an m-periodic array uₘ, and f(x) is the sum of uₘ[x mod m].

| term | meaning |
|---|---|
| `Qm[m]` | reversed cyclotomic polynomial for period m |
| `poly` | product of all `Qm`, the recurrence denominator |
| `A` | numerator obtained from the first values |
| `Rm` | repeating coefficients of 1 divided by `Qm` |
| `comp[m]` | recovered m-periodic contribution |

Worked trace for the sample with N = 3 and first value y(0) = 15:

| period | contribution at residue 1 | contribution at residue 0 |
|---|---|---|
| 1 | 10 | 10 |
| 2 | −8 | 5 |
| 3 | 1 | 0 |

For x = 10 the residues are 0, 0 and 1, so the sum is 10 + 5 + 1 = 16. Every sample query gives 16 for the same reason.

## Code

**Bulk input and signed scanner.** The whole stream is read once; the scanner keeps the minus sign.

```cpp
static i64 nextInteger() {
    while (scanPos < inputData.size() && (inputData[scanPos] < '0' || inputData[scanPos] > '9') && inputData[scanPos] != '-') scanPos += 1;
    bool negative = false;
    if (scanPos < inputData.size() && inputData[scanPos] == '-') { negative = true; scanPos += 1; }
    i64 value = 0;
    while (scanPos < inputData.size() && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
        value = value * 10 + (inputData[scanPos] - '0');
        scanPos += 1;
    }
    return negative ? -value : value;
}
```

The scan walks one buffer by index.
The sign branch handles negative known values.
No token is allocated while parsing.

```cpp
    vector<vector<i64>> Qm(N + 1);
    for (int m = 1; m <= N; m += 1) {
        vector<i64> den = {1};
        for (int d = 1; d < m; d += 1) {
            if (m % d == 0) den = multiply(den, Qm[d]);
        }
        vector<i64> num(m + 1, 0);
        num[0] = MOD - 1; num[m] = 1;
        auto [phi, rem] = divmod(num, den);
        trim(phi);
        Qm[m] = phi;
        reverse(Qm[m].begin(), Qm[m].end());
    }
```

The loop divides zᵐ − 1 by the smaller cyclotomic factors.
Reversing puts the constant term first, which makes division stable.
Degree totals stay below N².

```cpp
        int L = D - ph;
        vector<i64> series(nttSize, 0);
        for (int k = 0; k <= L; k += 1) series[k] = Rm[k % m];
        ntt(series, false);
        for (int i = 0; i < nttSize; i += 1) series[i] = mul(series[i], polyNtt[i]);
        ntt(series, true);
        series.resize(L + 1);
        vector<i64> R = move(series);
```

The repeating coefficients are filled once per period.
The transform of `poly` is reused across all periods.
One inverse transform finishes the product.

```cpp
    for (int qi = 0; qi < samples; qi += 1) {
        i64 x = queries[qi] % MOD;
        i64 total = 0;
        for (int m = 1; m <= N; m += 1) {
            total += comp[m][x % m];
            if (total >= MOD) total -= MOD;
        }
        i64 signedValue = total;
        if (signedValue > MOD / 2) signedValue -= MOD;
        output += to_string(signedValue);
        output += (qi + 1 == samples ? '\n' : ' ');
    }
```

Each query reads one entry per period.
Centring turns the residue back into a signed integer.
All answers are appended to one output buffer.

## Complexity

Let D be the total degree of the cyclotomic product, about 0.3 N². Building the denominator and numerator costs O(D log D) with transforms. Recovering each period costs one transform plus O(m·φ(m)) small polynomial work, so preprocessing is O(N·D log D).

| phase | time | space |
|---|---|---|
| build denominator and numerator | O(D log D) | O(D) |
| recover all periods | O(N·D log D) | O(D + N²) |
| answer N² queries | O(N²·N) | O(output) |

The whole program is O(N³ + N·D log D) time and O(N² + D) space. Testing every possible periodic decomposition would take far longer than the N² values available.
