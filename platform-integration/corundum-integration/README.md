#### Corundum Integration

(1) get Corundum and Menshen repos, set some envs

```bash
git clone git@github.com:multitenancy-project/menshen.git /path/to/menshen

export LIB_RMT_PATH=/path/to/menshen/lib_rmt

git clone git@github.com:corundum/corundum.git /path/to/corundum
cd /path/to/corundum
git checkout b140d736604d954266626c941df138c486e5cc48
```

(2) apply Menshen's patches to Corundum

```bash
cp /path/to/menshen/*.patch /path/to/corundum
patch -p0 --ignore-whitespace -i corundum-au250.patch
patch -p0 --ignore-whitespace -i corundum-modules.patch
patch -p0 --ignore-whitespace -i corundum-utils.patch
```

(3) go to the AU250 100g folder to create the project

```bash
cd /path/to/corundum/fpga/mqnic/AU250/fpga_100g
ln -s $LIB_RMT_PATH ./lib_rmt

make all
```



