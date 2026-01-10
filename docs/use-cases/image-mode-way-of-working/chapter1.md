## Build the demo base image for RHEL

The first steps we will build our base SOE (golden) image that we are going to use within the workshop. We will start with RHEL 9 and during the workshop update to RHEL 10.

We will name our SOE (Standard Operating Environment/Golden) image `soe-rhel:9` and also tag it as our latest rhel base image as `soe-rhel:latest`.

1. Use podman to build our soe base RHEL "golden image". Change to the directory where you have cloned this repo and use `podman build` to build the image from the `Containerfile`. The following command will work if you cloned it into your home directory.

    ```bash
    cd $HOME/redhat-image-mode-demo/use-cases/image-mode-way-of-working/soe-rhel9
    ```

    <details>
    <summary>Review soe-rhel9/Containerfile</summary>
    ```dockerfile
    --8<-- "use-cases/image-mode-way-of-working/soe-rhel9/Containerfile"
    ```
    </details>

    ```bash
    podman build -t quay.io/$QUAY_USER/soe-rhel:latest -t quay.io/$QUAY_USER/soe-rhel:9 -f Containerfile
    ```

2. If we want to test our image we can run it in a container. You can log in with user `bootc-user` and password `redhat` and run `curl localhost` to test if the httpd service is running and you can see the base image welcome page. You can stop and exit the container with `sudo halt`. We are going to run our container in the next step to check that the httpd service is running and that we can see our homepage before deploying it to a VM.

    ```bash
    podman run -it --rm --name soe-rhel9 -p 8080:80 quay.io/$QUAY_USER/soe-rhel:9
    ```

3. Push the base rhel image to our registry.

    ```bash
    podman push quay.io/$QUAY_USER/soe-rhel:latest && podman push quay.io/$QUAY_USER/soe-rhel:9
    ```

!!! tip
    We could base the initial image on an older release of RHEL, such as `rhel:9.6`, or a specific timestamp version of RHEL such as `rhel:9.6-1747275992`, or fix it at a certain release such as `rhel:9.7`, instead of pulling the latest release by specifying the release number in the Containerfile `FROM` statement.

## Deploying the Homepage Virtual Machine

We need to create an image for our httpd service based on the RHEL 9 base image we created in the previous step.
We will name our httpd service image `httpd:rhel9` and also tag it as our latest rhel base image as `httpd:latest`.

1. Use podman to build httpd service image. Change to the httpd-service folder.

    ```bash
    cd ../httpd-service
    ```

    <details>
    <summary>Review httpd-service/Containerfile</summary>
    ```dockerfile
    --8<-- "use-cases/image-mode-way-of-working/httpd-service/Containerfile"
    ```
    </details>

1. Change the $QUAY_USER in the `Containerfile` to your Quay userid or your registry.

2. Use `podman build` to build the image from the `Containerfile`.

    ```bash
    podman build -t quay.io/$QUAY_USER/httpd:latest -t quay.io/$QUAY_USER/httpd:rhel9 -f Containerfile
    ```

3. Push the httpd service image to our registry.

    ```bash
    podman push quay.io/$QUAY_USER/httpd:latest && podman push quay.io/$QUAY_USER/httpd:rhel9
    ```

4. If we want to test our image we can run it in a container.
    ```bash
    podman run -it --rm --name httpd-rhel9 -p 8080:80 quay.io/$QUAY_USER/httpd:rhel9
    ```

5. You can log in with user `bootc-user` and password `redhat` and run `curl localhost` to test if the httpd service is running and you can see the base image welcome page. You can test the homepage in a browser on the local machine by using the URL `http://localhost:8080`. You can stop and exit the container with `sudo halt`.

Now we are ready to create the virtual machine disk image that we are going to import into our new VM.

Since we need to run the Image Builder convert tool as superuser we need to pull the image from the registry using sudo to add it to sudo's image repository.


1. Since we need to run podman as root to build the virtual machine qcow2 image file, we need to pull the image as root.

    !!! tip
        You may also get an error `Error: unable to copy from source`. You need to go to your repository, in our example, Quay, and make the repositories `public`.

    ```bash
    sudo podman pull quay.io/$QUAY_USER/httpd:latest
    ```

