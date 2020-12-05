FROM timstephens24/ubuntu as buildstage

# build args
ARG EMBY_RELEASE
ENV DEBIAN_FRONTEND="noninteractive" 

RUN echo "**** install packages ****" \
  && apt-get update \
  && apt-get install -y cpio jq rpm2cpio \
  && echo "**** install emby ****" && \
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
FROM timstephens24/ubuntu

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="stephens.cc version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="stephens.cc"

# add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

# install packages
RUN echo "**** install packages ****" \
  && apt-get update \
  && apt-get install -y --no-install-recommends mesa-va-drivers \
  && echo "**** cleanup ****" \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* \
  && mkdir /tmp/neo \
  && cd /tmp/neo \
  && wget https://github.com/intel/compute-runtime/releases/download/20.48.18558/intel-gmmlib_20.3.2_amd64.deb \
  && wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.5699/intel-igc-core_1.0.5699_amd64.deb \
  && wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.5699/intel-igc-opencl_1.0.5699_amd64.deb \
  && wget https://github.com/intel/compute-runtime/releases/download/20.48.18558/intel-opencl_20.48.18558_amd64.deb \
  && wget https://github.com/intel/compute-runtime/releases/download/20.48.18558/intel-ocloc_20.48.18558_amd64.deb \
  && wget https://github.com/intel/compute-runtime/releases/download/20.48.18558/intel-level-zero-gpu_1.0.18558_amd64.deb \
  && dpkg -i *.deb

# add local files
COPY --from=buildstage /app/emby /app/emby
COPY root/ /

# ports and volumes
EXPOSE 8096 8920
VOLUME /config
