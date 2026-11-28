const zeroCode = 48
var text, line, res: string
while readLine(stdin, line): text.add line & '\n'
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'): pos += 1
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + (int(data[pos]) - zeroCode); pos += 1
var pos = 0
for i in 1 .. nextInt(text, pos):
  let base = nextInt(text, pos) mod 10
  let expVal = nextInt(text, pos)
  var ans = 1
  if expVal > 0:
    for step in 1 .. ((expVal - 1) mod 4) + 1: ans = (ans * base) mod 10
  res.add $ans & '\n'
stdout.write res
