# MOVES000 — Moves (SPOJ)

<https://www.spoj.com/problems/MOVES000/>

## Problem

A string s of length n and m queries. Each query gives L and R, 1-indexed, and asks to cut the substring s[L..R] and paste it at the front of the string. After all queries, print the final string.

| item | bound |
|---|---|
| length n | n ≤ 250000 |
| queries m | m ≤ 250000 |
| judge limit | 1000 ms, 1536 MB |

Rewriting the string per query costs O(n) each, far too much; a balanced tree makes each query logarithmic. The solution is submitted in C; a Nim port of the same treap passed locally but ran over the 1 s judge limit.

Sample input:

```
10 3
abcdefghij
2 3
3 5
3 7
```

Sample output:

```
ebcfgadhij
```

## Idea

A ribbon with pieces repeatedly moved to the front. Cutting and re-gluing a 250000-character ribbon 250000 times is hopeless if every move drags the whole ribbon.

An implicit treap stores the string as a randomized balanced binary tree, one node per character, ordered by position. Subtree sizes turn positions into tree paths. Each query is two splits and two merges: split off the part before L, split off s[L..R], then merge the pieces in the new order B + A + C. Random priorities keep the tree shallow, so every operation costs O(log n) expected.

The whole tree is built in one O(n) stack pass (a Cartesian tree over the positions with the random priorities), not by n separate merges. Split and merge walks are iterative, using two spine arrays, so no query can blow the call stack. Each node packs its children, size, priority and character in one 20-byte record, so a tree walk touches one cache line instead of five parallel arrays.

Takeaway: cut and paste in O(log n) with a tree that stores sizes.

## Why It Works

1. The in-order walk of the treap lists exactly the current string.
2. `splitTree(t, k)` returns the first k characters and the rest, by walking down and comparing k with the left subtree size.
3. Two splits carve the string into A = s[1..L-1], B = s[L..R], C = s[R+1..n].
4. Merging B, then A, then C produces B + A + C, which is the requested move.
5. Priorities are fixed random numbers, so merge keeps heap order and the tree stays balanced in expectation.
6. The stack build makes the same heap-ordered tree as n merges: the stack holds the right spine, and popping smaller priorities grafts the last subtree as the new node's left child.
7. Subtree sizes are recomputed along the visited spines after every split and merge, so later index lookups stay correct.
8. Node 0 is a null sentinel with size 0, which makes empty subtrees free to handle.

For the sample, `abcdefghij` becomes `bcadefghij` after (2,3), then `adebcfghij` after (3,5), then `ebcfgadhij` after (3,7).

The iterative spine walk rebuilds the same links a recursive merge would, node by node, from the bottom of the walk back up.

## Code

**Input and output plumbing.** A 1 MB read buffer, a hand integer scanner, and a block-buffered writer.

```c
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
```

The scanner skips any non-digit, so spaces and newlines cost nothing. Every value is positive, so no minus branch is needed.

**Tree storage.** One record per character; node 0 is the null sentinel.

```c
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
```

Xorshift generates the priorities, one per node.

```c
static unsigned long long randomState = 88172645463325252ULL;

static int nextRandomValue(void) {
    randomState ^= randomState << 13;
    randomState ^= randomState >> 7;
    randomState ^= randomState << 17;
    return (int)(randomState & ((1ULL << 62) - 1));
}
```

**Iterative merge.** The two trees are woven by priority, then relinked bottom-up.

```c
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
```

The higher-priority node joins the spine and the walk continues into its inner child. The second loop rewires each spine node to the merged part below it.

**Iterative split.** The first `takeCount` characters go left, the rest right.

```c
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
```

The two chains are grown as the walk descends, then their sizes are fixed on the way back up.

**Reading the string.** The arrays are sized once; the token is read character by character through the refill check, so it works even when it spans buffer boundaries.

```c
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
```

**Building the tree in O(n).** A monotone stack keeps the right spine of the Cartesian tree; smaller priorities get popped and grafted as left children.

```c
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
```

A preorder/stack pass then fills `subtreeSize` bottom-up, so the sizes are right before the first query.

**Queries.** Two splits isolate the piece; two merges paste it in front.

```c
    for (int queryIndex = 0; queryIndex < m; queryIndex++) {
        int moveLeft = nextint();
        int moveRight = nextint();
        int firstLeft = 0, firstRight = 0, secondLeft = 0, secondRight = 0;
        splitTree(rootTree, moveLeft - 1, &firstLeft, &firstRight);
        splitTree(firstRight, moveRight - moveLeft + 1, &secondLeft, &secondRight);
        rootTree = mergeTrees(secondLeft, mergeTrees(firstLeft, secondRight));
    }
```

`firstLeft` holds A and `firstRight` holds BC; the second split gives B and C. The merge order B, A, C is the move-to-front operation.

**Final walk.** An explicit-stack in-order traversal prints the string.

```c
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
```

The stack replaces recursion, so depth never overflows. Characters flush in blocks as they are visited.

## Complexity

Each query runs two splits and two merges on a tree of expected depth O(log n).

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one buffer |
| build | one stack pass, then one size pass | n nodes |
| queries | 4 tree walks each | spine arrays |
| output | one pass over nodes | one block buffer |

| measure | Big O |
|---|---|
| time | O((n + m) log n) expected |
| space | O(n) |

Cutting and rejoining plain strings costs O(n) per query, about 6×10^10 character moves at the limit.

Takeaway: implicit treaps turn string surgery into tree surgery.
