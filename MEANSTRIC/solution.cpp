#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <vector>
using namespace std;

int main() {
    const int readBlockSize = 1 << 20;
    static char readBlock[readBlockSize];
    vector<char> inputData;
    inputData.reserve(1 << 22);
    size_t bytesRead = 0;
    while ((bytesRead = fread(readBlock, 1, readBlockSize, stdin)) > 0)
        inputData.insert(inputData.end(), readBlock, readBlock + bytesRead);
    inputData.push_back('\0');

    char* endPos = 0;
    const char* scanPos = &inputData[0];
    int caseCount = (int)strtol(scanPos, &endPos, 10);
    scanPos = endPos;
    for (int caseIndex = 0; caseIndex < caseCount; caseIndex++) {
        int numberCount = (int)strtol(scanPos, &endPos, 10);
        scanPos = endPos;
        long double sumValues = 0;
        long double sumLogs = 0;
        long double sumReciprocals = 0;
        for (int i = 0; i < numberCount; i++) {
            double parsedValue = strtod(scanPos, &endPos);
            scanPos = endPos;
            long double value = (long double)parsedValue;
            sumValues += value;
            sumLogs += logl(value);
            sumReciprocals += 1 / value;
        }
        long double count = (long double)numberCount;
        long double arithmeticMean = sumValues / count;
        long double geometricMean = expl(sumLogs / count);
        long double harmonicMean = count / sumReciprocals;
        printf("%.9Lf %.9Lf %.9Lf\n", arithmeticMean, geometricMean, harmonicMean);
    }
    return 0;
}
