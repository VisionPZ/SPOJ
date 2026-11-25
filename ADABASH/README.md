# ADABASH — Ada and Servers (SPOJ)

<https://www.spoj.com/problems/ADABASH/>

## Problem

Find how many groups of connected servers remain after joining every listed pair. Treat each wire as an undirected link and count the groups at the end.

The input starts with `N` servers and `M` wires. Each of the next `M` lines holds two server indexes in `[0, N)`. Server indexes start at zero. Output one line with the group count.

| Item | Bound |
|---|---|
| Servers N | 1 to 600 |
| Wires M | 0 to 600 |
| Judge limit | 4000 ms, 1536 MB |

The small bounds keep the whole graph in memory.

The sample case reads three disjoint wire pairs among six servers:

```
6 3
1 2
3 4
5 0
```

The expected output is:

```
3
```

Each pair forms its own group, so the answer is three.

## Idea

Merge sets as wires arrive, like stamping every employee in a newly merged team with the same team label. Use a disjoint-set union, also called union-find. Each merge costs nearly constant time, while a fresh search from scratch per wire would cost up to O(M × N). Start with N groups and subtract one for every merge of two different groups.

## Why It Works

1. Every server starts in a set by itself, so the first count is N.
2. A wire between two servers in different sets must merge those sets.
3. A wire inside one set changes nothing, so it never lowers the count.
4. Path compression shortens each root lookup on later wires.
5. The final count equals the number of remaining root nodes.

| Term | Meaning |
|---|---|
| `parentServers` | parent link for each server in the union-find |
| `findRoot` | returns the representative of a server's set |
| `componentCount` | number of distinct groups seen so far |

The table names the only state the program keeps.

A short trace with the sample wires:

```
start:    parent = [0,1,2,3,4,5], groups = 6
wire 1 2: merge roots 1 and 2,   groups = 5
wire 3 4: merge roots 3 and 4,   groups = 4
wire 5 0: merge roots 5 and 0,   groups = 3
```

The trace reaches three groups, matching the sample output.

## Code

**Input and scanning.** The hand reader loads the header, then one pair per wire.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner skips whitespace and reads digits one by one.
It ignores line breaks, so any wire layout works.
One pass builds the whole input string.

**Root lookup.** Following parent links with compression keeps later merges short.

```nim
proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each visited node points closer to its root after one call.
The output buffer collects text and writes in large blocks.
No write happens per server.

**Merge pass.** Each wire reduces the count only when two roots differ.

```nim
let serverCount = nextInt(inputData, scanPos)
let wireCount = nextInt(inputData, scanPos)
var parentServers = newSeq[int](serverCount)
for serverIndex in 0 .. serverCount - 1:
  parentServers[serverIndex] = serverIndex
var componentCount = serverCount
for wireIndex in 0 .. wireCount - 1:
  let firstServer = nextInt(inputData, scanPos)
  let secondServer = nextInt(inputData, scanPos)
  let firstRoot = findRoot(parentServers, firstServer)
  let secondRoot = findRoot(parentServers, secondServer)
  if firstRoot != secondRoot:
    parentServers[firstRoot] = secondRoot
    componentCount -= 1
appendOutput($componentCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly `wireCount` times.
Self wires and repeated wires leave the count unchanged.
The final flush writes the single answer line.

## Complexity

The merge pass dominates, and output is one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the wire list | one input string |
| Union-find | nearly constant work per wire | one parent per server |
| Output | one line | block buffer |

Each phase grows with the wires, not with server pairs.

| Measure | Big O |
|---|---|
| Time | O((N + M) α(N)) |
| Space | O(N) |

Here α is the inverse Ackermann function, which stays below five in practice.
A fresh graph search per wire would cost O(M × N) instead, so union-find wins.
