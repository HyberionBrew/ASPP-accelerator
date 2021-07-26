# Introduction

This repository presents a VHDL-based neural network accelerator for atrous convolution. The accelerator is intended as a demonstration accelerator for atrous convolution with dynamic sparsity. For more information see the thesis contained in the repository. The output data from the fpga can be downloaded here: https://drive.google.com/file/d/1a3uyqQnyPQJ8WL4JJ-ioAksY3RZSXt8L/view?usp=sharing 

# Running the accelerator

First the modified model of DeepLabv3 needs to be run in order to extract ifmap inputs, filters and ofmaps of the ASPP layer.
This is done by executing the `deepLabv3main.py` script in the deeplabv3 directory.

The script is based on [1]. In order to run the script some setup is needed as described in [1].

Once the setup is completed for the Pascal VOC trainaug dataset the modified script can be run as follows:

```
$ python deepLabv3main.py --model deeplabv3_resnet101 --crop_val --ckpt model/best_deeplabv3_resnet101_voc_os16.pth --year 2012_aug --batch_size 16 --extract_values
```

This will run the model and will create some files in the local data folder. One of each file type (input, output, weights) needs to be placed in the `scripts` folder and needs to be renamed to `input_prunned.npy`, `outputs_prunned.npy` and `weights_prunned.npy`.

Next the `export_data.py` script can be executed. The calling interface looks as follows:
```
$ export_data.py [IFMAP_DEPTH/64] [PARALLEL_OFMS] [OFMS] [RATE] [REORDERED]
```

Importantly, the ifmap depth will be multiplied by 64. An example call with 640 ifmap channels, 32 parallel ofmap channels, 32 ofmap channels, an atrous rate of 6 and no re-ordering of the ofmap channels:

```
$ python export_data.py 10 32 32 6 false
```

Next, the provided source files need to be synthesis & implemented in Vivado 2021.2. For this it is necessary to create an UART and clock from the design libraries (both at 100Mhz). Once the bitstream is created it can be uploaded to the FPGA.

In order to catch the output of the FPGA over UART miniterm [2] can be utilized:

```
$ sudo miniterm --raw [port] | tee output.data
```

The resulting output file `output.data` needs to be post-processed by the `convert_to_result.py` script:


```
$ python convert_to_result.py output.data [IFMAP_DEPTH/64] [PARALLEL_OFMS] [OFMS] [PE_COLUMNS] [REORDERED]
```

This yields a `...-processed.data` file which contains the transformed outputs. This file should be equivalent to the results file yielded by running the `export_data.py` script.


[1] https://github.com/VainF/DeepLabV3Plus-Pytorch

[2] https://pyserial.readthedocs.io/en/latest/tools.html
