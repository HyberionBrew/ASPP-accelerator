#!/usr/bin/python3
import numpy as np
import sys
import matplotlib.pyplot as plt
from bitstring import Bits

SLICE_SIZE = 64
ifmap_zeros = 0
ifmap_values = 0
kernel_zeros = 0
kernel_values = 0

ZERO_MULTS = 0

with open('input_prunned.npy', 'rb') as f:
    ifmaps = np.load(f)[0]
    scale_ifmap = np.load(f)
    zero_point_ifmap = np.load(f)
with open('outputs_prunned.npy', 'rb') as f:
    outs = np.load(f)
    scale_out = np.load(f)
    zero_points_out = np.load(f)

def calc_M(M,bits):
    M0 = M
    n= -1
    M_out = 0
    while M_out < 0.5:
        n = n + 1
        if M0 > 1:
            print("This should never happen M0 > 1")
            break
        M_out = M0 * 2**n
    return min(int(M_out*2**(bits-1)),(2**bits-1)-1),n #because int !not uint!


def calc_start_end(kernel,rate):
    start_ifmap = [0,0] #y,x
    end_ifmap = [33,33]
    start_psum = [0,0]
    end_psum = [33,33]
    if kernel < 3:
        start_psum[0] = rate
        end_ifmap[0] = 33-rate
    elif kernel > 5:
        start_ifmap[0] = rate
        end_psum[0] = 33-rate
    
    if kernel%3 == 0:
        end_ifmap[1] = 33-rate
        start_psum[1] = rate
    elif kernel%3 ==2:
        end_psum[1] = 33-rate
        start_ifmap[1] = rate
    return (start_ifmap,end_ifmap),(start_psum,end_psum)

ALL = 0
def calc_psum_kernel(kernel,ifmap_slice,weights,rate):
    ifmap, psum = calc_start_end(kernel,rate)
    result = np.zeros_like(ifmap_slice[0])
    psum_x = psum[0][0]
    psum_y = psum[0][1]
    global ZERO_MULTS
    global ALL
    for x in range(ifmap[0][0],ifmap[1][0]):
        for y in range(ifmap[0][1],ifmap[1][1]):
            result[psum_x,psum_y] = ifmap_slice[:,x,y]@weights    
            psum_y= psum_y+1

            non_zero = ifmap_slice[:,x,y]*weights 
            ZERO_MULTS += np.count_nonzero(non_zero)
            ALL += len(non_zero)
        psum_x = psum_x+1
        psum_y= psum[0][1]
    return result


def export_weights(weights,slice_size,parallel_ofm,max_ofms,filter_depth):
    kernel_zeros = 0
    kernel_values = 0
    zero_points_kernels = 0
    print("zero point kernel: "+ str(zero_points_kernels))
    file_des = open("../data/weights.data",'w')
    f = open("../data/kernels_mem.data",'w')
    for ofms in range(0,max_ofms,parallel_ofm):#for ofms in range(0,256,parallel_ofm):
        for filters in range(filter_depth):
            kernel = 4
            for y in range(0,3):
                for x in range(0,3):
                    for I in range(parallel_ofm):
                        for J in range(slice_size):
                            file_des.write(str(weights[I+ofms,filters*slice_size+J].flatten()[kernel])+ " ") 
    #                        print(weights[I+ofms,filters*slice_size+J].flatten()[kernel], end = " ")
                            f.write(str(Bits(int = int(weights[I+ofms,filters*slice_size+J].flatten()[kernel]),length = 8).bin))
                        if ((weights[I+ofms,filters*slice_size+J].flatten()[kernel])==0):
                            kernel_zeros = kernel_zeros + 1
     #                   print('\n')
                        kernel_values += 1
                        file_des.write('\n')
                        f.write('\n')
                    kernel = kernel + 1
                    if kernel == 9:
                        kernel = 0
    #add another line for the last one process
    for i in range(parallel_ofm):
        for y in range(slice_size):
           file_des.write(str(0)+ " ")
        file_des.write('\n')
    file_des.close()
    f.close()
    return kernel_zeros, kernel_values


