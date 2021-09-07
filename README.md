UNBOUND-BADHOSTS(8) - System Manager's Manual

# NAME

**unbound-badhosts** - fetch blocklists for use with unbound

# SYNOPSIS

**unbound-badhosts**
\[**-fgpsx**&nbsp;|&nbsp;**-v**]

# DESCRIPTION

**unbound-badhosts**
is a utility that will fetch and process host file blocklists so it can be
used with the
unbound(8)
DNS resolver.

When run without any options,
**unbound-badhosts**
will create a blocklist containing adware and malware data, and attempt to
reload
unbound(8).
Variants to this default blocklist can be specified by passing one or more
optional flags.

Alternativly, the processed blocklist data can printed to stdout.

The options are as follows:

**-f**

> Include fake news sites in the blocklist.

**-g**

> Include gambling sites in the blocklist.

**-p**

> Include adult sites in the blocklist.

**-s**

> Include social media sites in the blocklist.

**-v**

> Print version information and exit.

**-x**

> Print blocklist data to stout and exit.

# FILES

*/var/unbound/etc/badhosts*

> Location of saved blocklist.

# EXIT STATUS

The **unbound-badhosts** utility exits&#160;0 on success, and&#160;&gt;0 if an error occurs.

# SEE ALSO

unbound.conf(5),
unbound(8),
unbound-control(8)

[https://github.com/StevenBlack/hosts](https://github.com/StevenBlack/hosts)

# AUTHORS

Sean Davies &lt;[sean@city17.org](mailto:sean@city17.org)&gt;

OpenBSD 7.0 - July 12, 2021
