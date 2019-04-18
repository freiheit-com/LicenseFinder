#
# Go profile
# added as
# /etc/profile.d/go.sh
# to set up PATH to go executables
#

if [[ -n "$GOPATH" && ! ":${PATH}:" == *":$GOPATH/bin:"* ]] ; then
    PATH="$GOPATH/bin:$PATH"
fi
