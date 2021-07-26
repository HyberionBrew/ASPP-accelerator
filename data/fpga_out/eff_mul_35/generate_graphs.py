import numpy as np
import matplotlib.pyplot as plt

utilization = []
total_cycles = []
ut_all = []
parallel_pes = np.array([2**i for i in range(6)])

with open('utilization/10-1-32-1-utilization.npy','rb') as f:
    utilization.append(np.load(f))
    total_cycles.append(np.load(f))
    ut_all.append(np.load(f))

for i in parallel_pes:
    try:
        with open('utilization/10-'+str(i)+'-32-3-utilization.npy','rb') as f:
            utilization.append(np.load(f))
            total_cycles.append(np.load(f))
            ut_all.append(np.load(f))
    except:
            total_cycles.append(-1)
            ut_all.append(-1)


parallel_pes = parallel_pes * 3
parallel_pes = np.insert(parallel_pes,0,1,axis=0)

plt.figure(0)
plt.plot(parallel_pes,ut_all,'ro',linestyle = '--')
plt.xlabel('Number of PEs')
plt.ylabel('PE Utilization')
plt.grid(True)

#plt.figure(1)
#plt.plot(parallel_pes*3,total_cycles)
#plt.show()

plt.figure(2)
plt.plot(parallel_pes,total_cycles/(parallel_pes*max(total_cycles)), 'ro',linestyle = '--')
plt.show()


#print(utilization)
#print(total_cycles)
#print(ut_all)
