#include <stdio.h>
#include <stdlib.h>

#define INCAP 1048576
#define OUTCAP 131072

typedef struct {
    int leftChild;
    int rightChild;
    int subtreeSize;
    unsigned nodePriority;
    char nodeChar;
} Node;

static Node *nodes;
static int *spineNodes;
static int *spineWalk;

static char inbuf[INCAP];
static char outbuf[OUTCAP];
static int inlen = 0, inpos = 0, outlen = 0;

static int fill(void) {
    if (inpos >= inlen) {
        inlen = (int)fread(inbuf, 1, INCAP, stdin);
        inpos = 0;
        if (inlen <= 0) return 0;
    }
    return 1;
}

static int nextint(void) {
    int c;
    do { if (!fill()) return 0; c = inbuf[inpos++]; } while (c < '0' || c > '9');
    int v = 0;
    while (c >= '0' && c <= '9') { v = v * 10 + (c - '0'); if (!fill()) break; c = inbuf[inpos++]; }
    return v;
}

static void putch(char c) {
    if (outlen >= OUTCAP) { fwrite(outbuf, 1, OUTCAP, stdout); outlen = 0; }
    outbuf[outlen++] = c;
}

static unsigned long long randomState = 88172645463325252ULL;

static int nextRandomValue(void) {
    randomState ^= randomState << 13;
    randomState ^= randomState >> 7;
    randomState ^= randomState << 17;
    return (int)(randomState & ((1ULL << 62) - 1));
}

static int mergeTrees(int leftTree, int rightTree) {
    if (leftTree == 0) return rightTree;
    if (rightTree == 0) return leftTree;
    int spineLen = 0;
    int leftWalk = leftTree, rightWalk = rightTree;
    while (leftWalk != 0 && rightWalk != 0) {
        if (nodes[leftWalk].nodePriority > nodes[rightWalk].nodePriority) {
            spineNodes[spineLen] = leftWalk;
            spineWalk[spineLen] = 1;
            spineLen++;
            leftWalk = nodes[leftWalk].rightChild;
        } else {
            spineNodes[spineLen] = rightWalk;
            spineWalk[spineLen] = 0;
            spineLen++;
            rightWalk = nodes[rightWalk].leftChild;
        }
    }
    int mergedTree = leftWalk;
    if (rightWalk != 0) mergedTree = rightWalk;
    for (int walkIndex = spineLen - 1; walkIndex >= 0; walkIndex--) {
        int spineNode = spineNodes[walkIndex];
        if (spineWalk[walkIndex] == 1) nodes[spineNode].rightChild = mergedTree;
        else nodes[spineNode].leftChild = mergedTree;
        nodes[spineNode].subtreeSize = nodes[nodes[spineNode].leftChild].subtreeSize +
            nodes[nodes[spineNode].rightChild].subtreeSize + 1;
        mergedTree = spineNode;
    }
    return mergedTree;
}

static void splitTree(int nodeIndex, int takeCount, int *leftOut, int *rightOut) {
    int leftHead = 0, leftTail = 0, rightHead = 0, rightTail = 0;
    int leftLen = 0, rightLen = 0;
    int walkNode = nodeIndex, remaining = takeCount;
    while (walkNode != 0) {
        int leftSize = nodes[nodes[walkNode].leftChild].subtreeSize;
        if (remaining <= leftSize) {
            spineWalk[rightLen] = walkNode;
            rightLen++;
            if (rightTail == 0) rightHead = walkNode;
            else nodes[rightTail].leftChild = walkNode;
            rightTail = walkNode;
            walkNode = nodes[walkNode].leftChild;
        } else {
            remaining -= leftSize + 1;
            spineNodes[leftLen] = walkNode;
            leftLen++;
            if (leftTail == 0) leftHead = walkNode;
            else nodes[leftTail].rightChild = walkNode;
            leftTail = walkNode;
            walkNode = nodes[walkNode].rightChild;
        }
    }
    if (leftTail != 0) nodes[leftTail].rightChild = 0;
    if (rightTail != 0) nodes[rightTail].leftChild = 0;
    for (int walkIndex = leftLen - 1; walkIndex >= 0; walkIndex--) {
        int spineNode = spineNodes[walkIndex];
        nodes[spineNode].subtreeSize = nodes[nodes[spineNode].leftChild].subtreeSize +
            nodes[nodes[spineNode].rightChild].subtreeSize + 1;
    }
    for (int walkIndex = rightLen - 1; walkIndex >= 0; walkIndex--) {
        int spineNode = spineWalk[walkIndex];
        nodes[spineNode].subtreeSize = nodes[nodes[spineNode].leftChild].subtreeSize +
            nodes[nodes[spineNode].rightChild].subtreeSize + 1;
    }
    *leftOut = leftHead;
    *rightOut = rightHead;
}