def export_ifmaps_bram(slice_size,depth):
    ifmap_zeros = 0
    ifmap_values = 0
    with open('input_prunned.npy', 'rb') as f:
        ifmaps = np.load(f)[0]
        scale_ifmap = np.load(f)
        zero_point_ifmap = np.load(f)

    print("zero point ifmap: "+ str(zero_point_ifmap))
    f = open("../data/ifmaps_mem.data",'w')
    for filters in range(0,depth*slice_size,slice_size):
        for y in range(0,33):
            for x in range(0,33):
                i = 0
                for J in range(slice_size):
                    f.write(str(Bits(uint = int(ifmaps[filters+J,y,x]),length = 8).bin))
                for padd in range(8):
                    f.write(str(Bits(int = int(0),length = 8).bin))
                if (ifmaps[filters+J,y,x] == zero_point_ifmap):
                    ifmap_zeros += 1
                ifmap_values += 1
                f.write('\n')
    f.close()
    return ifmap_zeros,ifmap_values

def export_ifmaps(slice_size,depth):
    with open('input_prunned.npy', 'rb') as f:
        ifmaps = np.load(f)[0]
        scale_ifmap = np.load(f)
        zero_point_ifmap = np.load(f)

    f = open("../data/ifmaps_input.data",'w')
    for filters in range(0,depth*slice_size,slice_size):
        for y in range(0,33):
            for x in range(0,33):
                for J in range(slice_size):
                    f.write(str(ifmaps[filters+J,y,x])+ " ")
                for padd in range(8):
                    f.write(str(0)+ " ")
                f.write('\n')
    
    #add another line for the last one process
    for i in range(8):
        for y in range(0,slice_size):
            f.write(str(0)+ " ") 
        f.write('\n')
    f.close()




def calc_ofm(weights,slice_size,depth,ofm,rate): # is true
    result = np.zeros_like(ifmaps[0].astype(int))

    for i in range(0,depth*slice_size,slice_size):
        ifmap_slice = ifmaps[i:i+SLICE_SIZE].astype(int)-zero_point_ifmap    
        kernel = 0
        for kernel_x in range(3):
            for kernel_y in range(3):
                weights_slice = weights[ofm,i:i+SLICE_SIZE,kernel_x,kernel_y].astype(int)
                result = result + calc_psum_kernel(kernel,ifmap_slice,weights_slice,rate)
                kernel = kernel +1
    return result

def export_result(result,filename,op):
    f = open(filename,op)
    for y in range(33):
        for x in range(33):
            f.write(str(result[y,x].astype(int)))
            f.write(" ")
        f.write('\n')
    #f.write(" ")
    f.write('\n')
    f.close()

def calc_final(result,ofm,scale_weights):	
    M0 = (scale_ifmap * scale_weights[ofm]) / scale_out
    M,n = calc_M(M0,32) #param 2 does nothing literally 0 worth
    print(M)
    shift = n +31
    final = result * M
    final = final* 2**(-shift)
    final = np.round(final+zero_points_out)
    return final

def export_results(weights,slice_size,depth,ofms,scale_weights,rate):
    op = "w"
    for i in range(ofms):	
        result = calc_ofm(weights,slice_size,depth,i,rate)
        export_result(result,"../data/result/result_acc.data",op)
        result = calc_final(result,i,scale_weights)	
        export_result(result,"../data/result/result_final.data",op)
        op = "a"

#ofms does nothing doesnt matter
def export_scales(ofms,scale_weights):
    with open('input_prunned.npy', 'rb') as f:
        ifmaps = np.load(f)[0]
        scale_ifmap = np.load(f)
        zero_point_ifmap = np.load(f)

    with open('outputs_prunned.npy', 'rb') as f:
        outs = np.load(f)
        scale_out = np.load(f)
        zero_points_out = np.load(f)
    print("zero point out: "+ str(zero_points_out))
    M0 = (scale_ifmap * scale_weights) / scale_out
    M = np.zeros(M0.shape)
    shift = np.zeros(M0.shape)
    for i in range(len(M0)):
        M[i],n= calc_M(M0[i],32) #param 2 does nothing literally 0 worth
        shift[i] = n +31
    
    f = open('../data/scales.data','w')
    for i in range(len(shift)):
        f.write(str(Bits(int = int(M[i]),length = 32).bin))
        f.write('\n')
    f.close()

    f = open('../data/shift.data','w')
    for i in range(len(shift)):
        f.write(str(Bits(uint = int(shift[i]),length = 8).bin))
        f.write('\n')
    f.close()


