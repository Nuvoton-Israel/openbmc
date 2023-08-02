do_patch:m1120-c2195() {
    bb.build.exec_func("update_i2cdev", d)
}

update_i2cdev() {
    sed -i 's/f0081000.i2c/f0083000.i2c/g' ${WORKDIR}/reload-sensors.sh
}
