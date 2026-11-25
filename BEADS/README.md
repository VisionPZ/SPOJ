# BEADS — Glass Beads (SPOJ)
<https://www.spoj.com/problems/BEADS/>

## Problem

A necklace can be opened at any bead, and a weak joint depends on the bead sizes that end up in front.
The inspector must find the opening that gives the smallest reading of sizes.

The first line gives the case count. Each next line holds one lowercase bead string of length up to 10000. Print the one-based index of the lexicographically smallest rotation (dictionary order), using the lowest index when ties occur.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Beads per case | up to 10000 |
| Bead letters | lowercase a to z |
| Judge time | 500 ms |
| Judge memory | 1536 MB |

A linear rotation scan is needed to meet the tight half-second limit.

The sample input and its expected output follow byte for byte.

```
4
helloworld
amandamanda
dontcallmebfu
aaabaaa
```

```
10
11
6
5
```


## Idea

Find the smallest rotation by racing two cursors around a doubled string, like comparing two runners who skip equal stretches together.
The program concatenates the necklace with itself, so every rotation appears as a substring of the same length. Two cursors start at positions zero and one and compare characters with an offset.
When a mismatch shows one cursor is larger, that cursor jumps past the whole matched block. Each cursor only moves forward, so the total work is linear.
Building and sorting all rotations costs quadratic time and cannot meet the half-second limit.
Two forward cursors locate the worst joint in one pass.

## Why It Works

1. Doubling the string makes every rotation a window of length n starting at some position.
2. Two cursors compare windows with an offset, so equal stretches are skipped in one shared pass.
3. If the character at i is larger, i jumps beyond the matched block; otherwise j jumps.
4. When the two cursors meet, the loop advances one of them to break the tie.
5. The smaller final cursor plus one is the printed bead number, using the lowest index on ties.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| doubled string | necklace followed by itself |
| rotation | window of n beads from a start index |
| cursor | candidate start index under comparison |
| match length | equal prefix shared by two rotations |

They explain why two cursors finish in linear time.

A script check of `aaabaaa` compares the doubled string with itself shifted.
The smallest rotation starts at zero-based index 4 and reads `aaaaaab`.
Adding one gives bead 5, which matches the sample output.

## Code

**Necklace reader.**
```nim
proc readNecklace(): string =
  skipToLowercase()
  var j = i
  while i < inputData.len and inputData[i] >= 'a' and inputData[i] <= 'z':
    inc i
  return inputData[j .. i - 1]
```

The reader skips non-lowercase characters. It returns the bead string between two cursors. The scan reuses one input buffer.

**Two-cursor minimum rotation.**
```nim
proc worstDisjoinStart(beads: string): int =
  let beadCount = beads.len
  if beadCount < 2:
    return 0
  let doubled = beads & beads
  var i = 0
  var j = 1
  while i < beadCount and j < beadCount:
    var matchCount = 0
    while matchCount < beadCount and doubled[i + matchCount] == doubled[j + matchCount]:
      inc matchCount
    if matchCount >= beadCount:
      break
    if doubled[i + matchCount] > doubled[j + matchCount]:
      i = i + matchCount + 1
      if i == j:
        inc i
    else:
      j = j + matchCount + 1
      if i == j:
        inc j
  return min(i, j)
```

The routine doubles the necklace once. Cursor jumps skip blocks that are already equal. The loop returns the smaller zero-based start index.

**Answer driver.**
```nim
let caseCount = readCaseCount()
for i in 0 ..< caseCount:
  let beads = readNecklace()
  outputBuffer.add($(worstDisjoinStart(beads) + 1))
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    flushOutput()
stdout.write(outputBuffer)
```

The driver reads the case count first. It prints the one-based start for each necklace. A block flush keeps output writes infrequent.


## Complexity

Each cursor advances at most n positions, so comparisons stay linear overall.

| Phase | Time | Space |
| --- | --- | --- |
| read necklace | O(n) | one string |
| double string | O(n) | one doubled string |
| cursor scan | O(n) | constant |

The small output buffer flushes only after many answers.

Big O uses bead count n.

| Measure | Big O |
| --- | --- |
| time | O(n) per case |
| space | O(n) |

Sorting all n rotations would cost O(n squared log n) time.
