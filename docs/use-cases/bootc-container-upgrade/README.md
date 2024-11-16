# Use Case - Upgrading a VM based on a bootc image

In this example, we want to add some bits to the [previously generated httpd image](../bootc-container-anaconda-ks/README.md) to add a [MariaDB server](https://mariadb.org/) and a text editor, [VIM](https://www.vim.org/).

We will then use **bootc** to manage the system update, and you will see how easy and fast perfoming upgrades is.

The Containerfile in this example will:

- Updates packages
- Installs tmux and mkpasswd to create a simple user password
- Creates a *bootc-user* user in the image
- Adds the wheel group to sudoers
- Installs [Apache Server](https://httpd.apache.org/)
- Enables the systemd unit for httpd
- Adds a custom index.html
- Customizes the Message of the day

But it will add the following two steps, resulting in a different image with an additional layer:

**- Add an additional message of the day with the upgrade notes**

**- Add mariadb-server package and vim**

**- Enable the mariadb systemd unit**

<details>
  <summary>Review Containerfile.replace</summary>
  ```dockerfile
  --8<-- "use-cases/bootc-container-upgrade/Containerfile.upgrade"
  ```
</details>

Since the *bootc update* command will preserve the /var and /etc content, we will use a workaround to create the needed dirs for MariaDB leveraging **systemd tmpfiles**:

```bash
--8<-- "use-cases/bootc-container-upgrade/files/00-mariadb-tmpfile.conf"
```

## Building the image

From the root folder of the repository, switch to the use case directory:

```bash
cd use-cases/bootc-container-upgrade
```

You can build the image right from the Containerfile using Podman:

```bash
podman build -f Containerfile.upgrade -t rhel-bootc-vm:httpd .
```

## Testing the image

You can now test it using:

```bash
podman run -it --name rhel-bootc-vm --hostname rhel-bootc-vm -p 8080:80 -p 3306:3306 rhel-bootc-vm:httpd
```

Note: The *"-p 8080:80" -p 3306:3306* part forwards the container's *http* and *mariadb* port to the port 8080 and 3306 on the host to test that httpd and mariadb are working.


The container will now start and a login prompt will appear:

![](./assets/bootc-container.png)

### Testing Apache

On another terminal tab or in your browser, you can verify that the httpd server is working and serving traffic.

**Terminal**

```bash
 ~ ▓▒░ curl localhost:8080                                                                                                           ░▒▓ ✔  11:59:44
Welcome to the bootc-http instance!
```

**Browser**

![](./assets/browser-test.png)

### Testing Mariadb

From the login prompt, login as **bootc-user/redhat** and impersonate the root user:

```bash
[bootc-user@rhel-bootc-vm ~]$ sudo -i
[root@rhel-bootc-vm ~]#
```

Verify that mariadb is running:

```bash
mysql
```

## Tagging and pushing the image

To tag and push the image you can simply run (replace **YOURQUAYUSERNAME** with the account name):


```bash
export QUAY_USER=YOURQUAYUSERNAME
```

```bash
podman tag rhel-bootc-vm:httpd quay.io/$QUAY_USER/rhel-bootc-vm:httpd
```

Log-in to Quay.io:

```bash
podman login -u $QUAY_USER quay.io
```

And push the image:

```bash
podman push quay.io/$QUAY_USER/rhel-bootc-vm:httpd
```

You can now browse to [https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-httpd?tab=settings](https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-httpd?tab=settings) and ensure that the repository is set to **"Public"**.

![](./assets/quay-repo-public.png)


## Updating the VM with the newly created image

The first thing to do is logging in the VM created in the [previous use case](../bootc-container-anaconda-ks/README.md) or any other use case (QCOW, ISO, AMI):

```bash
 ~ ▓▒░ ssh bootc-user@192.168.124.16
bootc-user@192.168.124.16's password:
This is a RHEL 9.5 VM installed using a bootable container as an rpm-ostree source!
Last login: Mon Jul 29 12:03:40 2024 from 192.168.124.1
[bootc-user@localhost ~]$
```

Verify that bootc is installed:

```bash
[bootc-user@localhost ~]$ bootc --help
Deploy and transactionally in-place with bootable container images.

The `bootc` project currently uses ostree-containers as a backend to support a model of bootable container images.  Once installed, whether directly via `bootc install` (executed as part of a container) or via another mechanism such as an OS installer tool, further updates can be pulled via e.g. `bootc upgrade`.

Changes in `/etc` and `/var` persist.

Usage: bootc <COMMAND>

Commands:
  upgrade      Download and queue an updated container image to apply
  switch       Target a new container image reference to boot
  edit         Apply full changes to the host specification
  status       Display status
  usr-overlay  Add a transient writable overlayfs on `/usr` that will be discarded on reboot
  install      Install the running container to a target
  help         Print this message or the help of the given subcommand(s)

Options:
  -h, --help   Print help (see a summary with '-h')
```

Note that among the options we have the **upgrade** option that we will be using in this use case.
The upgrade option allows checking, fetching and using any updated container image corresponding to the *imagename:tag* we used, in this case **quay.io/YOURQUAYUSERNAME/rhel-bootc-vm:httpd**

The upgrade command requires higher privileges to run, let's perform the upgrade!

```bash
[bootc-user@localhost ~]$ sudo bootc upgrade
layers already present: 71; layers needed: 4 (99.3 MB)
 379 B [████████████████████] (0s) Fetched layer sha256:3851db6a0d50                                                                                                                                                                                                                                                                                                                                            Queued for next boot: quay.io/kubealex/rhel-bootc-vm:httpd
  Version: 9.20240714.0
  Digest: sha256:09ceaf9cc673ddd49ca204216433c688b09418e24992492b7f0e46ef27f4d5a5
Total new layers: 75    Size: 1.3 GB
Removed layers:   1     Size: 403 bytes
Added layers:     4     Size: 99.3 MB
```

As you can see, at the beginning it performs a comparison between the actual rpm-ostree image that the system is booted from and the new image, fetching **only the additional layer** corresponding to the updates introduced during the last build.

Verify that mariadb is still not present at this time, and proceed with a reboot:

```bash
[bootc-user@localhost ~]$ systemctl status mariadb
Unit mariadb.service could not be found.
[bootc-user@localhost ~]$ sudo reboot
```

Let's log back in!

```bash
 ~ ▓▒░ ssh bootc-user@192.168.124.16
bootc-user@192.168.124.16's password:
This is a RHEL VM installed using a bootable container as an rpm-ostree source!
This server now supports MariaDB as a database, after last update
Last login: Mon Jul 29 12:10:44 2024 from 192.168.124.1
[bootc-user@localhost ~]$
```

You can already see that something changed, we have a new line in our message of the day, let's see if mariadb is running and test it using the default root user that is created by default (using sudo!):

```bash
[bootc-user@localhost ~]$ systemctl status mariadb
● mariadb.service - MariaDB 10.5 database server
     Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; preset: disabled)
     Active: active (running) since Mon 2024-07-29 12:12:27 CEST; 44s ago
       Docs: man:mariadbd(8)
             https://mariadb.com/kb/en/library/systemd/
    Process: 676 ExecStartPre=/usr/libexec/mariadb-check-socket (code=exited, status=0/SUCCESS)
    Process: 722 ExecStartPre=/usr/libexec/mariadb-prepare-db-dir mariadb.service (code=exited, status=0/SUCCESS)
    Process: 1373 ExecStartPost=/usr/libexec/mariadb-check-upgrade (code=exited, status=0/SUCCESS)
   Main PID: 1359 (mariadbd)
     Status: "Taking your SQL requests now..."
      Tasks: 13 (limit: 23136)
     Memory: 97.1M
        CPU: 195ms
     CGroup: /system.slice/mariadb.service
             └─1359 /usr/libexec/mariadbd --basedir=/usr

Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: The second is mysql@localhost, it has no password either, but
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: you need to be the system 'mysql' user to connect.
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: After connecting you can set the password, if you would need to be
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: able to connect as any of these users with a password and without sudo
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: See the MariaDB Knowledgebase at https://mariadb.com/kb
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: Please report any problems at https://mariadb.org/jira
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: The latest information about MariaDB is available at https://mariadb.org/.
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: Consider joining MariaDB's strong and vibrant community:
Jul 29 12:12:27 localhost.localdomain mariadb-prepare-db-dir[1315]: https://mariadb.org/get-involved/
Jul 29 12:12:27 localhost.localdomain systemd[1]: Started MariaDB 10.5 database server.
```

```bash
[bootc-user@localhost ~]$ sudo mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.5.22-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

Here we go, our image is updated and fully working. Of course we can use the new image to provision similar VMs that need the same pieces of software on them.
