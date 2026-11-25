#include <cstdio>
#include <string>

using namespace std;

const int maximumIdValue = 100000;

static string inputData;
static size_t scanPos = 0;
static bool seenId[maximumIdValue + 1];

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

int main() {
    char readChunk[1 << 20];
    size_t bytesRead;
    while ((bytesRead = fread(readChunk, 1, sizeof readChunk, stdin)) > 0)
        inputData.append(readChunk, bytesRead);

    int offlineCount = nextInt();
    int distinctCount = 0;
    for (int readIndex = 0; readIndex < offlineCount; readIndex++) {
        int submittedId = nextInt();
        if (!seenId[submittedId]) {
            seenId[submittedId] = true;
            distinctCount++;
        }
    }

    printf("%d\n", distinctCount);
    return 0;
}
