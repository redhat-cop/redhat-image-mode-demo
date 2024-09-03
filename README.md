# 🏗️🏗️ Introducing RHEL Image Mode! 🏗️🏗️

- [What is RHEL Image Mode?](#what-is-rhel-image-mode)
   * [How is RHEL Image Mode different?](#how-is-rhel-image-mode-different)
- [🎯🎯 Let's get started 🎯🎯](#-lets-get-started-)
- [Use Cases](#use-cases)
   * [Getting started with RHEL Image mode](#getting-started-with-rhel-image-mode)
   * [Managing VM lifecycle with RHEL Image mode](#managing-vm-lifecycle-with-rhel-image-mode)
   * [Generate and deploy VM Images, AMI and ISO images with bootc-image-builder](#generate-and-deploy-vm-images-ami-and-iso-images-with-bootc-image-builder)

- [Resources](#resources)

## What is RHEL Image Mode?

RHEL Image mode is a new approach for operating system deployment that enables users to create, deploy and manage Red Hat Enterprise Linux as a bootc container image.

This approach simplifies operations across the enterprise, allowing developers, operations teams and solution providers to use the same container-native tools and techniques to manage everything from applications to the underlying OS.

### How is RHEL Image Mode different?

Due to the container-oriented nature, RHEL Image mode opens up to a unification and standardization of OS management and deployment, allowing the integration with existing CI/CD workflows and/or GitOps, reducing complexity.

RHEL Image mode also helps increasing security as the content, updates and patches are predictable and atomic, preventing manual modification of core services, packages and applications for a guaranteed consistency at scale.

## 🎯🎯 Let's get started 🎯🎯

First of all, clone the repo:

```bash
git clone https://github.com/redhat-cop/redhat-image-mode-demo
```

Now check out the [documentation website](https://redhat-cop.github.io/redhat-image-mode-demo/) for the step-by-step instructions of the use cases!

## Use Cases

In this repo you will find some use cases that explain and show RHEL Image mode in action!

### Getting started with RHEL Image mode

- [Simple bootc container](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-container-simple/)
- [Bootc container with Apache](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-container-httpd/)

### Managing VM lifecycle with RHEL Image mode

- [Use a RHEL bootc container to spin up a RHEL 9 VM with Anaconda and Kickstart](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-container-anaconda-ks/)
- [Update a VM based on a RHEL bootc container as a source adding packages and configuration](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-container-upgrade/)
- [Apply a different RHEL container image to an existing VM](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-container-replace/)

### Generate and deploy VM Images, AMI and ISO images with bootc-image-builder

- [Generate a RHEL QCOW image for a VM using bootc-image-builder](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-image-builder-qcow/)
- [Generate a RHEL ISO image for a VM using bootc-image-builder](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-image-builder-iso/)
- [Generate a RHEL AMI image for an AWS instance using bootc-image-builder](https://redhat-cop.github.io/redhat-image-mode-demo/use-cases/bootc-image-builder-ami/)

## Resources

### RHEL Image mode

- [RHEL Image Mode landing page on Red Hat Website](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux/image-mode)
- [RHEL Image Mode quickstart on Red Hat Blog](https://www.redhat.com/en/blog/image-mode-red-hat-enterprise-linux-quick-start-guide)
- [RHEL Image Mode documentation on Red Hat Website](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/index)
- [Red Hat Developers - Getting Started with RHEL Image Mode](https://developers.redhat.com/products/rhel-image-mode/overview)
- [A new state of mind with image mode for RHEL on Red Hat Blog](https://www.redhat.com/en/blog/new-state-mind-image-mode-rhel)

### bootc Upstream projects

- [bootc project on GitHub](https://github.com/containers/bootc)
- [bootc-image-builder project on GitHub](https://github.com/osbuild/bootc-image-builder)

