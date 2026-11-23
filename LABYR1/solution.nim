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
  var index = 0
  while index < line.len:
    while index < line.len and (line[index] == ' ' or line[index] == '\r' or line[index] == '\t'):
      index += 1
    let start = index
    while index < line.len and line[index] != ' ' and line[index] != '\r' and line[index] != '\t':
      index += 1
    if index > start:
      tokens.add(line[start ..< index])
  return tokens.len
proc textToInt(text: string): int =
  var value = 0
  for index in 0 ..< text.len:
    if text[index] in {'0' .. '9'}:
      value = value * 10 + (text[index].ord - '0'.ord)
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
  var index = digits.len - 1
  while index >= 0:
    buffer.add(cast[char](digits[index]))
    index -= 1

proc bfs(start: int): int =
  for index in 0 ..< cellCount:
    distance[index] = -1
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
