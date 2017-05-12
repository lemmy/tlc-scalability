# tlc-scalability


provision.sh provisions an EC2 instance. It is passed as userdata to AWS. Examples can be found in the header.

Each folder contains the measurements and auxiliary scripts of a scalability experiment: 
- txt files include /bin/time information and stdout/stderr of each run
- .jfr files are bzip2 and can be opened with [Java Mission Control](http://www.oracle.com/technetwork/java/javaseproducts/mission-control/java-mission-control-1998576.html). A .jfr file is a "flight recording" of JVM and TLC performance counters of each run
- csv.sh parses the txt files and extracts scalability measurements. Output can be imported into R
- measure.sh and measureFPSet.sh are the scripts to launch an experiment. The master scripts can be found in the [TLC repository](https://github.com/tlaplus/tlaplus/tree/master/general/performance)
- patch.diff shows changes of the TLC code, which were active during an experiment
