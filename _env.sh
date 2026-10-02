DIR_SOC360_EISI_GITHUB=~/github/eisi/soc360
DIR_SOC360_EISI_BITBUCKET=~/bitbucket/soc360
DIR_SOC360_MZA_GITHUB=~/github/mza/soc360

DIR_SOC360=$DIR_SOC360_EISI_GITHUB

proj_back=$DIR_SOC360/soc360-back-java
proj_front=$DIR_SOC360/soc360-front-react


function getProjsSoc360Dev() {
	echo "soc360-doc soc360-front-react soc360-back-java"
}

function save_projs_soc360(){
	local comment=$*
	[ "$comment" == "" ] && { 
		comment="save $(date_now.sh)" 
		echo "comment is empty, use : $comment
			Ctrl+C pour arreter
		"
		read zz 
	}
	cd $DIR_SOC360
	local projs=$(getProjsSoc360Dev)

	save_projs -m "$comment" $projs

  }

function deploy_projs_soc360() {
	cd $DIR_SOC360
	local projs=$(getProjsSoc360Dev)
	for p in $projs; do 
		[ -d "$p" ] && {
			cd "$p"
			pwd 
			deploy_proj
			cd -
		} || {
			echo "
			$p IS NOT DIR !!!
			====================================
			"
		}
	done
}


function save_projs_soc360_mza() {
	local comment=$*
	[ "$comment" == "" ] && { 
		comment="save $(date_now.sh)" 
		echo "comment is empty, use : $comment
			Ctrl+C pour arreter
		"
		read zz

	}

	GIT_DIR=~/github/eisi/soc360
	local GIT_DIST=~/github/mza/soc360

	log "
		copy to mza : 
	"

	copy_rsync "$GIT_DIR/soc360-back-java/" "$GIT_DIST/soc360-back-java/"

	copy_rsync "$GIT_DIR/soc360-front-react/" "$GIT_DIST/soc360-front-react/"

	pwd 

	log "
		commit proj mza java ...
	"

	cd "$GIT_DIST/soc360-back-java/"
	pwd 
	git add . && git commit -m "$comment" && git push 

	log "
		commit proj mza react ...
	"

	cd "$GIT_DIST/soc360-front-react/"
	pwd 
	git add . && git commit -m "$comment" && git push 

}


function save_projs_soc360_bitbucket() {
	local comment=$*
	[ "$comment" == "" ] && { 
		comment="save $(date_now.sh)" 
		echo "comment is empty, use : $comment
			Ctrl+C pour arreter
		"
		read zz

	}

	GIT_DIR=~/github/eisi/soc360
	BITBUCKET_DIR=~/bitbucket/soc360

	log "
		copy to bitbucket : 
	"

	copy_rsync "$GIT_DIR/soc360-back-java/" "$BITBUCKET_DIR/soc360-back-java/"

	copy_rsync "$GIT_DIR/soc360-front-react/" "$BITBUCKET_DIR/soc360-front-react/"

	pwd 

	log "
		commit proj bitbucket java ...
	"

	cd "$BITBUCKET_DIR/soc360-back-java/"
	pwd 
	git add . && git commit -m "$comment" && git push 

	log "
		commit proj bitbucket react ...
	"

	cd "$BITBUCKET_DIR/soc360-front-react/"
	pwd 
	git add . && git commit -m "$comment" && git push 

}

function sdsoc360() {
	local comment=$*
	[ "$comment" == "" ] && { 
		comment="save $(date_now.sh)" 
		echo "comment is empty, use : $comment
			Ctrl+C pour arreter
		"
		read zz

	}
	save_projs_soc360 "$comment" && deploy_projs_soc360

	echo "
		end minimal of : $0 $* 
		$(date_now.sh)
	"

	save_projs_soc360_bitbucket "$comment"

	save_projs_soc360_mza "$comment"

	echo "
		end all 
		$0 $* 
		$(date_now.sh)
	"
}

function todoSoc360(){
	cd ~/github/eisi/soc360/soc360-doc/
	local i=1
	local isContinue=true
	while $isContinue ; do 
		local f="01_TODO_$(getNumber00 $i)"
		[ -f $f ] && {
			((i++))
		} || {
			echo "
				f : $f
			"
			isContinue=false
			vi $f 
			cat $f
			break;
		}

	done 
}

soc360_start_back() {
  cd $proj_back
  ./run_dev.sh
}

soc360_start_front() {
  cd $proj_front
  ./run_dev.sh
}

echo "
    soc360_start_back

    soc360_start_front

    cd_soc360
    todoSoc360
    sdsoc360  

"
