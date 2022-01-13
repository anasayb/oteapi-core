FROM ubuntu:21.04 as base

# Prevent writing .pyc files on the import of source modules
# and set unbuffered mode to ensure logging outputs
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory
WORKDIR /app

RUN apt-get -qq update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -qq -y --fix-missing \
    python3-dev \
    python3-pip \
    curl \
    git

RUN curl -L -o /tmp/dlite.deb https://github.com/SINTEF/dlite/releases/download/0.3.1/dlite-0.3.1-x86_64.deb

RUN apt-get install -y -f /tmp/dlite.deb \
  && rm -rf /var/lib/apt/lists/*

# Install requirements
COPY ./requirements.txt ./README.md ./
RUN pip install -q --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade pip \
  && pip install -q --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org --upgrade setuptools wheel
RUN pip install -q --trusted-host pypi.org --trusted-host files.pythonhosted.org .

ENV DLITE_ROOT=/usr
ENV DLITE_STORAGES=/app/entities/*.json
ENV PYTHONPATH=/usr/lib64/python3.9/site-packages
RUN mkdir -p /app/entities

################# DEVELOPMENT ####################################
FROM base as development
COPY . .

# Run static security check and linters
RUN pre-commit run --all-files  \
  && safety check -r requirements.txt

# Run pytest with code coverage
RUN pytest --cov app

# Run with reload option
CMD hypercorn wsgi:app --bind 0.0.0.0:8080 --reload
EXPOSE 8080


################# PRODUCTION ####################################
FROM base as production
COPY . .

# Run app
CMD hypercorn wsgi:app --bind 0.0.0.0:80
EXPOSE 80
