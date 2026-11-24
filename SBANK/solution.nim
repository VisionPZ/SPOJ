import algorithm

var output: string

proc emit(text: string) =
  output.add(text)
  if output.len >= 1 shl 19:
    stdout.write(output)
    setLen(output, 0)

proc compareAccounts(first: string, second: string): int =
  if first < second:
    return -1
  if first > second:
    return 1
  return 0

proc normalize(text: string): string =
  var trimmed = ""
  for i in 0 ..< text.len:
    if text[i] notin {' ', '\t', '\r', '\v', '\f'}:
      trimmed.add(text[i])
    elif trimmed.len > 0 and trimmed[^1] != ' ':
      trimmed.add(' ')
  if trimmed.len > 0 and trimmed[^1] == ' ':
    setLen(trimmed, trimmed.len - 1)
  return trimmed

proc readNonEmptyLine(): string =
  var current = ""
  while stdin.readLine(current):
    let text = normalize(current)
    if text.len > 0:
      return text
  return ""

proc readCount(): int =
  var value = 0
  let text = readNonEmptyLine()
  for i in 0 ..< text.len:
    if text[i] in {'0' .. '9'}:
      value = value * 10 + (text[i].ord - '0'.ord)
  return value

let caseCount = readCount()
for i in 0 ..< caseCount:
  let accountCount = readCount()
  var accounts: seq[string]
  for _ in 0 ..< accountCount:
    accounts.add(readNonEmptyLine())
  sort(accounts, compareAccounts)
  var j = 0
  while j < accounts.len:
    var repeatCount = 1
    while j + repeatCount < accounts.len and accounts[j + repeatCount] == accounts[j]:
      repeatCount += 1
    emit(accounts[j])
    emit(" ")
    emit($repeatCount)
    emit("\n")
    j += repeatCount
  emit("\n")
stdout.write(output)
