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

void appendAdjacency(int fromNode, int toNode, int weightId) {
  adjacencyCount++;
  adjacencyTo[adjacencyCount] = toNode;
  adjacencyEdgeId[adjacencyCount] = weightId;
  adjacencyNext[adjacencyCount] = adjacencyHead[fromNode];
  adjacencyHead[fromNode] = adjacencyCount;
}

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
