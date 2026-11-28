# UNTITLED — Untitled Problem (SPOJ)

<https://www.spoj.com/problems/UNTITLED/>

## Problem

Two sequences match when they have the same length and the same pairwise order. For each prefix of a text sequence, report the prefix length when some suffix matches one of the given patterns.

Input starts with the test count. Each test gives the number of sequences, then each sequence as a length followed by its integers. The first sequence is the text and the rest are patterns. Print matching prefix lengths in increasing order.

| item | bound |
|---|---|
| test cases | up to 3 |
| text length | up to 400000 |
| total pattern length | up to 100000 |
| integer value | up to 2^31 − 1 |
| repeated value inside a sequence | none |
| judge limit | 1000 ms, 1536 MB |

The total pattern length rules out comparing every suffix with every pattern.

Sample input:

```
2
2
1
1
1
2
3
3
3 1 2
2
4 5
2
10 1
```

Sample output:

```
1
2
3
```

## Idea

Rank each new value by how many earlier values are smaller, like placing a card into a sorted hand; matching hands share the same rank list.

An Aho-Corasick trie stores pattern prefixes by these rank labels. A persistent segment tree answers the rank of a text value inside any suffix window. Failure links move to shorter prefixes with recomputed ranks, and terminal links reveal a match ending at the current position.
Each text position advances one step plus a bounded number of failure jumps. Comparing every suffix against every pattern costs far more.
The trie shares common pattern prefixes, so the total work tracks the total pattern length.

## Why It Works

1. Two sequences of equal length match exactly when their rank lists match.
2. Adding a value to a matched prefix needs only its rank among the existing values.
3. Persistent segment tree versions count smaller values in any text or pattern prefix interval.
4. A failure link points to the longest proper suffix of a rank list that is also a trie prefix.
5. The terminal link of the current state names the matched pattern, if any, ending at this position.

| term | meaning |
|---|---|
| `patternRanks` | rank list for each input pattern |
| `valueRank` | compressed rank of one value |
| `updateVersion` | add one value to a persistent segment tree version |
| `countBelow` | count stored values below a rank in one version |
| `findChild` | trie child with a given rank label |
| `trieTerminalLink` | nearest terminal node on a failure chain |
| `stateNode` | longest matched prefix after the current text value |

The table names the structures that carry rank queries and failure transitions.

Worked example from the second sample test:

```
text [3 1 2] has ranks [0 0 1]
pattern [4 5] has ranks [0 1], pattern [10 1] has ranks [0 0]
prefix 2 suffix ranks [0 0] matches the second pattern
prefix 3 suffix ranks [0 1] matches the first pattern
```

The traced suffixes give output lines 2 and 3.

## Code

**Persistent counting tree.** Each version adds one value so any prefix interval can be queried.

```nim
  proc valueRank(value: int64): int =
    var lowIndex = 0
    var highIndex = valueCount - 1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if uniqueValues[middleIndex] == value:
        return middleIndex
      if uniqueValues[middleIndex] < value:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    return valueCount

  proc updateVersion(previousRoot: int, lowBound: int, highBound: int, rankValue: int): int =
    let newNode = segmentUsed
    segmentUsed += 1
    segmentLeft[newNode] = segmentLeft[previousRoot]
    segmentRight[newNode] = segmentRight[previousRoot]
    segmentCount[newNode] = segmentCount[previousRoot]
    if highBound - lowBound == 1:
      segmentCount[newNode] = segmentCount[previousRoot] + 1
      return newNode
    let middleIndex = (lowBound + highBound) div 2
    if rankValue < middleIndex:
      let childRoot = updateVersion(segmentLeft[previousRoot], lowBound, middleIndex, rankValue)
      segmentLeft[newNode] = childRoot
    else:
      let childRoot = updateVersion(segmentRight[previousRoot], middleIndex, highBound, rankValue)
      segmentRight[newNode] = childRoot
    segmentCount[newNode] = segmentCount[segmentLeft[newNode]] + segmentCount[segmentRight[newNode]]
    return newNode

  proc countBelow(rootIndex: int, rankValue: int): int =
    var currentNode = rootIndex
    var lowBound = 0
    var highBound = treeSize
    var total = 0
    while currentNode != 0 and lowBound < highBound:
      if highBound <= rankValue:
        total = total + segmentCount[currentNode]
        break
      let middleIndex = (lowBound + highBound) div 2
      if rankValue < middleIndex:
        currentNode = segmentLeft[currentNode]
        highBound = middleIndex
      else:
```

