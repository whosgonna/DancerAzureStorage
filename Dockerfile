### that by default pdi-build-deps will install our apps dependencies
### under /deps. This is important later on.
#COPY cpanfile* /app/
RUN git clone https://github.com/whosgonna/DancerAzureStorage.git . && \
    cd /app \
    && pdi-build-deps

### Copy the rest of the application to the app folder
#COPY . /app/


### The third stage is used to create a developers image, based on the
### package_deps and build phases, and with
### possible some extra tools that you might want during local
### development. This layer has no impact on the runtime final version,
### but can be generated with a `docker build --target devel`
FROM perl_package_deps AS devel

### Add any packaged dependencies that your application might need
### during development time. Given that we start from package_deps
### phase, all package dependencies from the build phase are already
### included.
#RUN    cd /app \
    #&& git remote set-url origin git@github.com:whosgonna/burnnote.git\
    #&& apk --no-cache add sqlite

### Assuming you have a cpanfile.devel file with all your devel-time
### dependencies, you can install it with this
#### Maybe add an empty cpanfile.devel?
#RUN cd /app
#&& pdi-build-deps cpanfile.devel

### Copy the App dependencies and the app code
COPY --from=perl-builder /deps/ /deps/
COPY --from=perl-builder /app/ /app/
#COPY .ssh/* /root/.ssh/
#COPY .profile /root/.profile

WORKDIR /app

#RUN chmod 600 /root/.ssh/id_rsa \
#    && cd /app
    #&& git remote set-url origin git@github.com:whosgonna/burnnote.git \
    #&& apk --no-cache add sqlite openssh-client

ENTRYPOINT ["sh", "-l"]

### And we are done: this "development" image can be generated with:
###
###      docker build -t my-app-devel --target devel .
###
### You can then run it as:
###
###      cd your-app-workdir; docker run -it --rm -v `pwd`:/app my-app-devel
###


### Now for the fourth and final stage, the runtime edition. We start from the
### runtime version and add all the files from the build phase
FROM melopt/perl-alt:latest-runtime

### Add any packaged dependencies that your application might need
#RUN apk --no-cache add postgres-libs

### Copy the App dependencies and the app code
COPY --from=perl-builder /deps/ /deps/
COPY --from=perl-builder /app/ /app/

### Add the command to start the application
CMD [ "plackup", "/app/bin/app.psgi" ]
