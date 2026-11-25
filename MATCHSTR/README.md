# MATCHSTR — Tìm xâu 01 (SPOJ)

<https://www.spoj.com/problems/MATCHSTR/>

## Problem

Two digit strings S and T are given, one per line. Count how many times T occurs inside S. Overlapping occurrences each count once.

| Item | Bound |
|---|---|
| Length of T | 1 ≤ lenT ≤ lenS |
| Length of S | lenS ≤ 10^6 |
| Alphabet | digits 0-9 only |
| Judge limit | 1000 ms, 1536 MB |
| Language | C++14 (no Nim offered) |

The sample case:

```
123123
12
```

```
2
```

## Idea

Build the KMP prefix function for T, then walk S once while carrying a match length. The prefix table says where to fall back after a mismatch, so every character of S is read a constant number of times. A naive scan compares up to lenS × lenT characters, which is 10^12 at the limit.

## Why It Works

1. `prefixValue[i]` stores the length of the longest proper prefix of T that is also a suffix of T[0..i].
2. During the scan, `matchedLength` is the length of the current suffix of the read part of S that matches a prefix of T.
3. On a mismatch the fallback chain jumps to shorter matching prefixes without rereading text.
4. When `matchedLength` reaches lenT, an occurrence ends here; the fallback keeps overlapping matches alive.
5. Each text character advances the scan exactly once, so the walk is linear.

| Term | Meaning |
|---|---|
| `prefixValue` | KMP fallback table for T |
| `matchedLength` | characters of T matched so far |
| `textStart` / `patternStart` | offsets of S and T inside the read buffer |
| `occurrenceCount` | number of matches found |

A script-traced example from `gen.py`:

```
S = 123123, T = 12
match ends at position 1, fallback to 0
match ends at position 4, fallback to 0
count = 2
```

The trace matches the sample answer.

## Code

**Bulk input read.** This block slurps stdin into one byte vector.

```cpp
    const int readBlockSize = 1 << 20;
    static char readBlock[readBlockSize];
    vector<char> inputData;
    inputData.reserve(1 << 21);
    size_t bytesRead = 0;
    while ((bytesRead = fread(readBlock, 1, readBlockSize, stdin)) > 0)
        inputData.insert(inputData.end(), readBlock, readBlock + bytesRead);
```

One megabyte arrives per `fread` call.
The vector holds both strings contiguously.

**Token extraction.** This block finds the two digit runs that form S and T.

```cpp
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
```

Newlines between the strings are skipped, not stored separately.
An empty or too-long pattern answers zero at once.

**Prefix table.** This block builds the KMP fallback values for T.

```cpp
    vector<int> prefixValue(patternLength, 0);
    int matchedLength = 0;
    for (size_t i = 1; i < patternLength; i++) {
        while (matchedLength > 0 && inputData[patternStart + i] != inputData[patternStart + matchedLength])
            matchedLength = prefixValue[matchedLength - 1];
        if (inputData[patternStart + i] == inputData[patternStart + matchedLength]) matchedLength++;
        prefixValue[i] = matchedLength;
    }
```

Each fallback step strictly shortens the match, so the inner loop is linear overall.

**Scanning for matches.** This block walks S and counts every completed match.

```cpp
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
```

The fallback after a hit allows overlapping occurrences.
One number is printed at the end.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Prefix table | O(lenT) | O(lenT) |
| Scan | O(lenS) | constant |

| Measure | Big O |
|---|---|
| Time | O(lenS + lenT) |
| Space | O(lenS + lenT) |

A naive substring scan costs O(lenS · lenT), up to 10^12 comparisons; KMP stays linear.
