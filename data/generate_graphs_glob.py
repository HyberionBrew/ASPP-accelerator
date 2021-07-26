# @Author: Fabian Kresse <fabian>
# @Date:   2021-06-16T10:16:34+02:00
# @Project: Aspp Accelerator
# @Filename: generate_graphs_glob.py
# @Last modified by:   fabian
# @Last modified time: 2021-07-16T10:00:36+02:00



import numpy as np
import matplotlib.pyplot as plt
spars = [10,16,25,35,50,100]
folders = ['eff_mul_10','eff_mul_16','eff_mul_25','eff_mul_35','eff_mul_50','eff_mul_100']
color = ['ro','go','yo','bo','co','mo']

real_spars = []

for fol in folders:
    with open('fpga_out/'+fol+'/eff_mult.data','rb') as f:
        eff_mul = float(f.readline())
        print(eff_mul)
        real_spars.append(eff_mul)

def plot_utilization(folder,col):
    utilization = []
    total_cycles = []
    ut_all = []
    try:
        with open('fpga_out/'+folder+'/utilization/10-1-32-1-utilization.npy','rb') as f:
            utilization.append(np.load(f))
            total_cycles.append(np.load(f))
            ut_all.append(np.load(f))
    except:
        total_cycles.append(-1)
        ut_all.append(-1)
        print("Did not find")


    parallel_pes = np.array([2**i for i in range(6)])
    for i in parallel_pes:
        try:
            with open('fpga_out/'+folder+'/utilization/10-'+str(i)+'-32-3-utilization.npy','rb') as f:
                utilization.append(np.load(f))
                total_cycles.append(np.load(f))
                ut_all.append(np.load(f))
        except:
                total_cycles.append(-1)
                ut_all.append(-1)
                print("Did not find")
    parallel_pes = parallel_pes * 3
    parallel_pes = np.insert(parallel_pes,0,1,axis=0)
    print("folder: "+ folder)
    print(ut_all)
    plt.figure(0,figsize=(15,8))
    plt.plot(parallel_pes,ut_all,col,linestyle = '--')
    plt.xlabel('Number of PEs',fontsize=18)
    plt.ylabel('PE Utilization',fontsize=18)
    plt.grid(True)
    return plt


def plot_spars(folders,spars,point):
    utilization = []
    total_cycles = []
    ut_all = []
    print(spars)
    for fol in folders:
        with open('fpga_out/'+fol+'/utilization/10-'+str(point)+'-32-3-utilization.npy','rb') as f:
            utilization.append(np.load(f))
            total_cycles.append(np.load(f))
            ut_all.append(np.load(f))

    plt.figure(1,figsize=(15,8))
    print("spars "+ str(spars))
    s = (np.array(spars)*0.01*62)/(64+4)
    print(s[::-1])
    #plt.plot(spars,s,'b')
    plt.gca().invert_xaxis()

    plt.rcParams['text.usetex'] = True
    plt.rcParams['font.family'] = 'serif'
    plt.rcParams.update({'font.size': 20})
    plt.plot(spars,ut_all,'b--')
    plt.plot(spars,ut_all,'bo')
    #plt.gca().invert_xaxis()
    plt.xlabel('Effective Multiplications')
    plt.ylabel('Utilization')
    plt.grid(True)

    return plt


def plot_dilation(folder,col):
    utilization = []
    total_cycles = []
    ut_all = []
    print('fpga_out/'+folder+'/utilization/10-1-32-1-utilization.npy')
    try:
        with open('fpga_out/'+folder+'/utilization/10-1-32-1-utilization.npy','rb') as f:
            utilization.append(np.load(f))
            total_cycles.append(np.load(f))
            ut_all.append(np.load(f))
    except:
        total_cycles.append(1)
        ut_all.append(1)
        print("Did not find")


    parallel_pes = np.array([2**i for i in range(6)])
    for i in parallel_pes:
        try:
            with open('fpga_out/'+folder+'/utilization/10-'+str(i)+'-32-3-utilization.npy','rb') as f:
                utilization.append(np.load(f))
                total_cycles.append(np.load(f))
                ut_all.append(np.load(f))
        except:
                total_cycles.append(1)
                ut_all.append(1)
                print("Did not find")
    parallel_pes = parallel_pes * 3
    parallel_pes = np.insert(parallel_pes,0,1,axis=0)

    plt.figure(1,figsize=(15,8))
    plt.rcParams['text.usetex'] = True
    plt.rcParams['font.family'] = 'serif'
    plt.rcParams.update({'font.size': 20})
    plt.plot(parallel_pes,ut_all,col,linestyle = '--')
    print(ut_all)
    plt.xlabel('Number of PEs')
    plt.ylabel('PE Utilization')
    plt.grid(True)
    return plt


fol_dil = ['eff_mul_25_3','eff_mul_25','eff_mul_25_12','eff_mul_25_18']
for fol_dil, col in zip(fol_dil,color):

    plt0 = plot_dilation(fol_dil,col)

plt0.rc('legend')
plt0.legend(["rate=3","rate=6","rate=12","rate=18"])

plt0.tick_params(labelsize=20)



plt0.savefig("../thesis/BachelorThesis/figures/Results/diffrates.pdf")
plt0.show()
for fol,col in zip(folders,color):
    plt = plot_utilization(fol,col)


plt.rc('legend', fontsize=20)

str_leg = ["eff\_mul: %.2f"%i for i in real_spars]
plt.legend(str_leg)
#plt.rcParams.update({'font.size': 15})
#plt.tick_params(labelsize=14)

plt.savefig("../thesis/BachelorThesis/figures/Results/utilizationvsPE.pdf")
plt.show()

print(spars)

sparsity = plot_spars(folders,real_spars,8)
sparsity.rc('legend')

#sparsity.tick_params(labelsize=14)


#sparsity.rcParams.update({'font.size': 15})
sparsity.savefig("../thesis/BachelorThesis/figures/Results/utilvseffmult.pdf")
sparsity.show()
