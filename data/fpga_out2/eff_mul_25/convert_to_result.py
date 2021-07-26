import numpy as np
import sys
from numpy import asarray
from numpy import save

file_in_name = sys.argv[1]
IFMAPS_DEPTH = int(sys.argv[2]) 
PARALLEL_OFMS = int(sys.argv[3]) 
NUM_OFMS = int(sys.argv[4])
PE_COLUMNS = int(sys.argv[5])
reorderd = sys.argv[6]

if reorderd == "True":
    red_str = "-reorderd"
else:
    red_str = ""
f = open(file_in_name,'rb')
pos = 0
x_offs = 0

result = np.zeros((NUM_OFMS,33,33))
ofm = 0
y = 0
vals = []

utilization = np.zeros((PARALLEL_OFMS,PE_COLUMNS))
total_cycles = 0


count = 0
col_utl = 0
ofm_utl = 0
while (True):
    count = count +1

    sliced = f.read(1)
    print(sliced)
    int_val = int.from_bytes(sliced, byteorder='little')
    vals.append(int_val)
    if ((count % 4 == 0) and (count != 0)):
        res = 0
        for i in range(4):
            res = res + vals[i]*16**(6-2*i)
        vals = []
    
        if count == 4:
            total_cycles = res
        else:
            utilization[ofm_utl,col_utl]=res
            if col_utl == PE_COLUMNS-1:
                col_utl = 0
                ofm_utl +=1
                if ofm_utl == PARALLEL_OFMS:
                    break
            else:
                col_utl += 1
            
#sliced = f.read(1)
print(utilization)
print(total_cycles)
elems = utilization.shape[0]*utilization.shape[1]
utiliz_all = np.sum(utilization/total_cycles)/elems
print(utiliz_all)
sliced = f.read(1)
print(sliced)


for ofm_offs in range(int(NUM_OFMS/PARALLEL_OFMS)):
    for y in range(33):
        for x_offs in range(11):
            for ofm in range(PARALLEL_OFMS):
                for x in range(3):
                    sliced = f.read(1)
                    result[ofm+ofm_offs*PARALLEL_OFMS,y,x_offs*3+x]= ord(sliced)

#print(result)

fw = open("processed/"+str(IFMAPS_DEPTH)+"-"+str(PARALLEL_OFMS)+"-"+str(NUM_OFMS)+"-"+str(PE_COLUMNS)+red_str+"-processed.data",'w')
for ofm in range(NUM_OFMS):
    for x in range(33):
        for y in range(33):
            fw.write(str(int(result[ofm,x,y]))+" ")
        fw.write('\n')
    fw.write('\n')
fw.close()



with open("utilization/"+str(IFMAPS_DEPTH)+"-"+str(PARALLEL_OFMS)+"-"+str(NUM_OFMS)+"-"+str(PE_COLUMNS)+red_str+"-utilization.npy",'wb') as f:
    np.save(f,utilization)
    np.save(f,total_cycles)
    np.save(f, utiliz_all)
