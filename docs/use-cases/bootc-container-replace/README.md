# Use Case - Applying a different RHEL container image to an existing VM

Our team is looking to improve performances and test different configurations.
We created our new and shiny image with Apache HTTPD and MariaDB, but you are exploring alternatives and want to use [Nginx](https://www.nginx.com/) and [PostgreSQL](https://www.postgresql.org/) as some of your team members are more familiar with that stack.

We will then create an alternative image, with a dedicated tag, that will help our fellow colleagues in their efforts.
Instead of redeploying the VM from scratch, we are going to use **bootc** to change the reference of the image in our existing VM to use it for configuring the system!

The Containerfile.replace is similar to the one in the [Image Upgrade use case](../bootc-container-upgrade/README.md):

- Updates packages
- Installs tmux and mkpasswd to create a simple user password
- Creates a *bootc-user* user in the image
- Adds the wheel group to sudoers
- Installs nginx server
- Enables the systemd unit for nginx
- Adds a custom index.html
- Customizes the Message of the day
- Add an additional message of the day with the new release notes
- Add postgresql-server package and vim
- Enable the postgresql-server systemd unit

Since the *bootc switch* command will preserve the /var and /etc content, we will use a workaround to create the needed dirs for Nginx and Postgresql leveraging [systemd-tmpfiles]({{ config.repo_url }}{{ config.edit_uri }}/use-cases/bootc-container-replace/files/tmpfiles.d/) and [systemd-sysusers]({{ config.repo_url }}{{ config.edit_uri }}/use-cases/bootc-container-replace/files/sysusers.d/) to ensure users are in place.

<details>
  <summary>Review Containerfile.replace</summary>
  ```dockerfile
  --8<-- "use-cases/bootc-container-replace/Containerfile.replace"
  ```
</details>

## Building the image

From the root folder of the repository, switch to the use case directory:

```bash
cd use-cases/bootc-container-replace
```

You can build the image right from the Containerfile using Podman:

```bash
podman build -f Containerfile.replace -t rhel-bootc-vm:nginx .
```

## Testing the image

You can now test it using:

```bash
podman run -it --name rhel-bootc-vm-nginx --hostname rhel-bootc-vm-nginx -p 8080:80 -p 5432:5432 rhel-bootc-vm:nginx
```

Note: The *"-p 8080:80" -p 5432:5432* part forwards the container's *http* and *postgresql* port to the port 8080 and 3306 on the host to test that nginx and postgresql are working.

The container will now start and a login prompt will appear:

![](./assets/bootc-container.png)

### Testing Nginx

On another terminal tab or in your browser, you can verify that the httpd server is working and serving traffic.

**Terminal**

```bash
 ~ ▓▒░ curl localhost:8080                                                                                                           ░▒▓ ✔  11:59:44
Welcome to the bootc-nginx instance!
```

**Browser**

![](./assets/browser-test.png)

### Testing Postgresql

From the login prompt, login as **bootc-user/redhat** and impersonate the root user:

```bash
[bootc-user@rhel-bootc-vm-nginx ~]$ sudo -i
[root@rhel-bootc-vm-nginx ~]#
```

Initialize PostgreSQL db and config:

```bash
[root@rhel-bootc-vm-nginx ~]# postgresql-setup --initdb
 * Initializing database in '/var/lib/pgsql/data'
 * Initialized, logs are in /var/lib/pgsql/initdb_postgresql.log
```

You will now be able to restart the postgresql systemd unit and test the connection:

```bash
[root@rhel-bootc-vm-nginx ~]# systemctl restart postgresql
[root@rhel-bootc-vm-nginx ~]# su - postgres
[postgres@rhel-bootc-vm-nginx ~]$ psql
psql (13.14)
Type "help" for help.

postgres=#
```

## Tagging and pushing the image

To tag and push the image you can simply run (replace **YOURQUAYUSERNAME** with the account name):


```bash
export QUAY_USER=YOURQUAYUSERNAME
```

```bash
podman tag rhel-bootc-vm:nginx quay.io/$QUAY_USER/rhel-bootc-vm:nginx
```

Log-in to Quay.io:

```bash
podman login -u $QUAY_USER quay.io
```

And push the image:

```bash
podman push quay.io/$QUAY_USER/rhel-bootc-vm:nginx
```

You can now browse to [https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-httpd?tab=settings](https://quay.io/repository/YOURQUAYUSERNAME/rhel-bootc-httpd?tab=settings) and ensure that the repository is set to **"Public"**.

![](./assets/quay-repo-public.png)


## Updating the VM with the newly created image

The first thing to do is logging in the VM updated in the [previous use case](../bootc-container-upgrade/README.md):

```bash
 ~ ▓▒░ ssh bootc-user@192.168.124.16
bootc-user@192.168.124.16's password: 
This is a RHEL VM installed using a bootable container as an rpm-ostree source!
This server now supports MariaDB as a database, after last update
Last login: Mon Jul 29 12:12:51 2024 from 192.168.124.1
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

Note that among the options we have the **switch** option that we will be using in this use case.
The switch option allows checking, fetching and using a different container image to replace the current configuration and spin up a new rpm-ostree image for the system.

In our case we will switch from **rhel-bootc-vm:httpd** to **rhel-bootc-vm:nginx** image.

The switch command requires higher privileges to run, let's perform the change!

```bash
[bootc-user@localhost ~]$ sudo bootc switch quay.io/kubealex/rhel-bootc-vm:nginx
layers already present: 69; layers needed: 7 (182.7 MB)
 426 B [████████████████████] (0s) Fetched layer sha256:8a192c7a518d                                                                                                                                                                                                                                                                                                                                            Queued for next boot: quay.io/kubealex/rhel-bootc-vm:nginx
  Version: 9.20240714.0
  Digest: sha256:e9dc2975eea3510044934fde745c296b734e8ca6f76add0e92c350e73db54620
```

In this case, unlike last time, the layers to retrieve were many more, as we changed big parts of the previous image.
At the end of the process, it queued the actual switch after reboot. Let's verify that postgres and nginx are still not present at this time, and proceed with a reboot:

```bash
[bootc-user@localhost ~]$ systemctl status nginx postgresql
Unit nginx.service could not be found.
Unit postgresql.service could not be found.
[bootc-user@localhost ~]$ sudo reboot
```

Let's log back in!

```bash
 ~/▓▒░ ssh bootc-user@192.168.124.16
bootc-user@192.168.124.16's password: 
This is a RHEL 9 VM installed using a bootable container as an rpm-ostree source!
This server is equipped with Nginx and PostgreSQL
Last login: Mon Jul 29 12:26:13 2024 from 192.168.124.1

```

You can already see that something changed, we have a different line in our message of the day, let's test if nginx and Postgresql are running and working!

Initialize the DB:

```bash
[root@rhel-bootc-vm-nginx ~]# postgresql-setup --initdb
 * Initializing database in '/var/lib/pgsql/data'
 * Initialized, logs are in /var/lib/pgsql/initdb_postgresql.log
```

Restart the PGSQL service:

```bash
[root@rhel-bootc-vm-nginx ~]# systemctl restart postgresql
```

And verify everything is up and running:


```bash
[bootc-user@localhost ~]$ systemctl status nginx postgresql

```

```bash
● nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: disabled)
     Active: active (running) since Mon 2024-07-29 12:31:03 CEST; 8min ago
    Process: 727 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 730 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 736 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 749 (nginx)
      Tasks: 3 (limit: 23136)
     Memory: 4.2M
        CPU: 11ms
     CGroup: /system.slice/nginx.service
             ├─749 "nginx: master process /usr/sbin/nginx"
             ├─750 "nginx: worker process"
             └─751 "nginx: worker process"

Jul 29 12:31:03 localhost.localdomain systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jul 29 12:31:03 localhost.localdomain nginx[730]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jul 29 12:31:03 localhost.localdomain nginx[730]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jul 29 12:31:03 localhost.localdomain systemd[1]: Started The nginx HTTP and reverse proxy server.

● postgresql.service - PostgreSQL database server
     Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; preset: disabled)
     Active: active (running) since Mon 2024-07-29 12:39:52 CEST; 2s ago
    Process: 1338 ExecStartPre=/usr/libexec/postgresql-check-db-dir postgresql (code=exited, status=0/SUCCESS)
   Main PID: 1340 (postmaster)
      Tasks: 8 (limit: 23136)
     Memory: 16.5M
        CPU: 16ms
     CGroup: /system.slice/postgresql.service
             ├─1340 /usr/bin/postmaster -D /var/lib/pgsql/data
             ├─1341 "postgres: logger "
             ├─1343 "postgres: checkpointer "
             ├─1344 "postgres: background writer "
             ├─1345 "postgres: walwriter "
             ├─1346 "postgres: autovacuum launcher "
             ├─1347 "postgres: stats collector "
             └─1348 "postgres: logical replication launcher "

Jul 29 12:39:52 localhost.localdomain systemd[1]: Starting PostgreSQL database server...
Jul 29 12:39:52 localhost.localdomain postmaster[1340]: 2024-07-29 12:39:52.234 CEST [1340] LOG:  redirecting log output to logging collector process
Jul 29 12:39:52 localhost.localdomain postmaster[1340]: 2024-07-29 12:39:52.234 CEST [1340] HINT:  Future log output will appear in directory "log".
Jul 29 12:39:52 localhost.localdomain systemd[1]: Started PostgreSQL database server.
```

Let's test if postgresql is working.

```bash
[bootc-user@localhost ~]$ sudo su -l postgres
Last login: Mon Mar 18 10:34:34 CET 2024 on pts/0
[postgres@localhost ~]$ psql
psql (13.14)
Type "help" for help.

postgres=#
```

Now we can try and see if the nginx server is reachable, using our browser we can go to the VM IP on port 80 to check:

![](./assets/vm-browser.png)

Here we go, our VM is fully working. Of course we can use the new image to provision similar VMs that need the same pieces of software on them.
