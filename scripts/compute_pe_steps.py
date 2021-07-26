import numpy as np
import sys
from bitstring import Bits

def calc_M(M,bits):
    M0 = M
    n = -1
    M_out = 0
    while M_out < 0.5:
        n = n + 1
        if M0 > 1:
            print("This should never happen M0 > 1")
            break
        M_out = M0 * 2**n
    return min(int(M_out*2**(bits-1)),(2**bits-1)-1),n #because int !not uint!


def generateBitvec(data):
    bitvec = np.ones_like(data)
    for i,elem in enumerate(data):
        if elem == 0:
            bitvec[i] = 0
    return np.flip(bitvec)

def export_weights(slice_size,parallel_ofm,weights,max_ofms,filter_depth):
    f = open("data/weights_int.txt",'w')
    for ofms in range(0,max_ofms,parallel_ofm):#for ofms in range(0,256,parallel_ofm):
        print(ofms)
        for filters in range(0,filter_depth,slice_size):
            print("Exporting Filters")
            print(filters)
            kernel = 4
            for y in range(0,3):
                for x in range(0,3):
                    for I in range(parallel_ofm):
                        for J in range(slice_size):
                            f.write(str(weights[I+ofms,filters+J].flatten()[kernel])+ " ") 
                        f.write('\n')
                    kernel = kernel + 1
                    if kernel == 9:
                        kernel = 0
    f.close()
"""
@brief should be working! has a padding of 8 per 64 values i.e. an utilization of 64/72=0.88
"""
def export_ifmaps(slice_size,ifmaps):
    f = open("ifmaps_int.txt",'w')
    for filters in range(0,2048,slice_size):
        for y in range(0,33):
            for x in range(0,33):
                for J in range(slice_size):
                    f.write(str(ifmaps[filters+J,y,x])+ " ")
                for padd in range(8):
                    f.write(str(0)+ " ")
                f.write('\n')
    f.close()



def convDilated(ifmap, kernel, rate):
    padded_ifmap = np.zeros((ifmap.shape[0]+rate*2, ifmap.shape[1]+rate*2))
    result = np.zeros((ifmap.shape[0]+rate*2, ifmap.shape[1]+rate*2))
    padded_ifmap[rate:-rate,rate:-rate] = ifmap
    kernel_indices =np.array([(-rate,-rate),(0,-rate),(rate,-rate),(-rate,0),(0,0),(rate,0),(-rate,rate),(0,rate),(rate,rate)])
    kernel = kernel.flatten()
    for x in range(rate,ifmap.shape[0]+rate):
        for y in range(rate,ifmap.shape[0]+rate):
            for i,weight in enumerate(kernel):
                x_offs = kernel_indices[i][0]
                y_offs = kernel_indices[i][1]
                
                result[y][x] = result[y][x] + weight * padded_ifmap[y+y_offs][x + x_offs]
            #break
        #break
    return result[rate:-rate,rate:-rate]




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

def calc_psum_kernel(kernel,ifmap_slice,weights,rate):
    ifmap, psum = calc_start_end(kernel,rate)
    result = np.zeros_like(ifmap_slice[0])
    psum_x = psum[0][0]
    psum_y = psum[0][1]
    for x in range(ifmap[0][0],ifmap[1][0]):
        for y in range(ifmap[0][1],ifmap[1][1]):
            result[psum_x,psum_y] = ifmap_slice[:,x,y]@weights    
            psum_y= psum_y+1
        psum_x = psum_x+1
        psum_y= psum[0][1]
    return result

def export_result(result,filename):
    f = open(filename,'w')
    for y in range(33):
        for x in range(33):
            f.write(str(result[y,x]))
            f.write(" ")
        f.write('\n')
    f.close()




