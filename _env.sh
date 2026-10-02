DIR_SOC360=~/github/eisi/soc360

proj_back=$DIR_SOC360/soc360-back-java
proj_front=$DIR_SOC360/soc360-front-react

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
