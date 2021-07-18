#!/bin/sh


# List of files to be given if running a number of files #
file="$*"
filename="$(echo $file | cut -d '/' -f1|cut -d '.' -f1)" 

echo $filename

basedir=/hercules/scratch/tasha/GC_search/meerkat/TRAPUM/6652_1/all_search_old/$filename/

mkdir -p $basedir

cp -r /hercules/scratch/tasha/GC_search/meerkat/TRAPUM/6652_1/all_search_old/meerkat_search_main.cfg $basedir/meerkat_search.cfg

config=$basedir/meerkat_search.cfg
echo "config: "$config
echo -e "FILE_LIST_DATAFILES             $basedir/meerkat_search_list_datafiles.txt\n$(cat $config)" > $config
echo -e "FILE_COMMON_BIRDIES             $basedir/meerkat_search_common_birdies.txt\n$(cat $config)" > $config
echo -e "ROOT_WORKDIR                    $basedir\n$(cat $config)" > $config
echo $file > $basedir/meerkat_search_list_datafiles.txt
echo "" > $basedir/meerkat_search_common_birdies.txt

DMlistfile=${basedir}/LOG/DMlistfiles.txt
accelcheck_file=${basedir}/accel_check.txt


onlyrfifind_step=0
#tot_accel_nodes=52
timeseries_per_node=9      #CHANGE IT TO DM LIST total %52 (NUMBER OF NODES) I.E. THIS MANY TIMESERIES PER NODE, then 9 will run at a time from call_accel.py code. Put ampersand and wait on the call_accel submit command and have that inside another loop of x jobs (with outer loop of 52 jobs to be submitted just once) --> check the time limit needed and change here then.
tjobout=$basedir/tjob.out
tjoberr=$basedir/tjob.err

partition_step1=gpu.q
partition_step2=gpu.q
partition_step3=gpu.q

echo ${file##*/}

rm -rf ${basedir}/accel_check.txt
######################################################################################################################################################################################################
									# STEP0: TO RUN ONLY RFIFIND
######################################################################################################################################################################################################
if [ ${onlyrfifind_step} == 1 ]
then

	sbatch --gres=gpu:1 -J 1_${filename} --error=${tjoberr}.%j --output=${tjobout}.%j --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step1} --cpus-per-task=48 --mem=60GB --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /mkfs/00/GC/:/mkfs/00/GC/ -B /hercules/scratch/tasha/:/hercules/scratch/tasha/ -B /hercules/scratch/tasha/:/home/psr/work /scratch/vkrishna/singularity_images/presto_gpu_sm75-2021-04-11-1a925bfbf734.sif python /home1/scripts/jerk_v1_4.py -config ${config} -obs ${file}"
	echo "Step rfifind submitted!"
####################################################################################################################################################################################################
									# STEP1: RUN BIRDIES,DEDISPERSION
###################################################################################################################################################################################################
else

	RES=$(sbatch --gres=gpu:1 -J 1_${filename} --parsable --error=${tjoberr}.%j --output=${tjobout}.%j --time=5-00:00:00 --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step1} --cpus-per-task=48 --mem=60GB --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /mkfs/00/GC/:/mkfs/00/GC/ -B /hercules/scratch/tasha/:/hercules/scratch/tasha/ -B /hercules/scratch/tasha/:/home/psr/work /scratch/vkrishna/singularity_images/presto_gpu_sm75-2021-04-11-1a925bfbf734.sif python /home1/scripts/jerk_v1_4.py -config ${config} -obs ${file}")	

	echo "$RES"


	step1_jobid=${RES}
	export JOB_STEP1=`squeue -u tasha -n 1_${filename} | wc -l` ## MIGREV
	export QUEUE_STEP1=`squeue -u tasha -n 1_${filename} | grep 'PD' | wc -l`
	while (( ${JOB_STEP1} > 1 || ${QUEUE_STEP1} >1))
	do
	    echo still running job of step_1 ${JOB_STEP1}
	    sleep 5
	    export JOB_STEP1=`squeue -u tasha -n 1_${filename} | wc -l` ## MIGREV
	    export QUEUE_STEP1=`squeue -u tasha -n 1_${filename} | grep 'PD' | wc -l`
	done 
	wait

	echo "DMlistfile and Parameter file should have been created by now!!"

	#tot_timeseries="$(wc -l ${DMlistfile}| awk '{print $1}')"
	#timeseries_per_node="$(echo "$tot_timeseries / $tot_accel_nodes" | bc)"
	#echo "Tot accel nodes" $tot_accel_nodes
	#echo "TOT TIMESERIES" $tot_timeseries
	#echo "TOTAL NUMBER OF TIMESERIES IN A SINGLE NODE LIST FILE" $timeseries_per_node
