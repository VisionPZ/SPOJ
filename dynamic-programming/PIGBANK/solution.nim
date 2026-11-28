var tokens: seq[string]
var i = 0
var coinWeight: seq[int]
var coinPrice: seq[int]
var bestPrice: seq[int]
const impossiblePrice = 1 shl 29

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

proc nextToken(): string =
  while true:
    if i < tokens.len:
      let answer = tokens[i]
      i += 1
      return answer
    setLen(tokens, 0)
    i = 0
    discard appendTokensFromLine()

proc nextNumber(): int =
  var text = nextToken()
  var value = 0
  var i = 0
  while i < text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
    i += 1
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

var output: string

proc emit(text: string) =
  output.add(text)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

let caseCount = nextNumber()
for _ in 0 ..< caseCount:
  let emptyWeight = nextNumber()
  let filledWeight = nextNumber()
  let coinCount = nextNumber()
  setLen(coinWeight, coinCount)
  setLen(coinPrice, coinCount)
  for j in 0 ..< coinCount:
    coinPrice[j] = nextNumber()
    coinWeight[j] = nextNumber()
  let target = filledWeight - emptyWeight
  setLen(bestPrice, target + 1)
  bestPrice[0] = 0
  for weight in 1 .. target:
    bestPrice[weight] = impossiblePrice
  for j in 0 ..< coinCount:
    let weight = coinWeight[j]
    let price = coinPrice[j]
    if weight > 0 and weight <= target:
      for current in weight .. target:
        let candidate = bestPrice[current - weight] + price
        if candidate < bestPrice[current]:
          bestPrice[current] = candidate
  if bestPrice[target] >= impossiblePrice:
    emit("This is impossible.\n")
  else:
    var line = "The minimum amount of money in the piggy-bank is "
    appendNumber(line, bestPrice[target])
    line.add(".\n")
    emit(line)
stdout.write(output)
