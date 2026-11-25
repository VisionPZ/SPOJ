import sys

firstUpperValue = 65
firstLowerValue = 97
alphabetSize = 26
firstDigitValue = 48


def nextNumber(data, position):
    length = len(data)
    while position < length and not (firstDigitValue <= data[position] <= firstDigitValue + 9):
        position += 1
    value = 0
    found = position < length
    while position < length and firstDigitValue <= data[position] <= firstDigitValue + 9:
        value = value * 10 + data[position] - firstDigitValue
        position += 1
    return value, position, found


inputData = sys.stdin.buffer.read()
headerEnd = inputData.find(b"\n")
if headerEnd < 0:
    headerBytes = inputData
    textBytes = b""
else:
    headerBytes = inputData[:headerEnd]
    textBytes = inputData[headerEnd + 1:]

scanPos = 0
lineCount, scanPos, _ = nextNumber(headerBytes, scanPos)
textLines = textBytes.split(b"\n")[:lineCount]

letterCounts = [0] * alphabetSize
for textLine in textLines:
    for byteValue in textLine:
        if firstUpperValue <= byteValue <= firstUpperValue + alphabetSize - 1:
            letterCounts[byteValue - firstUpperValue] += 1
        elif firstLowerValue <= byteValue <= firstLowerValue + alphabetSize - 1:
            letterCounts[byteValue - firstLowerValue] += 1

presentLetters = [letterIndex for letterIndex in range(alphabetSize) if letterCounts[letterIndex] > 0]
presentLetters.sort(key=lambda letterIndex: (-letterCounts[letterIndex], -letterIndex))

answerLines = []
for letterIndex in presentLetters:
    answerLines.append("%s %d" % (chr(firstUpperValue + letterIndex), letterCounts[letterIndex]))

outputBuffer = "\n".join(answerLines)
if answerLines:
    outputBuffer += "\n"
sys.stdout.write(outputBuffer)
