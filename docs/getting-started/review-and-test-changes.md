# Reviewing and testing the changes

Since documentation can contain snippets and markdown from [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) and [pymdown-extensions](https://facelessuser.github.io/pymdown-extensions/extensions/arithmatex/) projects, to properly test changes, whether while writing content or reviewing a Pull Request, a **Containerfile** is provided with the minimum packages to run the serving command for MkDocs.

<details>
  <summary>Review Containerfile</summary>
  ```dockerfile
    FROM registry.access.redhat.com/ubi9/python-312
    RUN pip3 install mkdocs mkdocs-material mkdocs-macros-plugin mkdocs mkdocs-mermaid2-plugin
    ENTRYPOINT mkdocs serve -a 0.0.0.0:8000
  ```
</details>

## Instructions to test changes

### Building the container image

While writing content, from the root folder of the repository, simply build the image:

```bash
podman build -t mkdocs-testing .
```

### Running the container

??? warning "**Read here if you are reviewing a Pull Request**"
    When reviewing a pull request, you need to create a temporary branch and fetch the content into it.
    Assuming user **kubealex** proposed a Pull Request involving the **testing** branch:
    ```bash
    git checkout -b kubealex-testing
    git pull https://github.com/kubealex/redhat-image-mode-demo.git testing
    ```

After the image is built, simply run the container mounting the current folder:

```bash
export HOST_PORT=8000
podman run -it --user $(id -u) --network podman -p $HOST_PORT:8000 -v ./:/opt/app-root/src:rw,Z mkdocs-testing mkdocs serve -a 0.0.0.0:8000
```

Replace the **HOST_PORT** variable with a free port on the host you are running the container.

If everything is working fine, the webserver will be listening on the desired port and reachable at the address [http://localhost:8000](http://localhost:8000)

![](./assets/mkdocs-serve.png)