2. We need to use podman to run the Image Mode virtual machine disk builder to pull the image from the registry and create the virtual machine disk file. You can edit the `config.toml `file to change it to add or replace the user, password, ssh key and more. Refer to [Supported image customizations for a configuration file](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/index#supported-image-customizations-for-a-configuration-file_creating-bootc-compatible-base-disk-images-with-bootc-image-builder).

    !!! tip
        If you get an error `Error: unable to copy from source` you may have to do a `sudo podman login registry.redhat.io -u $REDHAT_USER -p $REDHAT_PASSWORD`.

    ```bash
    sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v $(pwd)/config.toml:/config.toml:ro \
    -v $(pwd):/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage registry.redhat.io/rhel9/bootc-image-builder:latest \
    --type qcow2 \
    quay.io/$QUAY_USER/httpd:latest
    ```

3. We will copy the new disk image to the libvirt images pool.

    !!! tip
        You can move the disk image if you don't plan to use it for another VM using the mv command.

    ```bash
    sudo cp ./qcow2/disk.qcow2 /var/lib/libvirt/images/homepage.qcow2
    ```

4. Create the VM from the copied virtual machine image qcow2 file. We will give it 4GB of RAM and set the boot option to UEFI.

    ```bash
    sudo virt-install \
    --connect qemu:///system \
    --name homepage \
    --import \
    --boot uefi \
    --memory 4096 \
    --graphics none \
    --osinfo rhel9-unknown \
    --noautoconsole \
    --noreboot \
    --disk /var/lib/libvirt/images/homepage.qcow2
    ```

5. Start the VM.

    ```bash
    sudo virsh start homepage
    ```

6. Login via ssh. You can use the following command that will get the IP address from virsh and log you in.

    ```bash
    VM_IP=$(sudo virsh -q domifaddr homepage | awk '{ print $4 }' | cut -d"/" -f1) && ssh bootc-user@$VM_IP
    ```

7. You can run a `curl localhost` to check if the httpd service with our base image homepage is working. Exit the VM with `exit`, `logout` or Ctrl-d.

8. Since we are going to refer to the quay.io registry, let us add $QUAY_USER to our .bashrc file.

    ```bash
    sed -i '/unset rc[^\n]*/,$!b;//{x;//p;g};//!H;$!d;x;iexport QUAY_USER="your quay.io username not the email address"' .bashrc
    ```

9. and reload the .bashrc file to bring QUAY_USER into the variables.

    ```bash
    source .bashrc
    ```

10. Finally for this section run the bootc status command to view the booted image registry source and the RHEL version.

    ```bash
    sudo bootc status
    ```

    ```
        Booted image: quay.io/$QUAY_USER/httpd:rhel9 \
        Digest: sha256:a48811e05........... \
        Version: 9.7 (2025-07-21 13:10:35.887718188 UTC)
    ```

Our virtual machine based on Image Mode is now running and we are ready to make updates to the web page.

## Update the Homepage VM to our Image Mode web page

The next steps we will update the web page in our `homepage` VM from the basic RHEL webpage that we created to an more updated web page showing the advantages of using Image Mode.

On our image builder server we will build a new Image Mode for RHEL 9 homepage image that we will deploy to the VM.

1. Change directory to the new web page Container file and the *RHEL 9 Image Mode* web page at `homepage-rhel9`. You can open the `index.html` file in the `html` directory to see the updates to the homepage.

    ```bash
    cd ../homepage-rhel9
    ```

2. Build the new homepage images from the `Containerfile`.

    <details>
    <summary>Review homepage-rhel9/Containerfile</summary>
    ```dockerfile
    --8<-- "use-cases/image-mode-way-of-working/homepage-rhel9/Containerfile"
    ```
    </details>

    !!! tip
        Remeber to change the $QUAY_USER in the `Containerfile` to your repository userid.
        Remeber to make the homepage repository on your Quay registry public.

    ```bash
    podman build -t quay.io/$QUAY_USER/homepage:rhel9 -t quay.io/$QUAY_USER/homepage:latest -f Containerfile
    ```

3. Push the image to the registry using the `homepage:rhel9` and `homepage:latest` tags.

    ```bash
    podman push quay.io/$QUAY_USER/homepage:latest && podman push quay.io/$QUAY_USER/homepage:rhel9
    ```

4. Switch to the Homepage virtual machine and login to the `homepage` VM using ssh.

    ```bash
    VM_IP=$(sudo virsh -q domifaddr homepage | awk '{ print $4 }' | cut -d"/" -f1) && ssh bootc-user@$VM_IP
    ```

5. We are now going to use the `bootc switch` command to switch the virtual machine to the homepage image in the registry.

    !!! tip
        If you didn't add the `$QUAY_USER` to the `.bashrc` file then run the following

    ```bash
    QUAY_USER="your quay.io username not the email address"
    ```

    ```bash
    sudo bootc switch quay.io/$QUAY_USER/homepage:latest
    ```

6. Let us check the we have staged the new homepage image in the virtual machine.

    ```bash
    sudo bootc status
    ```

    ```
        Staged image: quay.io/$QUAY_USER/homepage:latest \
                Digest:  sha256:2be7b1...... \
            Version: 9.7 (2025-07-21 15:43:03.624175287 UTC) \
            \
        ● Booted image: quay.io/$QUAY_USER/soe-rhel:9.7 \
                Digest: sha256:a48811...... \
            Version: 9.7 (2025-07-21 13:10:35.887718188 UTC)
    ```

7. and we check that we have the old RHEL 9 homepage without our new Image Mode content.

    ```bash
    curl localhost
    ```

8. We need to reboot the virtual machine to activate the new layers and have our new home page.

    ```bash
    sudo reboot
    ```

9. Login to the virtual machine to verify that we have a new updated Image Mode homepage.

    ```bash
    VM_IP=$(sudo virsh -q domifaddr homepage | awk '{ print $4 }' | cut -d"/" -f1) && ssh bootc-user@$VM_IP
    curl localhost
    ```

10. Something went wrong! Our httpd service has failed during the update! Let us check the service.

    ```bash
    sudo systemctl status httpd
    ```

11. There is no httpd service. We will rollback in the next section and fix the problem.

## Rollback and fix our homepage

In the previous section the httpd service wasn't in the image. This is due to a mistake we made in the Containerfile. First, we will rollback so that we have the old homepage up and running, and then we will fix the problem.

On our image builder server we will build a new Image Mode for RHEL 9 homepage image that we will deploy to the VM.

1. In the homepage VM we will issue the rollback command, and use the `--apply` flag to automatically reboot the VM.

   ```bash
   sudo bootc rollback --apply
   ```
2. You should have been exited from the VM. If you aren't in the `homepage-rhel9` directory then change directory to the new web page Container file and the updated web page at `homepage-rhel9`. You can open the `index.html` file in the `html` directory to see the updates to the homepage.

    ```bash
    cd ../homepage-rhel9
    ```

3. We need to fix the Containerfile to pull the correct image from the registry. Use an editor to change the following line to

    !!! tip
        Remeber to change the $QUAY_USER in the `Containerfile` to your repository userid.

    ```dockerfile
    FROM quay.io/$QUAY_USER/soe-rhel:latest
    ```

    change to

    ```dockerfile
    FROM quay.io/$QUAY_USER/httpd:latest
    ```

4. Build the new homepage images from the `Containerfile` and tag to a new version `homepage:rhel9-fix`.

    ```bash
    podman build -t quay.io/$QUAY_USER/homepage:rhel9-fix -t quay.io/$QUAY_USER/homepage:latest -f Containerfile
    ```

5. Push the image to the registry using the `homepage:rhel9-fix` and `homepage:latest` tags.

    ```bash
    podman push quay.io/$QUAY_USER/homepage:latest && podman push quay.io/$QUAY_USER/homepage:rhel9-fix
    ```

6. Switch to the Homepage virtual machine and login to the `homepage` VM using ssh.

    ```bash
    VM_IP=$(sudo virsh -q domifaddr homepage | awk '{ print $4 }' | cut -d"/" -f1) && ssh bootc-user@$VM_IP
    ```

7. We are going to use the `bootc switch` command to switch the virtual machine to the homepage image in the registry.

    !!! tip
        If you didn't add the `$QUAY_USER` to the `.bashrc` file then run the following

    ```bash
    QUAY_USER="your quay.io username not the email address"
    ```

    ```bash
    sudo bootc switch quay.io/$QUAY_USER/homepage:latest
    ```

8. Let us check the we have staged the new homepage image in the virtual machine.

    ```bash
    sudo bootc status
    ```

    ```
        Staged image: quay.io/$QUAY_USER/homepage:latest \
                Digest:  sha256:2be7b1...... \
            Version: 9.7 (2025-07-21 15:43:03.624175287 UTC) \
            \
        ● Booted image: quay.io/$QUAY_USER/soe-rhel:9.7 \
                Digest: sha256:a48811...... \
            Version: 9.7 (2025-07-21 13:10:35.887718188 UTC)
    ```

9. and we check that we have the old RHEL 9 homepage without our new Image Mode content.

    ```bash
    curl localhost
    ```

10. We need to reboot the virtual machine to activate the new layers and have our new home page.

    ```bash
    sudo reboot
    ```

11. Login to the virtual machine to verify that we have a new updated Image Mode homepage.

    ```bash
    VM_IP=$(sudo virsh -q domifaddr homepage | awk '{ print $4 }' | cut -d"/" -f1) && ssh bootc-user@$VM_IP
    ```

    ```bash
    curl localhost
    ```

## Build the database virtual machine

We will then deploy a new virtual machine named `database` as this will be our new demo database server.
We will build the two images in one linked command and push it as the version 1 and latest images to our registry.

We are following a less complex deployment for the database server than the deployment we did for the homepage.
We are going to deploy the mariadb service using a bash script to automate the deployment.

In the `mariadb_service` directory update the QUAY_USER variable in the `mariadb-deploy-rhel9.sh` file and the `Containerfile` with your quay user id.

<details>
  <summary>Review mariadb-service/mariadb-deploy-rhel9.sh</summary>
  ```dockerfile
  --8<-- "use-cases/image-mode-way-of-working/mariadb-service/mariadb-deploy-rhel9.sh"
  ```
</details>

and the Containerfile

<details>
  <summary>Review mariadb-service/Containerfile</summary>
  ```dockerfile
  --8<-- "use-cases/image-mode-way-of-working/mariadb-service/Containerfile"
  ```
</details>

1. Change to the `mariadb-service` directory.

    ```bash
    cd ../mariadb-service
    ```

2. Ensure that the `mariadb-deploy.sh` file is executable.

    ```bash
    chmod +x mariadb-deploy.sh
    ```

3. Edit the mariadb-deploy.sh file and change the entry for the QUAY_USER to your quay.io user name.

4. Run the bash script `mariadb-deploy.sh` to create the database images and the database VM.

    ```bash
    ./mariadb_deploy.sh
    ```

This will build and push the mariadb service image and deploy the VM from the image.
