#include <cstdio>

int main() {
    int caseCount = 0;
    if (scanf("%d", &caseCount) != 1) return 0;
    while (caseCount--) {
        long long n = 0;
        scanf("%lld", &n);
        long long sumFirst = n * (n + 1) / 2;
        long long sumEven = n * (n + 1);
        long long sumOdd = n * n;
        long long sumSquares = n * (n + 1) * (2 * n + 1) / 6;
        long long sumCubes = sumFirst * sumFirst;
        printf("%lld %lld %lld %lld %lld\n", sumFirst, sumEven, sumOdd, sumSquares, sumCubes);
    }
    return 0;
}
