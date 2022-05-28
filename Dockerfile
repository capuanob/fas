# Build Stage
FROM fuzzers/aflplusplus:3.12c as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake wget clang gcc libasound-dev jackd qjackctl libjack-jackd2-dev libwebsockets-dev aubio-tools libsndfile1-dev libsamplerate0-dev

## Install PortAudio (Dependency for Building)
WORKDIR /
RUN wget http://files.portaudio.com/archives/pa_stable_v190700_20210406.tgz
RUN tar xvzf pa_stable_v190700_*
RUN rm pa_stable*.tgz
WORKDIR portaudio
RUN ./configure
RUN make clean && make -j$(nproc) && make install

# Install libldfds (Dependency for Building)
WORKDIR /lib
RUN wget https://liblfds.org/downloads/liblfds%20release%207.1.1%20source.tar.bz2
RUN tar xf liblfds* --one-top-level=liblfds --strip-components 1
RUN rm libl*bz2
WORKDIR liblfds/liblfds711/build/gcc_gnumake
RUN make -j$(nproc)



## Add source code to the build stage. ADD prevents git clone being cached when it shouldn't
WORKDIR /
ADD https://api.github.com/repos/capuanob/fas/git/refs/heads/mayhem version.json
RUN git clone -b mayhem https://github.com/capuanob/fas.git
WORKDIR /fas

## Build
WORKDIR /build
RUN cmake -S . -B . -DCMAKE_BUILD_TYPE=Release && make -j$(nproc)


## Prepare all library dependencies for copy
#RUN mkdir /deps
#RUN cp `ldd ./src/gregorio-6* | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :
#RUN cp `ldd /usr/local/bin/afl-fuzz | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :

## Package Stage

#FROM --platform=linux/amd64 ubuntu:20.04
#COPY --from=builder /usr/local/bin/afl-fuzz /afl-fuzz
#COPY --from=builder /gregorio/src/gregorio-6* /gregorio
#COPY --from=builder /deps /usr/lib
#COPY --from=builder /gregorio/corpus /tests

#env AFL_SKIP_CPUFREQ=1

#ENTRYPOINT ["/afl-fuzz", "-i", "/tests", "-o", "/out"]
#CMD ["/gregorio", "--stdin", "--stdout"]