##############################################################################################################################################################################################################
										# STEP2: TO RUN ACCELERATION AND JERK SEARCH USING CALL_ACCEL.PY ON DIFFERENT NODES
##############################################################################################################################################################################################################

	tmp=0
	#Taking 9 timeseries for accelsearch in each node

	while mapfile -t -n ${timeseries_per_node} ary && ((${#ary[@]}));
	do

		dmlist_files=${ary[@]}
		tmp=$(($tmp+1))
		#echo ${dmlist_files}
		
		sbatch --gres=gpu:3 --nodes=1 -J acl_${filename} --error=${tjoberr}.${tmp}.%j --output=${tjobout}.${tmp}.%j --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step2} --cpus-per-task=48 --mem=62000 --wrap="singularity exec --nv -H /hercules/scratch/tasha/:/home1 -B /mkfs/00/GC/:/mkfs/00/GC/ -B /hercules/scratch/tasha/:/hercules/scratch/tasha /scratch/vkrishna/singularity_images/presto_gpu_sm75-2021-04-11-1a925bfbf734.sif python /home1/scripts/call_accel_gpu.py -config ${config} -obs ${file} -infile ${dmlist_files}"		
		export JOBS=`squeue -u tasha| wc -l` ## MIGREV
		export QUEUE=`squeue -u tasha| grep 'PD' | wc -l`
		while (( ${JOBS} > 100 || ${QUEUE} > 100 ))
		do
			echo still queuing ${QUEUE} , sleep 10s
			sleep 10
			export JOBS=`squeue -u tasha | wc -l` ## MIGREV
			export QUEUE=`squeue -u tasha | grep 'PD' | wc -l`
		done


	done < ${DMlistfile}
	wait

	export JOBS_STEP2=`squeue -u tasha -n acl_${filename} | wc -l` ## MIGREV
	export QUEUE_STEP2=`squeue -u tasha -n acl_${filename} | grep 'PD' | wc -l`
	echo "FOR ACCELERATION SEARCH, SUBMITTED THIS MANY JOBS: ${JOBS_STEP2}"
	echo "This many in queue: ${QUEUE_STEP2}"
	while (( ${JOBS_STEP2} > 1 || ${QUEUE_STEP2} > 1 ))
	do
	    echo still running ${JOBS_STEP2} number of jobs
	    sleep 5
	    export JOBS_STEP2=`squeue -u tasha -n acl_${filename} | wc -l` ## MIGREV
	    export QUEUE_STEP2=`squeue -u tasha -n acl_${filename} | grep 'PD' | wc -l`
	    echo "This many in queue: ${QUEUE_STEP2}"
	done
	wait

	echo "Step 2 done!"
	echo "Acceleration search ran completely!" > ${accelcheck_file}

##############################################################################################################################################################################################################
										# STEP3: TO RUN SIFTING AND FOLDING FROM MAIN PIPELINE ON 1 NODE
##############################################################################################################################################################################################################

	sbatch --gres=gpu:1 -J 3_${filename} --error=${tjoberr}.%j --output=${tjobout}.%j --time=5-00:00:00 --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step3} --cpus-per-task=48 --mem=62000 --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /mkfs/00/GC/:/mkfs/00/GC/ -B /hercules/scratch/tasha/:/hercules/scratch/tasha/ -B /hercules/scratch/tasha/:/home/psr/work /scratch/vkrishna/singularity_images/presto_gpu_sm75-2021-04-11-1a925bfbf734.sif python /home1/scripts/jerk_v1_4.py -config ${config} -obs ${file}"

	echo "Step 3 submitted!"

fi
