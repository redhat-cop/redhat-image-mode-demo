# 🎯🎯 Let's get started 🎯🎯

First of all, clone the repo:

```bash
git clone https://github.com/redhat-cop/redhat-image-mode-demo
```

Creating a container for RHEL Image Mode is as easy as writing and running a Containerfile like this:

!!! warning
    To build images using RHEL bootc image you need a RHEL System with a valid subscription attached to it. For non-production workloads, you can register for a [free Red Hat developer subscription](https://developers.redhat.com/register).


```dockerfile
FROM registry.redhat.io/rhel9/rhel-bootc:9.6
```

You can proceed customizing the image, adding users, packages, configurations, etc following the [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/) as well as providing informative/documentation layers (MAINTAINER, LABEL, etc) following the best-practices of Containerfile creation.

!!! tip
    Some Dockerfile Directives (EXPOSE, ENTRYPOINT, ENV, among them) are ignored during RHEL Image deployment on a system, see [the documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/building-and-testing-the-rhel-bootable-container-images_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems#building-and-testing-the-rhel-bootable-container-images_using-image-mode-for-rhel-to-build-deploy-and-manage-operating-systems) for more details.
