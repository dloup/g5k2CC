# g5k2CC
This script allow you to port Grid'5000 images to Chameleon.
It needs a Grid'5000 images in qcow2 or tgz as input, and will give a qcow2 that can be uploaded and deployed on Chameleon Cloud.

## Requirement
This scripts need guestfish (for virt-customize command)
``` 
apt-get install libguestfs-tools
```
## Usage
```
bash g5k2CC.sh [ubuntu|debian] [source_image] (optional)[output_name]
```
When the convertion is complet, you can upload the image to Chameleon using
```
glance image-create --name g5k_image --disk-format qcow2 --container-format bare --file out.qcow2
```
## Tip : Getting Grid'5000 images
Copying `source_image` from Grid'5000 to your local machine or your Chameleon node can be very long depending on the image size and the connection speed.
It may be a good idea to deploy a Debian image on a Chameleon node, and regenerate the `source_image` locally instead of copying it with `scp` or `rsync` from Grid'5000 servers.

The following commands will:
* Clone the Grid'5000 images recipes repository
* Install Kameleon, the Grid'5000 image generator
* mount a tmpfs on /tmp, so that the image generation will be done faster
```
git clone https://github.com/grid5000/environments-recipes
bash environments-reciped/tools/setup_grid5000.sh
cd /tmp
kameleon build PATH_TO_THE_RECIPE
```
