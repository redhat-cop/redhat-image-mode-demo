# Build a minimal RHEL image from scratch

In this example, we will build a minimal bootc container image from scratch and optimize it for efficient distribution.

Unlike the typical approach of inheriting from a base image using `FROM registry.redhat.io/rhel10/rhel-bootc:latest`, building from scratch gives you full control over the root content set, resulting in a leaner image that includes only what you explicitly install.

The process covers:

- Generating a minimal root filesystem using `bootc-base-imagectl`
- Building a custom bootc image from scratch
- Installing essential components like NetworkManager, sudo and SSH
- Optimizing the final image using `rechunk` for efficient layer deduplication

<details>
  <summary>Review Containerfile</summary>
```dockerfile
  --8<-- "use-cases/image-mode-build-from-scratch/Containerfile"
```
</details>

## Understanding the Containerfile

The build is split into two stages.

The **first stage** uses the official `rhel-bootc` image as a builder to generate a minimal root filesystem. The `bootc-base-imagectl build-rootfs` command with the `--manifest=minimal` flag produces a stripped-down root filesystem in `/target-rootfs`, containing only the bare essentials needed to boot.

The **second stage** starts completely from scratch using `FROM scratch`, meaning there is no inherited base layer at all. The minimal root filesystem generated in the first stage is copied in, and then additional packages are installed on top of it. In this example, `NetworkManager` and `openssh-server` are added since they are not included in the minimal manifest but are essential for a usable system.

A few details worth noting:

- The `dnf clean all` and removal of `/var/{log,cache,lib}` reduce the final image size by discarding package manager metadata and temporary files that are not needed at runtime.
- `bootc container lint` validates that the image meets bootc requirements before the build completes.
- The `containers.bootc` and `ostree.bootable` labels are **required** for the image to be recognized as a valid bootc image.
- `STOPSIGNAL SIGRTMIN+3` and `CMD ["/sbin/init"]` ensure the container behaves correctly when run directly with a container runtime, allowing systemd to manage the lifecycle.

## Building the image

From the root folder of the repository, switch to the use case directory:
```bash
cd use-cases/image-mode-build-from-scratch
```

