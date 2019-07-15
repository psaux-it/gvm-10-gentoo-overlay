# GVM 10.0.0 (Greenbone Vulnerability Management) for Gentoo/Linux (Previously named OpenVAS)

This is not official Gentoo/Linux GVM package.

You can find -OLD- official Gentoo/Linux OpenVAS package: 
https://packages.gentoo.org/packages/net-analyzer/openvas

The new GVM-10 package hasn't been merged to main gentoo tree yet so you can use this overlay to use new GVM-10 version.

# Important Note:

If you confused about GVM and OpenVAS keep reading.

It is simple, OpenVAS project name changed to GVM (Greenbone Vulnerability Management).
Also some of the component names changed.You can find new naming schema for linux distros in below table.

You can find official discussion about new project naming schema on upstream -- > https://github.com/greenbone/gvm-libs/issues/197

```
Main Project Name:

GVM                          --> previously named OpenVAS

-------------------------------------------------------------------

Components Names:

gvm-libs                     --> previously named openvas-libraries
openvas-scanner              --> not changed
gvmd                         --> previously named openvas-manager
greenbone-security-assistant --> not-changed
gvm-tools                    --> previously named openvas-cli
ospd                         --> not changed

```

## Current Ebuild Versions

    GVM                          --> 10.0.0 (stable, latest)

---------------------------------------

    gvm-libs                     --> 10.0.0 (stable, latest)
    openvas-scanner              -->  6.0.0 (stable, latest)
    gvmd                         -->  8.0.0 (stable, latest)
    greenbone-security-assistant -->  8.0.0 (stable, latest)
    gvm-tools                    -->  1.4.1 (stable, latest)
    ospd                         -->  1.3.2 (stable, latest)

## Major Changes in GVM-10

Huge improvement in WEBUI (greenbone-security-assistant), lots of bug fixing in all components. Greenbone security assistant is completely rewritten in react.


## What is GVM (previously named OpenVAS)

GVM is a full-featured vulnerability scanner. Its capabilities include unauthenticated testing, authenticated testing, various high level and low level Internet and industrial protocols, performance tuning for large-scale scans and a powerful internal programming language to implement any type of vulnerability test.

    GVM Community Edition        --> https://github.com/greenbone
    OpenVAS HomePage (OLD)       --> http://www.openvas.org/
    Greenbone HomePage           --> https://www.greenbone.net/en/

## Usage

### via local overlays

Copy "gvm-overlay.conf" from this repository into /etc/portage/repos.conf/ to use the portage sync capabilities.
Alternatively you can create a /etc/portage/repos.conf/gvm-overlay.conf file containing:

    [gvm-overlay]
    location = /usr/local/custom/gvm-overlay
    sync-type = git
    sync-uri = https://github.com/hsntgm/gvm-10-gentoo-overlay.git
    priority = 9999

Then run:

    sync repo       --> emerge --sync or eix-sync or emaint -a sync
    install package --> emerge --ask net-analyzer/gvm

### via layman

    layman -o https://raw.github.com/hsntgm/gvm-10-gentoo-overlay/master/repositories.xml -f -a gvm-overlay

Then run:

    layman -s gvm-overlay

## Use Flags

     IUSE="cli cron extras gsa ldap ospd radius"

 - cli        --> Command Line Interfaces for OpenVAS-Scanner
 - cron       --> Install a cron job to update GVM's feed daily
 - extras     --> Required for docs, pdf results and fonts | Recommended
 - gsa        --> Greenbone Security Assistant (WebUI)
 - ldap       --> LDAP Support for Greenbone Vulnerability Management
 - ospd       --> Scanner wrappers which share the same communication protocol
 - postgres   --> Use PostgreSQL for data storage
 - radius     --> Radius Support for Greenbone Vulnerability Management

## Scripts

    Inspect the scripts. You never blindly run scripts you
    downloaded from the Internet, do you?
    
https://github.com/hsntgm/gvm-10-scripts
