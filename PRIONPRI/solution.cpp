#include <cstdio>

typedef unsigned long long u64;

u64 powerMod(u64 base, u64 exponent, u64 modulus) {
    u64 result = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

bool isPrime(u64 number) {
    if (number < 2) return false;
    const u64 smallPrimes[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    for (int i = 0; i < 12; i++) {
        if (number % smallPrimes[i] == 0) return number == smallPrimes[i];
    }
    u64 oddPart = number - 1;
    int trailingZeros = 0;
    while ((oddPart & 1) == 0) {
        oddPart >>= 1;
        trailingZeros++;
    }
    const u64 testBases[] = {2, 3, 5, 7};
    for (int b = 0; b < 4; b++) {
        u64 probe = powerMod(testBases[b], oddPart, number);
        if (probe == 1 || probe == number - 1) continue;
        bool passed = false;
        for (int r = 1; r < trailingZeros; r++) {
            probe = probe * probe % number;
            if (probe == number - 1) {
                passed = true;
                break;
            }
        }
        if (!passed) return false;
    }
    return true;
}

int main() {
    int caseCount = 0;
    if (scanf("%d", &caseCount) != 1) return 0;
    while (caseCount--) {
        u64 number = 0;
        scanf("%llu", &number);
        puts(isPrime(number) ? "YES" : "NO");
    }
    return 0;
}
