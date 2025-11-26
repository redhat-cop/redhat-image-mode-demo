#MAINTAINER Alessandro Rossi <alerossi@redhat.com>
FROM registry.access.redhat.com/ubi9/python-312
RUN pip3 install mkdocs mkdocs-material mkdocs-macros-plugin mkdocs-mermaid2-plugin
ENTRYPOINT mkdocs serve -a 0.0.0.0:8000
