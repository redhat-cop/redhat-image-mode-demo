# Ways of working with Image Mode for RHEL

In this example, we will build upon what we have learned from the previous examples. We will create a number of Image Mode container images where the images will be "inheriting" from the base images.

We will create a Standard Operating Environment (SOE) image, also called a "golden image" that can be reused in all RHEL deployments.. The services images, running specific systemd services such as httpd or mariadb, are build on top of the base image, and the applications deployed upon the services images. We will build a web server and deploy a MariaDB serverand go through the life-cycle of upgrading the servers.

There are two practices on building the systemd services images. The first is to build the services directly into the image based on the RHEL image from the `registry.redhat.io`. The second is what we will build in this example, create an base image (soe image) and reuse that image to build our services and applications.

## The Build process

The following Container files with the content will be built:

- soe-rhel
    - Updates packages
    - Installs tmux and mkpasswd to create a simple user password
    - Creates a *bootc-user* user in the image
    - Adds the wheel group to sudoers
    - Adds a custom Message of the Day
- httpd
    - use the soe-rhel image
    - Installs [Apache Server](https://httpd.apache.org/)
    - Enables the systemd unit for httpd
    - Move the www directory from var to usr
    - Copy our simple webpage content
    - Update the message of the day
- homepage
    - use the httpd image
    - copy our Image Mode webpage content
- database
    - use the soe-rhel image
    - Installs Mariadb
    - Copy the Mariadb config file
    - Enables the systemd unit for Mariadb

## The workflow

1. Create a RHEL 9.6 base image
2. Create our application images and VMs.
    1. Create a httpd server image based on our RHEL 9.6 base image
    2. Create a MariaDB server image based on our RHEL 9.6 base image
3. Deploy the application images as a virtual machine servers.
4. Create the homepage image with our 9 homepage content and switch the VM to the homepage image.
5. Rollback to get our old homepage back up and running.
6. Fix the error in the homepage container file and update the VM.
7. Upgrade the base RHEL image to RHEL 10.
8. Build a new version of the httpd service image on RHEL 10.
9. Build a new version of the homepage image containing the RHEL 10 homepage.
10. Upgrade the Homepage VM to the latest 10 homepage and the OS to RHEL version 10.
11. Upgrade the Database server to RHEL 10.