def check_outs(ifmaps,weights,DEPTH,SLICE_SIZE,zero_point_ifmap,ofm): # is true
    result = np.zeros_like(ifmaps[0].astype(int))

    for i in range(0,DEPTH,SLICE_SIZE):
        ifmap_slice = ifmaps[i:i+SLICE_SIZE].astype(int)-zero_point_ifmap    
        kernel = 0
        
        for kernel_x in range(3):
            for kernel_y in range(3):
                weights_slice = weights[ofm,i:i+SLICE_SIZE,kernel_x,kernel_y].astype(int)
                print(weights_slice)
                result = result + calc_psum_kernel(kernel,ifmap_slice,weights_slice,1)
                print("kernel: " +str(kernel))
                print(result[0,0])
                kernel = kernel +1
    print(result)
    print("final")
   # export_result(result,"result_from_acc.data")
    M0 = (scale_ifmap * scale_weights[0]) / scale_out
    M,n = calc_M(M0,32) #param 2 does nothing literally 0 worth
    shift = n +31
    final = result * M
    final = final* 2**(-shift)
    final = np.round(final+zero_points_out)
    print(final)
   # export_result(final.astype(int),"final_resul.data")
    """
    M,n = calc_M(M0,32) #param 2 does nothing literally 0 worth
    shift = n +31

    ff = -1296 * M    
    print("M [0]")
    print(M)
    print(ff)
    ff = ff* 2**(-shift)
    
    #print(final)
    ff = np.round(ff+zero_points_out)
    print("yyyyyyyyyyyyyyyyyyyyyyyyyy")
    print(ff)
   # print(outs[0,0])
   # print(final == outs[0,0])
    """
def export_scales(scale_weights,scale_ifmap,scale_out, zero_points_out):
    print(scale_weights)
    M0 = (scale_ifmap * scale_weights) / scale_out
    M_0 = (scale_ifmap * scale_weights[0]) / scale_out
    M = np.zeros(M0.shape)
    shift = np.zeros(M0.shape)
    for i in range(len(M0)):
        M[i],n= calc_M(M0[i],32) #param 2 does nothing literally 0 worth
        shift[i] = n +31
    
    f = open('data/scales.data','w')
    for i in range(len(shift)):
        f.write(str(Bits(int = int(M[i]),length = 32).bin))
        f.write('\n')
    f.close()

    f = open('data/shift.data','w')
    for i in range(len(shift)):
        f.write(str(Bits(uint = int(shift[i]),length = 8).bin))
        f.write('\n')
    f.close()



with open('input_prunned.npy', 'rb') as f:
    ifmaps = np.load(f)[0]
    scale_ifmap = np.load(f)
    zero_point_ifmap = np.load(f)

with open('weights_prunned.npy', 'rb') as f:
    weights = np.load(f)
    scale_weights = np.load(f)
    zero_points_kernels = np.load(f)

with open('outputs_prunned.npy', 'rb') as f:
    outs = np.load(f)
    scale_out = np.load(f)
    zero_points_out = np.load(f)




#check for weight 0
#np.set_printoptions(threshold=sys.maxsize)
#print(weights.shape)

#new data flow
#np.set_printoptions(threshold=sys.maxsize)
#data = []
#bitvec = []
#weight_slice = weights[0,0:64,0]  #first 64 w0s of ofmap 0 
#print((len(weights.flatten())-np.count_nonzero(weights.flatten()))/len(weights.flatten()))
#print(weights[0,0:64,0,0])
#print(weights[1,0:64,0,0])
#print(weights[2,0:64,0,0])
#print(weights[0,64:64+64,0,0])
SLICE_SIZE = 64 

ifmap_slice = ifmaps[0:SLICE_SIZE].astype(int)-zero_point_ifmap      #zero_point_ifmap
result = np.zeros_like(ifmaps[0].astype(int))
#export_ifmaps(64,ifmaps) #exports all ifmaps and should work flawlessly
#weights[0,0,2,1] = 0

#export_ifmaps(64,ifmaps)
check_outs(ifmaps,weights,SLICE_SIZE,SLICE_SIZE,zero_point_ifmap,0) # is true
i= 0
#for y in range(3):
#    for x in range(3):
#        weights_slice = weights[0,0:64,y,x].astype(int)
#        print(i)
#        print(weights_slice)
#        i = i+1
ifmap_slice = ifmaps[0:64].astype(int)-zero_point_ifmap    

