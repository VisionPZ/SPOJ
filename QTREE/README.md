# QTREE — Query on a tree (SPOJ)

<https://www.spoj.com/problems/QTREE/>

## Problem

A tree has numbered edges; commands change a cost or ask for the largest cost on the path between two nodes. The program answers every question in command order.

Input starts with the test count. Each test gives the node count, then `N - 1` lines with two endpoints and one cost, then commands ending with `DONE`. A blank line separates tests. Output holds one integer per `QUERY` command, on its own line.

The statement bounds are:

| Item | Bound |
|---|---|
| test cases `t` | at most 20 |
| nodes `N` | at most 10000 |
| edge cost `c` | at most 1000000 |
| edge count | `N - 1` per test |
| judge limit | 1000 ms, 1536 MB |
| language | C++ (g++ 4.3.2) |

The node count drives the build cost, and the command count drives the query cost.

The sample input:

```
1

3
1 2 1
2 3 2
QUERY 1 2
CHANGE 1 3
QUERY 1 2
DONE
```

The sample output:

```
1
3
```

## Idea

Cut the tree into long strands so every path becomes a few straight runs. Think of folding a road map into strips: you follow one strip at a time and switch strips only a few times.

Heavy-light decomposition names this trick. One depth-first pass picks the child with the largest subtree at each node. Strands that follow those heavy children are chains, and any root-to-node path crosses at most log N chains. Nodes of one chain sit in consecutive slots of one array, and a max tree over those slots answers interval questions.

A `QUERY` reads at most log N intervals, each in log N steps. A `CHANGE` writes one slot and walks log N levels up the max tree. Walking the path node by node costs O(N) per question, so a long chain makes the naive way slow.

One slot array plus a max tree replaces every path walk.

## Why It Works

Four facts carry the proof.

1. A node keeps one heavy child, the child with the largest subtree. Each move to a light child at least halves the subtree size, so a root path crosses at most log N light edges.
2. Nodes on one chain receive consecutive positions. A chain piece is therefore one interval in the slot array.
3. Each slot stores the cost of the edge from that node to its parent. The root slot stores zero, so a query inside one chain skips the common ancestor's slot.
4. A max tree returns the largest value in an interval in log N steps. A point change stops as soon as its parent value stops moving.

The arrays that make this work:

| Term | Meaning |
|---|---|
| `subtreeSize` | node count below a node, used to pick `heavyChild` |
| `chainHead` | first node of the strand that contains a node |
| `chainPosition` | slot index of a node, consecutive along a strand |
| `edgeCostAtNode` | edge cost stored at the deeper end of an edge |
| `deeperNodeOfEdge` | node where a numbered edge is stored |
| `segmentTree` | max tree over the slot array |

These arrays turn a tree path into a handful of interval maximum queries.

A script-traced example on the statement sample:

```
edges: 1-2 cost 1, 2-3 cost 2
depths: 1=0 2=1 3=2
chain heads: 1=1 2=1 3=1
positions: 1=0 2=1 3=2
cost at node: 1=0 2=1 3=2
segment leaves: [0, 1, 2]
QUERY 1 2: same head, read slots 1..1 -> 1
CHANGE 1 3: edge 1 ends at node 2, slot 1 becomes 3
segment leaves: [0, 3, 2]
QUERY 1 2: same head, read slots 1..1 -> 3
```

The trace gives the same two answers as the sample output.

## Code

**Sizes and storage.** Fixed arrays hold every tree of the legal size.

