# Use Case - Building a QCOW image using bootc-image-builder

In this example, we will build a container image from a Containerfile and we will generate a QCOW image to spin up a Virtual Machine in KVM.

The Containerfile in the example:

- Updates packages
- Installs tmux and mkpasswd to create a simple user password
- Creates a *bootc-user* user in the image
- Adds the wheel group to sudoers
- Installs [Apache Server](https://httpd.apache.org/)
- Enables the systemd unit for httpd
- Adds a custom index.html

## Building the image

Review the [Containerfile.qcow](Containerfile.qcow) file, that includes all the building steps for the image.

To build the image:

```bash
podman build -f Containerfile.qcow -t rhel-bootc-vm:qcow .
```

## Testing the image

You can now test it using:

```bash
podman run -it --name rhel-bootc-vm --hostname rhel-bootc-vm -p 8080:80 rhel-bootc-vm:qcow
```

Note: The *"-p 8080:80"* part forwards the container's *http* port to the port 8080 on the host to test that it is working.

The contaienr will now start and a login prompt will appear:

![](./assets/bootc-container.png)

On another terminal tab or in your browser, you can verify that the httpd server is working and serving traffic.

**Terminal**

```bash
 ~ ▓▒░ curl localhost:8080
Welcome to the bootc-http instance!
```

**Browser**

![](./assets/browser-test.png)

## Generating the QCOW image

To generate the QCOW image we will be using [bootc-image-builder](https://github.com/osbuild/bootc-image-builder) container image that will help us transitioning from our newly generated bootable container image to a VM image that can be used with KVM.

The bootc-image-builder container will need **rootful** access to run, so the first thing we need to do is copying the image from our current user (the one we built the image with) to *root*:

```bash
podman image scp $(whoami)@localhost::rhel-bootc-vm:qcow
```

Now, verify that the image is correctly present for root user:

```bash
 ~ ▓▒░ sudo podman images
REPOSITORY                                TAG         IMAGE ID      CREATED        SIZE
localhost/rhel-bootc-vm                 qcow        0ee1017eb9bc  7 minutes ago  1.81 GB
```

We are now ready!
Let's proceed with the QCOW image creation:

```bash
sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v $(pwd)/output:/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    registry.redhat.io/rhel9/bootc-image-builder:latest \
    --type qcow2 \
    --local \
    localhost/rhel-bootc-vm:qcow
```

We will use the local image we just copied to save in the **output** folder our generated image.

The process will take care of all required steps (deploying the image, SELinux configuration, filesystem configuration, ostree configuration, etc.), after a couple of minutes we will find in the output:

```bash
Generating manifest-qcow2.json ... DONE
Building manifest-qcow2.json
starting -Pipeline source org.osbuild.skopeo: 2bdb5945fe35e00303ccedea4d9a88be74a2fb903c57de4cea5c9cc2be516b38
Build
  root: <host>
source/org.osbuild.skopeo (org.osbuild.skopeo): Getting image source signatures
[...]

⏱  Duration: 68s
manifest - finished successfullybuild:          734b3cce0a0a99fdccc7d22454ed46542e5af3aae24a80ff0f7947a956fbe81c
ostree-deployment:      eb722c921b64950f84e0aa5537a569899603b0922cc16d7917f8018e923529d1
image:          818574c70b735b87695463a922e7e2c3037a9030e11268a2446483cc70f605ae
qcow2:          01eb69b883b4346cd81273d76f55dfa417e605172f7cb7ac45d6872453ae241a
vmdk:           3580b19f4160d14e629a7bfc72d057bd836441d2fd1c6a31032932dd3b785343
ovf:            05ec95f59cb3d3d40a81c69709fcacb34e07925b75a5d048dd56e5b25b34fad9
archive:        9620c02c16ce30df872a136e7b44f8064b197fb7141f51100cddc705d08a6d5c
Build complete!

```

Verify that under the *output/qcow2* folder we have our image ready to be used.

```bash
 ~/ ▓▒░ tree output
output
├── manifest-qcow2.json
└── qcow2
    └── disk.qcow2
```

## Create the VM in KVM

We will now use the image to spin up our Virtual Machine in KVM.

```bash
sudo virt-install \
    --name rhel-bootc-vm \
    --vcpus 4 \
    --memory 4096 \
    --import --disk ./output/qcow2/disk.qcow2,format=qcow2 \
    --os-variant rhel9.4 \
    --network network=default
```

Wait for the VM to be ready and retrieve the IP address for the domain to log-in using SSH using *bootc-user/redhat* credentials:

```bash
 ~ ▓▒░ VM_IP=$(sudo virsh -q domifaddr rhel-bootc-vm | awk '{ print $4 }' | cut -d"/" -f1) ssh bootc-user@$VM_IP
Warning: Permanently added '192.168.150.157' (ED25519) to the list of known hosts.
bootc-user@192.168.150.157's password:
[bootc-user@localhost ~]$ curl localhost
Welcome to the bootc-http instance!
[bootc-user@localhost ~]$
```

