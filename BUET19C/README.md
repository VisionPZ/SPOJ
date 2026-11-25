# BUET19C — Map (SPOJ)

<https://www.spoj.com/problems/BUET19C/>

## Problem

A copy checker gave every submission an ID, and submissions with the same ID are the same work. Given the N IDs, count how many different IDs appear, which is the number of students who really solved the offline.

Input starts with N, then one line holds the N IDs. Output holds one number.

| Item | Bound |
|---|---|
| Offline count | 1 ≤ N ≤ 100000 |
| Each ID | 1 ≤ ID ≤ 100000 |
| Judge limit | 1000 ms, 1536 MB |

One pass over the IDs is enough.

The sample case:

```
5
2 1 3 2 100
```

```
4
```

## Idea

Mark each ID in a table of 100001 boxes, and count a student only the first time its box is touched. Think of a teacher ticking a name on the class roster: a tick already there means nothing new. Each ID costs one array lookup, so the pass costs about N steps. Sorting the IDs first and counting runs costs N log N steps instead.

## Why It Works

1. An ID can only be counted once, because the box flips to true on the first hit and later hits are skipped.
2. Every counted box stands for one ID that appears in the input, so the count never overcounts.
3. Every ID in the input either was already marked or gets marked, so the count never misses one.
4. IDs are at most 100000, so a plain array of 100001 boxes covers them all without hashing.
5. The array starts all false, which is what a fresh roster looks like.

| Term | Meaning |
|---|---|
| `seenId` | one box per possible ID, true once that ID has been seen |
| `distinctCount` | number of IDs seen for the first time |
| `offlineCount` | N, the number of submissions |
| `submittedId` | the next ID from the input |
| `maximumIdValue` | 100000, the largest legal ID |

The count after the loop is the answer.

A script-traced example from `gen.py`:

```
ids 2 1 3 2 100
sorted 1 2 2 3 100
run heads 1 2 3 100
answer 4
```

The trace matches the sample answer.

## Code

**Input, scanner, and the mark table.** This block holds the input string and the roster boxes.

```cpp
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
```

The scanner skips newlines and spaces without special handling.
Scanning costs one pass over the consumed characters.
The table is 100001 bytes, so it fits in the static data segment.

**Main: bulk read, mark, count.** This block holds the whole program driver.

```cpp
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
```

One fread loop collects all input bytes into one string.
The loop runs exactly N times, one array test per ID.
One printf emits the single answer line.

## Complexity

The cost splits into input, one lookup per ID, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Marking | O(1) per ID | 100001 bools |
| Output | one write | constant |

| Measure | Big O |
|---|---|
| Time | O(N) |
| Space | O(N) for the input buffer, plus a fixed 100001 box table |

Sorting the IDs and counting runs costs O(N log N), about 1.7×10^6 comparisons; the mark table stays near 10^5 steps.