```cpp
#include <cstdio>
#include <cstdlib>
#include <cstring>

const int firstDigitValue = 48;
const int flushBlockBytes = 1 << 17;
const int maxNodeCount = 10000;
const int maxEdgeCount = 10000;
const int maxAdjacencyEntries = 2 * maxEdgeCount;
const int segmentBase = 16384;
const int segmentCellCount = 2 * segmentBase;

int parentNode[maxNodeCount + 1];
int nodeDepth[maxNodeCount + 1];
int subtreeSize[maxNodeCount + 1];
int heavyChild[maxNodeCount + 1];
int chainHead[maxNodeCount + 1];
int chainPosition[maxNodeCount + 1];
int nodeAtPosition[maxNodeCount + 1];
int edgeCostAtNode[maxNodeCount + 1];
int deeperNodeOfEdge[maxEdgeCount + 1];
int edgeWeight[maxEdgeCount + 1];
int adjacencyHead[maxNodeCount + 1];
int adjacencyTo[maxAdjacencyEntries + 2];
int adjacencyNext[maxAdjacencyEntries + 2];
int adjacencyEdgeId[maxAdjacencyEntries + 2];
int segmentTree[segmentCellCount + 1];
int adjacencyCount = 0;
int nextPosition = 0;

char* inputData = NULL;
int inputLength = 0;
int scanPos = 0;
char outputBuffer[flushBlockBytes + 16];
int outputLength = 0;
```

The segment base is 16384, the first power of two above 10000. Leaves start there, so an interval becomes two array indexes. The arrays are shared by all test cases.

**Token readers.** Both commands and numbers come from one buffered byte array.

```cpp
int nextInt() {
  while (scanPos < inputLength && inputData[scanPos] <= ' ') scanPos++;
  int value = 0;
  while (scanPos < inputLength && inputData[scanPos] >= '0' && inputData[scanPos] <= '9') {
    value = value * 10 + (int)inputData[scanPos] - firstDigitValue;
    scanPos++;
  }
  return value;
}

int nextWordStart() {
  while (scanPos < inputLength && inputData[scanPos] <= ' ') scanPos++;
  int wordStart = scanPos;
  while (scanPos < inputLength && inputData[scanPos] > ' ') scanPos++;
  return wordStart;
}
```

The scan position is a global, so it survives across calls. `nextWordStart` skips the blank line between tests along with all other whitespace, and the caller compares the word by length and bytes. The digit scan builds values without creating token objects.

**Chain building.** Two depth-first walks assign parents, then chain heads.

```cpp
void measureSubtree(int nodeIndex, int parentIndex) {
  parentNode[nodeIndex] = parentIndex;
  subtreeSize[nodeIndex] = 1;
  heavyChild[nodeIndex] = 0;
  int edgeCursor = adjacencyHead[nodeIndex];
  while (edgeCursor != 0) {
    int neighborNode = adjacencyTo[edgeCursor];
    if (neighborNode != parentIndex) {
      int weightId = adjacencyEdgeId[edgeCursor];
      nodeDepth[neighborNode] = nodeDepth[nodeIndex] + 1;
      edgeCostAtNode[neighborNode] = edgeWeight[weightId];
      deeperNodeOfEdge[weightId] = neighborNode;
      measureSubtree(neighborNode, nodeIndex);
      subtreeSize[nodeIndex] += subtreeSize[neighborNode];
      if (heavyChild[nodeIndex] == 0 || subtreeSize[neighborNode] > subtreeSize[heavyChild[nodeIndex]])
        heavyChild[nodeIndex] = neighborNode;
    }
    edgeCursor = adjacencyNext[edgeCursor];
  }
}

void decomposeChain(int nodeIndex, int headNode) {
  chainHead[nodeIndex] = headNode;
  chainPosition[nodeIndex] = nextPosition;
  nodeAtPosition[nextPosition] = nodeIndex;
  nextPosition++;
  if (heavyChild[nodeIndex] != 0)
    decomposeChain(heavyChild[nodeIndex], headNode);
  int edgeCursor = adjacencyHead[nodeIndex];
  while (edgeCursor != 0) {
    int neighborNode = adjacencyTo[edgeCursor];
    if (neighborNode != parentNode[nodeIndex] && neighborNode != heavyChild[nodeIndex])
      decomposeChain(neighborNode, neighborNode);
    edgeCursor = adjacencyNext[edgeCursor];
  }
}
```

