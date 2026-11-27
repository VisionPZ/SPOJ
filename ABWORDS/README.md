# ABWORDS — AB-words (SPOJ)
<https://www.spoj.com/problems/ABWORDS/>

## Problem

Each case gives a set of balanced strings over a and b, with a recursive similarity rule defined on them.
Find the largest subset in which no two strings are similar.

The first line gives the case count. Each case starts with n, then n strings built from a and b. Every string has length 1 to 200. Print one integer per case: the level of diversity, which is the largest subset with no similar pair.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Strings per case | 1 to 1000 |
| String length | 1 to 200 |
| Judge time | 2.640 s |
| Judge memory | 1536 MB |

These bounds keep each case small enough for pairwise graph checks.

The sample input and its expected output follow byte for byte.

```
1
3
aabaabbbab
abababaabb
abaaabbabb
```

```
2
```


## Idea

Treat each string as a nested fork and give every fork a canonical shape (children sorted into a fixed order). This is like sorting a family tree before comparing two copies.
The program interns each word into an exact id and a canonical id. It then builds a similarity graph inside each canonical group.
Two words are similar when their child sequences match under separable splits or mirror splits, checked by a memoized dynamic program.
The final answer is a maximum independent set (largest group with no similar pair) in that graph, solved with bitsets and branch and bound.
Testing every subset is exponential, while grouping by canonical shape first keeps each comparison local.
Canonical shapes turn a fuzzy relation into small graphs and a fast answer.

## Why It Works

1. A nice word splits at each place where the prefix holds equal counts of a and b. The parser stores each nest as a child list.
2. Two trees share a canonical shape exactly when their sorted child shape lists match. That id check prunes most comparisons.
3. A split is separable when child kinds form blocks that merge inward. A stack in `isSeparablePermutation` decides this in linear time.
4. Prefix hashes compare candidate cuts in constant time. The dynamic program then visits only reachable span states.
5. The answer is a maximum independent set, because chosen words must have no similarity edge between them. Greedy coloring bounds the search.

Five terms carry the proof.

| Term | Meaning |
| --- | --- |
| exact id | tree shape with child order kept |
| canonical id | tree shape after sorting children |
| separable permutation | child order formed by nested blocks |
| universal shape | every word of that shape is similar |
| independent set | words with no similarity edge |

Together they reduce similarity to cheap id checks and a small graph search.

A script check of the sample gives 3 words and answer 2. That means one similar pair and one word outside it.
The program picks the outsider plus one member of the pair. The reported diversity is 2.

## Code

**Bulk input scanner.**
```nim
proc readInputStream() =
  var chunk = newString(flushBlockBytes)
  var totalBytes = 0
  while true:
    let bytesRead = stdin.readBuffer(addr chunk[0], flushBlockBytes)
    if bytesRead <= 0:
      break
    let previousLen = totalBytes
    totalBytes += bytesRead
    if inputData.len < totalBytes:
      let nextCapacity = max(totalBytes, inputData.len * 2)
      inputData.setLen(nextCapacity)
    copyMem(addr inputData[previousLen], addr chunk[0], bytesRead)
  inputData.setLen(totalBytes)

var scanPos = 0

proc nextInt(): int {.inline.} =
  let dataLen = inputData.len
  while scanPos < dataLen and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  var value = 0
  while scanPos < dataLen and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    inc scanPos
  return value
```

The scanner reads the whole stream into one buffer and walks it by index. `nextInt` skips non-digits and folds digits into a value. One read avoids a syscall per line.

**Balanced word parser.**
```nim
proc parseWordToExactId(startPos, stopPos: int): int32 =
  var depth = 0
  var stackTop = 0
  parseFrameStart[0] = 0
  for pos in startPos..<stopPos:
    if inputData[pos] == 'a':
      inc depth
      parseFrameStart[depth] = stackTop
    else:
      let frameBase = parseFrameStart[depth]
      let childCount = stackTop - frameBase
      let nodeId = internExact(parseChildStack, frameBase, childCount)
      stackTop = frameBase
      dec depth
      parseChildStack[stackTop] = nodeId
      inc stackTop
  return internExact(parseChildStack, 0, stackTop)
```

