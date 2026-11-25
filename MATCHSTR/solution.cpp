#include <cstdio>
#include <vector>
using namespace std;

int main() {
    const int readBlockSize = 1 << 20;
    static char readBlock[readBlockSize];
    vector<char> inputData;
    inputData.reserve(1 << 21);
    size_t bytesRead = 0;
    while ((bytesRead = fread(readBlock, 1, readBlockSize, stdin)) > 0)
        inputData.insert(inputData.end(), readBlock, readBlock + bytesRead);

    size_t inputSize = inputData.size();
    size_t scanPos = 0;
    while (scanPos < inputSize && (inputData[scanPos] < '0' || inputData[scanPos] > '9')) scanPos++;
    size_t textStart = scanPos;
    while (scanPos < inputSize && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') scanPos++;
    size_t textLength = scanPos - textStart;
    while (scanPos < inputSize && (inputData[scanPos] < '0' || inputData[scanPos] > '9')) scanPos++;
    size_t patternStart = scanPos;
    while (scanPos < inputSize && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') scanPos++;
    size_t patternLength = scanPos - patternStart;

    if (patternLength == 0 || patternLength > textLength) {
        printf("0\n");
        return 0;
    }

    vector<int> prefixValue(patternLength, 0);
    int matchedLength = 0;
    for (size_t i = 1; i < patternLength; i++) {
        while (matchedLength > 0 && inputData[patternStart + i] != inputData[patternStart + matchedLength])
            matchedLength = prefixValue[matchedLength - 1];
        if (inputData[patternStart + i] == inputData[patternStart + matchedLength]) matchedLength++;
        prefixValue[i] = matchedLength;
    }

    long long occurrenceCount = 0;
    matchedLength = 0;
    for (size_t i = 0; i < textLength; i++) {
        while (matchedLength > 0 && inputData[textStart + i] != inputData[patternStart + matchedLength])
            matchedLength = prefixValue[matchedLength - 1];
        if (inputData[textStart + i] == inputData[patternStart + matchedLength]) matchedLength++;
        if (matchedLength == (int)patternLength) {
            occurrenceCount++;
            matchedLength = prefixValue[matchedLength - 1];
        }
    }

    printf("%lld\n", occurrenceCount);
    return 0;
}
