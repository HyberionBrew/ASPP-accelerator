import numpy as np
with open('input_prunned.npy', 'rb') as f:
    ifmaps = np.load(f)
    scale_i = np.load(f)
    zero_point_ifmap = np.load(f)

with open('weights_prunned.npy', 'rb') as f:
    weights = np.load(f)
    scale_w = np.load(f)
    zero_points_kernels = np.load(f)

with open('outputs_prunned.npy', 'rb') as f:
    outs = np.load(f)
    scale_o = np.load(f)
    zero_points_out = np.load(f)

ins = np.ones(np.shape(ifmaps))
with open('input_prunned_dense.npy', 'wb') as f:
    np.save(f,ins)
    np.save(f,scale_i)
    np.save(f,0)
    
w = np.ones(np.shape(weights))
with open('weights_prunned_dense.npy','wb') as f:
    np.save(f,w)
    np.save(f,scale_w)
    np.save(f,0)


with open('outputs_prunned_dens.npy', 'wb') as f:
        np.save(f,outs)
        np.save(f,scale_o)
        np.save(f,0)

