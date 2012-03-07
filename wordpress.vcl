# This is a basic VCL configuration file for running varnish 3.x in front of
# WordPress.
# https://github.com/felixmiddendorf/wordpress.vcl

backend default {
    # Modify this according to your setup.
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    if (req.url ~ "preview=true") {
        # Send requests to preview versions straight to WordPress.
        return (pipe);
    }
    if (req.url ~ "\.(css|js|gif|jpg|jpeg|png|ico|zip|pdf|doc|docx)$"){
        # Static assets (images, CSS, JavaScript, downloads) have no need for
        # for cookies or compression.
        remove req.http.Cookie;
        remove req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
        set req.http.Accept-Encoding = "gzip"; # normalize (favoring gzip)
    } elsif (req.http.Accept-Encoding ~ "deflate") {
        set req.http.Accept-Encoding = "deflate"; # normalize (2nd choice)
    } else {
        remove req.http.Accept-Encoding; # unknown algorithm, most likely junk
    }

    if (req.http.Cookie) {
        # Uncomment the following "set" line if you are using Google Analytics.
        # Remove all cookies named "__utm?".
        # set req.http.Cookie = regsuball(req.http.Cookie, "(^|; ) *__utm.=[^;]+;? *", "\1");

        # Remove irrelevant WordPress cookies unless "wp-login" or "wp-admin" is part of the URL.
        if (!(req.url ~ "wp-(login|admin)")) {
            set req.http.Cookie = regsuball(req.http.Cookie, "(^|; ) *(wordpress_test_cookie|wp-settings)[^;=]+=[^;]+;? *", "\1");
        }

        # Remove the "Cookie" header altogether if no cookies are left.
        if (req.http.Cookie == "") {
            remove req.http.Cookie;
        }
    }
}
