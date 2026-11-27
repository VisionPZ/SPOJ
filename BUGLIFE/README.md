# BUGLIFE — A Bug's Life (SPOJ)

<https://www.spoj.com/problems/BUGLIFE/>

## Problem

Test whether all recorded interactions in each scenario can connect only bugs of opposite genders, meaning the interaction graph is bipartite (two-colorable).

Input starts with the scenario count, then each scenario gives the bug count and interaction count followed by bug pairs `(u, v)`. Output prints `Scenario #i:` and `Suspicious bugs found!` if an odd cycle exists, or `No suspicious bugs found!` otherwise.

Constraints and limits for the task:

| item | bound |
|---|---|
| bugs per scenario | `1` to `2000` |
| interactions per scenario | up to `1000000` |
| judge limit | 1000 ms, 1536 MB |

Storing one million undirected edges in adjacency lists consumes tens of megabytes and slows graph setup.

Sample input and output:

```
2
3 3
1 2
2 3
1 3
4 2
1 2
3 4
```

```
Scenario #1:
Suspicious bugs found!
Scenario #2:
No suspicious bugs found!
```

Scenario one forms a triangle (`1 - 2 - 3 - 1`), which cannot be two-colored, while scenario two has disjoint pairs.

## Idea

Track relative gender parity inside a disjoint-set union (`parent`, `parity`), like linking magnets pole-to-pole and flagging any contradiction around a loop. Every edge forces its endpoints to hold opposite parity (`xor 1`), so a conflict happens only when two endpoints already share a component with identical root parity.

Parity union-find checks up to one million edges in `O(M * alpha(N))` time using only two 2005-element arrays (`16 KB`), avoiding adjacency list allocation completely. Storing all edges first for BFS would allocate millions of list entries needlessly.

Skipping union updates once `suspicious` turns true finishes scanning remaining edges quickly within `1000 ms`.

## Why It Works

1. `parity[node]` stores the relative bit (`0` or `1`) between `node` and its DSU `parent[node]`.
2. `findRoot` compresses the path to `rootNode` while accumulating `accPar`, yielding `node`'s parity relative to its root.
3. If `bugU` and `bugV` already share `infoU.root == infoV.root`, an opposite-gender edge is possible if and only if `infoU.par != infoV.par`.
4. Otherwise merging the two roots sets the child root's parity to `infoU.par xor infoV.par xor 1`, enforcing opposite parity across `(bugU, bugV)`.

Key identifiers in the program:

| term | meaning |
|---|---|
| `parent` | DSU array storing parent or negative component size |
| `parity` | parity `0/1` relative to the DSU parent |
| `findRoot` | compresses paths while returning root and root-relative parity |
| `suspicious` | true when an odd cycle contradiction is found |

Worked trace on triangle `(1, 2), (2, 3), (1, 3)`: edge `(1, 2)` sets `parity[2] = 1` and `(2, 3)` sets `parity[3] = 0` under root `1`. Edge `(1, 3)` sees `infoU.par == infoV.par` and flags `Suspicious bugs found!`.

## Code

**Parity-compressing root lookup.** `findRoot` updates each compressed node's parity relative to `rootNode` along the path.

```nim
proc findRoot(
    parent: var seq[int],
    parity: var seq[int],
    node: int
): tuple[root: int, par: int] =
  var cur = node
  var accPar = 0
  while parent[cur] >= 0:
    accPar = accPar xor parity[cur]
    cur = parent[cur]
  let rootNode = cur
  cur = node
  var downPar = accPar
  while cur != rootNode:
    let nxt = parent[cur]
    let nextStepPar = parity[cur]
    parent[cur] = rootNode
    parity[cur] = downPar
    downPar = downPar xor nextStepPar
    cur = nxt
  result = (rootNode, accPar)
```

**Online edge contradiction check.** `main` merges components with flipped parity and flags same-component, same-parity pairs.

```nim
      let infoU = findRoot(parent, parity, bugU)
      let infoV = findRoot(parent, parity, bugV)
      if infoU.root == infoV.root:
        if infoU.par == infoV.par:
          suspicious = true
      else:
        if parent[infoU.root] > parent[infoV.root]:
          parent[infoV.root] += parent[infoU.root]
          parent[infoU.root] = infoV.root
          parity[infoU.root] = infoU.par xor infoV.par xor 1
        else:
          parent[infoU.root] += parent[infoV.root]
          parent[infoV.root] = infoU.root
          parity[infoV.root] = infoU.par xor infoV.par xor 1
```

## Complexity

| metric | cost |
|---|---|
| time | O(M * alpha(N)) |
| space | O(N) |

Checking `M <= 10^6` interactions uses tiny `O(N)` array storage with near-linear time per scenario.
