FROM nvidia/cuda:10.2-base-ubuntu18.04
LABEL maintainer="Nayab"
LABEL repository="upmonth"

# Locale environment variables
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Expose default uvicorn port
EXPOSE 8000

# Install required packages
RUN apt-get update && \
    apt-get -y --no-install-recommends install libgomp1 libsndfile1 gcc g++ python3.6 python3-dev python3-pip && \
    rm -rf /var/lib/apt/lists

# Install paperetl project and dependencies
RUN ln -s /usr/bin/python3.6 /usr/bin/python && \
    python -m pip install --no-cache-dir -U pip wheel setuptools && \
    python -m pip install --user -U nltk && \
    python -c "import nltk; nltk.download('punkt')"

# Cleanup build packages
RUN apt-get -y purge gcc g++ python3-dev && apt-get -y autoremove

# Generate YAML file
RUN echo "path: /upmonth" > index.yml && \
    echo "writable: True" >> index.yml && \
    echo "embeddings:" >> index.yml && \ 
    echo "  method: transformers" >> index.yml && \
    echo "  path: sentence-transformers/bert-base-nli-mean-tokens" >> index.yml && \
    echo "extractor:" >> index.yml && \
    echo "  path: distilbert-base-cased-distilled-squad" >> index.yml && \
    echo "labels:" >> index.yml

# Cache models in Docker image
RUN python -c "from transformers import AutoModel; AutoModel.from_pretrained('sentence-transformers/bert-base-nli-mean-tokens')" && \ 
    python -c "from transformers import AutoModel; AutoModel.from_pretrained('distilbert-base-cased-distilled-squad')" && \
    python -c "from transformers import AutoModel; AutoModel.from_pretrained('facebook/bart-large-mnli')"

# Start script on all interfaces (localhost + bridged interface)
ENTRYPOINT CONFIG=index.yml uvicorn --host 0.0.0.0 "upmonth.api:app"