kernel = 4
weights_slice = weights[0,0:64,1,1].astype(int)


"""
print("first weights")
print(weights_slice)
print("ifmap_slice:")
print(ifmap_slice+zero_point_ifmap)
xx = calc_psum_kernel(kernel,ifmap_slice,weights_slice,6)
print(xx)
print("------------------------")
kernel = kernel+1
weights_slice = weights[0,0:64,1,2].astype(int)
xx = xx + calc_psum_kernel(kernel,ifmap_slice,weights_slice,6)
print(xx)
print("------------------------")
kernel = kernel+1
ifmap_slice = ifmaps[0:64].astype(int)-zero_point_ifmap    
weights_slice = weights[0,0:64,2,0].astype(int)
xx = xx + calc_psum_kernel(kernel,ifmap_slice,weights_slice,6)
print(xx)
print("------------------------")
kernel = kernel+1
weights_slice = weights[0,0:64,2,1].astype(int)
xx = xx + calc_psum_kernel(5,ifmap_slice,weights_slice,6)
print(xx)
#check_outs(ifmaps,weights,SLICE_SIZE,SLICE_SIZE,zero_point_ifmap,3) # is true
print("XXXXXX")
weights_slice = weights[0,0:64,1,2].astype(int)
print(weights_slice)
weights_slice = weights[0,0:SLICE_SIZE,1,1].astype(int)
print(weights_slice)

print(ifmap_slice[0:SLICE_SIZE,0,0])
print(ifmap_slice[0:SLICE_SIZE,0,0]+43)
print(ifmap_slice[0:SLICE_SIZE,0,0]*weights_slice)
result2 = calc_psum_kernel(4,ifmap_slice,weights_slice,6)
print(result2)
#export_weights(SLICE_SIZE,3,weights,9,SLICE_SIZE)
print("--------")
weights_slice = weights[0,0:SLICE_SIZE,1,2].astype(int)
print(weights_slice)

print(ifmap_slice[0:SLICE_SIZE,0,0])
print(ifmap_slice[0:SLICE_SIZE,0,0]+43)
print(ifmap_slice[0:SLICE_SIZE,0,0]*weights_slice)
result2 = calc_psum_kernel(5,ifmap_slice,weights_slice,6)
print(result2)

#export_scales(scale_weights,scale_ifmap,scale_out,zero_points_out)
"""
"""
kernel = 4
print(weights_slice)
print("ifs:")
print(ifmap_slice[:,32,32])
print(ifmap_slice[:,32,32]+43)
x = weights_slice*ifmap_slice[:,32,32]
print(x)
print(sum(x))
"""
#write_result_to_file(result)

#ifmap values 
#same
"""
result = np.zeros_like(ifmaps[0].astype(int))
for i in range(64):
    result = result + convDilated(ifmap_slice[i],weights[0,i],rate = 6)
#export_weights(64,3,weights,3)

data.append(weight_slice)
data.append(ifmap_slice)
bitvec.append(generateBitvec(weight_slice))
bitvec.append(generateBitvec(ifmap_slice-zero_point_ifmap))
print(weight_slice)
print(generateBitvec(weight_slice))
print(generateBitvec(ifmap_slice-zero_point_ifmap))
print("-------")
print(ifmap_slice-zero_point_ifmap)
print(weight_slice)
x = (ifmap_slice-zero_point_ifmap)*weight_slice
print(x)
print(sum(x))
f = open("../test_PE/data/bitvecs_pe_test.txt",'w')
for i,slice_data in enumerate(data):
    for elem in slice_data:
        f.write(str(elem)+ " ")
    for elem in bitvec[i]:
        f.write(str(elem))
    f.write(" "+ str(zero_point_ifmap))
    f.write('\n')
"""

























