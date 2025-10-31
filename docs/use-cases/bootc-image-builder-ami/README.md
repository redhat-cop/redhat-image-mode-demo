# Use Case - Building a RHEL AWS AMI image using bootc-image-builder

!!! warning
    This example requires an [active AWS account](https://aws.amazon.com/). Free tier could not be enough due to the 5GB limitation on S3 storage.

In this example, we will build a container image from a Containerfile and we will generate an AWS AMI to use as a base for Instances.

The Containerfile in the example:

- Updates packages
- Installs tmux and mkpasswd to create a simple user password
- Creates a **bootc-user** user in the image
- Adds the wheel group to sudoers
- Installs [Apache Server](https://httpd.apache.org/)
- Enables the systemd unit for httpd
- Adds a custom index.html

<details>
  <summary>Review Containerfile.ami</summary>
  ```dockerfile
  --8<-- "use-cases/bootc-image-builder-ami/Containerfile.ami"
  ```
</details>

## Building the image

From the root folder of the repository, switch to the use case directory:

```bash
cd use-cases/bootc-image-builder-ami
```

To build the image:

```bash
podman build -f Containerfile.ami -t rhel-bootc-vm:ami .
```

## Testing the image

You can now test it using:

```bash
podman run -it --name rhel-bootc-vm --hostname rhel-bootc-vm -p 8080:80 rhel-bootc-vm:ami
```

Note: The *"-p 8080:80"* part forwards the container's *http* port to the port 8080 on the host to test that it is working.

The container will now start and a login prompt will appear.

On another terminal tab or in your browser, you can verify that the httpd server is working and serving traffic.

**Terminal**

```bash
 ~ ▓▒░ curl localhost:8080
Welcome to the bootc-http instance!
```

**Browser**

![](./assets/browser-test.png)

## Tagging and pushing the image

To tag and push the image you can simply run (replace **YOURQUAYUSERNAME** with the account name):


```bash
export QUAY_USER=YOURQUAYUSERNAME
```

```bash
podman tag rhel-bootc-vm:ami quay.io/$QUAY_USER/rhel-bootc-vm:ami
```

Log-in to Quay.io:

```bash
podman login -u $QUAY_USER quay.io
```

And push the image:

```bash
podman push quay.io/$QUAY_USER/rhel-bootc-vm:ami
```

You can now browse to [https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-vm?tab=settings](https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-vm?tab=settings) and ensure that the repository is set to **"Public"**.

![](./assets/quay-repo-public.png)

## Configure required resources for AWS

The AMI building process will need some configuration both on the client (for CLI configuration and credentials) and on AWS (for resources and IAM).

The specific needs are:

- an S3 bucket to temporarily store the AMI image that will be imported in the catalog
- a policy (**vmimport**) to allow importing from S3 to the AMI catalog
- a role to allow the **vmie** service and bind the policy

In [the files folder]({{ config.repo_url }}{{ config.edit_uri }}/use-cases/bootc-image-builder-ami/files/) are stored the **policy definition** and the **role definition** that you can review below before applying.

<details>
  <summary>Review aws-policy.json</summary>
  ```json
  --8<-- "use-cases/bootc-image-builder-ami/files/aws-policy.json"
  ```
</details>

<details>
  <summary>Review aws-role.json</summary>
  ```json
  --8<-- "use-cases/bootc-image-builder-ami/files/aws-role.json"
  ```
</details>

To start the configuration use the *aws configure* command and provide the required information:

```bash
[~]$ aws configure
AWS Access Key ID []:
AWS Secret Access Key []:
Default region name []:
Default output format [json]:
```

Once this is in place, we can proceed with the resources.

For S3 (replace YOURREGION with the correct region, ie. eu-west-1):

!!! tip
    S3 Bucket names are globally registered and unique, based on the name you find available, **edit the reference in lines 12-13 of the aws-policy.json file**

```bash
[~]$ export REGION=YOURREGION
aws s3api create-bucket --bucket rhel-bootc-demo --create-bucket-configuration LocationConstraint=$REGION
```

Let's proceed with the role:

```bash
aws iam create-role --role-name vmimport --assume-role-policy-document file://files/aws-role.json
```

And then associate the policy to the role:

```bash
aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document file://files/aws-policy.json
```

We are now good to go!


## Generating the AWS AMI image

To generate the AMI image we will be using [bootc-image-builder](https://github.com/osbuild/bootc-image-builder) container image that will help us transitioning from our newly generated bootable container image to an AMI image that can be used on AWS.

Let's proceed with the QCOW image creation:

```bash
sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    -v $HOME/.aws:/root/.aws:ro \
    --env AWS_PROFILE=default \
    registry.redhat.io/rhel10/bootc-image-builder:latest \
    build \
    --type ami \
    --aws-ami-name rhel-bootc-x86 \
    --aws-bucket rhel-bootc-demo \
    --aws-region eu-west-1 \
    quay.io/$QUAY_USER/rhel-bootc-vm:ami
```

The process will take care of all required steps (deploying the image, SELinux configuration, filesystem configuration, ostree configuration, etc.), after a couple of minutes we will find in the output:

```bash
Building manifest-ami.json
starting -Pipeline source org.osbuild.containers-storage: 6ec72d5cb7fb74985ee0fcdc8d90db85079cd08caa64fde9153c40aae3744f18
Build
  root: <host>
Pipeline build: 733863e98e5497425dbf00ac2eec52175d453834f17868944ed3408bcd9a3d16
Build
  root: <host>
  runner: org.osbuild.rhel82 (org.osbuild.rhel82)
[...]

⏱  Duration: 1s
manifest - finished successfully
build:          733863e98e5497425dbf00ac2eec52175d453834f17868944ed3408bcd9a3d16
image:          6b2f313ea4e75ddb9f8c9f2da14d4234760986240d1957093bb3631f0010c09e
qcow2:          194f4993f08ada94b56bc5a59d17a08251388f9210e13f4671d231f7cd9abb97
vmdk:           6d03b4759af85fd6408f36c72fde3eaa271466beef14a5f1af0499410055df9c
ovf:            c2410b0f4eecb91c7298d17c98dc672b42aedd02bb9809dab8feb1b185259689
archive:        950f23c305d2b41148790246e9abb8c925da34077f2954fabad284b9782f914e
Build complete!
Uploading image/disk.raw to rhel-bootc-demo:b1a83f25-051e-434c-a50f-ab634d1b798c-disk.raw
10.00 GiB / 10.00 GiB [------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------] 100.00% 79.03 MiB p/s
File uploaded to https://rhel-bootc-demo.s3.eu-west-1.amazonaws.com/b1a83f25-051e-434c-a50f-ab634d1b798c-disk.raw
Registering AMI rhel-bootc-x86
Deleted S3 object rhel-bootc-demo:b1a83f25-051e-434c-a50f-ab634d1b798c-disk.raw
AMI registered: ami-0ade40e197a89bb69
Snapshot ID: snap-068821f35b9b832af

```

You can verify that the AMI is now present in the [AMIs section](https://eu-west-1.console.aws.amazon.com/ec2/home?region=eu-west-1#Images:visibility=owned-by-me) on AWS. (the URL may be different based on the region).

![](./assets/aws-ami.png)


## Create the Instance on AWS

Using your preferred method, either via GUI or CLI, you can now create a fresh instance using the AMI we just imported.

Wait for the Instance to be ready and retrieve the IP address to log-in using SSH using *bootc-user/redhat* credentials:

```bash
 ~ ▓▒░
❯ ssh bootc-user@*****

The authenticity of host '***** (*****)' can't be established.
ED25519 key fingerprint is SHA256:OgY5Ym9dycIE2KPS5SRYRcmogUHalrUD35CyEH2A/j4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '*****' (ED25519) to the list of known hosts.
bootc-user@*****'s password:
[bootc-user@ip-172-31-22-31 ~]$
```
