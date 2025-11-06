## Building the demo

We include the httpd service from the start in the base image.
An alternative is to create a vanilla base image with only our login user in the base image and then do the steps to install httpd service.

!!! tip
    What we need to do if we install httpd in a next step is after the VM is upgraded to add the httpd log directories in the VM. See the Notes at the end of this document.

### Set the environment

Setup of the terminal for building Image Mode images that we are going to push to the registry.

In this workshop we will be pushing to **Red Hat Quay**, but if you have your own registry, or have access to a corporate registry we highly recommend using those registries as you can then continue using these to build your own RHEL images going forward.

We recommend that you set two variables in the terminal you are using for the logins to the Red Hat Registry and Quay.io.

Using Quay we recommend that when you push the images to Quay that you make the repositories *public* by selecting the repository and using the Actions to set *Make Public*
Update the variables QUAY_USER and REDHAT_USER with your Quay and Red Hat account userids. They may be the same if you use your Red Hat account.
Replace `$QUAY_PASSWORD` and `$REDHAT_PASSWORD` with your passwords. If you decide to use these variables, we recommend you hash encrypt the passwords in the variables.

```bash
QUAY_USER="your quay.io username not the email address"
REDHAT_USER="your Red Hat username, full email address may no longer work"
podman login -u $QUAY_USER quay.io -p $QUAY_PASSWORD && podman login -u $REDHAT_USER registry.redhat.io -p $REDHAT_PASSWORD
sudo mkdir -p /run/containers/0
sudo cp /run/user/1000/containers/auth.json /run/containers/0/auth.json #The user number 1000 may be different for your user
```
