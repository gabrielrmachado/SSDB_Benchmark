# SS-DB Benchmark
*A full Python script for running the SS-DB benchmark on SciDB and SAVIME array DBMS.*

## 1. Prerequisites
### 1.1. Installing SciDB 19.11

*Make sure you have already had SciDB installed in your Linux machine. If not, check in the [SciDB documentation](https://paradigm4.atlassian.net/wiki/spaces/scidb/pages/726958116/19.11+Release+Notes) to assure your Linux distro and version are compatible with SciDB before following the steps below.*

Open up the Linux terminal in the SciDB project folder and run the following command to install SciDB:

```bash
sudo bash install-scidb-ce.sh
```
The installation can take a while to be completed. If it is successful, you will see a message in terminal asking to add the SciDB installation folder to ```$PATH```. To do so in Ubuntu, type in the command ```nano ~/.bashrc```. Then, add the following two lines at the end of ```.bashrc``` and save it afterwards:

```bash
export SCI_DB=/opt/scidb/19.11/bin
export PATH=$PATH:$SCI_DB
```

After saving the file, source it by typing in terminal ```source ~/.bashrc```. Finally, check whether the path has been actually added in ```PATH``` by typing ```echo $PATH```. The installation, when finishes, uses to start the SciDB engine. However, it might be stopped after restarting the machine. In order to start SciDB, type in terminal the following command:

```bash
scidbctl.py start mydb
```
Now, SciDB is ready to receive commands and queries. By typing ```iquery -a``` in terminal, you are able to enter in the AFL console, which is responsible for processing the queries.  