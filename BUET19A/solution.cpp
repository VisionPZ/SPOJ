#include <cstdio>

int main() {
    int caseCount = 0;
    if (scanf("%d", &caseCount) != 1) return 0;
    while (caseCount--) {
        long long gonNumber = 0;
        long long killuaNumber = 0;
        scanf("%lld %lld", &gonNumber, &killuaNumber);
        int gonSign = (int)(gonNumber % 3);
        int killuaSign = (int)(killuaNumber % 3);
        if (gonSign == killuaSign) {
            puts("DRAW");
        } else if ((gonSign - killuaSign + 3) % 3 == 1) {
            puts("GON");
        } else {
            puts("KILLUA");
        }
    }
    return 0;
}
