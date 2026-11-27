# LABYR1 — Labyrinth (SPOJ)

<https://www.spoj.com/problems/LABYR1/>

## Problem

A labyrinth is a grid of rock and free cells with exactly one path between any
two free cells. Two hooks joined by a rope need the longest possible rope, so find
the greatest number of steps between two free cells.

Each test case gives the column count and the row count, then a grid of `#` (rock)
and `.` (free) cells. Free cells form a tree: exactly one path joins any two of them.
Print `Maximum rope length is X.` where X is the number of steps on the longest path
between two free cells. Columns and rows go up to 1000 each, so a grid can hold
1 000 000 cells.

## Idea

The graph is a tree, so its longest path is the tree diameter. Two breadth-first
searches give it: start anywhere, find the cell that is farthest away, then search
from that cell, and the largest distance reached is the answer. Every cell is visited
once per search, so the cost is linear in the grid size.

## Why It Works

In a tree the farthest cell from any start is always an endpoint of a diameter, so a
second search from it must trace the whole diameter. The grid sits in a flat byte array at `row * columns + column`.
Horizontal neighbors shift by 1 (guarded by column), and vertical neighbors shift by `columns`. Marking is done with a distance array filled with `-1`, which doubles as the
visited set and the rope length.

## Code

```nim
var grid: seq[byte]
var distance: seq[int]
var queue: seq[int]
var tokens: seq[string]
var columns = 0
var cellCount = 0
var farthestDistance = 0

proc readLineText(): string =
  var current = ""
  discard stdin.readLine(current)
  return current

proc appendTokensFromLine(): int =
  var line = readLineText()
  while line.len == 0:
    line = readLineText()
  var i = 0
  while i < line.len:
    while i < line.len and (line[i] == ' ' or line[i] == '\r' or line[i] == '\t'):
      i += 1
    let start = i
    while i < line.len and line[i] != ' ' and line[i] != '\r' and line[i] != '\t':
      i += 1
    if i > start:
      tokens.add(line[start ..< i])
  return tokens.len
proc textToInt(text: string): int =
  var value = 0
  for i in 0 ..< text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
  return value

proc appendNumber(buffer: var string, value: int) =
  var digits: seq[byte]
  if value == 0:
    digits.add(cast[uint8]('0'.ord))
  else:
    var rest = value
    while rest > 0:
      digits.add(cast[uint8]('0'.ord + (rest mod 10)))
      rest = rest div 10
  var i = digits.len - 1
  while i >= 0:
    buffer.add(cast[char](digits[i]))
    i -= 1

proc bfs(start: int): int =
  for i in 0 ..< cellCount:
    distance[i] = -1
  var head = 0
  var tail = 1
  distance[start] = 0
  queue[0] = start
  var far = start
  farthestDistance = 0
  while head < tail:
    let current = queue[head]
    head += 1
    let step = distance[current]
    let column = current mod columns
    if column > 0 and grid[current - 1] == 1 and distance[current - 1] < 0:
      distance[current - 1] = step + 1
      queue[tail] = current - 1
      tail += 1
    if column + 1 < columns and grid[current + 1] == 1 and distance[current + 1] < 0:
      distance[current + 1] = step + 1
      queue[tail] = current + 1
      tail += 1
    if current >= columns and grid[current - columns] == 1 and distance[current - columns] < 0:
      distance[current - columns] = step + 1
      queue[tail] = current - columns
      tail += 1
    if current + columns < cellCount and grid[current + columns] == 1 and distance[current + columns] < 0:
      distance[current + columns] = step + 1
      queue[tail] = current + columns
      tail += 1
    if step > farthestDistance:
      farthestDistance = step
      far = current
  return far

discard appendTokensFromLine()
let caseCount = textToInt(tokens[0])
for _ in 0 ..< caseCount:
  setLen(tokens, 0)
  var tokenCount = appendTokensFromLine()
  while tokenCount < 2:
    tokenCount = appendTokensFromLine()
  columns = textToInt(tokens[0])
  let rows = textToInt(tokens[1])
  cellCount = columns * rows
  setLen(grid, cellCount)
  setLen(distance, cellCount)
  setLen(queue, cellCount + 1)
  var start = -1
  for row in 0 ..< rows:
    setLen(tokens, 0)
    var rowTokens = appendTokensFromLine()
    while rowTokens < 1:
      rowTokens = appendTokensFromLine()
    let line = tokens[0]
    let base = row * columns
    for column in 0 ..< columns:
      if line[column] == '.':
        grid[base + column] = 1
        if start < 0:
          start = base + column
      else:
        grid[base + column] = 0
  var answer = 0
  if start >= 0:
    let farEnd = bfs(start)
    discard bfs(farEnd)
    answer = farthestDistance
  var line = "Maximum rope length is "
  appendNumber(line, answer)
  line.add(".\n")
  stdout.write(line)
```

## Complexity

Each search visits every free cell once and checks four neighbors.
One test case costs O(C R) time and O(C R) space for the grid, distances, and queue.
Two searches per case: O(2 C R) work, linear. The naive alternative, a search from
every free cell, costs O((C R)^2) and dies on a 1000 by 1000 grid.
