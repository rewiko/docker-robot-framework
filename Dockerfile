FROM python:3.9.0-alpine3.12

# Set the reports directory environment variable
ENV ROBOT_REPORTS_DIR /opt/robotframework/reports

# Set the tests directory environment variable
ENV ROBOT_TESTS_DIR /opt/robotframework/tests

# Set the working directory environment variable
ENV ROBOT_WORK_DIR /opt/robotframework/temp

# Setup the timezone to use, defaults to UTC
ENV TZ UTC

# Set number of threads for parallel execution
# By default, no parallelisation
ENV ROBOT_THREADS 1

# Define the default user who'll run the tests
ENV ROBOT_UID 1000
ENV ROBOT_GID 1000

# Dependency versions
ENV AWS_CLI_VERSION 1.20.6
ENV DATETIMETZ_VERSION 1.0.6
ENV FAKER_VERSION 5.0.0
ENV PABOT_VERSION 2.0.1
ENV REQUESTS_VERSION 0.9.1
ENV ROBOT_FRAMEWORK_VERSION 4.1

# By default, no reports are uploaded to AWS S3
ENV AWS_UPLOAD_TO_S3 false

# Prepare binaries to be executed
COPY bin/run-tests.sh /opt/robotframework/bin/

# Install system dependencies
RUN apk update \
  && apk --no-cache upgrade \
  && apk --no-cache --virtual .build-deps add \
    # Continue with system dependencies
    gcc \
    g++ \
    libffi-dev \
    linux-headers \
    make \
    musl-dev \
    openssl-dev \
    which \
    wget \
  && apk --no-cache add \
    xauth \
    tzdata \
# Install Robot Framework 
  && pip3 install \
    --no-cache-dir \
    robotframework==$ROBOT_FRAMEWORK_VERSION \
    robotframework-datetime-tz==$DATETIMETZ_VERSION \
    robotframework-faker==$FAKER_VERSION \
    robotframework-pabot==$PABOT_VERSION \
    robotframework-requests==$REQUESTS_VERSION \
    PyYAML \
# Install awscli to be able to upload test reports to AWS S3
    awscli==$AWS_CLI_VERSION \
# Clean up buildtime dependencies
  && apk del --no-cache --update-cache .build-deps

# Create the default report and work folders with the default user to avoid runtime issues
# These folders are writeable by anyone, to ensure the user can be changed on the command line.
RUN mkdir -p ${ROBOT_REPORTS_DIR} \
  && mkdir -p ${ROBOT_WORK_DIR} \
  && chown ${ROBOT_UID}:${ROBOT_GID} ${ROBOT_REPORTS_DIR} \
  && chown ${ROBOT_UID}:${ROBOT_GID} ${ROBOT_WORK_DIR} \
  && chmod ugo+w ${ROBOT_REPORTS_DIR} ${ROBOT_WORK_DIR}

# Allow any user to write logs
RUN chmod ugo+w /var/log \
  && chown ${ROBOT_UID}:${ROBOT_GID} /var/log

# Update system path
ENV PATH=/opt/robotframework/bin:/opt/robotframework/drivers:$PATH

# Set up a volume for the generated reports
VOLUME ${ROBOT_REPORTS_DIR}

USER ${ROBOT_UID}:${ROBOT_GID}

# A dedicated work folder to allow for the creation of temporary files
WORKDIR ${ROBOT_WORK_DIR}

# Execute all robot tests
CMD ["run-tests.sh"]
