# 🏗️🏗️ Introducing RHEL Image Mode! 🏗️🏗️

- [What are bootable container images?](#what-are-bootable-containers)
   * [How are they different?](#how-are-they-different)
- [🎯🎯 Let's get started 🎯🎯](#-lets-get-started-)
- [Use Cases](#use-cases)
   * [Getting started with bootable container images](#getting-started-with-bootable-containers)
   * [Managing VM lifecycle with bootable container images](#managing-vm-lifecycle-with-bootable-containers)
   * [Generate and deploy VM Images, AMI and ISO images with bootc-image-builder](#generate-and-deploy-vm-images-ami-and-iso-images-with-bootc-image-builder)

- [Resources](#resources)

## What are bootable container images?

As the name suggests, bootable container images differ from general purpose containers as the underlying image they use contains all necessary bits to make it act exactly like a standard OS, including modules, systemd, etc.
They use specific tailored base images that include a Linux kernel and upon boot *systemd* is running as pid1 as in a "standard" OS.

> [!TIP]
> Read more in the [mission statement](https://containers.github.io/bootable/)

### How are they different?

Bootable container images can enable a 360° integrated container-native workflow that covers the underlying OS up to the application layer.
They benefit of a set of dedicated tools (bootc, bootc-image-builder, etc) to compose, build and distribute images that can be defined using common Containerfile structure and instructions.

Some of the main features are:

- Bootable container images goal is to provide a way to deploy and manage immutable image-based Linux systems
- Bootable container images images can act as a source to build VMs/Cloud images.
- Bootable container images images can be used as a source to install and configure a new server/VM using kickstart/Anaconda
- Bootable container images simplify testing applications on different architectures/platforms
- Bootable container images streamline OS updates leveraging the [rpm-ostree system](https://coreos.github.io/rpm-ostree/)

## 🎯🎯 Let's get started 🎯🎯

Creating a bootable container for RHEL Image Mode is as easy as writing and running a Containerfile like this:

```dockerfile
FROM registry.redhat.io/rhel9/rhel-bootc:9.4
CMD [ "/sbin/init" ]
```

> [!INFO]
> To build images using RHEL bootc image you need a RHEL System with a valid subscription attached to it. For non-production workloads, you can register for a [free Red Hat developer subscription](https://developers.redhat.com/register).

You can proceed customizing the image, adding users, packages, configurations, etc following the [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)

## Use Cases

In this repo you will find some use cases that explain and show RHEL Image mode in action!

### Getting started with RHEL Image mode

- [Simple bootc container](./use-cases/simple-bootc-container/)
- [Bootc container with Apache](./use-cases/httpd-bootc-container/)

### Managing VM lifecycle with RHEL Image mode

- [Use a bootc container to spin up a RHEL 9 VM with Anaconda and Kickstart](./use-cases/anaconda-ks-bootc-container/)
- [Update a VM based on bootc container as a source adding packages and configuration](./use-cases/upgrade-bootc-container/)
- [Change the ostree image of a running VM based on bootc](./use-cases/replace-bootc-container/)

### Generate and deploy VM Images, AMI and ISO images with bootc-image-builder

- [Generate a QCOW image for a VM using bootc-image-builder](./use-cases/image-builder-bootc-container/)

## Resources

- [Bootable container images mission statement](https://containers.github.io/bootable/)

- [bootc project on GitHub](https://github.com/containers/bootc)
- [bootc documentation](https://containers.github.io/bootc/)
- [bootc-image-builder project on GitHub](https://github.com/osbuild/bootc-image-builder)

- [Podman page](https://podman.io/)
- [Fedora ELN project](https://docs.fedoraproject.org/en-US/eln/)
- [CentOS9 Stream project](https://centos.org/stream9/)
