#!/bin/bash

unzip xapp1151_Param_CAM.zip
cp -r xapp1151_cam_v1_1/src/vhdl ./lib_rmt/xilinx_cam

cd ./lib_rmt
patch -p0 --ignore-whitespace -i cam.patch