Each `a` opens a frame and each `b` closes one. Closing a frame interns the children gathered since its start. The parser turns ten letters into a compact tree id.

**Nesting order test.**
```nim
proc isSeparablePermutation(perm: openArray[int], length: int): bool {.inline.} =
  var stackLow: array[maxComponents, int]
  var stackHigh: array[maxComponents, int]
  var stackTop = 0
  for i in 0..<length:
    var rangeLow = perm[i]
    var rangeHigh = rangeLow
    while stackTop > 0:
      if stackHigh[stackTop - 1] + 1 == rangeLow:
        rangeLow = stackLow[stackTop - 1]
        dec stackTop
      elif rangeHigh + 1 == stackLow[stackTop - 1]:
        rangeHigh = stackHigh[stackTop - 1]
        dec stackTop
      else:
        break
    stackLow[stackTop] = rangeLow
    stackHigh[stackTop] = rangeHigh
    inc stackTop
  return stackTop == 1
```

The stack merges adjacent kind ranges until one range remains. A separable order of children means a valid series of nested splits. The test costs linear time in the child count.

**Universal similarity dynamic program.**
```nim
proc dpUniversal(leftStart, rightStart, spanLen: int): bool =
  if spanLen <= 3 or leftStart + spanLen <= int(dpLeftPtr.easyEnd[leftStart]):
    return true
  let statePos = spanLen * dpStride + leftStart * dpRowLen + rightStart
  if dpStamp[statePos] == dpCurStamp:
    return dpValue[statePos] == 1

  var matched = false
  let leftFirst = dpLeftPtr.symbols[leftStart]
  let leftLast = dpLeftPtr.symbols[leftStart + spanLen - 1]
  let rightFirst = dpRightPtr.symbols[rightStart]
  let rightLast = dpRightPtr.symbols[rightStart + spanLen - 1]
  if leftFirst == rightFirst and dpUniversal(leftStart + 1, rightStart + 1, spanLen - 1):
    matched = true
  elif leftFirst == rightLast and dpUniversal(leftStart + 1, rightStart, spanLen - 1):
    matched = true
  elif leftLast == rightLast and dpUniversal(leftStart, rightStart, spanLen - 1):
    matched = true
  elif leftLast == rightFirst and dpUniversal(leftStart, rightStart + 1, spanLen - 1):
    matched = true
  else:
    let baseLeftA = dpLeftPtr.prefixPrimary[leftStart]
    let baseLeftB = dpLeftPtr.prefixSecondary[leftStart]
    let baseRightA = dpRightPtr.prefixPrimary[rightStart]
    let baseRightB = dpRightPtr.prefixSecondary[rightStart]
    let endRightA = dpRightPtr.prefixPrimary[rightStart + spanLen]
    let endRightB = dpRightPtr.prefixSecondary[rightStart + spanLen]
    let headRun = min(int(dpLeftPtr.runRight[leftStart]), spanLen)
    let tailRun = min(int(dpLeftPtr.runLeft[leftStart + spanLen - 1]), spanLen)
    var splitLow = max(2, headRun + 1)
    var splitHigh = min(spanLen - 2, spanLen - tailRun - 1)
    while splitLow <= splitHigh:
      let cutLeft = splitLow
      let deltaA = dpLeftPtr.prefixPrimary[leftStart + cutLeft] - baseLeftA
      let deltaB = dpLeftPtr.prefixSecondary[leftStart + cutLeft] - baseLeftB
      if deltaA == dpRightPtr.prefixPrimary[rightStart + cutLeft] - baseRightA and
         deltaB == dpRightPtr.prefixSecondary[rightStart + cutLeft] - baseRightB:
        if dpUniversal(leftStart, rightStart, cutLeft) and
           dpUniversal(leftStart + cutLeft, rightStart + cutLeft, spanLen - cutLeft):
          matched = true
          break
      if deltaA == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutLeft] and
         deltaB == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutLeft]:
        if dpUniversal(leftStart, rightStart + spanLen - cutLeft, cutLeft) and
           dpUniversal(leftStart + cutLeft, rightStart, spanLen - cutLeft):
          matched = true
          break
      if splitHigh != splitLow:
        let cutRight = splitHigh
        let deltaA2 = dpLeftPtr.prefixPrimary[leftStart + cutRight] - baseLeftA
        let deltaB2 = dpLeftPtr.prefixSecondary[leftStart + cutRight] - baseLeftB
        if deltaA2 == dpRightPtr.prefixPrimary[rightStart + cutRight] - baseRightA and
           deltaB2 == dpRightPtr.prefixSecondary[rightStart + cutRight] - baseRightB:
          if dpUniversal(leftStart, rightStart, cutRight) and
             dpUniversal(leftStart + cutRight, rightStart + cutRight, spanLen - cutRight):
            matched = true
            break
        if deltaA2 == endRightA - dpRightPtr.prefixPrimary[rightStart + spanLen - cutRight] and
           deltaB2 == endRightB - dpRightPtr.prefixSecondary[rightStart + spanLen - cutRight]:
          if dpUniversal(leftStart, rightStart + spanLen - cutRight, cutRight) and
             dpUniversal(leftStart + cutRight, rightStart, spanLen - cutRight):
            matched = true
            break
      inc splitLow
      dec splitHigh

  dpStamp[statePos] = dpCurStamp
  dpValue[statePos] = if matched: 1'i8 else: 0'i8
  return matched
```

