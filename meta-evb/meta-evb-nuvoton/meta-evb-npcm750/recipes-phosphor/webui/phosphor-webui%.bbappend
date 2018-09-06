FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-Implement-KVM-in-webui.patch"


do_compile () {
    cd ${S}
    rm -rf node_modules
    npm --loglevel info --proxy=${HTTP_PROXY} --https-proxy=${HTTPS_PROXY} install
    sed -i -e 's/new WebSocket(uri, protocols)/new WebSocket(uri)/g' node_modules/@novnc/novnc/core/websock.js
    npm run-script build
}