Log-in to [registry.redhat.io](https://registry.redhat.io) using your Red Hat Credentials:

```bash
podman login registry.redhat.io --authfile auth.json
```

??? tip "Saving credentials to an authfile"

    During the example, we will use *sudo* to run privileged commands with podman, with authfiles we can save the login information to a shared file that can be used by both users to interact with the Red Hat registry.

To build the image, the inner build process requires elevated privileges for mount namespacing and device access. Without these flags, the rootfs generation step will fail:
```bash
 podman build \
  --cap-add=all \
  --security-opt=label=type:container_runtime_t \
  --device /dev/fuse \
  -f Containerfile \
  --authfile auth.json \
  -t rhel-image-mode:from-scratch .
```

??? tip "Making the image available to root for further steps"

    You can use `podman` to copy images between remote hosts using
    SCP with the `image` subcommand. This will also work for local
    storage on Linux without using SSHd. For example, to copy the
    locally built image to system storage without pulling from the quay.io:

    ```bash
    podman image scp localhost/rhel-image-mode:from-scratch root@localhost::
    ```

## Optimizing the image

The image produced in the previous step contains a single large tar layer. Every subsequent change — such as a kernel update — results in the entire layer being retransferred when pushing to a registry or pulling on a client. This is inefficient at scale.

Use the `rechunk` subcommand to split the filesystem into content-addressed reproducible layers with precomputed SELinux labeling. This maximizes layer deduplication and minimizes data transfer across image builds:

```bash
sudo podman run --rm --privileged \
  -v /var/lib/containers:/var/lib/containers \
  --authfile auth.json \
  registry.redhat.io/rhel10/rhel-bootc:latest \
  /usr/libexec/bootc-base-imagectl rechunk \
    localhost/rhel-image-mode:from-scratch  \
    localhost/rhel-image-mode:from-scratch-chunked
```

This produces a new image tagged `:from-scratch-chunked`. Going forward, only changed layers need to be pushed or pulled, significantly reducing transfer size for incremental updates.

## Verifying the image

If you inspect the original image, you will see that it created two large layers:

```bash
podman inspect localhost/rhel-image-mode:from-scratch | jq '.[0].RootFS'
```

<details>
  <summary>Review original layers</summary>
```bash
    [root@rhel10-builder ]# podman inspect localhost/rhel-image-mode:from-scratch | jq '.[0].RootFS'
    {
    "Type": "layers",
    "Layers": [
        "sha256:731ec36e8755dc84939cb6ba95a2a47e5e700e6370aba22316038b81fda799a4",
        "sha256:241e15d042753bedd2b5bd30a44102fd3359e0cabce34025ac67fe5ff348137a"
    ]
    }
```
</details>

You can inspect the resulting image layers to confirm the rechunk produced multiple layers instead of a single large one:

```bash
podman inspect localhost/rhel-image-mode:from-scratch-chunked | jq '.[0].RootFS'
```

<details>
  <summary>Review chunked layers</summary>
```bash
    [root@rhel10-builder ]# podman inspect localhost/rhel-image-mode:from-scratch-chunked | jq '.[0].RootFS'
    {
    "Type": "layers",
    "Layers": [
        "sha256:2c9f9f8a1d0eda07e7604e55eb259b2c6ecace1654884cceda653d37c2a4b54d",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:bac86f936754a0b09f737e91de5b6633621b95e5ba5c85145163b159a3c7cfde",
        "sha256:7865ba4c592ed4aecce26573fd2813d4e85e79da5e6f87da057bfe02d00e59bf",
        "sha256:de4c420771ad73306cd0d0a9f588a0075f78c6ccf0f119e7d2ed89147562d202",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:e7688bd7996e23a6940bf351eb288202db3060edbca9cb6fdfe213c4242ca2f3",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:1e4a51dec5a2eb411ddc87648ac3c41943ebec5129f345d74d1df8f89c591953",
        "sha256:66ac8370151a7f19975edf6fbd46042fa7c1ea94092c460429839bc8a4125cc7",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:01337b4d441f6a35a2797bddef9b7c13dc42f56c75df5a97b73f41736210152d",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:45ee5a9e8b61a870dbfb8f97965d9f68207b4035ae743915bdbb909ff0ddd273",
        "sha256:8ff4bc6a351c7400a6c682b48daec3a5e62f166dfa1e88004fb91a2e80751d59",
        "sha256:48edf0014d3f3a30aab7680eaa68dac057c5365202ecd7eae1373adca1852925",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:949afbe39c10f0ba478dc9bb06fbafaa946b1ab5bc5987129ff3e667355ec8ab",
        "sha256:aa0b4b0de8ecd1bdfcadaac993172ccd5659657b14c1f25b28d6de58420095ea",
        "sha256:88a6986f516ca6d220e65b66c8a1622ce4b966d8704be18a18cfc0e8f8c43d1a",
        "sha256:52edc45c16cb5442cd8fa7cd31ce7a4fa07a63f2fed4d7dcb31d6615b36d8eb3",
        "sha256:cc8c410e53bce0436f0c667b4b0a27a7624a25aeab863ca1a2c0b838650e20b8",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:3c1d2d8091732b6c6199815aecf96865dcc216bb2f4a3642e2380d364e1e49bf",
        "sha256:fb71a89e9ae4f47a10e8b9e4741258cc6c95fc765f3a2f0fbb9be30bd846aba8",
        "sha256:5a622315b451aa6580193a2d92c4fe992170257d3b7c377b20611112baa92caa",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:6740848009e15386c619e79ddd8c450e8431f441f46aaba818d45ec096f4569c",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:8b5fba73db205818cc82402b71e38df5d7cc4bd902a72270110ea00e808918cf",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:60b57bdf53986394f502aa41f96fe8dc2c632b1cd0c178c14d6aee3dc1416581",
        "sha256:271c819cce242d0bda5b630e04d25a6f744c07ffe96c288798b2c545b0d7b034",
        "sha256:18659a2d6bff206859ed472f81d042261b8a6bd2dee53116dabfc01512ab9b18",
        "sha256:12787d84fa137cd5649a9005efe98ec9d05ea46245fdc50aecb7dd007f2035b1",
        "sha256:0cd7283c6b769026ffc298b9c115547f0a0f96a80d41db1db26f98328c361f97",
        "sha256:a5f4c83e54d1e1bf25192e391d5296043f19c48e786a7fdaecdd5f730f14e500",
        "sha256:7a895c812edba11d5510d3da7f92268f20851c804977aec723000eb12a36a58b",
        "sha256:24e0ea6fb72d5bf3c5c9ebc875b3dcfb955c32a1a18bbeff58d82a1d291f5c03",
        "sha256:1726dbc246d0717c4ba568414c8be3cbf2fbcc469e0355e03ba776227b819681",
        "sha256:d51121535b0448112625c175dd6a7d74c441675f1939787f4d98cf28fec877fb",
        "sha256:632623f7194c33d6485d9e1cf44133c2b472a156eea41cbbf54f1cb6d1cbc35f",
        "sha256:ba9e182d6b09e9f61be61261a8c164e0fec7d1bd6d778bf8c9f49009150cdb25",
        "sha256:f205389181c68776076f4dfc7aea2bc28b5fc68dd17557038615619a580c03c1",
        "sha256:5af5cf8651870214e6cd76711daebab0f7208fac0ef05c55ebd8aa8c3ff9c6fa",
        "sha256:8e83434a6a0a92affae0ef5b71c36fedd24cd8ac2206e55b0a0e1b8ed8cfb937",
        "sha256:4ac01609a4a9b250ccc3b8a7bcd7fd8b5b2ce51844011b83dcd4f57811d0ee84",
        "sha256:a0432cabe0e89d4788e5b3b40f9ddd29756311ff65031cae263ce92cf5800fd9",
        "sha256:17ad34a6fd832146e0b16dc115bdfa6baaabc79dc72d58e2f50b8b7e89f1e707",
        "sha256:4d3ae3c68db7761f772963d9ebad9c259a2bf69820363cdc6be2a73ad921f088",
        "sha256:17c36c591ef3a816331a86d94dbbd343b9363e399d50d451865dc6e205282ec9",
        "sha256:7a3739ac5758153ba32254ae60294069c2a97a5e1b909429dee1acd317f83f9d",
        "sha256:e0e567962eac22b92fc73be7c8dbb6f07d8c4145389ed7a570b336a29239090c",
        "sha256:10c86074670583ed670f693272d7a883a085800da0d197aca4008eead8ee4aef",
        "sha256:1e74f46ecb9ffdc3eb4a62ccbe603c8bb20465e7e0892d6c5e18bb8c822ca103",
        "sha256:ed81ad04abf04203e8f6de03f038a6d5f8aa360c970949f7d50d585cc974f2a5",
        "sha256:64f865c40c105105541e6cb8bba7f0c7fae7352300d62f1a9c3342416612f24f",
        "sha256:205f83f988b2261536df2279dca54ceea417506cfa37f728b5135ca58bfe250b",
        "sha256:302c3e3c9918617ba4059d392659f1e5be645012af742a02fbca5fc858347743",
        "sha256:069c9de8db07aa5cadf3fb3efa1e2868c42d4347954230cc774418fd9d038473"
    ]
    }
```
</details>

You can also run a quick smoke test to verify the image is functional:
```bash
podman run -it --rm localhost/rhel-image-mode:from-scratch-chunked /usr/bin/systemctl --version
```

## Exploring the image

If you want to inspect the contents of the image interactively:
```bash
podman run -it --rm localhost/rhel-image-mode:from-scratch-chunked /bin/bash
```

From here, you can verify that:

- The bootc tooling is present
```bash
bash-5.1# bootc --version
```

- NetworkManager is installed and enabled
```bash
bash-5.1# systemctl status NetworkManager
```

- SSH is available
```bash
bash-5.1# systemctl status sshd
```
