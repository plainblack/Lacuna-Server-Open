docker run --rm -it --name=tle-server --net=tle-network -v ${PWD}/../captcha:/data/captcha -v ${PWD}/..:/data/Lacuna-Server icydee/tle-server /bin/bash
