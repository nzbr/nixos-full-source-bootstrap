src_configure () {
    ./configure
}

src_compile () {
    make
}

src_install () {
    make DESTDIR="${DESTDIR}" install
}