def reorder_weights(SLICE_SIZE, depth, ofms, weights,scale_weights): 
    ordering = []
    for ofm in range(ofms):
    #    print("new ofm")

        var_l = []
        for ifmap in range(0,SLICE_SIZE*depth,SLICE_SIZE):
            item = 0

            for x in range(3):
                for y in range(3):
                    item += np.count_nonzero(weights[ofm,ifmap:ifmap+64,x,y]==0)
                    item /= 64 
            var_l.append(item)
        #print(min(var_l))
        ordering.append(min(var_l))
    print(sorted(ordering))

    fig, ax1 = plt.subplots(1, 1)

    ax1.bar([i for i in range(len(ordering))],ordering)

    ax1.grid(True)

    plt.show()



    weights_subs = weights[0:ofms]
    scale_weights_subs = scale_weights[0:ofms]
    ordering = np.array(ordering)
    arr1inds = ordering.argsort()
    weights_reorderd = weights_subs[arr1inds]
    scales_reorderd = scale_weights_subs[arr1inds]
    ordering = []
    for ofm in range(ofms):
    #    print("new ofm")

        var_l = []
        for ifmap in range(0,SLICE_SIZE*depth,SLICE_SIZE):
            item = 0

            for x in range(3):
                for y in range(3):
                    item += np.count_nonzero(weights_reorderd[ofm,ifmap:ifmap+64,x,y]==0)
                    item /= 64 
            var_l.append(item)
        #print(min(var_l))
        ordering.append(min(var_l))
    fig, ax1 = plt.subplots(1, 1)

    ax1.bar([i for i in range(len(ordering))],ordering)

    ax1.grid(True)

    plt.show()
    return weights_reorderd, scales_reorderd

def calculate_ops_ideal(rate,depth,ofmaps,valid):
    res = 33*33*64*depth*ofmaps #middle
    res += (33-rate)*(33-rate)*64*depth*ofmaps*4#edges
    res += (33-rate)*33*64*depth*ofmaps*4#outer middles
    return res * valid


def export(args):
    depth = int(args[1])
    parallel_ofms = int(args[2])
    ofms = int(args[3])
    rate = int(args[4])

    print("depth="+str(depth))
    print("OFMS="+str(ofms))
    print("parallel="+str(parallel_ofms))
    print("Exporting weights") 
    with open('weights_prunned.npy', 'rb') as f:
        weights = np.load(f)
        scale_weights = np.load(f)
        zero_points_kernels = np.load(f)
    
    if args[5] == "True":
        weights, scale_weights = reorder_weights(SLICE_SIZE, depth, ofms, weights,scale_weights)
        print("Reordering weights & OFMs")
        
    w_zeros, w_values = export_weights(weights,SLICE_SIZE,parallel_ofms,ofms,depth)
    print("Exporting ifmaps") 
    export_ifmaps(SLICE_SIZE,depth)
    print("Exporting Scales")
    if_zeros, if_values=export_ifmaps_bram(SLICE_SIZE,depth)
    export_scales(ofms,scale_weights)
    print("Exporting Results")
    export_results(weights,SLICE_SIZE,depth,ofms,scale_weights,rate)
    print("Ifmap zeros")
    print(if_zeros/if_values)
    print("kernel zeros")
    print(w_zeros/w_values)
    print("Finished")
    print("Zero multiplications")
    print(ZERO_MULTS/ALL)
    print(ALL)
    print(calculate_ops_ideal(rate,depth,ofms,1))
if __name__ == '__main__':

    export(sys.argv)	
