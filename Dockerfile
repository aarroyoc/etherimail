FROM rust:1.57.0

RUN git clone https://github.com/mthom/scryer-prolog
RUN cd scryer-prolog && \
    cargo build --release && \
    cp target/release/scryer-prolog /usr/bin/scryer-prolog

WORKDIR /opt/etherimail

COPY . .