The first walk visits N nodes and fills the edge cost at each deeper endpoint. The second walk visits heavy children first, so one chain occupies consecutive slots. Each walk costs O(N).

**Max tree.** Leaves hold slot costs, and internal cells hold maxima.

```cpp
void buildSegmentTree(int nodeCount) {
  for (int cellIndex = segmentBase; cellIndex <= segmentCellCount; cellIndex++)
    segmentTree[cellIndex] = 0;
  for (int nodeIndex = 1; nodeIndex <= nodeCount; nodeIndex++)
    segmentTree[segmentBase + chainPosition[nodeIndex]] = edgeCostAtNode[nodeIndex];
  int cellIndex = segmentBase - 1;
  while (cellIndex >= 1) {
    int leftValue = segmentTree[2 * cellIndex];
    int rightValue = segmentTree[2 * cellIndex + 1];
    segmentTree[cellIndex] = leftValue > rightValue ? leftValue : rightValue;
    cellIndex--;
  }
}

void updateSegment(int positionValue, int weightValue) {
  int cellIndex = segmentBase + positionValue;
  segmentTree[cellIndex] = weightValue;
  cellIndex = cellIndex / 2;
  while (cellIndex >= 1) {
    int leftValue = segmentTree[2 * cellIndex];
    int rightValue = segmentTree[2 * cellIndex + 1];
    int mergedValue = leftValue > rightValue ? leftValue : rightValue;
    if (segmentTree[cellIndex] == mergedValue) break;
    segmentTree[cellIndex] = mergedValue;
    cellIndex = cellIndex / 2;
  }
}

int querySegment(int leftPosition, int rightPosition) {
  int leftCell = segmentBase + leftPosition;
  int rightCell = segmentBase + rightPosition;
  int result = 0;
  while (leftCell <= rightCell) {
    if ((leftCell & 1) == 1) {
      if (segmentTree[leftCell] > result) result = segmentTree[leftCell];
      leftCell++;
    }
    if ((rightCell & 1) == 0) {
      if (segmentTree[rightCell] > result) result = segmentTree[rightCell];
      rightCell--;
    }
    leftCell = leftCell / 2;
    rightCell = rightCell / 2;
  }
  return result;
}
```

Clearing starts at `segmentBase`, so past slot values cannot leak into the next test. `updateSegment` stops early once a parent keeps its value. `querySegment` walks two indexes toward each other and reads O(log N) cells.

**Path maximum.** The query climbs chains until both ends share a head.

```cpp
int queryPath(int firstNode, int secondNode) {
  int nodeA = firstNode;
  int nodeB = secondNode;
  int result = 0;
  while (chainHead[nodeA] != chainHead[nodeB]) {
    if (nodeDepth[chainHead[nodeA]] < nodeDepth[chainHead[nodeB]]) {
      int swapNode = nodeA;
      nodeA = nodeB;
      nodeB = swapNode;
    }
    int headPosition = chainPosition[chainHead[nodeA]];
    int endPosition = chainPosition[nodeA];
    int chainBest = querySegment(headPosition, endPosition);
    if (chainBest > result) result = chainBest;
    nodeA = parentNode[chainHead[nodeA]];
  }
  if (nodeDepth[nodeA] > nodeDepth[nodeB]) {
    int swapNode = nodeA;
    nodeA = nodeB;
    nodeB = swapNode;
  }
  int chainBest = querySegment(chainPosition[nodeA] + 1, chainPosition[nodeB]);
  if (chainBest > result) result = chainBest;
  return result;
}
```

The deeper head is always consumed first. The final interval starts one slot past the shared ancestor, because that slot belongs to the edge above the path.

**Driver.** One input read, one output buffer, block writes.

