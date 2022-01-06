FROM ubuntu:18.04

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get --no-install-recommends -y install tzdata

RUN apt install --no-install-recommends -y bedtools samtools wget perl build-essential make software-properties-common dirmngr gpg-agent libpng-dev libjpeg-turbo8-dev

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && apt update

RUN apt install --no-install-recommends -y r-base r-cran-lattice gfortran
RUN apt upgrade --no-install-recommends -y
 
# Fix to get libpng12.so.0 installed
RUN wget http://fr.archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb \
    && dpkg -x libpng12-0_1.2.54-1ubuntu1_amd64.deb /root/libpng12 \
    && ln -s /root/libpng12/lib/x86_64-linux-gnu/libpng12.so.0 /usr/lib/libpng12.so.0 \
    && ln -s /root/libpng12/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /usr/lib/libpng12.so.0.54.0 \
    && ldconfig

RUN R -e "install.packages('latticeExtra', repos = 'http://cran.uk.r-project.org')"	
	
RUN R -e "install.packages('Hmisc', repos = 'http://cran.uk.r-project.org')"	
	
RUN cd /usr \
    && wget --no-check-certificate https://sourceforge.net/projects/excavator2tool/files/EXCAVATOR2_Package_v1.1.2.tgz \
    && tar zxvf EXCAVATOR2_Package_v1.1.2.tgz \
    && R CMD SHLIB /usr/EXCAVATOR2_Package_v1.1.2/lib/F77/F4R.f \
    && R CMD SHLIB /usr/EXCAVATOR2_Package_v1.1.2/lib/F77/FastJointSLMLibraryI.f
	
COPY GCA_000001405.15_GRCh38.bw /usr/EXCAVATOR2_Package_v1.1.2/data/
COPY ucsc.hg19.bw /usr/EXCAVATOR2_Package_v1.1.2/data/

COPY SourceTarget.hg19.txt /usr/EXCAVATOR2_Package_v1.1.2/
COPY SourceTarget.hs37d5.txt /usr/EXCAVATOR2_Package_v1.1.2/
COPY SourceTarget.hg38.txt /usr/EXCAVATOR2_Package_v1.1.2/

# GRCh37 wig file for complexity masking
RUN wget --no-check-certificate http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigWigToWig \
    && wget --no-check-certificate  http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/wigToBigWig \
    && wget --no-check-certificate -O /usr/EXCAVATOR2_Package_v1.1.2/data/hg19.chrom.sizes http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.chrom.sizes \
    && sed 's/chr//' /usr/EXCAVATOR2_Package_v1.1.2/data/hg19.chrom.sizes > /usr/EXCAVATOR2_Package_v1.1.2/data/grch37.sizes \
    && chmod +x *Wig*
RUN ./bigWigToWig /usr/EXCAVATOR2_Package_v1.1.2/data/ucsc.hg19.bw /usr/EXCAVATOR2_Package_v1.1.2/data/ucsc.hg19.wig \
    && sed s'/^chr//' /usr/EXCAVATOR2_Package_v1.1.2/data/ucsc.hg19.wig > /usr/EXCAVATOR2_Package_v1.1.2/data/grch37.wig \
    && ./wigToBigWig /usr/EXCAVATOR2_Package_v1.1.2/data/grch37.wig /usr/EXCAVATOR2_Package_v1.1.2/data/grch37.sizes /usr/EXCAVATOR2_Package_v1.1.2/data/grch37.bw

ENV PATH $PATH:/usr/EXCAVATOR2_Package_v1.1.2

WORKDIR /usr/EXCAVATOR2_Package_v1.1.2

CMD ["bash"]
