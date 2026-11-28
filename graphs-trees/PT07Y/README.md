# PT07Y — Is it a tree (SPOJ)

<https://www.spoj.com/problems/PT07Y/>

## Problem

Given an unweighted, undirected graph with `N` vertices and `M` edges, decide whether the graph forms a single connected tree.

Input begins with `N` and `M`, followed by `M` pairs `(u, v)`. Output prints `YES` if the graph is a tree, or `NO` otherwise.

Constraints and limits for the task:

| item | bound |
|---|---|
| vertices `N` | `1 <= N <= 10000` |
| edges `M` | `0 <= M <= 20000` |
| judge limit | 500 ms, 1536 MB |

Rejecting `M != N - 1` immediately avoids scanning edges when a graph has too few or too many edges to be a tree.

Sample input and output:

```
3 2
1 2
2 3
```

```
YES
```

Three vertices connected by two acyclic edges `(1, 2)` and `(2, 3)` form a single tree.

## Idea

Merge connected vertices using a disjoint-set union (`parent`), like tying beads together and checking that no tie forms a loop. A graph with `N` vertices and `N - 1` edges is a tree if and only if every merge joins two separate components, leaving `components == 1`.

Union by negative component size and iterative path compression run in near-constant `O(alpha(N))` time per edge without building adjacency lists or recursion stacks. Building explicit edge lists uses extra memory and requires traversal bookkeeping.

Checking `edgeCount != nodeCount - 1` up front resolves non-tree edge counts in `O(1)` time.

## Why It Works

1. Any tree on `nodeCount` vertices contains exact `nodeCount - 1` edges; any other `edgeCount` yields `NO` at once.
2. When `edgeCount == nodeCount - 1`, `components` starts at `nodeCount` and drops by `1` on each edge connecting two distinct components.
3. Self-loops or parallel edges share `rootU == rootV`, leaving `components > 1` after processing all `edgeCount` edges.
4. Reaching `components == 1` proves the graph is connected with `nodeCount - 1` edges, hence acyclic and a tree.

Key identifiers in the program:

| term | meaning |
|---|---|
| `nodeCount` | number of vertices `N` |
| `edgeCount` | number of edges `M` |
| `parent` | DSU array storing parent index or negative component size |
| `components` | count of remaining connected components |
| `findRoot` | iterative root lookup with path compression |

Worked trace on sample `3 2`: `components` starts at `3`, `(1, 2)` merges `{1, 2}` (`components = 2`), and `(2, 3)` merges `{1, 2, 3}` (`components = 1`), giving `YES`.

## Code

**Disjoint-set connectivity check.** `main` skips edge scanning unless `edgeCount == nodeCount - 1`, then counts successful unions.

```nim
  if edgeCount != nodeCount - 1:
    outBuffer.add "NO\n"
    stdout.write outBuffer
    return
  var parent = newSeq[int](nodeCount + 1)
  for idx in 1 .. nodeCount:
    parent[idx] = -1
  var components = nodeCount
  for edgeIdx in 0 ..< edgeCount:
    let nodeU = nextInt(inputData, scanPos)
    let nodeV = nextInt(inputData, scanPos)
    let rootU = findRoot(parent, nodeU)
    let rootV = findRoot(parent, nodeV)
    if rootU != rootV:
      if parent[rootU] > parent[rootV]:
        parent[rootV] += parent[rootU]
        parent[rootU] = rootV
      else:
        parent[rootU] += parent[rootV]
        parent[rootV] = rootU
      components -= 1
```

## Complexity

| metric | cost |
|---|---|
| time | O(N + M * alpha(N)) |
| space | O(N) |

Using iterative union-find keeps memory linear in `N` with almost constant work per edge.
