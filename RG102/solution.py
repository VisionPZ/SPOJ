import sys

minutesPerDay = 1440
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
scanPos = 0
answerLines = []
while True:
    hourValue, scanPos, hourFound = nextNumber(inputData, scanPos)
    if not hourFound:
        break
    minuteValue, scanPos, _ = nextNumber(inputData, scanPos)
    minutesSoFar = hourValue * 60 + minuteValue
    if minutesSoFar == 0:
        break
    answerLines.append(str(minutesPerDay - minutesSoFar))

sys.stdout.write("\n".join(answerLines))
if answerLines:
    sys.stdout.write("\n")
