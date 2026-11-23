## Problem

A die with numbered stickers starts on a four-row strip. Each roll moves one square and costs the number that lands on top. Read the die values, the start square, and the target square, then print the smallest total cost.

| input or limit | bound |
| --- | --- |
| sticker value | 1 to 50 |
| column | -1,000,000,000 to 1,000,000,000 |
| row | 1 to 4 |
| time | 2569 ms |
| memory | 1536 MB |

The column span is huge, so the program must skip most columns.

## Idea

A die position needs a column, a row, and an orientation. An orientation says which original face is on top and which faces forward. Only 24 orientations exist, so a shortest-path search stays small. Dijkstra expands one state at a time, and a roll costs the new top value.

When two finished columns hold distance vectors that differ by one constant, every later column repeats that same gap. The program detects the gap, then jumps straight to the target column with arithmetic.

Each expanded state examines four rolls, so the search spends constant work per state.

## Why It Works

A roll moves one square and turns the die by a quarter turn. A quarter turn permutes the four body diagonals in a cycle of length four. That cycle is odd. The row parity flips on the same roll, so the sum of both parities stays fixed. Half of the row-orientation pairs can never occur.

- `orientationsCount = 24` counts the distinct die orientations.
- `statesPerColumn = 96` counts every row-orientation pair in one column.
- `reachablePerColumn = 48` counts the reachable half of those pairs.
- `orientationsCount * node.rowIndex + node.orientation` packs one pair into one slot.
- `columnOffset = 4` reserves four columns on the left of the start.
- `let blocks = (horizontalDistance - leftEdge) div periodLength` counts full repeats.
- `answer = baseCost + blocks * periodDelta` turns the gap into the final cost.

The script generated this walk for the sample. The start maps to column 0 and row 0.

| step | move | column | row | top dots | cost | total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | roll left | -2 | 1 | 4 | 3 | 3 |
| 2 | roll back | -2 | 2 | 2 | 2 | 5 |
| 3 | roll right | -1 | 2 | 1 | 1 | 6 |
| 4 | roll right | 0 | 2 | 5 | 1 | 7 |

The four rolls cost 3, 2, 1, and 1, so the minimum is 7.

## Code

```nim
proc nextInt(input: string, pos: var int): int =
  while pos < input.len and (input[pos] < '0' or input[pos] > '9') and input[pos] != '-':
    inc pos
  var sign = 1
  if pos < input.len and input[pos] == '-':
    sign = -1
    inc pos
  var value = 0
  while pos < input.len and input[pos] >= '0' and input[pos] <= '9':
    value = value * 10 + (int(input[pos]) - 48)
    inc pos
  result = sign * value
```

The loop ends at `input.len`, so the scanner reads the whole buffer once. It handles the minus sign before negative columns. The cost is one pass over the digits of each number.

```nim
proc ensureColumn(columnIndex: int) =
  let pooledIndex = columnIndex + columnOffset
  if pooledIndex + 1 > columnCount:
    columnCount = pooledIndex + 1
  if columnPool[pooledIndex].generation != caseGeneration:
    for stateIndex in 0..<statesPerColumn:
      columnPool[pooledIndex].distances[stateIndex] = infinite
    columnPool[pooledIndex].remaining = reachablePerColumn
    columnPool[pooledIndex].generation = caseGeneration
```

The pool has `maxColumns = 8192` slots, which covers the short search window. The generation mark skips clearing slots that a later case reuses. A fresh slot costs one pass over 96 distances.

```nim
    if columnPool[columnIndex].remaining == 0:
      if periodLength < 0:
        for earlierIndex in 0..<columnCount:
          if earlierIndex == columnIndex or columnPool[earlierIndex].remaining != 0:
            continue
          var delta = infinite
          var matches = true
          for state in 0..<statesPerColumn:
            let currentDistance = columnPool[columnIndex].distances[state]
            if currentDistance == infinite:
              continue
            let earlierDistance = columnPool[earlierIndex].distances[state]
            if earlierDistance == infinite:
              matches = false
              break
            if delta == infinite:
              delta = currentDistance - earlierDistance
            elif currentDistance - earlierDistance != delta:
              matches = false
              break
```

The scan checks only columns that are already complete. It compares the current vector with each earlier vector, one state at a time. A single mismatch rejects that pair. Each comparison costs 96 index reads.

```nim
      if periodLength > 0 and pendingColumns == 0 and horizontalDistance >= leftEdge:
        let blocks = (horizontalDistance - leftEdge) div periodLength
        let offset = (horizontalDistance - leftEdge) mod periodLength
        let baseColumn = columnPool[leftEdge + offset + columnOffset]
        var baseCost = infinite
        for orientation in 0..<orientationsCount:
          baseCost = min(baseCost, baseColumn.distances[orientationsCount * targetRow + orientation])
        answer = baseCost + blocks * periodDelta
        break
```

The offset stays inside one period, so the base column is always filled. The loop over `0..<orientationsCount` keeps the cheapest final orientation. The guard `horizontalDistance >= leftEdge` prevents a negative block count. This step costs 24 reads.

```nim
    for move in 0..<moveCount:
      var newColumn = node.columnIndex
      var newRow = node.rowIndex
      case move
      of 0:
        if node.rowIndex == 0:
          continue
        dec newRow
      of 1:
        if node.rowIndex == rowsCount - 1:
          continue
        inc newRow
      of 2:
        if node.columnIndex <= -columnOffset:
          continue
        dec newColumn
      else:
        inc newColumn
      let newOrientation = orientationNext[node.orientation][move]
      let moveCost = faceCosts[orientationCostFace[node.orientation][move]]
      heapPush(SearchNode(distance: node.distance + moveCost, columnIndex: newColumn, rowIndex: newRow, orientation: newOrientation))
```

The loop bound is four moves: forward, back, left, and right. The two row checks keep the die inside rows 1 to 4. The column check stops leftward rolls at the reserved edge. Each move pushes one heap entry.

```nim
  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen(0)
```

The buffer holds up to 256 KiB before a write. The program never writes one answer at a time. Each answer adds only its digits and one newline.

## Complexity

Building the orientation tables visits 24 states and four moves once, so it costs O(1) time and O(24) space.

Dijkstra visits 48 reachable states per column and four moves per state. Let K be the number of columns opened before the gap closes. The search costs O(K × 48 × log K) time and O(K × 96) space. The period check adds O(K × 96) time. The final jump costs O(24) time.

Per case, the total is O(K log K) time and O(K) space, with K small in tests. A direct walk over every column would cost O(|x2 - x1|) time and cannot handle a span of 2,000,000,000.