The routine tries matching ends first, then candidate split cuts. Prefix hashes reject wrong cuts before any recursion. A stamp array memoizes each span state across calls.

**Clique expansion.**
```nim
proc expandClique(depth: int) =
  var branchCount = 0
  colorAndRenumber(depth, candStack[depth], branchCount)
  if branchCount == 0: return
  var currentPool = candStack[depth]
  for i in countdown(branchCount - 1, 0):
    if depth + int(colorStack[depth][i]) <= bestCliqueSize:
      return
    let vertex = int(orderStack[depth][i])
    var hasNext = false
    for wordIdx in 0..<cliqueWordCount:
      let nextWord = currentPool[wordIdx] and cliqueAdj[vertex][wordIdx]
      candStack[depth + 1][wordIdx] = nextWord
      if nextWord != 0'u64: hasNext = true
    if hasNext:
      expandClique(depth + 1)
    elif depth + 1 > bestCliqueSize:
      bestCliqueSize = depth + 1
    currentPool[vertex shr 6] = currentPool[vertex shr 6] and not (1'u64 shl uint(vertex and 63))
```

Bitsets hold the candidate vertices for each depth. Greedy coloring orders candidates and prunes branches past the best clique. The routine feeds the maximum independent set search.

**Case driver.**
```nim
let caseCount = nextInt()
for _ in 0..<caseCount:
  let wordCount = nextInt()
  resetCaseTrees()
  resetSimCache()
  var groups = initTable[int32, seq[int32]]()
  var seenExact = initTable[int32, bool]()
  for _ in 0..<wordCount:
    var startPos, stopPos: int
    nextWordSpan(startPos, stopPos)
    let exactId = parseWordToExactId(startPos, stopPos)
    if not seenExact.hasKey(exactId):
      seenExact[exactId] = true
      let canonId = canonOfExact[exactId]
      if groups.hasKey(canonId):
        groups[canonId].add(exactId)
      else:
        groups[canonId] = @[exactId]

  var diversity = 0
  for canonId, members in groups:
    if members.len <= 1 or canonUniversal[canonId]:
      inc diversity
    else:
      diversity += solveGroup(members)
  appendInt(diversity)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
  outputBuffer.setLen(0)
```

The driver reads each case and resets per-case tables. A table groups words by canonical id, then each group is solved. The final buffer flushes once at the end.


## Complexity

Costs split into parsing, similarity checks, and graph search.

| Phase | Time | Space |
| --- | --- | --- |
| parse and intern | linear in total letters | one record per interned tree |
| similarity checks | bounded by child pairs per group | one stamp per span state |
| independent set | worst case exponential per group | bitsets over group members |

Parsing stays linear, while the search depends on group size rather than word count.

Big O summary uses total letters L, interned states S, and largest group size G.

| Measure | Big O |
| --- | --- |
| time | O(L + S + search(G)) |
| space | O(S + G) |

The shape grouping keeps the hardest case inside the judge limit.
