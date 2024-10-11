FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y gcc gcc-9 libc-dev make flex bison

ADD DSGen-software-code-3.2.0rc1 /home/tpcds
WORKDIR /home/tpcds/tools

RUN rm makefile
RUN mv Makefile.suite Makefile

RUN sed -i 's/\(LINUX_CC[\t ]*= gcc\)/\1-9/' Makefile
RUN echo 'define _END = "";' >> ../query_templates/netezza.tpl
RUN make
ADD auto_run_dsgen.sh .
RUN chmod +x auto_run_dsgen.sh
RUN mkdir data

ENTRYPOINT ["/home/tpcds/tools/auto_run_dsgen.sh"]
