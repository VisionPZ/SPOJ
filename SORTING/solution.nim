{.passC: "-O2".}
{.push checks: off.}

const firstUpperValue = 65
const letterKinds = 26
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var letterCounts: array[0..letterKinds - 1, int]
var scanPos = 0
while scanPos < inputData.len:
  let ch = inputData[scanPos]
  if ch >= 'A' and ch <= 'Z':
    letterCounts[int(ch) - firstUpperValue] += 1
  scanPos += 1

var outputBuffer = ""

proc appendLetter(letter: char) =
  outputBuffer.add letter
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for i in 0..<letterKinds:
  let repeatCount = letterCounts[i]
  for j in 0..<repeatCount:
    appendLetter(char(i + firstUpperValue))

appendLetter('\n')
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
