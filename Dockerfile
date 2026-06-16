FROM maayanlab/base:1.6.0 AS builder
ADD requirements.txt ./requirements.txt
RUN NODE_VERSION=20 PYTHON_VERSION=3.11 /install.sh && rm requirements.txt
COPY --chown=ubuntu ./src /home/ubuntu
RUN HOST=0.0.0.0 jupyter book build --html --keep-host

FROM nginx
COPY --from=builder /home/ubuntu/_build/html /usr/share/nginx/html/