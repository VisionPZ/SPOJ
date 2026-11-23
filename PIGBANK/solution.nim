var tokens: seq[string]
var tokenIndex = 0
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

proc nextToken(): string =
  while true:
    if tokenIndex < tokens.len:
      let answer = tokens[tokenIndex]
      tokenIndex += 1
      return answer
    setLen(tokens, 0)
    tokenIndex = 0
    discard appendTokensFromLine()

proc nextNumber(): int =
  var text = nextToken()
  var value = 0
  var position = 0
  while position < text.len:
    if text[position] in {'0' .. '9'}:
      value = value * 10 + (text[position].ord - '0'.ord)
    position += 1
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
  for index in 0 ..< coinCount:
    coinPrice[index] = nextNumber()
    coinWeight[index] = nextNumber()
  let target = filledWeight - emptyWeight
  setLen(bestPrice, target + 1)
  bestPrice[0] = 0
  for weight in 1 .. target:
    bestPrice[weight] = impossiblePrice
  for coin in 0 ..< coinCount:
    let weight = coinWeight[coin]
    let price = coinPrice[coin]
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
