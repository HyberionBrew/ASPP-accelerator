# @Author: Fabian Kresse <fabian>
# @Date:   2021-06-07T12:00:09+02:00
# @Project: Aspp Accelerator
# @Filename: col_vs_row_eff.py
# @Last modified by:   fabian
# @Last modified time: 2021-07-16T11:54:13+02:00



import numpy as np
import matplotlib.pyplot as plt
spars = [10,16,25,35,50,100]
folders = ['eff_mul_10','eff_mul_16','eff_mul_25','eff_mul_35','eff_mul_50','eff_mul_100']
color = ['ro','go','yo','bo','co','mo']

def plot_oneCol(folders):
    utilization = [[],[]]
    total_cycles = [[],[]]
    ut_all = [[],[]]
    i = 0

    with open('fpga_out/'+folders[1]+'/utilization/10-1-32-1-utilization.npy','rb') as f:
        utilization[0].append(np.load(f))
        total_cycles[0].append(np.load(f))
        ut_all[0].append(np.load(f))
        """
        except:
            total_cycles.append(-1)
            ut_all.append(-1)
            print("Did not find")
        """
    pos = 0
    parallel_pes = np.array([2**i for i in range(6)])

    for i in parallel_pes:
        try:
            with open('fpga_out/'+folders[1]+'/utilization/10-'+str(i)+'-32-3-utilization.npy','rb') as f:
                utilization[pos].append(np.load(f))
                total_cycles[pos].append(np.load(f))
                ut_all[pos].append(np.load(f))
        except:
            total_cycles[pos].append(1)
            ut_all[pos].append(1)
            print("Did not find")


    parallel_pes = parallel_pes * 3
    parallel_pes = np.insert(parallel_pes,0,1,axis=0)
    plt.figure(1,figsize=(12,7))
    plt.rcParams['text.usetex'] = True
    plt.rcParams['font.family'] = 'serif'
    plt.rcParams.update({'font.size': 20})
    plt.plot(parallel_pes,ut_all[0],'ro',linestyle = '--')

    parallel_pes = np.array([2**i for i in range(6)])
    pos = 1
    for i in parallel_pes:
        try:
            with open('fpga_out/'+folders[0]+'/utilization/10-'+str(i)+'-32-1-utilization.npy','rb') as f:
                utilization[pos].append(np.load(f))
                total_cycles[pos].append(np.load(f))
                ut_all[pos].append(np.load(f))
        except:
            total_cycles[pos].append(1)
            ut_all[pos].append(1)
            print("Did not find")



    plt.plot(parallel_pes,ut_all[1],'bo',linestyle = '--')
    print(ut_all)
    plt.xlabel('Number of PEs', fontsize=20)
    plt.ylabel('PE Utilization', fontsize=20)
    plt.grid(True)
    return plt



folders = ["col_1_eff_mul_25","eff_mul_25"]
plt0 = plot_oneCol(folders)
#plt0.rc('axes', titlesize=15)     # fontsize of the axes title
plt.xlim(0, 32)

#plt0.tick_params(labelsize=14)

plt0.rc('legend', fontsize=20)
plt0.legend(["Three Columns","One Column"])
plt.savefig("../thesis/BachelorThesis/figures/Results/colvsrows.pdf",transparent=True)
plt0.show()
