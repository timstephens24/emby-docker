FROM ghcr.io/linuxserver/baseimage-ubuntu:focal as buildstage

# build args
ARG EMBY_RELEASE
ENV DEBIAN_FRONTEND="noninteractive"

RUN echo "**** install packages ****" \
  && apt-get update \
  && apt-get install -y cpio jq rpm2cpio \
  && echo "**** install emby ****" \
  && mkdir -p /app/emby \
  && if [ -z ${EMBY_RELEASE+x} ]; then \
      EMBY_RELEASE=$(curl -s https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest | jq -r '. | .tag_name'); \
    fi \
  && curl -o /tmp/emby.rpm -L \
    "https://github.com/MediaBrowser/Emby.Releases/releases/download/${EMBY_RELEASE}/emby-server-rpm_${EMBY_RELEASE}_x86_64.rpm" \
  && cd /tmp \
  && rpm2cpio emby.rpm | cpio -i --make-directories \
  && mv -t /app/emby/ /tmp/opt/emby-server/system/* /tmp/opt/emby-server/lib/* /tmp/opt/emby-server/bin/ff* /tmp/opt/emby-server/etc

# runtime stage
FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="stephens.cc version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="stephens.cc"

# add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# install packages
RUN echo "**** install dependencies ****" \
  && apt update \
  && apt install -y --no-install-recommends wget iproute2 beignet-opencl-icd jq ocl-icd-libopencl1 udev unrar wget \
  && COMP_RT_RELEASE=$(curl -sX GET "https://api.github.com/repos/intel/compute-runtime/releases/latest" | jq -r '.tag_name') \
  && COMP_RT_URLS=$(curl -sX GET "https://api.github.com/repos/intel/compute-runtime/releases/tags/${COMP_RT_RELEASE}" | jq -r '.body' | grep wget | sed 's|wget ||g') \
  && mkdir -p /opencl-intel \
  && for i in ${COMP_RT_URLS}; do \
      i=$(echo ${i} | tr -d '\r'); \
      echo "**** downloading ${i} ****"; \
      curl -o "/opencl-intel/$(basename ${i})" -L "${i}"; \
    done \
  && echo "**** cleanup ****" \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /opencl-intel

# add local files
COPY --from=buildstage /app/emby /app/emby
COPY root/ /

# ports and volumes
EXPOSE 8096 8920
VOLUME /config
