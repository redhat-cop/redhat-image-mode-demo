# 🏗️🏗️ Introducing RHEL Image Mode! 🏗️🏗️

- [What is RHEL Image Mode?](#what-is-rhel-image-mode)
   * [How is RHEL Image Mode different?](#how-is-rhel-image-mode-different)
- [🎯🎯 Let's get started 🎯🎯](#-lets-get-started-)
- [Use Cases](#use-cases)
   * [Getting started with bootable container images](#getting-started-with-bootable-containers)
   * [Managing VM lifecycle with bootable container images](#managing-vm-lifecycle-with-bootable-containers)
   * [Generate and deploy VM Images, AMI and ISO images with bootc-image-builder](#generate-and-deploy-vm-images-ami-and-iso-images-with-bootc-image-builder)

- [Resources](#resources)

## What is RHEL Image Mode?

RHEL Image mode is a new approach for operating system deployment that enables users to create, deploy and manage Red Hat Enterprise Linux as a bootc container image.

This approach simplifies operations across the enterprise, allowing developers, operations teams and solution providers to use the same container-native tools and techniques to manage everything from applications to the underlying OS.

### How is RHEL Image Mode different?

Due to the container-oriented nature, RHEL Image mode opens up to a unification and standardization of OS management and deployment, allowing the integration with existing CI/CD workflows and/or GitOps, reducing complexity.

RHEL Image mode also helps increasing security as the content, updates and patches are predictable and atomic, preventing manual modification of core services, packages and applications for a guaranteed consistency at scale.

## 🎯🎯 Let's get started 🎯🎯

Creating a container for RHEL Image Mode is as easy as writing and running a Containerfile like this:

> [!WARNING]
> To build images using RHEL bootc image you need a RHEL System with a valid subscription attached to it. For non-production workloads, you can register for a [free Red Hat developer subscription](https://developers.redhat.com/register).


```dockerfile
FROM registry.redhat.io/rhel9/rhel-bootc:9.4
```

You can proceed customizing the image, adding users, packages, configurations, etc following the [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/) as well as providing informative/documentation layers (MAINTAINER, LABEL, etc) following the best-practices of Containerfile creation.

> [!TIP]
> Some Dockerfile Directives (EXPOSE, ENTRYPOINT, ENV, among them) are ignored during RHEL Image deployment on a system, see [the documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/building-and-testing-the-rhel-bootable-container-images_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems#building-and-testing-the-rhel-bootable-container-images_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems) for more details.

## Use Cases

In this repo you will find some use cases that explain and show RHEL Image mode in action!

### Getting started with RHEL Image mode

- [Simple bootc container](./use-cases/simple-bootc-container/)
- [Bootc container with Apache](./use-cases/httpd-bootc-container/)

### Managing VM lifecycle with RHEL Image mode

- [Use a RHEL bootc container to spin up a RHEL 9 VM with Anaconda and Kickstart](./use-cases/anaconda-ks-bootc-container/)
- [Update a VM based on a RHEL bootc container as a source adding packages and configuration](./use-cases/upgrade-bootc-container/)
- [Change the ostree image of a running VM based on RHEL bootc container](./use-cases/replace-bootc-container/)

### Generate and deploy VM Images, AMI and ISO images with bootc-image-builder

- [Generate a RHEL QCOW image for a VM using bootc-image-builder](./use-cases/image-builder-bootc-qcow/)
- [Generate a RHEL ISO image for a VM using bootc-image-builder](./use-cases/image-builder-bootc-iso/)

## Resources

### RHEL Image mode

- [RHEL Image Mode landing page on Red Hat Website](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux/image-mode)
- [RHEL Image Mode quickstart on Red Hat Blog](https://www.redhat.com/en/blog/image-mode-red-hat-enterprise-linux-quick-start-guide)
- [RHEL Image Mode documentation on Red Hat Website](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/index)
- [Red Hat Developers - Getting Started with RHEL Image Mode](https://developers.redhat.com/products/rhel-image-mode/overview)

### bootc Upstream projects

- [bootc project on GitHub](https://github.com/containers/bootc)
- [bootc-image-builder project on GitHub](https://github.com/osbuild/bootc-image-builder)

