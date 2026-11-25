# ALIBB — Alibaba (SPOJ)
<https://www.spoj.com/problems/ALIBB/>

## Problem

Each dataset gives positions and deadlines of items along a line.
Find the earliest time to collect them all, choosing the starting point, or report that it cannot be done.

The first line gives the dataset count. Each dataset gives n, then n pairs of place and deadline in increasing place order. Print the smallest finish time, or the words No solution.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Datasets K | up to 10 |
| Treasures n | up to 10000 |
| Judge time | 1 s |
| Judge memory | 1536 MB |

The quadratic dynamic program fits these bounds with two rolling rows.

The sample input and its expected output follow byte for byte.

```
2
5
1 3
3 1
5 8
8 19
10 15
5
1 5
2 1
3 4
4 2
5 3
```

```
11
No solution
```


## Idea

Treat each sweep as choosing which end to visit next, extending a collected block one item at a time.
The program keeps two dynamic program rows (tables of best times) over the collected block. One row ends at the left end, and the other row ends at the right end.
Each state adds the travel time for the next treasure and rejects a choice that misses its deadline. A full straight sweep is handled as a quick special case.
Enumerating visit orders costs factorial time, while the block state collapses them into O(n squared) work.
The interval state turns a maze of orders into two short rows.

## Why It Works

1. After any number of picks, the collected treasures form a contiguous block in place order.
2. The next pick must extend that block on the left or the right, so the block endpoints describe every useful state.
3. `curLeft` records the earliest finish when the last pick sat at the left end, and `curRight` records the right-end case.
4. A pick arriving after its deadline is stored as infinity, which removes that route.
5. When every deadline exceeds the full span, a straight sweep to the far end takes exactly that span.

Four terms describe the state.

| Term | Meaning |
| --- | --- |
| block | collected treasures between two place indices |
| left state | sweep currently parked at the block left end |
| right state | sweep currently parked at the block right end |
| deadline | latest arrival time allowed at a treasure |

They show why two rows replace a factorial search.

A script check of the first dataset reads places [1,3,5,8,10] and deadlines [3,1,8,19,15].
The full span is 10 minus 1, which is 9. The deadline 1 at place 3 is not loose, so the rows are needed.
The dynamic program returns 11, matching the sample. The second dataset reaches infinity and prints No solution.

## Code

**Integer scanner.**
```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  value
```

The scanner reads places and deadlines from one buffer. Whitespace between numbers is ignored. The cost is one pass over the dataset bytes.

**Dataset setup and shortcut.**
```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let treasureCount = nextInt(inputData, scanPos)
  var position = newSeq[int](treasureCount + 1)
  var deadline = newSeq[int](treasureCount + 1)
  for k in 1..treasureCount:
    position[k] = nextInt(inputData, scanPos)
    deadline[k] = nextInt(inputData, scanPos)
  let span = position[treasureCount] - position[1]
  var allDeadlinesLoose = true
  for k in 1..treasureCount:
    if deadline[k] <= span:
      allDeadlinesLoose = false
      break
  var answer = 0
  if allDeadlinesLoose:
    answer = span
  elif treasureCount > 1:
```

The code reads every pair before deciding. It checks whether all deadlines exceed the full span. A loose set returns the span in constant extra work.

**Rolling interval dynamic program.**
```nim
    var prevLeft = newSeq[int](treasureCount + 2)
    var prevRight = newSeq[int](treasureCount + 2)
    var curLeft = newSeq[int](treasureCount + 2)
    var curRight = newSeq[int](treasureCount + 2)
    for k in 0..treasureCount + 1:
      prevLeft[k] = infinity
      prevRight[k] = infinity
      curLeft[k] = infinity
      curRight[k] = infinity
    prevLeft[1] = 0
    prevRight[1] = 0
    for rightIndex in 2..treasureCount:
      curLeft[rightIndex] = 0
      curRight[rightIndex] = 0
      var leftIndex = rightIndex - 1
      while leftIndex >= 1:
        var bestLeft = curLeft[leftIndex + 1] + position[leftIndex + 1] - position[leftIndex]
        let crossLeft = curRight[leftIndex + 1] + position[rightIndex] - position[leftIndex]
        if crossLeft < bestLeft: bestLeft = crossLeft
        if bestLeft >= deadline[leftIndex]: bestLeft = infinity
        curLeft[leftIndex] = bestLeft
        var bestRight = prevLeft[leftIndex] + position[rightIndex] - position[leftIndex]
        let crossRight = prevRight[leftIndex] + position[rightIndex] - position[rightIndex - 1]
        if crossRight < bestRight: bestRight = crossRight
        if bestRight >= deadline[rightIndex]: bestRight = infinity
        curRight[leftIndex] = bestRight
        leftIndex -= 1
      swap prevLeft, curLeft
      swap prevRight, curRight
    answer = min(prevLeft[1], prevRight[1])
```

The outer loop grows the block by one place each round. The inner loop walks the left edge inward and fills two rows. A swap reuses the arrays instead of allocating new ones.

**Answer emission.**
```nim
  if answer >= infinity:
    appendOutput("No solution")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
```

Infinity means no valid route exists. The code prints No solution in that case. All answers collect in one output buffer.


## Complexity

Two rolling rows keep memory small while the state count grows quadratically.

| Phase | Time | Space |
| --- | --- | --- |
| input parse | O(n) | two arrays |
| loose check | O(n) | constant |
| interval dynamic program | O(n squared) | four rows |

No allocation happens inside the inner loop, which keeps the 1 s limit safe.

Big O uses treasure count n.

| Measure | Big O |
| --- | --- |
| time | O(n squared) per dataset |
| space | O(n) |

A factorial search over visit orders is far slower than this block state.
