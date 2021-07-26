# @Author: Fabian Kresse <fabian>
# @Date:   2021-06-23T09:28:50+02:00
# @Project: Aspp Accelerator
# @Filename: generate_totalRuntime.py
# @Last modified by:   fabian
# @Last modified time: 2021-07-16T11:50:11+02:00



import numpy as np
import matplotlib.pyplot as plt
import math
import copy

#the last term describes the additional kernel values (i.e. the zero paddeds in the kernel)
def calculate_ops_naive(rate,depth,ofmaps):
    return 33*33*64*depth*ofmaps*(3+(rate-1)*2)**2

def calculate_ops_padding(rate,depth,ofmaps):
    return 33*33*9*64*depth*ofmaps

def calculate_ops_nopad(rate,depth,ofmaps):
    res = 33*33*64*depth*ofmaps #middle
    res += (33-rate)*(33-rate)*64*depth*ofmaps*4#edges
    res += (33-rate)*(33-rate)*64*depth*ofmaps*4#outer middles
    return res


folder = ['eff_mul_25_3','eff_mul_25','eff_mul_25_12', 'eff_mul_25_18']
total_cycles = [[]]*4
utilization = [[],[],[],[]]
print(utilization)
ut_all = [[]]*4
arr = np.zeros((5,len(folder)))
rates = [3,6,12,18]
Pes = 32*3


for i in range(4):
    with open('fpga_out/'+folder[i]+'/utilization/10-32-32-3-utilization.npy','rb') as f:
        utilization[i].append(np.load(f))
        arr[2,i] = int(np.load(f))
        #arr[2,i] = int(np.load(f))
        total_cycles[i].append(int(np.load(f)))
        print(total_cycles)
        #ut_all[i].append(np.load(f))
    arr[0,i] = calculate_ops_padding(6,10,32)/Pes
    arr[1,i] = calculate_ops_nopad(rates[i],10,32)/Pes

print("-------")


#The below could also be calculated with ops_ideal with the right amount of valid (as in eff_mult.data of each data)
arr[3,0] = int(39908008/Pes)

print(arr[3,0])
print("-------")
arr[3,1] = int(35218132/Pes)
arr[3,2] = int(26275369/Pes)
arr[3,3] = int(17662420/Pes)

print(arr)
for i in range(4):
    rate = rates[i]
    print(rate)
    res = int(calculate_ops_naive(rate,10,32)/Pes)
    print(res)
    arr[4,i] = res
    print(arr[4,i])
print("------")
print(arr)
print("------")
#total_cycles[1].append(100000)
X = np.arange(4)
print(arr)


arr_org = copy.deepcopy(arr)

#arr = arr / arr[0,0]
arr = arr[:,::-1]
#setup plot
plt.rcParams['text.usetex'] = True
plt.rcParams['font.family'] = 'serif'

plt.tick_params(labelsize=20)
plt.rc('legend', fontsize=24)
plt.rcParams.update({'font.size': 24})
plt.tick_params(labelsize=24)

SIZE = (12,7)
fig = plt.figure(0,figsize=SIZE)
ax = fig.add_axes([0.1,0.1,0.9,0.9])


wide = 0.15
ax.bar(X +wide*0,arr[4], color = 'tab:purple', width = wide )
ax.bar(X + wide*1, arr[0], color = 'tab:blue', width = wide)
ax.bar(X + wide*2, arr[1], color = 'tab:orange', width = wide)
ax.bar(X + wide*3, arr[2], color = 'tab:red', width = wide)
ax.bar(X + wide*4, arr[3], color = 'tab:green', width = wide)
ax.spines['top'].set_visible(False)
ax.legend(labels=['naive','kernel padding aware','ifmap+kernel padding aware','this implementation','ideal'])
ax.set_yscale('log')
ax.set_ylabel('Cycles',fontsize=24)
ax.set_xticks(X+0.3)
ax.set_axisbelow(True)
plt.tick_params(labelsize=24)
ax.yaxis.grid(which="both",linestyle ='dashed')
ax.set_xticklabels(['rate=3', 'rate=6', 'rate=12', 'rate=18'][::-1])
plt.savefig("../thesis/BachelorThesis/figures/Results/normMults.pdf",transparent=True)
plt.show()

arr_org = arr
fig = plt.figure(1,figsize=SIZE)
ax = fig.add_axes([0.1,0.1,0.9,0.9])
plt.rc('legend', fontsize=20)
plt.rcParams.update({'font.size': 20})
plt.rcParams['text.usetex'] = True
plt.rcParams['font.family'] = 'serif'
plt.tick_params(labelsize=20)

#X = np.arange(3)
print(arr_org)
ax.bar(X + 0.0,arr[4], color = 'tab:purple', width = 0.2 )
#ax.bar(X + 0.2,(arr[1]), color = 'tab:blue', width = 0.2)
ax.bar(X + 0.2,(arr[1]), color = 'tab:orange', width = 0.2)
ax.bar(X + 0.4, arr[3], color = 'tab:green', width = 0.2)
ax.set_yscale('log')
ax.spines['top'].set_visible(False)
ax.legend(labels=['naive implementation', 'padding aware', 'ideal'])
ax.set_title('title')
ax.set_xticks(X+0.2)
ax.set_axisbelow(True)
ax.yaxis.grid(which="both",linestyle ='dashed')
plt.tick_params(labelsize=24)
ax.set_ylabel('Cycles',fontsize=24)
ax.set_xticklabels(['rate=3', 'rate=6', 'rate=12', 'rate=18'][::-1])


plt.tight_layout()
plt.savefig("../thesis/BachelorThesis/figures/Introduction/validMultiplications.pdf",transparent=True)
plt.show()
