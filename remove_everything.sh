#!/bin/bash

printf "Removing the folder agile_autonomy_ws..."
sudo rm -rf agile_autonomy_ws/
echo "Done"
printf "Removing the folder Open3D..."
sudo rm -rf Open3D/
echo "Done"
printf "Removing the folder docker_usr_local..."
sudo rm -rf docker_usr_local/
echo "Done"
printf "Removing the agile_autonomy_container..."
sudo docker rm -f agile_autonomy_container
echo "Done"
sudo docker container prune
sudo docker ps -a
echo "Done"
echo "If you see an empty table, then all folders and containers were removed succesfully."

