# PT07Z — Longest path in a tree (SPOJ)

<https://www.spoj.com/problems/PT07Z/>

## Problem

Given an undirected tree on `N` vertices, find the length in edges of the longest simple path between any pair of vertices.

Input begins with `N`, followed by `N - 1` edge pairs `(u, v)`. Output prints a single integer giving the tree diameter.

Constraints and limits for the task:

| item | bound |
|---|---|
| vertices `N` | `1 <= N <= 10000` |
| edges | `N - 1` undirected edges |
| judge limit | 500 ms, 1536 MB |

Running BFS from every vertex would cost `O(N^2)` work and risk exceeding the tight 500 ms limit.

Sample input and output:

```
3
1 2
2 3
```

```
2
```

In a path `1 - 2 - 3`, vertices `1` and `3` are `2` edges apart.

## Idea

Run two breadth-first sweeps (`bfsFarthest`), like finding one corner of a sprawling maze from the entrance and then walking from that corner to the farthest dead end. The first sweep from node `1` finds one endpoint of a longest path, and the second sweep from that endpoint measures the true diameter.

Using flat linked adjacency arrays (`head`, `edgeTo`, `edgeNext`) and iterative BFS avoids recursion stack limits on long paths of up to `10,000` vertices. Testing all `N` starting nodes would do `N / 2` times more work.

Two linear passes solve the tree diameter in `O(N)` time and `O(N)` space.

## Why It Works

1. Any longest path `(a, b)` in a tree is separated from any root `1` by a branch point where one endpoint is strictly or equally farthest from `1`.
2. Therefore every vertex maximizing distance from `1` is guaranteed to be an endpoint of some tree diameter.
3. Running `bfsFarthest` a second time from `firstPass.node` reaches the opposite diameter endpoint at distance `secondPass.distance`.
4. When `nodeCount <= 1`, there are zero edges, so `0` is emitted immediately.

Key identifiers in the program:

| term | meaning |
|---|---|
| `nodeCount` | number of tree vertices `N` |
| `head` | first half-edge index per vertex in flat adjacency storage |
| `edgeTo` | neighbor vertex of each directed half-edge |
| `edgeNext` | next half-edge index in adjacency list |
| `bfsFarthest` | iterative BFS returning farthest node and edge distance |

Worked trace on sample `3` with `(1, 2)` and `(2, 3)`: BFS from `1` finds `3` at distance `2`, then BFS from `3` finds `1` at distance `2`.

## Code

**Two-pass iterative tree diameter.** `main` builds a flat adjacency list and runs `bfsFarthest` twice without recursion.

```nim
  var dist = newSeq[int](nodeCount + 1)
  var queue = newSeq[int](nodeCount + 1)
  let firstPass = bfsFarthest(1, nodeCount, head, edgeTo, edgeNext, dist, queue)
  let secondPass = bfsFarthest(firstPass.node, nodeCount, head, edgeTo, edgeNext, dist, queue)
  outBuffer.add $secondPass.distance
  outBuffer.add '\n'
  stdout.write outBuffer
```

**Flat BFS helper.** `bfsFarthest` sweeps reachable vertices iteratively using pre-allocated `dist` and `queue` buffers.

```nim
  while qHead < qTail:
    let cur = queue[qHead]
    qHead += 1
    let curDist = dist[cur]
    if curDist > bestDist:
      bestDist = curDist
      bestNode = cur
    var edgeIdx = head[cur]
    while edgeIdx != -1:
      let nxt = edgeTo[edgeIdx]
      if dist[nxt] == -1:
        dist[nxt] = curDist + 1
        queue[qTail] = nxt
        qTail += 1
      edgeIdx = edgeNext[edgeIdx]
```

## Complexity

| metric | cost |
|---|---|
| time | O(N) |
| space | O(N) |

Two breadth-first passes visit every vertex and edge twice, using linear time and memory instead of `O(N^2)`.
