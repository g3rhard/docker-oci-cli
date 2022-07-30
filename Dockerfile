ARG ARCH=armv7hf
ARG PYTHON_VERSION=3.9
ARG PKG=oci-cli
ARG PKG_VERSION=3.12.0

FROM balenalib/${ARCH}-debian-python:${PYTHON_VERSION}-build as builder
ARG PKG
ARG PKG_VERSION
ARG ARCH
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1

RUN if [ ${ARCH} = "armv7hf" ] ; then [ "cross-build-start" ] ; fi

RUN apt update

RUN apt-get install -y build-essential libssl-dev libffi-dev \
    python3-dev cargo

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

RUN pip3 install --upgrade pip
RUN pip3 install wheel \
    && pip3 wheel ${PKG}==${PKG_VERSION} --wheel-dir=/tmp/build-${PKG}
RUN if [ ${ARCH} = "armv7hf" ] ; then [ "cross-build-end" ] ; fi

FROM balenalib/${ARCH}-debian-python:${PYTHON_VERSION}
ARG PKG
ARG ARCH
COPY --from=builder /tmp/build-${PKG} /tmp/build-${PKG}
WORKDIR /tmp/build-${PKG}
RUN if [ ${ARCH} = "armv7hf" ] ; then [ "cross-build-start" ] ; fi
RUN pip3 install --no-index --find-links=/tmp/build-${PKG} ${PKG} \
    && rm -rf /tmp/build-${PKG}
RUN useradd -m ${PKG}
RUN if [ ${ARCH} = "armv7hf" ] ; then [ "cross-build-end" ] ; fi

USER ${PKG}
WORKDIR /
ENTRYPOINT [ "oci" ]
