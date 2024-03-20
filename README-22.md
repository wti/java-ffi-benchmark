# Java 22 variant
- Code changed to track API's
- [run.sh](run.sh) updated to require JAVA_HOME, java reporting version of 22
- running takes some time
- working so far only in Linux
    - macOS native build fails seeking header for sysinfo

```
export JAVA_HOME=$HOME/dev/jdk22
./run.sh > run.out.txt 2>&1
```
Then

```
tail -f run.out.txt | sed -n '/Result/N;/Result/p' 
```
