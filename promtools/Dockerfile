FROM golang:latest

MAINTAINER Egon Rijpkema <e.m.a.rijpkema@rug.nl>

RUN mkdir /results

RUN go install github.com/prometheus/node_exporter@latest && \
    cp /go/bin/node_exporter /results

RUN go install github.com/vpenso/prometheus-slurm-exporter@latest  && \
    cp /go/bin/prometheus-slurm-exporter /results

RUN go install git.webhosting.rug.nl/HPC/nvidia_smi_exporter.git@latest  && \
    cp /go/bin/nvidia_smi_exporter.git /results/nvidia_smi_exporter

RUN go install github.com/soundcloud/ipmi_exporter@latest  && \
    cp /go/bin/ipmi_exporter /results/ipmi_exporter

CMD /go/bin/proxy
