
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_705b

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {705} \
    CONFIG.Input_Depth {512} \
    CONFIG.Output_Data_Width {705} \
    CONFIG.Output_Depth {512} \
    CONFIG.Data_Count_Width {9} \
    CONFIG.Write_Data_Count_Width {9} \
    CONFIG.Read_Data_Count_Width {9} \
    CONFIG.Full_Threshold_Assert_Value {511} \
    CONFIG.Full_Threshold_Negate_Value {510} \
    CONFIG.Empty_Threshold_Assert_Value {4} \
    CONFIG.Empty_Threshold_Negate_Value {5}\
] [get_ips fifo_generator_705b]