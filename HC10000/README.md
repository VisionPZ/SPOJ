# HC10000 — Hofstadter–Conway 10000 dollar sequence (SPOJ)

<https://www.spoj.com/problems/HC10000/>

## Problem

Given indices up to 10^18, output the sum of the first n terms of the Hofstadter–Conway sequence modulo 10^9. The terms follow a self-referential rule, so a direct loop cannot reach the largest inputs.

Input starts with T, then one positive integer n per line. Output one sum per line in the same order.

| item | bound |
|---|---|
| tests T | 1 to 10000 |
| index n | 1 to 1000000000000000000 |
| modulus | 1000000000 |
| judge limit | 2000 ms, 1536 MB (largest official input 12 s) |

The sequence starts a1 = a2 = 1 and an = a[a(n−1)] + a[n−a(n−1)] for n ≥ 3.

Sample input:

```
10
1
2
3
4
5
10
100
1000
1000000
1000000000
```

Sample output:

```
1
2
4
6
9
32
2818
269446
334706485
137951847
```

## Idea

Draw a tree where each index points to a(n), like each child pointing to its parent. The indices appear in breadth-first order, and each level ends at a power of two. Repeating generation patterns let one subtree stand for many nodes, so a few dozen levels suffice for huge n.

A complete subtree is stored by level counts and parent-index sums. Merging two subtrees is one pass over those levels. Enumerating every a(i) up to n would take time proportional to n.

## Why It Works

1. For every positive k, a(2^k) = 2^(k−1), so level k ends at index 2^k.
2. Exactly k + 1 indices satisfy a(m) = 2^k, which fixes that level's run lengths.
3. The run lengths of one level come from the previous level by replacing each r with 1, 2, ..., r and adding one to the last entry.
4. A subtree with a given root degree and height repeats under that rule, so memoization stores it once.
5. Level counts give how many nodes add a wide offset, and parent sums give the local parent values.
6. Each node at level i contributes 2^(i−2) plus its local parent value to the sum.

| term | meaning |
|---|---|
| `LayerData` | level counts and summed parent indices for one subtree |
| `mergeLayers` | combine two side-by-side subtree representations |
| `fullSubtree` | memoized representation of a complete subtree |
| `partialSubtree` | representation when the last level is cut short |
| `totalSum` | accumulated answer modulo one billion |

The level offset is what turns local parent sums into global index sums.

The script example uses n = 5. The sequence begins 1, 1, 2, 2, 3, so S(5) = 1 + 1 + 2 + 2 + 3 = 9. The tree traversal reaches the same value by summing level contributions.

The sample also gives S(10^9) = 259987670137951847, which leaves 137951847 after reduction.

## Code

**Layer representation and merging.** Counts stay exact, while parent sums stay reduced.

```nim
type LayerData = object
  counts: seq[int64]
  parentSums: seq[int64]

var memoizedLayers: array[2, array[maximumDepth + 1, array[maximumDepth + 1, LayerData]]]

proc addRoot(layers: var LayerData) =
  if layers.counts.len > 0:
    layers.parentSums[layers.parentSums.len - 1] = layers.counts[layers.counts.len - 1] mod modulusValue
  layers.parentSums.add 0
  layers.counts.add 1

proc mergeLayers(resultData: var LayerData, other: LayerData) =
  if other.counts.len == 0:
    return
  if resultData.counts.len == 0:
    resultData.counts = other.counts
    resultData.parentSums = other.parentSums
    return
  let lastLayer = resultData.counts.len - 1
  for layerIndex in 0 .. lastLayer - 1:
    resultData.parentSums[layerIndex] = (resultData.parentSums[layerIndex] +
      other.parentSums[layerIndex] +
      (other.counts[layerIndex] mod modulusValue) *
      (resultData.counts[layerIndex + 1] mod modulusValue)) mod modulusValue
    resultData.counts[layerIndex] += other.counts[layerIndex]
  resultData.counts[lastLayer] += other.counts[other.counts.len - 1]
```

Exact counts keep cut-level comparisons correct.
The offset product is reduced before multiplication.
The root layer holds one node.

**Memoized complete subtrees.** Height and root degree identify one stored shape.

```nim
proc fullSubtree(depth: int, degree: int, lastFlag: bool): LayerData =
  if depth < 0:
    var emptyLayers: LayerData
    return emptyLayers
  if depth == 0:
    var singleRoot: LayerData
    singleRoot.counts.add 1
    singleRoot.parentSums.add 0
    return singleRoot
  let flagIndex = if lastFlag: 1 else: 0
  if memoizedLayers[flagIndex][depth][degree].counts.len > 0:
    return memoizedLayers[flagIndex][depth][degree]
  var resultData: LayerData
  for childIndex in 1 .. degree:
    let childIsLast = (childIndex == degree) and lastFlag
    var childDegree = childIndex
    if childIsLast:
      childDegree += 1
    let childLayers = fullSubtree(depth - 1, childDegree, childIsLast)
    mergeLayers(resultData, childLayers)
  resultData.addRoot()
  memoizedLayers[flagIndex][depth][degree] = resultData
  return resultData
```

The last child gains one degree when its parent ends a level.
Each distinct shape is built once.
A leaf is a single root node.

**Cut last level.** Only nodes along one chain need special handling.

```nim
proc partialSubtree(depth: int, degree: int, remainingNodes: int64,
                    lastFlag: bool, maxDepth: int): LayerData =
  var resultData: LayerData
  var remainingCount = remainingNodes
  for childIndex in 1 .. degree:
    let childIsLast = (childIndex == degree) and lastFlag
    var childDegree = childIndex
    if childIsLast:
      childDegree += 1
    if remainingCount == 0:
      var childLayers = fullSubtree(maxDepth - 1 - depth, childDegree, childIsLast)
      childLayers.counts.insert(0, 0)
      childLayers.parentSums.insert(0, 0)
      mergeLayers(resultData, childLayers)
    else:
      let childLayers = fullSubtree(maxDepth - depth, childDegree, childIsLast)
      if childLayers.counts[0] <= remainingCount:
        remainingCount -= childLayers.counts[0]
        mergeLayers(resultData, childLayers)
      else:
        let deeperLayers = partialSubtree(depth + 1, childDegree, remainingCount,
                                          childIsLast, maxDepth)
        mergeLayers(resultData, deeperLayers)
        remainingCount = 0
  resultData.addRoot()
  return resultData
```

A zero layer aligns shorter full subtrees.
The remaining count shrinks by whole subtrees when possible.
Only one child needs the recursive cut.

## Complexity

The tree states are small; the binary search is absent.

| phase | time | space |
|---|---|---|
| input read | one pass over indices | none beyond input string |
| complete subtrees | one build per degree and height pair | memoized layer arrays |
| cut level | one chain per test | temporary layer arrays |
| answer sum | one pass over levels | none |

The memo table is shared by all tests.

| measure | Big O |
|---|---|
| time | O(log^4 n + T log^3 n) worst case |
| space | O(log^3 n) |

Computing every sequence term up to n would take linear time per test. Level reuse reduces the largest inputs to a small stack of tree states.
