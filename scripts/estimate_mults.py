rates = [6,12,18,24]
IFMAP = 33
DEPTH = 32
totalMults = 0
PEs = 96
frequency = 100* 10**6

for rate in rates:
    totalMults += DEPTH * ((IFMAP-rate)**2 * 4 + (IFMAP-rate) *IFMAP * 4 +IFMAP**2)

time = totalMults/(PEs*frequency)
print(time)
frequencySes = 181 *10**6
ses = (IFMAP*IFMAP*DEPTH/(32*frequencySes))
print(ses)
print("Speedup of Ses: "+ str(time/ses))
