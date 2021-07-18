#!/bin/sh

tjobout=/hercules/scratch/tasha/GC_search/gmrt_imaging_search/2MS-GC01/search/tjob.out
tjoberr=/hercules/scratch/tasha/GC_search/gmrt_imaging_search/2MS-GC01/search/tjob.err
partition_step1=parallel.q
partition_step2=parallel.q
partition_step3=parallel.q
config=/home1/GC_search/gmrt_imaging_search/2MS-GC01/search/gmrt_search.cfg
file=/home1/GC_search/gmrt_imaging_search/2MS-GC01/data/gpt_file/2MS_GC01_gpt.fil
basedir=/hercules/scratch/tasha/GC_search/gmrt_imaging_search/2MS-GC01/search/
DMlistfile=${basedir}/LOG/DMlistfiles.txt
accelcheck_file=${basedir}/accel_check.txt
echo ${file##*/}
rm -rf ${basedir}/accel_check.txt


onlyrfifind_step=0
timeseries_per_node=9
######################################################################################################################################################################################################
									# STEP0: TO RUN ONLY RFIFIND
######################################################################################################################################################################################################
if [ ${onlyrfifind_step} == 1 ]
then

	sbatch -J 1_${file##*/} --error=${tjoberr}.%j --output=${tjobout}.%j --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step1} --cpus-per-task=48 --mem=60GB --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /hercules/scratch/tasha/:/home/psr/work /hercules/scratch/tasha/docker_sing_imgs/prestonew5-2019-09-30-5cd93e04bd30.simg python /home1/scripts/jerk_v1_3.py -config ${config} -obs ${file}"
	echo "Step rfifind submitted!"
####################################################################################################################################################################################################
									# STEP1: RUN BIRDIES,DEDISPERSION
###################################################################################################################################################################################################
else

	RES=$(sbatch -J 1_${file##*/} --parsable --error=${tjoberr}.%j --output=${tjobout}.%j --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step1} --cpus-per-task=28 --mem=60GB --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /hercules/scratch/tasha/:/home/psr/work /hercules/scratch/tasha/docker_sing_imgs/prestonew5-2019-09-30-5cd93e04bd30.simg python /home1/scripts/jerk_v1_3.py -config $config -obs $file")
	#echo "$RES"


	step1_jobid=${RES}
	export JOB_STEP1=`squeue -u tasha -n 1_${file##*/} | wc -l` ## MIGREV
	export QUEUE_STEP1=`squeue -u tasha -n 1_${file##*/} | grep 'PD' | wc -l`
	while (( ${JOB_STEP1} > 1 || ${QUEUE_STEP1} >1))
	do
	    echo still running job of step_1 ${JOB_STEP1}
	    sleep 5
	    export JOB_STEP1=`squeue -u tasha -n 1_${file##*/} | wc -l` ## MIGREV
	    export QUEUE_STEP1=`squeue -u tasha -n 1_${file##*/} | grep 'PD' | wc -l`
	done 
	wait

	echo "DMlistfile and Parameter file should have been created by now!!"



##############################################################################################################################################################################################################
										# STEP2: TO RUN ACCELERATION AND JERK SEARCH USING CALL_ACCEL.PY ON DIFFERENT NODES
##############################################################################################################################################################################################################

	tmp=0
	#Taking 9 timeseries for accelsearch in each node

	while mapfile -t -n ${timeseries_per_node} ary && ((${#ary[@]}));
	do

		dmlist_files=${ary[@]}
		tmp=$(($tmp+1))
		echo ${dmlist_files}

		sbatch --nodes=1 -J acl_${file##*/} --error=${tmp}.%j.err --output=${tmp}.%j.out --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step2} --cpus-per-task=48 --mem=62000 --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /hercules/scratch/tasha/:/home/psr/work /hercules/scratch/tasha/docker_sing_imgs/prestonew5-2019-09-30-5cd93e04bd30.simg python /home1/scripts/call_accel.py -config ${config} -obs ${file} -infile ${dmlist_files}"

		export JOBS=`squeue -u tasha | wc -l` ## MIGREV
		export QUEUE=`squeue -u tasha| grep 'PD' | wc -l`
		while (( ${JOBS} > 700 || ${QUEUE} > 700 ))
		do
			echo still queuing ${QUEUE} , sleep 10s
			sleep 10
			export JOBS=`squeue -u tasha | wc -l` ## MIGREV
			export QUEUE=`squeue -u tasha | grep 'PD' | wc -l`
		done


	done < ${DMlistfile}
	wait

	export JOBS_STEP2=`squeue -u tasha -n acl_${file##*/} | wc -l` ## MIGREV
	export QUEUE_STEP2=`squeue -u tasha -n acl_${file##*/} | grep 'PD' | wc -l`
	echo "FOR ACCELERATION SEARCH, SUBMITTED THIS MANY JOBS: ${JOBS_STEP2}"
	echo "This many in queue: ${QUEUE_STEP2}"
	while (( ${JOBS_STEP2} > 1 || ${QUEUE_STEP2} > 1 ))
	do
	    echo still running ${JOBS_STEP2} number of jobs
	    sleep 5
	    export JOBS_STEP2=`squeue -u tasha -n acl_${file##*/} | wc -l` ## MIGREV
	    export QUEUE_STEP2=`squeue -u tasha -n acl_${file##*/} | grep 'PD' | wc -l`
	    echo "This many in queue: ${QUEUE_STEP2}"
	done
	wait

	echo "Step 2 done!"
	echo "Acceleration search ran completely!" > ${accelcheck_file}

##############################################################################################################################################################################################################
										# STEP3: TO RUN SIFTING AND FOLDING FROM MAIN PIPELINE ON 1 NODE
##############################################################################################################################################################################################################

	sbatch -J 3_${file##*/} --error=${tjoberr}.%j --output=${tjobout}.%j --mail-user=tgautam@mpifr-bonn.mpg.de --partition=${partition_step3} --cpus-per-task=48 --mem=62000 --wrap="singularity exec -H /hercules/scratch/tasha/:/home1 -B /hercules/scratch/tasha/:/home/psr/work /hercules/scratch/tasha/docker_sing_imgs/prestonew5-2019-09-30-5cd93e04bd30.simg python /home1/scripts/jerk_v1_3.py -config ${config} -obs ${file}"

	echo "Step 3 submitted!"

fi
