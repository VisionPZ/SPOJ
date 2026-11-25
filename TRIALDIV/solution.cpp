#include <cstdio>

const int limitValue = 1000000;
int smallestPrime[limitValue + 1];
char outputBuffer[1 << 20];
int outputLength = 0;

void flushOutput() {
    if (outputLength > 0) {
        fwrite(outputBuffer, 1, outputLength, stdout);
        outputLength = 0;
    }
}

void putChar(char c) {
    if (outputLength == (int)sizeof(outputBuffer)) flushOutput();
    outputBuffer[outputLength++] = c;
}

void putInt(int value) {
    char digits[12];
    int digitCount = 0;
    do {
        digits[digitCount++] = (char)('0' + value % 10);
        value /= 10;
    } while (value > 0);
    while (digitCount > 0) putChar(digits[--digitCount]);
}

int main() {
    for (int i = 2; (long long)i * i <= limitValue; i++) {
        if (smallestPrime[i] == 0) {
            smallestPrime[i] = i;
            for (long long j = (long long)i * i; j <= limitValue; j += i)
                if (smallestPrime[(int)j] == 0) smallestPrime[(int)j] = i;
        }
    }
    for (int i = 2; i <= limitValue; i++)
        if (smallestPrime[i] == 0) smallestPrime[i] = i;

    int caseCount = 0;
    if (scanf("%d", &caseCount) != 1) return 0;
    while (caseCount--) {
        int number = 0;
        scanf("%d", &number);
        bool firstFactor = true;
        while (number > 1) {
            int factor = smallestPrime[number];
            if (!firstFactor) putChar(' ');
            putInt(factor);
            firstFactor = false;
            number /= factor;
        }
        putChar('\n');
    }
    flushOutput();
    return 0;
}
