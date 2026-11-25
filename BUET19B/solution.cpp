#include <cstdio>
#include <string>

using namespace std;

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

static int gcdPair(int leftValue, int rightValue) {
    while (rightValue != 0) {
        int remainder = leftValue % rightValue;
        leftValue = rightValue;
        rightValue = remainder;
    }
    return leftValue;
}

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
