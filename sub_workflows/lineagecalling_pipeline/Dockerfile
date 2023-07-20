# Use minconda base image 
FROM continuumio/miniconda3

# Set environment variables
ENV mykrobe_version=0.12.1

# Set the working directory within the container
WORKDIR /app

# Set up bioconda
RUN conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge \
    && conda config --set channel_priority strict

# Install McCortex
RUN conda install mccortex~=1.0

# Install mykrobe
RUN conda install mykrobe~=0.12.2

# Install jq
RUN conda install jq~=1.6

# Update mykrobe databases
RUN mykrobe panels update_metadata \
    && mykrobe panels update_species all

# Run mykrobe (In practice this command will be overriden by NextFlow)
CMD ["mykrobe", "--version"]