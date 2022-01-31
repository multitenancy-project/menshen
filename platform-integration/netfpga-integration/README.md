#### NetFPGA Integration

(1) get Menshen repo, set some envs

```bash
git clone git@github.com:multitenancy-project/menshen.git /path/to/menshen

export LIB_RMT_PATH=/path/to/menshen/lib_rmt
export ONNETFPGA_PATH=/path/to/menshen/platform-integration/netfpga-integration

cd $ONNETFPGA_PATH/Tproj.src
ln -s $LIB_RMT_PATH ./lib_rmt_256b
```

(2) go to the integration folder to create the project

```bash
cd /path/to/menshen/platform-integration/netfpga-integration

make project
```



