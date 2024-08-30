# How to contribute to the project

Contributions are more than welcome, as it's the only way to ensure quality and keep projects alive, and to keep consistency it's great to have some guidance when starting to submit and be part of the changes.

Here are a few guidelines that can be useful when contributing.

## Project structure

The project is structured to host:

- the operative files (Containerfiles, additional configurations) in the [use cases folder](./use-cases/)
- the documentation for the doc website [https://redhat-cop.github.io/redhat-image-mode-demo/](https://redhat-cop.github.io/redhat-image-mode-demo/) in the [docs folder](./docs/)

The documentation uses [Mkdocs](https://mkdocs.org) with the [Mkdocs Material theme](https://squidfunk.github.io/mkdocs-material/) to render the markdown pages into the site.

## Working on existing use cases

If you want to contribute with fixes or enhancement for already existing use cases, you can go straight to the content in the **docs/use-cases/** folder of the corresponding use case and start working on it. If changes are needed on the core part, you can work in the corresponding dedicated folder under **use-cases/**.

## Working on new use cases

### Operating on the use case folders

To contribute with new use cases, you can create a new folder in the **docs/use-cases/** and **use-cases/** folders with a meaningful name. 

The README.md of each single use case should contain minimal information about the use case and a link to the Document Site section corresponding to it.

To include snippets within the repo you can follow the [Pymdownx-snippets plugin documentation](https://facelessuser.github.io/pymdown-extensions/extensions/snippets/). 

Paths are *relative to the root of the repository*, below an example to include a snippet coming from *use-cases/bootc-container-anaconda-ks* folder into the doc file in *docs/use-cases/bootc-container-anaconda-ks":

```
--8<-- "use-cases/bootc-container-anaconda-ks/ks.cfg"
```

When directly linking files within the repo, use direct linking to the GitHub repo, accessible using the variables **{{ config.repo_url}}{{ config.edit_uri }}** that points to the root (/blob/main/) folder of the repository, to avoid direct download within the browser.

### Adapting the mkdocs configuration

After adding a new use case it is enough to add the new use case to the **nav** section of [the mkdocs.yml configuration file](./mkdocs.yml) under the "Use Cases" section with a title and the link:

```
    - Generate a RHEL AMI image for an AWS instance using bootc-image-builder: use-cases/bootc-image-builder-ami/README.md
```