Values are compressed once per test.
Each update copies a root-to-leaf path.
The query walks that path with two range counts.

**Trie transitions.** Rank-labeled children and failure links cover shorter matching suffixes.

```nim
  proc findChild(nodeIndex: int, labelValue: int): int =
    let entryList = children[nodeIndex]
    var lowIndex = 0
    var highIndex = entryList.len - 1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if entryList[middleIndex].label == labelValue:
        return entryList[middleIndex].child
      if entryList[middleIndex].label < labelValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    return 0

  proc smallerInSuffix(patternIndex: int, endPosition: int, windowLength: int, value: int64): int =
    if windowLength <= 0:
      return 0
    let offset = patternOffsets[patternIndex]
    let upperRoot = patternRoots[offset + endPosition - 1]
    let lowerRoot = patternRoots[offset + endPosition - windowLength - 1]
    return countBelow(upperRoot, valueRank(value)) - countBelow(lowerRoot, valueRank(value))

  var queue = newSeq[int]()
  for entry in children[0]:
    trieFail[entry.child] = 0
    queue.add entry.child
  var queueHead = 0
  while queueHead < queue.len:
    let parentNode = queue[queueHead]
    queueHead += 1
    if trieTerminal[parentNode]:
      trieTerminalLink[parentNode] = parentNode
    else:
      trieTerminalLink[parentNode] = trieTerminalLink[trieFail[parentNode]]
    for entry in children[parentNode]:
      let childNode = entry.child
      let patternIndex = triePattern[childNode]
      let endPosition = triePosition[childNode]
      let value = patternValues[patternIndex][endPosition - 1]
      var ancestorNode = trieFail[parentNode]
      var assigned = 0
      if ancestorNode != 0:
        var rankValue = smallerInSuffix(patternIndex, endPosition, trieDepth[ancestorNode], value)
        while true:
          let candidate = findChild(ancestorNode, rankValue)
          if candidate != 0:
            assigned = candidate
            break
          ancestorNode = trieFail[ancestorNode]
          if ancestorNode == 0:
            break
          rankValue = smallerInSuffix(patternIndex, endPosition, trieDepth[ancestorNode], value)
      if assigned == 0:
        assigned = findChild(0, 0)
      trieFail[childNode] = assigned
      queue.add childNode

```

Children are sorted so lookup is a binary search.
Suffix ranks come from pattern prefix versions.
Breadth-first order gives each node its failure link.

**Text scan.** Each text value advances or falls back through the trie.

```nim
  var stateNode = 0
  for textIndex in 0 .. textValues.len - 1:
    let currentPosition = textIndex + 1
    let currentValue = textValues[textIndex]
    let currentRank = valueRank(currentValue)
    while true:
      if stateNode == 0:
        let candidate = findChild(0, 0)
        if candidate != 0:
          stateNode = candidate
        break
      let windowLength = trieDepth[stateNode]
      let smallerCount = countBelow(textRoots[currentPosition - 1], currentRank) -
                         countBelow(textRoots[currentPosition - windowLength - 1], currentRank)
      let candidate = findChild(stateNode, smallerCount)
      if candidate != 0:
        stateNode = candidate
        break
      stateNode = trieFail[stateNode]
    if trieTerminalLink[stateNode] != -1:
      appendOutput($currentPosition)
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A rank query of the current suffix drives the transition.
Failure jumps repeat with a shorter window.
A terminal link emits the current prefix length.

## Complexity

Costs follow the text length and the total pattern length.

| phase | time | space |
|---|---|---|
| value compression | O(L log L) | O(L) |
| persistent versions | O(L log L) | O(L log L) |
| trie and failure links | O(P log L) | O(P) |
| text scan | O(N log L) | O(1) extra |
| output | one line per match | block buffer |

The persistent versions dominate memory.

| measure | Big O |
|---|---|
| time | O((N + P) log(N + P)) |
| space | O((N + P) log(N + P)) |

Testing every pattern against every suffix costs quadratic time and cannot reach the stated bounds.
Shared trie prefixes and rank queries keep the work near linear in the input size.
