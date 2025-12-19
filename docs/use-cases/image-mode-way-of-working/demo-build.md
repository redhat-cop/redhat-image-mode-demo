## Set the environment

As in the previous use-cases you require system or systems running podman, libvirt and have access to a container registry. A web browser that can access the VMs is helpful to view the results of the web page changes.

We will be pushing to **Red Hat Quay**, but if you have your own registry, or have access to a corporate registry we highly recommend using those registries as you can then continue using these to build your own RHEL images going forward.

We will be referring to `quay.io\$QUAY_USER` where `$QUAY_USER` is a variable of your Quay userid, and `$REDHAT_USER` as your Red Hat userid to pull from `registry.redhat.io`.

We recommend that you set two variables in the terminal you are using for the logins to the Red Hat Registry and Quay.io, as that allows you to use the copy icon in the command line boxes.

Using Quay we recommend that when you push the images to Quay that you make the repositories *public* by selecting the repository and using the Actions to set *Make Public*
Update the variables QUAY_USER and REDHAT_USER with your Quay and Red Hat account userids. They may be the same if you use your Red Hat account.
Replace `$QUAY_PASSWORD` and `$REDHAT_PASSWORD` with your passwords. If you decide to use these variables, we recommend you hash encrypt the passwords in the variables.

```bash
QUAY_USER="your quay.io username not the email address"
REDHAT_USER="your Red Hat username, full email address may no longer work"
USER_ID=$(id -ur)
podman login -u $QUAY_USER quay.io -p $QUAY_PASSWORD && podman login -u $REDHAT_USER registry.redhat.io -p $REDHAT_PASSWORD
sudo mkdir -p /run/containers/0
sudo cp /run/user/$USER_ID/containers/auth.json /run/containers/0/auth.json
```