```cpp
void readAllInput() {
  int capacity = 1 << 22;
  inputData = (char*)malloc((size_t)capacity);
  int length = 0;
  while (true) {
    int got = (int)fread(inputData + length, 1, (size_t)(capacity - length), stdin);
    if (got == 0) break;
    length += got;
    if (length == capacity) {
      capacity *= 2;
      inputData = (char*)realloc(inputData, (size_t)capacity);
    }
  }
  inputLength = length;
}

void flushOutput() {
  if (outputLength > 0) {
    fwrite(outputBuffer, 1, (size_t)outputLength, stdout);
    outputLength = 0;
  }
}

void appendAnswer(int value) {
  char digits[16];
  int digitCount = 0;
  if (value == 0) {
    digits[digitCount++] = '0';
  } else {
    while (value > 0) {
      digits[digitCount++] = (char)(firstDigitValue + value % 10);
      value /= 10;
    }
  }
  while (digitCount > 0) outputBuffer[outputLength++] = digits[--digitCount];
  outputBuffer[outputLength++] = '\n';
  if (outputLength >= flushBlockBytes) flushOutput();
}

int main() {
  readAllInput();
  int caseCount = nextInt();
  for (int caseIndex = 0; caseIndex < caseCount; caseIndex++) {
    int nodeCount = nextInt();
    adjacencyCount = 0;
    for (int nodeIndex = 1; nodeIndex <= nodeCount; nodeIndex++) {
      adjacencyHead[nodeIndex] = 0;
      heavyChild[nodeIndex] = 0;
    }
    for (int weightId = 1; weightId <= nodeCount - 1; weightId++) {
      edgeWeight[weightId] = 0;
      deeperNodeOfEdge[weightId] = 0;
    }
    nodeDepth[1] = 0;
    for (int weightId = 1; weightId <= nodeCount - 1; weightId++) {
      int fromNode = nextInt();
      int toNode = nextInt();
      int costValue = nextInt();
      edgeWeight[weightId] = costValue;
      appendAdjacency(fromNode, toNode, weightId);
      appendAdjacency(toNode, fromNode, weightId);
    }
    measureSubtree(1, 0);
    nextPosition = 0;
    decomposeChain(1, 1);
    buildSegmentTree(nodeCount);
    while (scanPos < inputLength) {
      int wordStart = nextWordStart();
      int wordLength = scanPos - wordStart;
      if (wordLength == 0) break;
      if (wordLength == 4 && memcmp(inputData + wordStart, "DONE", 4) == 0) break;
      if (wordLength == 5 && memcmp(inputData + wordStart, "QUERY", 5) == 0) {
        int firstNode = nextInt();
        int secondNode = nextInt();
        appendAnswer(queryPath(firstNode, secondNode));
      } else if (wordLength == 6 && memcmp(inputData + wordStart, "CHANGE", 6) == 0) {
        int weightId = nextInt();
        int newWeight = nextInt();
        edgeWeight[weightId] = newWeight;
        updateSegment(chainPosition[deeperNodeOfEdge[weightId]], newWeight);
      }
    }
  }
  flushOutput();
  return 0;
}
```

The command loop reads words, so the blank line and the word `DONE` need no special case. `CHANGE` finds the deeper node of an edge before writing its slot. The buffer keeps 16 spare bytes so a number may cross the block edge before the flush check, and the final write covers the remaining bytes of a small test.

## Complexity

Costs split into one build per test and one short walk per command.

| Phase | Time | Space |
|---|---|---|
| input read | one pass over the input bytes | input bytes |
| tree build | two walks over N nodes | arrays of N slots |
| one `QUERY` | O(log² N) interval reads | no extra storage |
| one `CHANGE` | O(log N) writes up the max tree | no extra storage |
| output | one write per block | block buffer |

The build runs once per test, while each command pays a logarithmic cost.

The overall bounds follow from the chain count and the max tree height.

| Measure | Big O |
|---|---|
| time per test | O(N + Q log² N) |
| space | O(N) |

A path walk costs O(N) per query, so a 10000-node chain needs thousands of steps where the max tree needs dozens. The max tree keeps both commands fast on a long chain.
