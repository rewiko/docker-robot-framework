# Robot Framework in Docker Alpine

## Project initially created by [ppodgorsek](https://github.com/ppodgorsek)

Code source avialable [here](https://github.com/ppodgorsek/docker-robot-framework).

I have just removed the browser library and to make it lighter, I will update it with use cases to test AWS and kubernetes resources.
## What is it?

This project consists of a Docker image containing a Robot Framework installation.

## Versioning

The versioning of this image follows the one of Robot Framework:

* Major version matches the one of Robot Framework
* Minor and patch versions are specific to this project (allows to update the versions of the other dependencies)

The versions used are:

* [Robot Framework](https://github.com/robotframework/robotframework) 4.1
* [Robot Framework DateTimeTZ](https://github.com/testautomation/DateTimeTZ) 1.0.6
* [Robot Framework Faker](https://github.com/guykisel/robotframework-faker) 5.0.0
* [Robot Framework Pabot](https://github.com/mkorpela/pabot) 2.0.1
* [Robot Framework Requests](https://github.com/bulkan/robotframework-requests) 0.9.1
* [Amazon AWS CLI](https://pypi.org/project/awscli/) 1.20.6

## Running the container

This container can be run using the following command:

    docker run \
        -v <local path to the reports' folder>:/opt/robotframework/reports:Z \
        -v <local path to the test suites' folder>:/opt/robotframework/tests:Z \
        rewiko/robot-framework:<version>

### Changing the container's tests and reports directories

It is possible to use different directories to read tests from and to generate reports to. This is useful when using a complex test file structure. To change the defaults, set the following environment variables:

* `ROBOT_REPORTS_DIR` (default: /opt/robotframework/reports)
* `ROBOT_TESTS_DIR` (default: /opt/robotframework/tests)

### Parallelisation

It is possible to parallelise the execution of your test suites. Simply define the `ROBOT_THREADS` environment variable, for example:

    docker run \
        -e ROBOT_THREADS=4 \
        rewiko/robot-framework:latest

By default, there is no parallelisation.

#### Parallelisation options

When using parallelisation, it is possible to pass additional [pabot options](https://github.com/mkorpela/pabot#command-line-options), such as `--testlevelsplit`, `--argumentfile`, `--ordering`, etc. These can be passed by using the `PABOT_OPTIONS` environment variable, for example:

    docker run \
        -e ROBOT_THREADS=4 \
        -e PABOT_OPTIONS="--testlevelsplit" \
        rewiko/robot-framework:latest

### Passing additional options

RobotFramework supports many options such as `--exclude`, `--variable`, `--loglevel`, etc. These can be passed by using the `ROBOT_OPTIONS` environment variable, for example:

    docker run \
        -e ROBOT_OPTIONS="--loglevel DEBUG" \
        rewiko/robot-framework:latest

### Dealing with Datetimes and Timezones

This project is meant to allow your tests to run anywhere. Sometimes that can be in a different timezone than your local one or of the location under test. To help solve such issues, this image includes the [DateTimeTZ Library](https://testautomation.github.io/DateTimeTZ/doc/DateTimeTZ.html).

To set the timezone used inside the Docker image, you can set the `TZ` environment variable:

    docker run \
        -e TZ=America/New_York \
        rewiko/robot-framework:latest

## Security consideration

By default, containers are implicitly run using `--user=1000:1000`, please remember to adjust that command-line setting accordingly, for example:

    docker run \
        --user=1001:1001 \
        rewiko/robot-framework:latest

Remember that that UID/GID should be allowed to access the mounted volumes in order to read the test suites and to write the output.

Additionally, it is possible to rely on user namespaces to further secure the execution. This is well described in the official container documentation:

* Docker: [Introduction to User Namespaces in Docker Engine](https://success.docker.com/article/introduction-to-user-namespaces-in-docker-engine)
* Podman: [Running rootless Podman as a non-root user](https://www.redhat.com/sysadmin/rootless-podman-makes-sense)

This is a good security practice to make sure containers cannot perform unwanted changes on the host. In that sense, Podman is probably well ahead of Docker by not relying on a root daemon to run its containers.

## Continuous integration

It is possible to run the project from within a Jenkins pipeline by relying on the shell command line directly:

    pipeline {
        agent any
        stages {
            stage('Functional regression tests') {
                steps {
                    sh "docker run --shm-size=1g -v $WORKSPACE/robot-tests:/opt/robotframework/tests:Z -v $WORKSPACE/robot-reports:/opt/robotframework/reports:Z rewiko/robot-framework:latest"
                }
            }
        }
    }

The pipeline stage can also rely on a Docker agent, as shown in the example below:

    pipeline {
        agent none
        stages {
            stage('Functional regression tests') {
                agent { docker {
                    image 'rewiko/robot-framework:latest'
                    args '--shm-size=1g -u root' }
                }
                environment {
                    ROBOT_TESTS_DIR = "$WORKSPACE/robot-tests"
                    ROBOT_REPORTS_DIR = "$WORKSPACE/robot-reports"
                }
                steps {
                    sh '''
                        /opt/robotframework/bin/run-tests-in-virtual-screen.sh
                    '''
                }
            }
        }
    }

### Defining a test run ID

When relying on Continuous Integration tools, it can be useful to define a test run ID such as the build number or branch name to avoid overwriting consecutive execution reports.

For that purpose, the `ROBOT_TEST_RUN_ID` variable was introduced:
* If the test run ID is empty, the reports folder will be: `${ROBOT_REPORTS_DIR}/`
* If the test run ID was provided, the reports folder will be: `${ROBOT_REPORTS_DIR}/${ROBOT_TEST_RUN_ID}/`

It can simply be passed during the execution, such as:

    docker run \
        -e ROBOT_TEST_RUN_ID="feature/branch-name" \
        rewiko/robot-framework:latest

By default, the test run ID is empty.

### Upload test reports to an AWS S3 bucket

To upload the report of a test run to an S3 bucket, you need to define the following environment variables:
    
    docker run \
        -e AWS_ACCESS_KEY_ID=<your AWS key> \
        -e AWS_SECRET_ACCESS_KEY=<your AWS secret> \
        -e AWS_DEFAULT_REGION=<your AWS region e.g. eu-central-1> \
        -e AWS_BUCKET_NAME=<name of your S3 bucket> \
        rewiko/robot-framework:latest

## Testing this project

Not convinced yet? Simple tests have been prepared in the `test/` folder, you can run them using the following commands:

```
docker-compose up
```

Screenshots of the results will be available in the `reports/` folder.

## Troubleshooting

### Accessing the logs

In case further investigation is required, the logs can be accessed by mounting their folder. Simply add the following parameter to your `run` command:

* Linux/Mac: ``-v `pwd`/logs:/var/log:Z``
* Windows: ``-v ${PWD}/logs:/var/log:Z``

### Error: Suite contains no tests

When running tests, an unexpected error sometimes occurs:

> [Error] Suite contains no tests.

There are two main causes to this:
* Either the test folder is not the right one,
* Or the permissions on the test folder/test files are too restrictive.

As there can sometimes be issues as to where the tests are run from, make sure the correct folder is used by trying the following actions:
* Use a full path to the folder instead of a relative one,
* Replace any`` `pwd` ``or `${PWD}` by the full path to the folder.

It is also important to check if Robot Framework is allowed to access the resources it needs, i.e.:
* The folder where the tests are located,
* The test files themselves.

## Please contribute!

Have you found an issue? Do you have an idea for an improvement? Feel free to contribute by submitting it [on the GitHub project](https://github.com/rewiko/docker-robot-framework/issues).