int main(void) {
    int n = nextint();
    int m = nextint();
    nodes = (Node *)calloc((size_t)n + 2, sizeof(Node));
    spineNodes = (int *)malloc((size_t)(n + 2) * sizeof(int));
    spineWalk = (int *)malloc((size_t)(n + 2) * sizeof(int));

    while (fill() && inbuf[inpos] <= ' ') inpos++;

    int tokenLength = 0;
    while (tokenLength < n && fill() && inbuf[inpos] > ' ') {
        nodes[tokenLength + 1].nodePriority = (unsigned)nextRandomValue();
        nodes[tokenLength + 1].nodeChar = inbuf[inpos];
        inpos++;
        tokenLength++;
    }

    int *buildStack = (int *)malloc((size_t)(tokenLength + 2) * sizeof(int));
    int stackTop = 0;
    int rootTree = 0;
    for (int nodeIndex = 1; nodeIndex <= tokenLength; nodeIndex++) {
        int carriedNode = 0;
        while (stackTop > 0 && nodes[buildStack[stackTop - 1]].nodePriority <
               nodes[nodeIndex].nodePriority) {
            carriedNode = buildStack[--stackTop];
        }
        if (stackTop > 0) nodes[buildStack[stackTop - 1]].rightChild = nodeIndex;
        else rootTree = nodeIndex;
        nodes[nodeIndex].leftChild = carriedNode;
        buildStack[stackTop++] = nodeIndex;
    }
    free(buildStack);

    int *orderStack = (int *)malloc((size_t)(tokenLength + 2) * sizeof(int));
    int *visitOrder = (int *)malloc((size_t)(tokenLength + 2) * sizeof(int));
    stackTop = 0;
    int orderLength = 0;
    if (rootTree != 0) orderStack[stackTop++] = rootTree;
    while (stackTop > 0) {
        int walkNode = orderStack[--stackTop];
        visitOrder[orderLength++] = walkNode;
        if (nodes[walkNode].leftChild != 0) orderStack[stackTop++] = nodes[walkNode].leftChild;
        if (nodes[walkNode].rightChild != 0) orderStack[stackTop++] = nodes[walkNode].rightChild;
    }
    for (int cursor = orderLength - 1; cursor >= 0; cursor--) {
        int walkNode = visitOrder[cursor];
        nodes[walkNode].subtreeSize = nodes[nodes[walkNode].leftChild].subtreeSize +
            nodes[nodes[walkNode].rightChild].subtreeSize + 1;
    }
    free(orderStack);
    free(visitOrder);

    for (int queryIndex = 0; queryIndex < m; queryIndex++) {
        int moveLeft = nextint();
        int moveRight = nextint();
        int firstLeft = 0, firstRight = 0, secondLeft = 0, secondRight = 0;
        splitTree(rootTree, moveLeft - 1, &firstLeft, &firstRight);
        splitTree(firstRight, moveRight - moveLeft + 1, &secondLeft, &secondRight);
        rootTree = mergeTrees(secondLeft, mergeTrees(firstLeft, secondRight));
    }

    int *visitStack = (int *)malloc((size_t)(tokenLength + 2) * sizeof(int));
    int stackLength = 0;
    int walkNode = rootTree;
    while (walkNode != 0 || stackLength > 0) {
        while (walkNode != 0) {
            visitStack[stackLength++] = walkNode;
            walkNode = nodes[walkNode].leftChild;
        }
        walkNode = visitStack[--stackLength];
        putch(nodes[walkNode].nodeChar);
        walkNode = nodes[walkNode].rightChild;
    }
    putch('\n');
    if (outlen > 0) fwrite(outbuf, 1, outlen, stdout);
    return 0;
}
