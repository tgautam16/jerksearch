# JERK SEARCH PIPELINE

A faster parallelised jerksearch pipeline usable in MPIFR's hercules cluster based on A. Ridolfi's PULSAR_MINER code
JERK SEARCH PIPELINE V1.3 (this version does not includ MPI_PREPSUBBAND and includes only cpu based accelsearch + cpu based jerksearch), for a version with MPI_PREPSUBBAND use v1.4:
Requirements: Singularity image including PRESTO,TEMPO,PSRCHIVE

You run the pipeline by doing ‘source submission.sh’

0) Required files needed in the working directory are:
 Submission.sh,*.cfg, *_common_birdies.txt (you can leave it empty, or add frequencies you want to zap), *_list_datafiles.txt( include name of the data file to search)

Firstly, to run rfifind: put only_rfifind=1 flag in submission.sh and make other flags except rfifind one in *.cfg file = 0
All the parameters and file directories in *.cfg file must be set accordingly
After a good mask is created, put only_rfifind=0 and make other flags in *.cfg file = 1 to run the full script
You can find all the results in 05_FOLDING folder

-To make it work, you would need a call_accel.py in the python path (already in my directory if you are running in hercules)
-A submission script.sh which will one by one first run usual pipeline till dedispersion, then call 'call_accel.py' to run acceleration search on individual nodes of the cluster and then will again call the pipeline to do final steps of sifting and folding on a single node.
-A file called accel_check.txt will also be produced in base directory by call_accel.py to confirm that it ran completely, to check manually run find . -name "*.err" -type f ! -size 0 in the 03_DEDISPERSION folder and check if any error files are produced

-Two files named DMlistfile.txt and parametersfile.txt (no longer needed though) will also be produced in the LOG directory by the first run of the pipeline(i.e. In first step)

JERK SEARCH PIPELINE V1.4 (mainly for 300 beams of TRAPUM survey) (this version includes MPI_PREPSUBBAND and gpu based accelsearch + cpu based jerksearch):
You run the pipeline by doing ‘source submission.sh’

0) Required files needed in the working directory are:
 Submission.sh,*.cfg, *_common_birdies.txt (you can leave it empty, or add frequencies you want to zap), *_list_datafiles.txt( include name of the data file to search)

Once good mask parameters are created by following method above (which can be done for a single beam) (others can take the same mask parameters)
Put only_rfifind=0 in submission.sh file and make other flags in *.cfg file = 1 to run the full script
You can find all the results in 05_FOLDING folder

-To make it work, you would need a call_accel.py in the python path (already in my directory if you are running in hercules)
-A submission script.sh which will one by one first run usual pipeline till dedispersion, then call 'call_accel.py' to run acceleration search on individual nodes of the cluster and then will again call the pipeline to do final steps of sifting and folding on a single node.
-A file called accel_check.txt will also be produced in base directory by call_accel.py to confirm that it ran completely, to check manually run find . -name "*.err" -type f ! -size 0 in the 03_DEDISPERSION folder and check if any error files are produced

-Two files named DMlistfile.txt and parametersfile.txt (no longer needed though) will also be produced in the LOG directory by the first run of the pipeline(i.e. In first step)



Contact me at tgautam@mpifr-bonn.mpg.de for doubts/suggestions.
